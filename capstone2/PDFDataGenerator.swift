//
//  PdfDataGenerator.swift
//  capstone2
//
//  Created by Xiaojing Meng on 3/11/26.

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

    init(entries: [SymptomEntry], patientName: String, range: ExportRange) {
        self.entries = entries.sorted { $0.date < $1.date }
        self.patientName = patientName
        self.range = range
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
                if last > first + 0.5      { trend = "Worsening" }
                else if last < first - 0.5 { trend = "Improving" }
                else                       { trend = "Stable" }
            } else { trend = "Stable" }
            return SymptomStat(name: name, category: data.0,
                               occurrences: severities.count, avgSeverity: avg,
                               maxSeverity: maxVal, trend: trend)
        }
        .sorted { $0.avgSeverity > $1.avgSeverity }
    }

    var mostConcerningSymptom: SymptomStat? {
        let worsening = symptomStats.filter { $0.trend == "Worsening" }
        return (worsening.isEmpty ? symptomStats : worsening).first
    }

    var avgMentalHealth: Double {
        guard !entries.isEmpty else { return 0 }
        return Double(entries.map(\.mentalHealthScore).reduce(0, +)) / Double(entries.count)
    }

    var uniqueSymptomCount: Int {
        Set(entries.flatMap(\.symptoms).map(\.name)).count
    }

    var dailySnapshots: [DailySnapshot] {
        entries.map { DailySnapshot(date: $0.date, symptoms: $0.symptoms,
                                    mentalHealth: $0.mentalHealthScore, notes: $0.notes) }
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
        parts.append("Over \(entries.count) logged day(s), \(uniqueSymptomCount) distinct symptom(s) were recorded.")
        if let top = mostConcerningSymptom {
            parts.append("The most notable symptom was \(top.name) (average severity \(String(format: "%.1f", top.avgSeverity))/10, \(top.trend.lowercased())).")
        }
        let avg = avgMentalHealth
        if avg >= 7 { parts.append("Mental wellbeing has been strong during this period.") }
        else if avg >= 4 { parts.append("Mental wellbeing has been moderate, with some difficult days.") }
        else { parts.append("Mental wellbeing has been challenging. Consider discussing emotional support with your care team.") }
        return parts.joined(separator: " ")
    }
}
