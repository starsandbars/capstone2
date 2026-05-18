import Foundation
import SwiftUI

// MARK: - Computed data structs
struct SymptomStat {
    let name: String
    let category: SymptomCategory
    let occurrences: Int
    let avgSeverity: Double
    let maxSeverity: Int
    let trend: String
}

struct DailySnapshot {
    let date: Date
    let symptoms: [LoggedSymptom]
    let mentalHealth: Int
    let anger: Int
    let anxiety: Int
    let loneliness: Int
    let heaviness: Int
    let notes: String

    var avgSeverity: Double {
        guard !symptoms.isEmpty else { return 0 }
        return Double(symptoms.map(\.severity).reduce(0, +)) / Double(symptoms.count)
    }
}

class PDFDataGenerator {
    let entries: [SymptomEntry]
    let patientName: String
    let range: ExportRange
    let generatedAt = Date()
    let pdfBundle: Bundle   // language bundle for the PDF output

    init(entries: [SymptomEntry], patientName: String, range: ExportRange, pdfBundle: Bundle = .main) {
        self.entries = entries.sorted { $0.date < $1.date }
        self.patientName = patientName
        self.range = range
        self.pdfBundle = pdfBundle
    }

    /// Resolve a UI string in the chosen PDF language
    func str(_ key: String) -> String {
        pdfBundle.localizedString(forKey: key, value: key, table: nil)
    }

    /// Resolve a symptom name:
    /// - Preloaded symptoms: looks up the catalog key in the PDF language bundle
    /// - Custom symptoms: returns the raw text as typed by the user
    func resolveSymptomName(_ name: String) -> String {
        let catalogAttempt = pdfBundle.localizedString(forKey: name, value: "", table: nil)
        return catalogAttempt.isEmpty ? name : catalogAttempt
    }

    // MARK: - Stats
    var symptomStats: [SymptomStat] {
        var map: [String: (SymptomCategory, [Int])] = [:]
        for entry in entries {
            for s in entry.symptoms {
                var existing = map[s.name] ?? (s.category, [])
                existing.1.append(s.severity)
                map[s.name] = existing
            }
        }
        return map.map { name, data in
            let severities = data.1
            let avg = Double(severities.reduce(0, +)) / Double(severities.count)
            let maxVal = severities.max() ?? 0
            let half = severities.count / 2
            let trend: String
            if half > 0 {
                let first = Double(severities.prefix(half).reduce(0, +)) / Double(half)
                let last  = Double(severities.suffix(half).reduce(0, +)) / Double(half)
                if last > first + 0.5      { trend = str("pdf.trend.worsening") }
                else if last < first - 0.5 { trend = str("pdf.trend.improving") }
                else                       { trend = NSLocalizedString("pdf.trend.stable",    comment: "") }
            } else { trend = str("pdf.trend.stable") }
            return SymptomStat(name: name, category: data.0,
                               occurrences: severities.count, avgSeverity: avg,
                               maxSeverity: maxVal, trend: trend)
        }
        .sorted { $0.avgSeverity > $1.avgSeverity }
    }

    var mostConcerningSymptom: SymptomStat? {
        let worsening = symptomStats.filter { $0.trend == str("pdf.trend.worsening") }
        return (worsening.isEmpty ? symptomStats : worsening).first
    }

    var avgMentalHealth: Double {
        guard !entries.isEmpty else { return 0 }
        return Double(entries.map(\.mentalHealthScore).reduce(0, +)) / Double(entries.count)
    }

    var avgAnger: Double {
        guard !entries.isEmpty else { return 0 }
        return Double(entries.map(\.angerScore).reduce(0, +)) / Double(entries.count)
    }

    var avgAnxiety: Double {
        guard !entries.isEmpty else { return 0 }
        return Double(entries.map(\.anxietyScore).reduce(0, +)) / Double(entries.count)
    }

    var avgLoneliness: Double {
        guard !entries.isEmpty else { return 0 }
        return Double(entries.map(\.lonelinessScore).reduce(0, +)) / Double(entries.count)
    }

    var avgHeaviness: Double {
        guard !entries.isEmpty else { return 0 }
        return Double(entries.map(\.heavinessScore).reduce(0, +)) / Double(entries.count)
    }

    /// All four emotional dimensions as a sorted array for PDF rendering
    var emotionalScores: [(label: String, score: Double)] {
        [
            (str("pdf.emotional.anger"), avgAnger),
            (str("pdf.emotional.anxiety"), avgAnxiety),
            (str("pdf.emotional.loneliness"), avgLoneliness),
            (str("pdf.emotional.heaviness"), avgHeaviness),
        ]
    }

    var mostElevatedEmotion: (label: String, score: Double)? {
        emotionalScores.filter { $0.score >= 4 }.max(by: { $0.score < $1.score })
    }

    var uniqueSymptomCount: Int {
        Set(entries.flatMap(\.symptoms).map(\.name)).count
    }

    var dailySnapshots: [DailySnapshot] {
        entries.map { DailySnapshot(
            date: $0.date,
            symptoms: $0.symptoms,
            mentalHealth: $0.mentalHealthScore,
            anger: $0.angerScore,
            anxiety: $0.anxietyScore,
            loneliness: $0.lonelinessScore,
            heaviness: $0.heavinessScore,
            notes: $0.notes
        )}
    }

    var dateRangeLabel: String {
        guard let first = entries.first?.date, let last = entries.last?.date else { return "No data" }
        let f = DateFormatter(); f.dateFormat = "MMM d, yyyy"
        if Calendar.current.isDate(first, inSameDayAs: last) { return f.string(from: first) }
        return "\(f.string(from: first)) - \(f.string(from: last))"
    }

    var generatedLabel: String {
        let f = DateFormatter(); f.dateFormat = "MMMM d, yyyy 'at' h:mm a"
        return f.string(from: generatedAt)
    }

    var topSymptoms: [SymptomStat] { Array(symptomStats.prefix(6)) }

    var overallSummary: String {
        guard !entries.isEmpty else { return "No symptom data available for the selected period." }
        var parts: [String] = []
        let daysFmt = str("pdf.summary.days")
        parts.append(String(format: daysFmt, entries.count, uniqueSymptomCount))
        if let top = mostConcerningSymptom {
            let localSymptomName = resolveSymptomName(top.name)
        let notableFmt = str("pdf.summary.notable")
        parts.append(String(format: notableFmt, localSymptomName, top.avgSeverity, top.trend.lowercased()))
        }
        let avg = avgMentalHealth
        if avg >= 7 { parts.append(str("pdf.overall.mood.strong")) }
        else if avg >= 4 { parts.append(str("pdf.overall.mood.moderate")) }
        else { parts.append(str("pdf.overall.mood.challenging")) }
        if let elevated = mostElevatedEmotion {
            let elevatedFmt = str("pdf.summary.elevated")
        parts.append(String(format: elevatedFmt, elevated.label, elevated.score))
        }
        return parts.joined(separator: " ")
    }
}
