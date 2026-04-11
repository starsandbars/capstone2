import Foundation
import SwiftUI
import SwiftData

// MARK: - Most Worrying Symptom
struct WorriedSymptom {
    let name: String
    let category: SymptomCategory
    let currentAvg: Double
    let previousAvg: Double

    /// Weighted score: percent increase × current severity
    /// Ensures high-severity symptoms that are rising rank above low-severity ones
    var worryScore: Double {
        guard previousAvg > 0 else { return currentAvg * 100 }
        return percentIncrease * currentAvg
    }

    var percentIncrease: Double {
        guard previousAvg > 0 else { return 100 }
        return ((currentAvg - previousAvg) / previousAvg) * 100
    }

    var percentIncreaseLabel: String {
        let pct = percentIncrease
        if pct > 0 { return String(format: "+%.0f%%", pct) }
        if pct < 0 { return String(format: "%.0f%%", pct) }
        return "Unchanged"
    }

    var isWorsening: Bool { percentIncrease > 0 }
}

// MARK: - Weekly Summary Data
struct WeeklySummary {
    let weekStart: Date
    let weekEnd: Date
    let entries: [SymptomEntry]
    let previousEntries: [SymptomEntry] // prior week for comparison

    var totalDaysLogged: Int { entries.count }

    var averageMentalHealth: Double {
        guard !entries.isEmpty else { return 0 }
        return Double(entries.map(\.mentalHealthScore).reduce(0, +)) / Double(entries.count)
    }

    var averageAnger: Double {
        guard !entries.isEmpty else { return 0 }
        return Double(entries.map(\.angerScore).reduce(0, +)) / Double(entries.count)
    }

    var averageAnxiety: Double {
        guard !entries.isEmpty else { return 0 }
        return Double(entries.map(\.anxietyScore).reduce(0, +)) / Double(entries.count)
    }

    var averageLoneliness: Double {
        guard !entries.isEmpty else { return 0 }
        return Double(entries.map(\.lonelinessScore).reduce(0, +)) / Double(entries.count)
    }

    var averageHeaviness: Double {
        guard !entries.isEmpty else { return 0 }
        return Double(entries.map(\.heavinessScore).reduce(0, +)) / Double(entries.count)
    }

    /// The emotional dimension with the highest average score this week
    var mostElevatedEmotion: (label: String, icon: String, score: Double, color: String)? {
        guard !entries.isEmpty else { return nil }
        let scores: [(String, String, Double, String)] = [
            (NSLocalizedString("emotion.anger", comment: ""),       "flame.fill",        averageAnger,      "E74C3C"),
            (NSLocalizedString("emotion.anxiety", comment: ""),     "cloud.rain.fill",   averageAnxiety,    "5B85C4"),
            (NSLocalizedString("emotion.loneliness", comment: ""),  "person.fill.xmark", averageLoneliness, "8E44AD"),
            (NSLocalizedString("emotion.heaviness", comment: ""),   "scalemass.fill",    averageHeaviness,  "5D7A8A"),
        ]
        return scores.filter { $0.2 >= 4 }.max(by: { $0.2 < $1.2 })
    }

    var allSymptoms: [LoggedSymptom] {
        entries.flatMap(\.symptoms)
    }

    var mostCommonSymptoms: [(name: String, count: Int, category: SymptomCategory)] {
        var counts: [String: (Int, SymptomCategory)] = [:]
        for s in allSymptoms {
            let existing = counts[s.name]?.0 ?? 0
            counts[s.name] = (existing + 1, s.category)
        }
        return counts
            .map { (name: $0.key, count: $0.value.0, category: $0.value.1) }
            .sorted { $0.count > $1.count }
            .prefix(5)
            .map { $0 }
    }

    var averageSeverityByDay: [DaySeverity] {
        let calendar = Calendar.current
        return entries.map { entry in
            let avg = entry.symptoms.isEmpty ? 0.0 :
                Double(entry.symptoms.map(\.severity).reduce(0, +)) / Double(entry.symptoms.count)
            return DaySeverity(date: entry.date, averageSeverity: avg, dayLetter: calendar.shortDayLetter(for: entry.date))
        }.sorted { $0.date < $1.date }
    }

    var overallSeverityTrend: TrendDirection {
        let severities = averageSeverityByDay.map(\.averageSeverity)
        guard severities.count >= 2 else { return .stable }
        let first = severities.prefix(severities.count / 2).reduce(0, +) / Double(severities.count / 2)
        let last = severities.suffix(severities.count / 2).reduce(0, +) / Double(severities.count / 2)
        if last < first - 0.5 { return .improving }
        if last > first + 0.5 { return .worsening }
        return .stable
    }

    /// The most clinically worrying symptom: highest combined score of
    /// percent severity increase vs last week × current average severity.
    /// Only considers symptoms that appear in the current week.
    var mostWorriedSymptom: WorriedSymptom? {
        guard !entries.isEmpty else { return nil }

        // Build current week avg severity per symptom name
        var currentTotals: [String: (Double, Int, SymptomCategory)] = [:]
        for s in allSymptoms {
            let existing = currentTotals[s.name] ?? (0, 0, s.category)
            currentTotals[s.name] = (existing.0 + Double(s.severity), existing.1 + 1, s.category)
        }

        // Build previous week avg severity per symptom name
        let prevSymptoms = previousEntries.flatMap(\.symptoms)
        var prevTotals: [String: (Double, Int)] = [:]
        for s in prevSymptoms {
            let existing = prevTotals[s.name] ?? (0, 0)
            prevTotals[s.name] = (existing.0 + Double(s.severity), existing.1 + 1)
        }

        // Score each symptom that appeared this week
        let candidates = currentTotals.compactMap { name, currentData -> WorriedSymptom? in
            let currentAvg = currentData.0 / Double(currentData.1)
            // Only flag if severity is at least 3 (not trivial)
            guard currentAvg >= 3 else { return nil }

            let prevAvg: Double
            if let prev = prevTotals[name] {
                prevAvg = prev.0 / Double(prev.1)
            } else {
                // Symptom is new this week — treat previous as 0 (new onset is always concerning)
                prevAvg = 0
            }

            return WorriedSymptom(name: name, category: currentData.2,
                                  currentAvg: currentAvg, previousAvg: prevAvg)
        }
        // Only surface worsening or new symptoms
        .filter { $0.isWorsening }
        .sorted { $0.worryScore > $1.worryScore }

        return candidates.first
    }

    var weekLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: weekStart)) – \(formatter.string(from: weekEnd))"
    }
}

// MARK: - Supporting types
struct DaySeverity: Identifiable {
    let id = UUID()
    let date: Date
    let averageSeverity: Double
    let dayLetter: String
}

enum TrendDirection {
    case improving, stable, worsening

    var icon: String {
        switch self {
        case .improving: return "arrow.down.right"
        case .stable: return "arrow.right"
        case .worsening: return "arrow.up.right"
        }
    }

    var label: String {
        switch self {
        case .improving: return NSLocalizedString("home.trend.improving", comment: "")
        case .stable: return NSLocalizedString("home.trend.stable", comment: "")
        case .worsening: return NSLocalizedString("home.trend.worsening", comment: "")
        }
    }

    var color: Color {
        switch self {
        case .improving: return Color("severityLow")
        case .stable: return Color("accentTeal")
        case .worsening: return Color("severityHigh")
        }
    }
}

// MARK: - ViewModel
@Observable
class HomeViewModel {
    var selectedWeekOffset: Int = 0

    func weeklySummary(from entries: [SymptomEntry], offset: Int = 0) -> WeeklySummary {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start,
              let offsetStart = calendar.date(byAdding: .weekOfYear, value: offset, to: weekStart),
              let offsetEnd = calendar.date(byAdding: .day, value: 6, to: offsetStart),
              let prevStart = calendar.date(byAdding: .weekOfYear, value: -1, to: offsetStart),
              let prevEnd = calendar.date(byAdding: .day, value: 6, to: prevStart)
        else {
            return WeeklySummary(weekStart: now, weekEnd: now, entries: [], previousEntries: [])
        }

        let weekEntries = entries.filter { entry in
            entry.date >= offsetStart && entry.date <= calendar.date(byAdding: .day, value: 1, to: offsetEnd)!
        }
        let prevEntries = entries.filter { entry in
            entry.date >= prevStart && entry.date <= calendar.date(byAdding: .day, value: 1, to: prevEnd)!
        }

        return WeeklySummary(weekStart: offsetStart, weekEnd: offsetEnd,
                             entries: weekEntries, previousEntries: prevEntries)
    }

    func greetingText() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return NSLocalizedString("home.greeting.morning", comment: "")
        case 12..<17: return NSLocalizedString("home.greeting.afternoon", comment: "")
        default:      return NSLocalizedString("home.greeting.evening", comment: "")
        }
    }

    func wellbeingMessage(for summary: WeeklySummary) -> String {
        guard !summary.entries.isEmpty else { return NSLocalizedString("home.wellbeing.nodata", comment: "") }
        let avg = summary.averageMentalHealth
        // Surface the most elevated emotional dimension if significant
        if let top = summary.mostElevatedEmotion, top.score >= 6 {
            switch top.label {
            case "Anger / Frustration":
                return "Frustration has been elevated this week. Those feelings are valid — recovery is hard. 🤍"
            case "Worry / Anxiety":
                return "Anxiety about recovery has been high. Try to take it one day at a time. You're doing the work. 💙"
            case "Loneliness":
                return "Loneliness has been present this week. Reaching out to someone, even briefly, can help. 🌿"
            default:
                return "This week has felt heavy. Be gentle with yourself — rest is part of recovery. 🤍"
            }
        }
        switch avg {
        case 7...10: return NSLocalizedString("home.wellbeing.strong", comment: "")
        case 4..<7:  return NSLocalizedString("home.wellbeing.mixed", comment: "")
        case 1..<4:  return NSLocalizedString("home.wellbeing.tough", comment: "")
        default:     return NSLocalizedString("home.wellbeing.nodata", comment: "")
        }
    }
}

// MARK: - Calendar extension
extension Calendar {
    func shortDayLetter(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return String(formatter.string(from: date).prefix(1))
    }
}
