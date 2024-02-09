// Item.swift
import Foundation

class Item: Identifiable, ObservableObject, Equatable, Codable {
    var id = UUID()
    @Published var name: String
    @Published var expirationDate: Date?
    @Published var notificationTime: Date?
    @Published var isNotificationEnabled: Bool

    init(name: String, expirationDate: Date? = nil) {
        self.name = name
        self.expirationDate = expirationDate
        self.notificationTime = expirationDate?.noon()
        self.isNotificationEnabled = false
    }

    // Conform to Encodable
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(expirationDate, forKey: .expirationDate)
        try container.encode(notificationTime, forKey: .notificationTime)
        try container.encode(isNotificationEnabled, forKey: .isNotificationEnabled)
    }

    // Conform to Decodable
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        expirationDate = try container.decode(Date?.self, forKey: .expirationDate)
        notificationTime = try container.decode(Date?.self, forKey: .notificationTime)
        isNotificationEnabled = try container.decode(Bool.self, forKey: .isNotificationEnabled)
    }

    // Conform to Equatable
    static func == (lhs: Item, rhs: Item) -> Bool {
        return lhs.id == rhs.id
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case expirationDate
        case notificationTime
        case isNotificationEnabled
    }
}

extension Date {
    func noon() -> Date {
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self) ?? self
    }
}
