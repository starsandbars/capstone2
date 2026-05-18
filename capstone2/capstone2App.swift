import SwiftUI
import SwiftData
import UserNotifications

@main
struct capstone2App: App {

    init() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        SymptomReminderScheduler.scheduleIfAuthorized()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [SymptomEntry.self, Habit.self])
    }
}

// MARK: - Notification Delegate
// Shows notifications as banners even when the app is in the foreground
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}

// MARK: - Symptom Reminder Scheduler
struct SymptomReminderScheduler {

    static let notificationID = "daily.symptom.checkin"

    /// Call this on every app launch. If the notification is already scheduled,
    /// this is a no-op. If permission was granted but the notification is missing
    /// (e.g. after an app reinstall), it reschedules it automatically.
    static func scheduleIfAuthorized() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized ||
                  settings.authorizationStatus == .provisional else { return }

            // Check if already scheduled to avoid duplicates
            UNUserNotificationCenter.current().getPendingNotificationRequests { pending in
                let alreadyScheduled = pending.contains { $0.identifier == notificationID }
                guard !alreadyScheduled else { return }
                schedule()
            }
        }
    }

    /// Schedule the 9pm daily symptom log reminder.
    static func schedule() {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notif.symptom.title", comment: "")
        content.body  = NSLocalizedString("notif.symptom.body",  comment: "")
        content.sound = .default
        content.badge = 1

        var dateComponents = DateComponents()
        dateComponents.hour   = 21  // 9pm
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true   // fires every day at 9pm
        )

        let request = UNNotificationRequest(
            identifier: notificationID,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("Symptom reminder scheduling failed: \(error.localizedDescription)")
            }
        }
    }

    /// Cancel the reminder — call this if the user disables it in settings.
    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [notificationID]
        )
    }
}
