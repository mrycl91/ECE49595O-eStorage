// NotificationSettingView.swift
import SwiftUI

struct NotificationSettingView: View {
    @ObservedObject var item: Item
    @State private var selectedNotificationDate: Date = Date()
    @State private var daysPrior: Int = 0
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Form {
            Section(header: Text("Notification Settings")) {
                Stepper(value: $daysPrior, in: 0...30, step: 1) {
                    Text("Days Prior to Expiration: \(daysPrior)")
                }

                DatePicker("Select Time", selection: $selectedNotificationDate, displayedComponents: .hourAndMinute)
            }

            Button("Save Notification Settings") {
                saveNotificationSettings()
            }
        }
        .onAppear {
            setupInitialValues()
        }
    }

    private func saveNotificationSettings() {
        // Combine daysPrior with the selectedNotificationDate to calculate the final notification date
        let calculatedNotificationDate = Calendar.current.date(byAdding: .day, value: -daysPrior, to: selectedNotificationDate) ?? selectedNotificationDate

        // Check if notifications are currently enabled
        let notificationsEnabled = item.isNotificationEnabled

        // If notifications are enabled, cancel the previous scheduled notification
        if notificationsEnabled {
            removeScheduledNotification(for: item)
            // Schedule a new notification with the updated settings
            scheduleNotification(for: item)
        }

        // Update the item's notification time
        item.notificationTime = calculatedNotificationDate

        // Dismiss the view and go back to the previous view (ItemDetailView)
        presentationMode.wrappedValue.dismiss()
    }

    private func setupInitialValues() {
        // Use the existing notificationTime for initial values
        selectedNotificationDate = item.notificationTime ?? Date()

        // Calculate daysPrior from the existing notificationTime
        if let expirationDate = item.expirationDate {
            let daysBetween = Calendar.current.dateComponents([.day], from: selectedNotificationDate, to: expirationDate)
            daysPrior = max(0, daysBetween.day ?? 0)
        }
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

