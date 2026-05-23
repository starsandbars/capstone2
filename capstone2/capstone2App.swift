import SwiftUI
import SwiftData
import UserNotifications

// MARK: - In-app language bundle override
//
// Strategy: subclass Bundle and replace Bundle.main's runtime class.
// This is safer than method swizzling because:
//   - It only affects Bundle.main, not every Bundle instance in the process.
//   - It doesn't interfere with xcstrings' internal lookup chain.
//   - Calling super.localizedString(...) cleanly delegates to the original implementation.
//
// English is never overridden: Bundle.main already serves English natively
// from the compiled .xcstrings. Setting an English override would break things
// because en.lproj/Localizable.strings is not generated for the source language.

private var _languageOverrideBundle: Bundle? = {
    let saved = UserDefaults.standard.string(forKey: "selectedLanguage") ?? ""
    return languageBundleFor(saved)
}()

/// Returns the .lproj Bundle for the given language ID, or nil for English / empty.
private func languageBundleFor(_ identifier: String) -> Bundle? {
    guard !identifier.isEmpty, !identifier.hasPrefix("en") else { return nil }
    // Try exact ID first (e.g. "pt-BR"), then base code ("pt")
    let base = String(identifier.prefix(2))
    for candidate in (identifier == base ? [identifier] : [identifier, base]) {
        if let path = Bundle.main.path(forResource: candidate, ofType: "lproj"),
           let bundle = Bundle(path: path) { return bundle }
    }
    return nil
}

/// Subclass that reads from the user-chosen language bundle, falling back to
/// Bundle.main's default behaviour (which handles English + xcstrings natively).
class LanguageBundle: Bundle {
    override func localizedString(forKey key: String,
                                  value: String?,
                                  table tableName: String?) -> String {
        guard let override = _languageOverrideBundle else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        // Pass the key as the fallback value so a cache-miss is detectable.
        let result = override.localizedString(forKey: key, value: key, table: tableName)
        // If the override didn't have this key, fall through to the original bundle.
        guard result != key else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        return result
    }
}

/// Activates the LanguageBundle subclass on Bundle.main once, at launch.
/// Must be called before any localised string is read.
private func installLanguageBundle() {
    object_setClass(Bundle.main, LanguageBundle.self)
}

/// Updates the active language for the current session and persists it.
/// Pass an empty string or "en" to revert to the default English bundle.
func setAppLanguage(_ identifier: String) {
    _languageOverrideBundle = languageBundleFor(identifier)
    // Also persist via AppleLanguages so the correct .lproj is used on next cold launch.
    if identifier.isEmpty || identifier.hasPrefix("en") {
        UserDefaults.standard.removeObject(forKey: "AppleLanguages")
    } else {
        let base = String(identifier.prefix(2))
        let langs = identifier == base ? [identifier] : [identifier, base, "en"]
        UserDefaults.standard.set(langs, forKey: "AppleLanguages")
    }
}

@main
struct capstone2App: App {
    @AppStorage("selectedLanguage") private var selectedLanguage = ""

    init() {
        // Install the Bundle subclass before any view or string is loaded.
        // _languageOverrideBundle is already initialised from UserDefaults by its lazy closure.
        installLanguageBundle()
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        SymptomReminderScheduler.scheduleIfAuthorized()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onChange(of: selectedLanguage) { _, newValue in
                    setAppLanguage(newValue)
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

    static func scheduleIfAuthorized() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized ||
                  settings.authorizationStatus == .provisional else { return }
            UNUserNotificationCenter.current().getPendingNotificationRequests { pending in
                let alreadyScheduled = pending.contains { $0.identifier == notificationID }
                guard !alreadyScheduled else { return }
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

        var dateComponents = DateComponents()
        dateComponents.hour   = 21
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
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

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [notificationID]
        )
    }
}
