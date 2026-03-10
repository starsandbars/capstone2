import Foundation
import SwiftData
import SwiftUI

// MARK: - Habit Frequency
enum HabitFrequency: String, Codable, CaseIterable {
    case daily  = "Daily"
    case weekly = "Weekly"
    case once   = "One-time"

    var icon: String {
        switch self {
        case .daily:  return "arrow.clockwise"
        case .weekly: return "calendar"
        case .once:   return "checkmark.seal"
        }
    }
}

// MARK: - Habit Category
enum HabitCategory: String, Codable, CaseIterable {
    case movement    = "Movement"
    case nutrition   = "Nutrition"
    case mindfulness = "Mindfulness"
    case social      = "Social"
    case rest        = "Rest"
    case medical     = "Medical"
    case personal    = "Personal"

    var icon: String {
        switch self {
        case .movement:    return "figure.walk"
        case .nutrition:   return "leaf.fill"
        case .mindfulness: return "brain.head.profile"
        case .social:      return "person.2.fill"
        case .rest:        return "moon.fill"
        case .medical:     return "cross.fill"
        case .personal:    return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .movement:    return Color(hex: "3498DB")
        case .nutrition:   return Color(hex: "27AE60")
        case .mindfulness: return Color(hex: "9B59B6")
        case .social:      return Color(hex: "E67E22")
        case .rest:        return Color(hex: "2471A3")
        case .medical:     return Color(hex: "E74C3C")
        case .personal:    return Color(hex: "F39C12")
        }
    }
}

// MARK: - Habit SwiftData Model
@Model
class Habit {
    var id: UUID
    var title: String
    var habitDescription: String
    var category: HabitCategory
    var frequency: HabitFrequency
    var createdAt: Date
    var completionDates: [Date]
    var isSuggested: Bool
    var notificationsEnabled: Bool
    var notificationHour: Int
    var notificationMinute: Int
    var isArchived: Bool
    var emoji: String

    init(title: String,
         description: String = "",
         category: HabitCategory = .personal,
         frequency: HabitFrequency = .daily,
         isSuggested: Bool = false,
         emoji: String = "⭐️",
         notificationHour: Int = 9,
         notificationMinute: Int = 0) {
        self.id = UUID()
        self.title = title
        self.habitDescription = description
        self.category = category
        self.frequency = frequency
        self.createdAt = Date()
        self.completionDates = []
        self.isSuggested = isSuggested
        self.notificationsEnabled = true
        self.notificationHour = notificationHour
        self.notificationMinute = notificationMinute
        self.isArchived = false
        self.emoji = emoji
    }

    // MARK: - Completion
    func isCompletedToday() -> Bool {
        completionDates.contains { Calendar.current.isDateInToday($0) }
    }

    func isCompletedThisWeek() -> Bool {
        guard let interval = Calendar.current.dateInterval(of: .weekOfYear, for: Date()) else { return false }
        return completionDates.contains { interval.contains($0) }
    }

    func markComplete() {
        if frequency == .daily  && isCompletedToday()     { return }
        if frequency == .weekly && isCompletedThisWeek()  { return }
        completionDates.append(Date())
        if frequency == .once { isArchived = true }
    }

    func unmarkComplete() {
        switch frequency {
        case .daily:
            completionDates.removeAll { Calendar.current.isDateInToday($0) }
        case .weekly:
            guard let interval = Calendar.current.dateInterval(of: .weekOfYear, for: Date()) else { return }
            completionDates.removeAll { interval.contains($0) }
        case .once:
            completionDates.removeAll()
            isArchived = false
        }
    }

    var isCompletedForPeriod: Bool {
        switch frequency {
        case .daily:  return isCompletedToday()
        case .weekly: return isCompletedThisWeek()
        case .once:   return isArchived
        }
    }

    var isDue: Bool { !isCompletedForPeriod && !isArchived }

    // MARK: - Streak
    var currentStreak: Int {
        guard frequency == .daily else {
            return completionDates.isEmpty ? 0 : 1
        }
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        if !isCompletedToday() {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) else { return 0 }
            checkDate = yesterday
        }

        for _ in 0..<365 {
            if completionDates.contains(where: { calendar.isDate($0, inSameDayAs: checkDate) }) {
                streak += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prev
            } else { break }
        }
        return streak
    }

    var totalCompletions: Int { completionDates.count }

    /// Bool array for last 7 days (oldest → newest)
    var last7Days: [Bool] {
        let calendar = Calendar.current
        return (0..<7).reversed().map { offset -> Bool in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return false }
            return completionDates.contains { calendar.isDate($0, inSameDayAs: date) }
        }
    }

    /// Day-letter labels for last 7 days
    var last7DayLabels: [String] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return (0..<7).reversed().map { offset -> String in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return "" }
            return String(formatter.string(from: date).prefix(1))
        }
    }
}

// MARK: - Suggested Habits catalogue
struct SuggestedHabit: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let category: HabitCategory
    let frequency: HabitFrequency
    let emoji: String

    static let all: [SuggestedHabit] = [
        SuggestedHabit(title: "Go for a walk",          description: "Even 10 minutes outside makes a difference",     category: .movement,    frequency: .daily,  emoji: "🚶"),
        SuggestedHabit(title: "Gentle stretching",      description: "5 minutes of light stretching to ease stiffness", category: .movement,    frequency: .daily,  emoji: "🧘"),
        SuggestedHabit(title: "Chair yoga",             description: "Low-impact movement for any energy level",        category: .movement,    frequency: .daily,  emoji: "🪑"),
        SuggestedHabit(title: "Drink 8 glasses water",  description: "Stay hydrated throughout the day",                category: .nutrition,   frequency: .daily,  emoji: "💧"),
        SuggestedHabit(title: "Make a healthy meal",    description: "Cook one nourishing meal from scratch",           category: .nutrition,   frequency: .daily,  emoji: "🥗"),
        SuggestedHabit(title: "Eat a piece of fruit",   description: "A simple step toward better nutrition",           category: .nutrition,   frequency: .daily,  emoji: "🍎"),
        SuggestedHabit(title: "5-min meditation",       description: "Breathe deeply and be present",                   category: .mindfulness, frequency: .daily,  emoji: "🌿"),
        SuggestedHabit(title: "Write in a journal",     description: "Reflect on today, however it went",               category: .mindfulness, frequency: .daily,  emoji: "📓"),
        SuggestedHabit(title: "Gratitude moment",       description: "Name 3 things you're grateful for today",         category: .mindfulness, frequency: .daily,  emoji: "🙏"),
        SuggestedHabit(title: "Call a loved one",       description: "Connection is powerful medicine",                 category: .social,      frequency: .daily,  emoji: "📞"),
        SuggestedHabit(title: "Time with family",       description: "Quality time with people who care for you",       category: .social,      frequency: .weekly, emoji: "🏠"),
        SuggestedHabit(title: "Sleep by 10pm",          description: "Rest is a crucial part of recovery",              category: .rest,        frequency: .daily,  emoji: "🌙"),
        SuggestedHabit(title: "Afternoon rest",         description: "A short rest can restore your energy",            category: .rest,        frequency: .daily,  emoji: "😴"),
        SuggestedHabit(title: "Take medications",       description: "Consistency with medication matters",             category: .medical,     frequency: .daily,  emoji: "💊"),
        SuggestedHabit(title: "Check in with your body",description: "Notice how you're feeling today",                 category: .medical,     frequency: .daily,  emoji: "🔍"),
    ]
}
