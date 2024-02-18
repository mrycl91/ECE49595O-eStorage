import Foundation

class Item: Identifiable, ObservableObject, Equatable, Codable {
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
        self.priordate = 0
    }

    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, name, expirationDate, notificationTime, isNotificationEnabled, priordate
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        name = try container.decode(String.self, forKey: .name)
        expirationDate = try container.decodeIfPresent(Date.self, forKey: .expirationDate)
        notificationTime = try container.decodeIfPresent(Date.self, forKey: .notificationTime)
        isNotificationEnabled = try container.decode(Bool.self, forKey: .isNotificationEnabled)
        priordate = try container.decode(Int.self, forKey: .priordate)

        // id is optional because it's generated during initialization
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(expirationDate, forKey: .expirationDate)
        try container.encode(notificationTime, forKey: .notificationTime)
        try container.encode(isNotificationEnabled, forKey: .isNotificationEnabled)
        try container.encode(priordate, forKey: .priordate)
    }
}

extension Date {
    func midnight() -> Date {
        return Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: self) ?? self
    }
}
