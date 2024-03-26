// ContentView.swift

import SwiftUI
import Combine


enum MealType: String, CaseIterable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case somethingSimple = "Something Simple"
}






struct ContentView: View {
    @State private var items: [Item] = []
    @State private var showingAddItemView = false
    @State private var selectedItem: Item?
    @State private var showingDeleteAlert = false
    @State private var navigationTag: Int?
    @State private var showingOptions = false
    @State private var selectedMealType: MealType?
    @State private var recommendationContent: String?

    // Key for UserDefaults
    private let itemsKey = "StoredItemsKey"

    var body: some View {
            NavigationView {
                VStack(spacing: 10) { // Add some spacing between views
                    List {
                        ForEach(items.indices, id: \.self) { index in
                            NavigationLink(destination: ItemDetailView(item: items[index]), tag: index, selection: $navigationTag) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(" \(items[index].name)")
                                            .foregroundColor(isItemExpired(items[index].expirationDate) ? .red : .primary)
                                        if let expirationDate = items[index].expirationDate {
                                            Text("Expiration Date: \(formattedDate(expirationDate))")
                                                .foregroundColor(isItemExpired(expirationDate) ? .red : .secondary)
                                        }
                                    }
                                    Spacer()
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedItem = items[index]
                                navigationTag = index
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .listStyle(PlainListStyle()) // Use PlainListStyle for a cleaner appearance

                    // Buttons with adjusted styling
                    VStack(spacing: 20) { // Add spacing between buttons
                        Button(action: {
                            deleteAllExpiredItems()
                        }) {
                            Text("Delete Expired Items➖")
                                .padding()
                                .foregroundColor(Color.white)
                                .background(Color.red)
                                .cornerRadius(8)
                        }

                        Button(action: {
                            showingAddItemView = true
                        }) {
                            Text("Add Item➕")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }

                        Button(action: {
                            showingOptions = true
                        }) {
                            Text("Recommend Recipe🥘")
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                }
                .navigationTitle("eStorage🍔")
                .onAppear(perform: loadItems)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    saveItems()
                }
                
                .sheet(isPresented: $showingAddItemView) {
                    AddItemView(onAdd: { newItem in
                        addItem(newItem)
                        showingAddItemView = false // Dismiss AddItemView
                    })
                }

                
                
                
                .sheet(isPresented: $showingOptions) {
                    MealTypeSelectionView(selectedMealType: $selectedMealType, recommendationContent: $recommendationContent) { mealType in
                        recommendRecipes(for: mealType)
                    }
                }
                .alert(isPresented: $showingDeleteAlert) {
                    Alert(
                        title: Text("Delete Item"),
                        message: Text("Are you sure you want to delete \(selectedItem?.name ?? "this item")?"),
                        primaryButton: .destructive(Text("Delete")) {
                            deleteSelectedItem()
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
        }

    private func recommendRecipes(for mealType: MealType) {
        print("Recommendation requested for meal type: \(mealType.rawValue)")

        guard let selectedMealType = selectedMealType else {
            print("Selected meal type is nil")
            return
        }

        // Prepare the prompt for GPT-3 based on selected meal type and available ingredients
        let ingredients = items.map { $0.name }.joined(separator: ", ")
        let prompt = "What can I have for \(selectedMealType.rawValue) with \(ingredients) in my storage? Just simply list out the name,ingrediants,and steps to make it,be as concise as possible,just show 1 recipe"

        // Construct the request data including the required 'messages' property
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

        // Call GPT-3 API
        let apiKey = "apikey"
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


    private func addItem(_ newItem: Item) {
        if let index = items.firstIndex(where: { $0.expirationDate ?? Date() > newItem.expirationDate ?? Date() }) {
            items.insert(newItem, at: index)
        } else {
            items.append(newItem)
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        selectedItem = items[offsets.first ?? 0]
        showingDeleteAlert = true
    }

    private func deleteSelectedItem() {
        if let selectedItem = selectedItem,
           let index = items.firstIndex(where: { $0.id == selectedItem.id }) {
            items.remove(at: index)
        }
        selectedItem = nil
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func isItemExpired(_ expirationDate: Date?) -> Bool {
        guard let expirationDate = expirationDate else {
            return false
        }
        let currentDate = Date()

        return currentDate > expirationDate
    }

    private func deleteAllExpiredItems() {
        let currentDate = Date()
        let expiredItemsIndices = items.indices.filter { index in
            guard let expirationDate = items[index].expirationDate else {
                return false
            }
            return currentDate > expirationDate
        }

        // Display an alert if there are no expired items to delete
        guard !expiredItemsIndices.isEmpty else {
            showingDeleteAlert = true
            selectedItem = nil
            return
        }

        // Delete expired items
        for index in expiredItemsIndices.reversed() {
            items.remove(at: index)
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}



struct MealTypeSelectionView: View {
    @Binding var selectedMealType: MealType?
    @Binding var recommendationContent: String?
    var onSelection: ((MealType) -> Void)
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Recipe Recommendation🌮")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.blue)

            ScrollView {
                if let recommendationContent = recommendationContent {
                    Text(recommendationContent)
                        .padding()
                        .multilineTextAlignment(.leading)
                } else if isLoading {
                    ProgressView("Loading Recipes...")
                        .padding()
                        .foregroundColor(.blue)
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                }
            }
            .padding()

            Text("Select Meal Type🥐")
                .font(.title)
                .fontWeight(.semibold)

            VStack(spacing: 10) {
                ForEach(MealType.allCases, id: \.self) { type in
                    Button(action: {
                        selectedMealType = type
                        isLoading = true
                        recommendationContent = nil
                        onSelection(type)
                    }) {
                        Text(type.rawValue)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .navigationBarTitle("Meal Type", displayMode: .inline)
    }
}
