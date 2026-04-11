import Foundation
import SwiftUI
import SwiftData
import UserNotifications

@Observable
class HabitViewModel {

    // MARK: - Sheet state
    var showingAddHabit   = false
    var showingSuggestions = false
    var showingDetail: Habit? = nil

    // MARK: - New habit form
    var newTitle       = ""
    var newDescription = ""
    var newCategory: HabitCategory  = .personal
    var newFrequency: HabitFrequency = .daily
    var newEmoji       = "⭐️"
    var newNotifHour   = 9
    var newNotifMinute = 0
    var newNotifEnabled = true

    // MARK: - Filter
    enum Filter: String, CaseIterable {
        case today = "Today"
        case all   = "All"
        case done  = "Done"

        var localizedTitle: String {
            switch self {
            case .today: return NSLocalizedString("habits.filter.today", comment: "")
            case .all:   return NSLocalizedString("habits.filter.all",   comment: "")
            case .done:  return NSLocalizedString("habits.filter.done",  comment: "")
            }
        }
    }
    var activeFilter: Filter = .today

    // MARK: - Computed lists
    func habits(from all: [Habit], filter: Filter) -> [Habit] {
        let active = all.filter { !$0.isArchived || $0.frequency == .once }
        switch filter {
        case .today:
            return active.filter { $0.isDue || $0.isCompletedForPeriod }
                         .sorted { !$0.isCompletedForPeriod && $1.isCompletedForPeriod }
        case .all:
            return active.sorted { !$0.isCompletedForPeriod && $1.isCompletedForPeriod }
        case .done:
            return all.filter { $0.isCompletedForPeriod || $0.isArchived }
        }
    }

    func completedCount(from all: [Habit]) -> Int {
        all.filter { $0.isCompletedForPeriod }.count
    }

    func dueCount(from all: [Habit]) -> Int {
        all.filter { $0.isDue }.count
    }

    var progressFraction: Double {
        // computed in view since we need the habits list
        0
    }

    // MARK: - Save new habit
    func saveHabit(context: ModelContext) {
        guard !newTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let habit = Habit(
            title: newTitle.trimmingCharacters(in: .whitespaces),
            description: newDescription,
            category: newCategory,
            frequency: newFrequency,
            emoji: "⭐️",
            notificationHour: newNotifHour,
            notificationMinute: newNotifMinute
        )
        context.insert(habit)
        try? context.save()
        if newNotifEnabled { scheduleNotification(for: habit) }
        resetForm()
        showingAddHabit = false
    }

    func addSuggested(_ suggestion: SuggestedHabit, context: ModelContext) {
        let habit = Habit(
            title: suggestion.title,
            description: suggestion.description,
            category: suggestion.category,
            frequency: suggestion.frequency,
            isSuggested: true,
            emoji: suggestion.emoji
        )
        context.insert(habit)
        try? context.save()
        scheduleNotification(for: habit)
    }

    func deleteHabit(_ habit: Habit, context: ModelContext) {
        cancelNotification(for: habit)
        context.delete(habit)
        try? context.save()
    }

    func resetForm() {
        newTitle = ""; newDescription = ""
        newCategory = .personal; newFrequency = .daily
        newEmoji = "⭐️"; newNotifHour = 9; newNotifMinute = 0
        newNotifEnabled = true
    }

    // MARK: - Notifications
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }

    func scheduleNotification(for habit: Habit) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [habit.id.uuidString])

        let content = UNMutableNotificationContent()
        content.title = "\(habit.emoji) \(habit.title)"
        content.body  = habit.habitDescription.isEmpty
            ? NSLocalizedString("notif.habit.body.default", comment: "")
            : habit.habitDescription
        content.sound = .default

        var components = DateComponents()
        components.hour   = habit.notificationHour
        components.minute = habit.notificationMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: habit.frequency != .once)
        let request = UNNotificationRequest(identifier: habit.id.uuidString, content: content, trigger: trigger)
        center.add(request)
    }

    func cancelNotification(for habit: Habit) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [habit.id.uuidString])
    }

    // MARK: - Helpers
    var motivationalMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return NSLocalizedString("habits.motivation.morning",   comment: "")
        case 12..<17: return NSLocalizedString("habits.motivation.afternoon", comment: "")
        case 17..<21: return NSLocalizedString("habits.motivation.evening",   comment: "")
        default:      return NSLocalizedString("habits.motivation.night",     comment: "")
        }
    }

    var todayFormatted: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: Date())
    }
}
