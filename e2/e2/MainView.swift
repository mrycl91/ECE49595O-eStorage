//
//  MainView.swift
//  e2
//
//  Created by Anita Chen on 3/26/24.
//
import SwiftUI
import Foundation

struct MainView: View {
    @State private var items: [Item] = []
    var body: some View {
            TabView{
                ContentView(items: $items)
                    .tabItem {
                        Label("List", systemImage: "list.dash")
                    }
                AddItemView(onAdd: { newItem in
                    addItem(newItem)
                    })
                    .tabItem {
                        Label("Add Item", systemImage: "cart.badge.plus")
                    }
                Text("Recipe")
                    .tabItem {
                        Label("Recipe", systemImage: "book.pages.fill")
                    }
                Text("Setting")
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
            }
    }
    
    private func addItem(_ newItem: Item) {
        if let index = items.firstIndex(where: { $0.expirationDate ?? Date() > newItem.expirationDate ?? Date() }) {
            items.insert(newItem, at: index)
        } else {
            items.append(newItem)
        }
    }
}


struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
//        MainView()
//            .environmentObject(ContentView())
    }
}
