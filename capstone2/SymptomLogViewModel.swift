import Foundation
import SwiftUI
import SwiftData

@Observable
class SymptomLogViewModel {
    
    // MARK: - State
    var selectedSymptoms: [LoggedSymptom] = []
    var mentalHealthScore: Int = 5
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
    
    // MARK: - Severity color helper
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
    
    // MARK: - Add / Remove symptom
    func toggleSymptom(_ symptom: CommonSymptom) {
        if let idx = selectedSymptoms.firstIndex(where: { $0.name == symptom.name }) {
            selectedSymptoms.remove(at: idx)
        } else {
            selectedSymptoms.append(LoggedSymptom(name: symptom.name, category: symptom.category))
        }
    }
    
    func isSelected(_ symptom: CommonSymptom) -> Bool {
        selectedSymptoms.contains(where: { $0.name == symptom.name })
    }
    
    func updateSeverity(for symptomName: String, severity: Int) {
        if let idx = selectedSymptoms.firstIndex(where: { $0.name == symptomName }) {
            selectedSymptoms[idx].severity = severity
        }
    }
    
    func removeSymptom(_ symptom: LoggedSymptom) {
        selectedSymptoms.removeAll { $0.id == symptom.id }
    }
    
    func addCustomSymptom() {
        guard !customSymptomName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let symptom = LoggedSymptom(name: customSymptomName.trimmingCharacters(in: .whitespaces),
                                    category: customSymptomCategory)
        selectedSymptoms.append(symptom)
        customSymptomName = ""
        showingCustomSymptom = false
    }
    
    // MARK: - Copy from yesterday
    func copyYesterdaySymptoms(from entries: [SymptomEntry]) {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        if let yesterdayEntry = entries.first(where: { calendar.isDate($0.date, inSameDayAs: yesterday) }) {
            for symptom in yesterdayEntry.symptoms {
                if !selectedSymptoms.contains(where: { $0.name == symptom.name }) {
                    selectedSymptoms.append(symptom)
                }
            }
        }
    }
    
    // MARK: - Save entry
    func saveEntry(context: ModelContext) {
        let entry = SymptomEntry(
            date: Date(),
            symptoms: selectedSymptoms,
            mentalHealthScore: mentalHealthScore,
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
        for entry in entries.prefix(14) {
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
