// ContentView.swift

import SwiftUI

struct ContentView: View {
    @State private var items: [Item] = []
    @State private var showingAddItemView = false
    @State private var selectedItem: Item?
    @State private var showingDeleteAlert = false
    @State private var navigationTag: Int?

    // Key for UserDefaults
    private let itemsKey = "StoredItemsKey"

    var body: some View {
        NavigationView {
            VStack {
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

                // New Button to delete all expired items
                Button("Delete Expired Items", action: {
                    deleteAllExpiredItems()
                })
                .foregroundColor(.red)
                .padding()

                NavigationLink(destination: AddItemView(onAdd: { newItem in
                    addItem(newItem)
                    showingAddItemView = false // Dismiss AddItemView
                }), isActive: $showingAddItemView) {
                    EmptyView()
                }

                Button("Add Item", action: {
                    showingAddItemView = true
                })
                .padding()
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
            .navigationTitle("eStorage🍔")
            .onAppear(perform: loadItems)
            .onDisappear(perform: saveItems)
        }
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
