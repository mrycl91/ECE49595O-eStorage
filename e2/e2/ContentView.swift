// ContentView.swift

import SwiftUI
import Combine


struct ContentView: View {
    @Binding var items: [Item]
    @State private var selectedItem: Item?
    @State private var showingDeleteAlert = false
    @State private var showingALLDeleteAlert = false
    @State private var navigationTag: Int?

    // Key for UserDefaults
    private let itemsKey = "StoredItemsKey"

    var body: some View {
        VStack{
            GeometryReader { proxy in
                Text("Grocery Lists")
                    .font(.system(size: 26, weight: .bold))
                    .position(x: 120, y: 60)
                    .foregroundColor(Color(hex: 0x535657))
                Path { path in
                    path.move(to: CGPoint(x:proxy.size.width, y:0))
                    path.addArc(
                        center: CGPoint(x:proxy.size.width, y:0),
                        radius: 110,
                        startAngle: Angle(degrees: 90),
                        endAngle: Angle(degrees: 180),
                        clockwise: false
                    )
                    path.closeSubpath()
                }
                    .fill(Color(hex: 0x535657))
                
                Button(action: {
                    showingALLDeleteAlert = true
                }, label: {
                    Text("Delete\n       All")
                        .foregroundColor(Color(hex: 0xf4faff))
                })
                    .frame(width: 100, height:80)
                    .position(x: proxy.size.width - 55, y: 45)
                    .alert(isPresented: $showingALLDeleteAlert) {
                        Alert(
                            title: Text("Delete Expired Item"), message: Text("Confirm deletion of all expired items?"),
                            primaryButton: .destructive(Text("Delete")) {
                                deleteAllExpiredItems()
                                showingALLDeleteAlert = false
                            },
                            secondaryButton: .cancel(){
                                showingALLDeleteAlert = false
                            }
                        )
                    }
            }
//            ScrollView{
                VStack{
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
                    .listRowBackground(Color(hex: 0xdee7e7))
                    .listStyle(PlainListStyle()) // Use PlainListStyle for a cleaner appearance
                    .alert(isPresented: $showingDeleteAlert) {
                        Alert(
                            title: Text("Delete Item"), message: Text("Are you sure you want to delete \(selectedItem?.name ?? "this item")?"),
                            primaryButton: .destructive(Text("Delete")) {
                                deleteSelectedItem()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
//            }
        }
        .background(Color(hex: 0xdee7e7))
    }

    private func deleteItems(at offsets: IndexSet) {
        selectedItem = items[offsets.first ?? 0]
        showingDeleteAlert = true
    }

    private func deleteSelectedItem() {
        print("delete selected item")
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
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let items: [Item] = [] // Provide sample data
        
        // Use a dummy Binding to pass the items array to the preview
        ContentView(items: .constant(items))
    }
}
