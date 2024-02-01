// Item.swift
// e2
// Created by 李京樺 on 2024/1/28.

import Foundation

class Item: Identifiable, ObservableObject, Equatable {
    static func == (lhs: Item, rhs: Item) -> Bool {
        return lhs.id == rhs.id
    }

    var id = UUID()
    @Published var name: String
    @Published var expirationDate: Date?

    init(name: String, expirationDate: Date? = nil) {
        self.name = name
        self.expirationDate = expirationDate
    }
}
