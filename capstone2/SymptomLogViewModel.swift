import Foundation
import SwiftUI
import SwiftData

@Observable
class SymptomLogViewModel {

    // MARK: - State
    var selectedSymptoms: [LoggedSymptom] = []
    var mentalHealthScore: Int = 5
    var angerScore: Int = 1
    var anxietyScore: Int = 1
    var lonelinessScore: Int = 1
    var heavinessScore: Int = 1
    var notes: String = ""
    var showingSymptomPicker = false
    var showingCustomSymptom = false
    var customSymptomName = ""
    var customSymptomCategory: SymptomCategory = .other
    var isSaved = false
    var showingSaveConfirmation = false

    // MARK: - Today's date string
    var todayFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    // MARK: - Load today's existing entry into the form
    /// Call this on .onAppear so edits to an existing day's log pre-populate the UI.
    func loadTodayEntry(from entries: [SymptomEntry]) {
        guard let todayEntry = entries.first(where: {
            Calendar.current.isDateInToday($0.date)
        }) else { return }

        // Only pre-populate if the user hasn't started editing yet
        if selectedSymptoms.isEmpty {
            selectedSymptoms = todayEntry.symptoms
            mentalHealthScore = todayEntry.mentalHealthScore
            angerScore = todayEntry.angerScore
            anxietyScore = todayEntry.anxietyScore
            lonelinessScore = todayEntry.lonelinessScore
            heavinessScore = todayEntry.heavinessScore
            notes = todayEntry.notes
            isSaved = true
        }
    }

    // MARK: - Severity / mental health helpers
    func severityColor(for score: Int) -> Color {
        switch score {
        case 1...3: return Color("severityLow")
        case 4...6: return Color("severityMed")
        case 7...10: return Color("severityHigh")
        default: return .gray
        }
    }

    func severityLabel(for score: Int) -> String {
        switch score {
        case 1...3: return "Mild"
        case 4...6: return "Moderate"
        case 7...10: return "Severe"
        default: return ""
        }
    }

    func mentalHealthLabel(for score: Int) -> String {
        switch score {
        case 1...2: return "Very Low"
        case 3...4: return "Low"
        case 5...6: return "Moderate"
        case 7...8: return "Good"
        case 9...10: return "Excellent"
        default: return ""
        }
    }

    func mentalHealthColor(for score: Int) -> Color {
        switch score {
        case 1...3: return Color("severityHigh")
        case 4...6: return Color("severityMed")
        case 7...10: return Color("severityLow")
        default: return .gray
        }
    }

    // MARK: - Add / Toggle symptom
    func toggleSymptom(_ symptom: CommonSymptom) {
        if let idx = selectedSymptoms.firstIndex(where: { $0.name == symptom.name }) {
            selectedSymptoms.remove(at: idx)
        } else {
            selectedSymptoms.append(LoggedSymptom(name: symptom.name, category: symptom.category))
        }
        // Reset saved state so user knows they need to re-save
        isSaved = false
    }

    func isSelected(_ symptom: CommonSymptom) -> Bool {
        selectedSymptoms.contains(where: { $0.name == symptom.name })
    }

    func updateSeverity(for symptomName: String, severity: Int) {
        if let idx = selectedSymptoms.firstIndex(where: { $0.name == symptomName }) {
            selectedSymptoms[idx].severity = severity
        }
        isSaved = false
    }

    /// Remove a symptom from the in-memory list AND update/delete the SwiftData entry for today.
    func removeSymptom(_ symptom: LoggedSymptom, context: ModelContext, allEntries: [SymptomEntry]) {
        // 1. Remove from in-memory list
        selectedSymptoms.removeAll { $0.id == symptom.id }
        isSaved = false

        // 2. Find today's SwiftData entry
        guard let todayEntry = allEntries.first(where: {
            Calendar.current.isDateInToday($0.date)
        }) else { return }

        if selectedSymptoms.isEmpty {
            // No symptoms left at all — delete the whole entry
            context.delete(todayEntry)
        } else {
            // Update the entry with the symptom removed
            todayEntry.symptoms.removeAll { $0.name == symptom.name }
        }

        try? context.save()
    }

    func addCustomSymptom() {
        guard !customSymptomName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let symptom = LoggedSymptom(
            name: customSymptomName.trimmingCharacters(in: .whitespaces),
            category: customSymptomCategory
        )
        selectedSymptoms.append(symptom)
        customSymptomName = ""
        showingCustomSymptom = false
        isSaved = false
    }

    // MARK: - Copy from yesterday
    func copyYesterdaySymptoms(from entries: [SymptomEntry]) {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        guard let yesterdayEntry = entries.first(where: {
            calendar.isDate($0.date, inSameDayAs: yesterday)
        }) else { return }

        for symptom in yesterdayEntry.symptoms {
            if !selectedSymptoms.contains(where: { $0.name == symptom.name }) {
                selectedSymptoms.append(symptom)
            }
        }
        isSaved = false
    }

    // MARK: - Save entry (upsert: delete today's existing entry first, then insert fresh)
    func saveEntry(context: ModelContext, allEntries: [SymptomEntry]) {
        // Delete any existing entry for today before saving the new one
        let todayEntries = allEntries.filter {
            Calendar.current.isDateInToday($0.date)
        }
        for existing in todayEntries {
            context.delete(existing)
        }

        // Insert the fresh, up-to-date entry
        let entry = SymptomEntry(
            date: Date(),
            symptoms: selectedSymptoms,
            mentalHealthScore: mentalHealthScore,
            angerScore: angerScore,
            anxietyScore: anxietyScore,
            lonelinessScore: lonelinessScore,
            heavinessScore: heavinessScore,
            notes: notes
        )
        context.insert(entry)
        try? context.save()

        showingSaveConfirmation = true
        isSaved = true
    }

    // MARK: - Past symptoms for quick access
    func pastSymptomNames(from entries: [SymptomEntry]) -> [CommonSymptom] {
        var seen = Set<String>()
        var result: [CommonSymptom] = []
        // Skip today's entry so we don't show current symptoms as "recent"
        let pastEntries = entries.filter { !Calendar.current.isDateInToday($0.date) }
        for entry in pastEntries.prefix(14) {
            for s in entry.symptoms {
                if !seen.contains(s.name) {
                    seen.insert(s.name)
                    result.append(CommonSymptom(name: s.name, category: s.category))
                }
            }
        }
        return result
    }
}
