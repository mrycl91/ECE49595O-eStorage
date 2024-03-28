// ItemDetailView.swift
import SwiftUI
import UserNotifications

struct ItemDetailView: View {
    @ObservedObject var item: Item
    @State private var showingNotificationSetting = false
    @State private var notifyEnable = false

    var body: some View {
        VStack {
            Spacer()
            Text("\(item.name)\n")
                .frame(maxWidth: .infinity)
                .font(.title)
                .foregroundColor(Color(hex: 0xfafaff))
            Text("Best by \(formattedDate(item.expirationDate))\n")
                .foregroundColor(Color(hex: 0xdee7e7))
            Text("Notify on \(formattedDateTime(item.notificationTime))")
                .foregroundColor(Color(hex: 0xdee7e7))
            
            Spacer()
            
            Toggle( isOn: $item.isNotificationEnabled){
                Label("Notification", systemImage: "bell")
            }
            .frame(width: 200)
                .onChange(of: item.isNotificationEnabled) {
                    if item.isNotificationEnabled {
                        // If notifications are enabled, schedule the notification
                        scheduleNotification(for: item)
                    } else {
                        // If notifications are disabled, remove the existing notification
                        removeScheduledNotification(for: item)
                    }
                }

            // Navigation button to NotificationSettingView
            Button(action: {
                showingNotificationSetting = true
            }) {
                Label("Go to Notification Setting", systemImage: "gear")
//                Text("Notification Setting")
                    .foregroundColor(Color(hex: 0xfafaff))
            }
                .padding()
                .sheet(isPresented: $showingNotificationSetting){
//                    Text("Hi")
                    NotificationSettingView(item: item)
                        .presentationDetents([.fraction(0.4)])
                }
            
            Spacer()
        }
            .padding()
            .background(Color(hex: 0x4f646f))
    
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
