import SwiftUI
import SwiftData
import UserNotifications

// MARK: - In-app language bundle override
// NSLocalizedString uses Bundle.main with the SYSTEM language, ignoring the
// in-app language picker. This swizzle redirects it to the user-chosen .lproj
// bundle so every NSLocalizedString call respects the selected language.
//
// English is intentionally excluded: Bundle.main already serves English
// correctly without an override, and en.lproj may not contain Localizable.strings
// (Xcode skips generating it for the development language).
private var _overrideBundle: Bundle? = {
    let saved = UserDefaults.standard.string(forKey: "selectedLanguage") ?? ""
    return Bundle.bundleForLanguage(saved)
}()

extension Bundle {
    /// Returns the .lproj bundle for the given language identifier, or nil for
    /// English / empty (let Bundle.main handle those natively).
    static func bundleForLanguage(_ identifier: String) -> Bundle? {
        // English: don't override — Bundle.main already serves English.
        guard !identifier.isEmpty, !identifier.hasPrefix("en") else { return nil }
        // Try exact match (e.g. "pt-BR.lproj") then base code ("pt.lproj")
        let baseLang = String(identifier.prefix(2))
        let candidates = identifier == baseLang ? [identifier] : [identifier, baseLang]
        for candidate in candidates {
            if let path = Bundle.main.path(forResource: candidate, ofType: "lproj"),
               let bundle = Bundle(path: path) { return bundle }
        }
        return nil
    }

    /// Call this on launch and whenever the user changes language.
    static func setLanguage(_ identifier: String) {
        _overrideBundle = bundleForLanguage(identifier)
    }
}

// Swizzle Bundle.localizedString so NSLocalizedString reads from our override.
private final class BundleSwizzler {
    static let install: Void = {
        let original = class_getInstanceMethod(Bundle.self, #selector(Bundle.localizedString(forKey:value:table:)))!
        let swizzled = class_getInstanceMethod(Bundle.self, #selector(Bundle.swizzled_localizedString(forKey:value:table:)))!
        method_exchangeImplementations(original, swizzled)
    }()
}

extension Bundle {
    @objc func swizzled_localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        // Only intercept Bundle.main lookups; leave system/framework bundles alone.
        // When no override is set (English or unset), call through to the original
        // implementation directly — note: after swizzling, calling swizzled_localizedString
        // on self IS the original implementation.
        guard self == Bundle.main, let override = _overrideBundle else {
            return swizzled_localizedString(forKey: key, value: value, table: tableName)
        }
        // Ask the override bundle. Pass key as the fallback value so we can detect misses.
        let result = override.swizzled_localizedString(forKey: key, value: key, table: tableName)
        // If the override didn't find it (returned the key unchanged), fall through to
        // Bundle.main's original implementation so English strings still show.
        guard result != key else {
            return swizzled_localizedString(forKey: key, value: value, table: tableName)
        }
        return result
    }
}

@main
struct capstone2App: App {
    @AppStorage("selectedLanguage") private var selectedLanguage = ""

    init() {
        // Install the bundle swizzle once at launch
        BundleSwizzler.install
        // Apply any previously saved language immediately
        if !selectedLanguage.isEmpty {
            Bundle.setLanguage(selectedLanguage)
        }
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        SymptomReminderScheduler.scheduleIfAuthorized()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Re-apply bundle override whenever the user changes language
                .onChange(of: selectedLanguage) { _, newValue in
                    Bundle.setLanguage(newValue)
                }
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
