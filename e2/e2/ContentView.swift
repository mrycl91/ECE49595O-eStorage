// ContentView.swift
// e2
// Created by 李京樺 on 2024/1/28.

import SwiftUI

struct ContentView: View {
    @State private var items: [Item] = []
    @State private var showingAddItemView = false
    @State private var selectedItem: Item?
    @State private var showingDeleteAlert = false
    @State private var navigationTag: Int?

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(items.indices, id: \.self) { index in
                        NavigationLink(destination: ItemDetailView(item: items[index]), tag: index, selection: $navigationTag) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(" \(items[index].name)")
                                    if let expirationDate = items[index].expirationDate {
                                        Text("Expiration Date: \(formattedDate(expirationDate))")
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
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
