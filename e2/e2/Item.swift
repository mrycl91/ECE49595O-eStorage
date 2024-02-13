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
        self.notificationTime = expirationDate?.midnight()
        self.isNotificationEnabled = false
        self.priordate=0
    }
}

extension Date {
    func midnight() -> Date {
        return Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: self) ?? self
    }
}
