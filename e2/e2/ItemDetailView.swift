// ItemDetailView.swift
// e2
// Created by 李京樺 on 2024/1/28.

import SwiftUI

struct ItemDetailView: View {
    var item: Item

    var body: some View {
        VStack {
            Text("Item Detail")
                .font(.title)

            Text("Name: \(item.name)")
            Text("Expiration Date: \(formattedDate(item.expirationDate))")

            Spacer()
        }
        .padding()
        .navigationBarTitle("Item Detail")
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else {
            return "Not specified"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct ItemDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleItem = Item(name: "Sample Item", expirationDate: Date())
        return ItemDetailView(item: sampleItem)
    }
}
