// ItemDetailView.swift
import SwiftUI
import UserNotifications

struct ItemDetailView: View {
    @ObservedObject var item: Item
    @State private var showingNotificationSetting = false

    var body: some View {
        VStack {
            Text("Name: \(item.name)").font(.title)
            Text("Expiration Date: \(formattedDate(item.expirationDate))")
            Text("Notification Time: \(formattedDateTime(item.notificationTime))")

            // Toggle button for notification on/off
            Toggle("Enable Notification", isOn: $item.isNotificationEnabled)
                .onChange(of: item.isNotificationEnabled) { _ in
                    toggleNotification()
                }
                .padding()
                .onAppear {
                    // Update the isActive state when the view appears
                    showingNotificationSetting = item.isNotificationEnabled
                }

            Spacer()

            NavigationLink(destination: NotificationSettingView(item: item), isActive: $showingNotificationSetting) {
                Text("Notification Setting")
                    .foregroundColor(.blue)
            }
            .padding()
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

    private func formattedDateTime(_ date: Date?) -> String {
        guard let date = date else {
            return "Not specified"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func toggleNotification() {
     

        if item.isNotificationEnabled {
            // If notifications are enabled, schedule the notification
            scheduleNotification(for: item)
        } else {
            // If notifications are disabled, remove the existing notification
            removeScheduledNotification(for: item)
        }
    }

    private func scheduleNotification(for item: Item) {
        guard item.isNotificationEnabled,
              let notificationTime = item.notificationTime else {
            return
        }

       

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "eStorage Notification"
        content.body = "\(item.name) will expire soon."

        // Extract components from the notification time
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationTime)

        // Create notification trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        // Create notification request
        let request = UNNotificationRequest(identifier: item.id.uuidString, content: content, trigger: trigger)

        // Schedule the notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled successfully.")
            }
        }
    }

    private func removeScheduledNotification(for item: Item) {
        // Remove the scheduled notification with the item's identifier
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [item.id.uuidString])
        print("Notification removed successfully.")
    }
}
