import Foundation
import UserNotifications
import Combine

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private init() { }

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    func requestPermissionIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        authorizationStatus = settings.authorizationStatus

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                let updatedSettings = await center.notificationSettings()
                authorizationStatus = updatedSettings.authorizationStatus
                return granted
            } catch {
                return false
            }
        @unknown default:
            return false
        }
    }

    func schedulePaymentReminder(
        tenantID: UUID,
        tenantName: String,
        propertyName: String,
        dueDate: Date,
        amountText: String
    ) async {
        let granted = await requestPermissionIfNeeded()
        guard granted else { return }

        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        let reminderDate = calendar.date(
            bySettingHour: 9,
            minute: 0,
            second: 0,
            of: dueDate
        ) ?? dueDate

        let content = UNMutableNotificationContent()
        content.title = "Payment due today"
        content.body = "\(tenantName) at \(propertyName) has a payment due today for \(amountText)."
        content.sound = .default

        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: reminderDate
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "payment-due-\(tenantID.uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule reminder:", error)
        }
    }

    func removePaymentReminder(for tenantID: UUID) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(
            withIdentifiers: ["payment-due-\(tenantID.uuidString)"]
        )
    }
}
