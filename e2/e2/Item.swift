// Item.swift
// e2
// Created by 李京樺 on 2024/1/28.

import Foundation
import SwiftData

class Item: Identifiable, ObservableObject, Equatable {
    static func == (lhs: Item, rhs: Item) -> Bool {
        return lhs.id == rhs.id
    }

    var id = UUID()
    @Published var name: String
    @Published var expirationDate: Date?
    @Published var notificationTime: Date?
    @Published var isNotificationEnabled: Bool
    @Published var priordate: Int

    init(name: String, expirationDate: Date? = nil) {
        self.name = name
        self.expirationDate = expirationDate
        self.notificationTime = expirationDate?.noon() // Set default notification time to noon on the expiration date
        self.isNotificationEnabled = false // Enable notification by default
        self.priordate=0
    }
}

extension Date {
    func noon() -> Date {
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self) ?? self
    }
}
