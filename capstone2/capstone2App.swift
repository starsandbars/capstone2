import SwiftUI
import SwiftData
import UserNotifications

@main
struct capstone2App: App {
    @AppStorage("selectedLanguage") private var selectedLanguage = ""

    init() {
        // Apply the saved language before any view or string loads.
        // Called unconditionally so AppleLanguages is always in a known state,
        // even if a prior session set it to a different language.
        capstone2App.applyLanguage(
            UserDefaults.standard.string(forKey: "selectedLanguage") ?? ""
        )
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        SymptomReminderScheduler.scheduleIfAuthorized()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onChange(of: selectedLanguage) { _, newValue in
                    // Persist for next cold launch.
                    // NSBundle caches its language on first string access per process,
                    // so NSLocalizedString fully switches on the next cold launch.
                    // SwiftUI Text() switches immediately via ContentView's .environment locale.
                    capstone2App.applyLanguage(newValue)
                }
        }
        .modelContainer(for: [SymptomEntry.self, Habit.self])
    }

    /// Writes UserDefaults["AppleLanguages"] so that NSLocalizedString uses the
    /// correct .lproj on every launch, regardless of the device system language.
    ///
    /// Using AppleLanguages is the native iOS mechanism — it works with xcstrings
    /// at the OS level without any bundle subclassing or method interception.
    ///
    /// - Empty string: clear override — fall back to system language (not yet chosen).
    /// - "en": pin to ["en"] explicitly so NSLocalizedString is not affected by the
    ///   device system language, even if the device is set to something else.
    /// - All others: set [identifier, base, "en"], e.g. ["pt-BR", "pt", "en"],
    ///   covering both full and base lproj names with English as the final fallback.
    static func applyLanguage(_ identifier: String) {
        if identifier.isEmpty {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else if identifier.hasPrefix("en") {
            UserDefaults.standard.set(["en"], forKey: "AppleLanguages")
        } else {
            let base = String(identifier.prefix(2))
            let langs: [String] = (identifier == base)
                ? [identifier, "en"]
                : [identifier, base, "en"]
            UserDefaults.standard.set(langs, forKey: "AppleLanguages")
        }
    }
}

// MARK: - Notification Delegate
// Shows notifications as banners even when the app is in the foreground.
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

    /// Schedules the daily reminder only if permission is already granted.
    /// Call this on every launch — it is a no-op if already scheduled.
    static func scheduleIfAuthorized() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized ||
                  settings.authorizationStatus == .provisional else { return }
            UNUserNotificationCenter.current().getPendingNotificationRequests { pending in
                guard !pending.contains(where: { $0.identifier == notificationID }) else { return }
                schedule()
            }
        }
    }

    static func schedule() {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notif.symptom.title", comment: "")
        content.body  = NSLocalizedString("notif.symptom.body",  comment: "")
        content.sound = .default
        content.badge = 1
        var dc = DateComponents()
        dc.hour = 21; dc.minute = 0
        let request = UNNotificationRequest(
            identifier: notificationID,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("Reminder scheduling failed: \(error)") }
        }
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [notificationID])
    }
}
