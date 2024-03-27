//
//  MainView.swift
//  e2
//
//  Created by Anita Chen on 3/26/24.
//
import SwiftUI
import Foundation

enum MealType: String, CaseIterable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case somethingSimple = "Snack"
}

struct MainView: View {
    @State private var items: [Item] = []
    @State private var selectedMealType: MealType?
    @State private var recommendationContent: String?
    private let itemsKey = "StoredItemsKey"
    
    var body: some View {
            TabView{
                ContentView(items: $items)
                    .tabItem {
                        Label("List", systemImage: "list.dash")
                    }
                    .onAppear(perform: loadItems)
                AddItemView(onAdd: { newItem in
                    addItem(newItem)
                    })
                    .tabItem {
                        Label("Add Item", systemImage: "cart.badge.plus")
                    }
                MealTypeSelectionView(selectedMealType: $selectedMealType, recommendationContent: $recommendationContent) { mealType in
                    recommendRecipes(for: mealType)
                }
                    .tabItem {
                        Label("Recipe", systemImage: "book.pages.fill")
                    }
                Text("Setting")
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)){ _ in
                saveItems()
            }
    }
    
    private func loadItems() {
        if let data = UserDefaults.standard.data(forKey: itemsKey) {
            if let decodedItems = try? JSONDecoder().decode([Item].self, from: data) {
                items = decodedItems
            }
        }
    }
    
    private func saveItems() {
        if let encodedData = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encodedData, forKey: itemsKey)
        }
    }
    
    private func addItem(_ newItem: Item) {
        if let index = items.firstIndex(where: { $0.expirationDate ?? Date() > newItem.expirationDate ?? Date() }) {
            items.insert(newItem, at: index)
        } else {
            items.append(newItem)
        }
    }
    
    private func recommendRecipes(for mealType: MealType) {
        print("Recommendation requested for meal type: \(mealType.rawValue)")

        guard let selectedMealType = selectedMealType else {
            print("Selected meal type is nil")
            return
        }
        let ingredients = items.map { $0.name }.joined(separator: ", ")
        let prompt = "What can I have for \(selectedMealType.rawValue) with \(ingredients) in my storage? Just simply list out the name,ingrediants,and steps to make it,be as concise as possible,just show 1 recipe"
        let requestData: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 300
        ]
        let apiKey = "api_key"
        let apiUrl = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestData)
        } catch {
            print("Error serializing request data: \(error)")
            return
        }
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error calling GPT API: \(error)")
                return
            }
            guard let data = data else {
                print("No data received from GPT-3.5 API")
                return
            }
            if let responseString = String(data: data, encoding: .utf8) {
                  if let responseData = responseString.data(using: .utf8) {
                      do {
                          let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any]
                          if let choices = json?["choices"] as? [[String: Any]], let firstChoice = choices.first, let message = firstChoice["message"] as? [String: Any], let content = message["content"] as? String {
                              recommendationContent = content
                          }
                      } catch {
                          print("Error decoding response from GPT-3.5 API: \(error)")
                      }
                  }
              } else {
                  print("Unable to decode response from GPT-3.5 API")
              }
          }.resume()
      }
}


struct MealTypeSelectionView: View {
    @Binding var selectedMealType: MealType?
    @Binding var recommendationContent: String?
    var onSelection: ((MealType) -> Void)
    @State private var isLoading = false
    @State private var decisionMade = false

    var body: some View {
        VStack(spacing: 20) {
//            Text("Let's see what we have...")
//                .font(.largeTitle)
//                .fontWeight(.bold)
//                .foregroundColor(.blue)
            
            if decisionMade {
                ScrollView {
                    if let recommendationContent = recommendationContent {
                        Text(recommendationContent)
                            .padding()
                            .multilineTextAlignment(.leading)
                        Button(action: {
                            isLoading = false
                            decisionMade = false
                        }) {
                            Text("Generate New Recipe")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 200, height: 30)
                                .padding()
                                .background(Color.blue)
                        }
                    } else if isLoading {
                        Spacer()
                        ProgressView("Loading Recipes...")
                            .padding()
                            .foregroundColor(.blue)
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        Spacer()
                    }
                }
                .padding()
            }
            else{
                Spacer()
                
                Text("Time for...")
                    .padding(.vertical, 40)
                    .font(.title)
                    .fontWeight(.semibold)
                
                VStack(spacing: 10) {
                    ForEach(MealType.allCases, id: \.self) { type in
                        Button(action: {
                            selectedMealType = type
                            isLoading = true
                            recommendationContent = nil
                            onSelection(type)
                            decisionMade = true
                        }) {
                            Text(type.rawValue)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 100, height: 30)
                                .padding()
                                .background(Color.blue)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
//        .background(Color(hex: 0xdee7e7))
    }
}


struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}


extension Color {
    init(hex: Int, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: opacity
        )
    }
}
