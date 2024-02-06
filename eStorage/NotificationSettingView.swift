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
