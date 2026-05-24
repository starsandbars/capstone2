import SwiftUI
import SwiftData
import UserNotifications

// MARK: - In-app language bundle override
/// Computed variable ensures lookups dynamically pull the latest chosen language bundle.
private var _languageOverrideBundle: Bundle? {
    let saved = UserDefaults.standard.string(forKey: "selectedLanguage") ?? ""
    return languageBundleFor(saved)
}

/// Returns the .lproj Bundle for the given language ID, or nil for English / empty.
private func languageBundleFor(_ identifier: String) -> Bundle? {
    guard !identifier.isEmpty, !identifier.hasPrefix("en") else { return nil }
    let base = String(identifier.prefix(2))
    for candidate in (identifier == base ? [identifier] : [identifier, base]) {
        if let path = Bundle.main.path(forResource: candidate, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
    }
    return nil
}

/// Subclass that reads from the user-chosen lproj bundle dynamically.
final class LanguageBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if let overrideBundle = _languageOverrideBundle {
            return overrideBundle.localizedString(forKey: key, value: value, table: tableName)
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}

extension Bundle {
    private static let once: Void = {
        object_setClass(Bundle.main, LanguageBundle.self)
    }()
    
    static func setLanguage(_ identifier: String) {
        _ = Bundle.once
        UserDefaults.standard.set(identifier, forKey: "selectedLanguage")
    }
}

@main
struct capstone2App: App {
    init() {
        // Initialize dynamic language switching hook on application boot
        let savedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? ""
        Bundle.setLanguage(savedLanguage)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: SymptomEntry.self)
    }
}

// MARK: - Notification Scheduler
struct SymptomReminderScheduler {
    static let notificationID = "daily_symptom_reminder"

    static func requestAndSchedule() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            guard granted else { return }
            center.getNotificationSettings { settings in
                guard settings.authorizationStatus == .authorized ||
                      settings.authorizationStatus == .provisional else { return }
                UNUserNotificationCenter.current().getPendingNotificationRequests { pending in
                    let alreadyScheduled = pending.contains { $0.identifier == notificationID }
                    guard !alreadyScheduled else { return }
                    schedule()
                }
            }
        }
    }

    static func schedule() {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notif.symptom.title", comment: "")
        content.body  = NSLocalizedString("notif.symptom.body",  comment: "")
        content.sound = .default
        content.badge = 1

        var dateComponents = DateComponents()
        dateComponents.hour   = 21
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("Symptom reminder scheduling failed: \(error.localizedDescription)")
            }
        }
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
    }
}
