import Foundation
import SwiftData

// MARK: - Symptom Category
enum SymptomCategory: String, CaseIterable, Codable {
    case fatigue = "Fatigue"
    case pain = "Pain"
    case nausea = "Nausea & Digestion"
    case cognitive = "Cognitive"
    case emotional = "Emotional"
    case skin = "Skin & Hair"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .fatigue: return "battery.25"
        case .pain: return "bolt.fill"
        case .nausea: return "waveform.path"
        case .cognitive: return "brain.head.profile"
        case .emotional: return "heart.fill"
        case .skin: return "person.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .fatigue: return "symptomFatigue"
        case .pain: return "symptomPain"
        case .nausea: return "symptomNausea"
        case .cognitive: return "symptomCognitive"
        case .emotional: return "symptomEmotional"
        case .skin: return "symptomSkin"
        case .other: return "symptomOther"
        }
    }
}

// MARK: - Common Symptom
struct CommonSymptom: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let category: SymptomCategory
    
    static let preloaded: [CommonSymptom] = [
        // Fatigue
        CommonSymptom(name: "Tiredness", category: .fatigue),
        CommonSymptom(name: "Weakness", category: .fatigue),
        CommonSymptom(name: "Shortness of breath", category: .fatigue),
        CommonSymptom(name: "Low energy", category: .fatigue),
        
        // Pain
        CommonSymptom(name: "Headache", category: .pain),
        CommonSymptom(name: "Joint pain", category: .pain),
        CommonSymptom(name: "Muscle aches", category: .pain),
        CommonSymptom(name: "Chest pain", category: .pain),
        CommonSymptom(name: "Back pain", category: .pain),
        
        // Nausea
        CommonSymptom(name: "Nausea", category: .nausea),
        CommonSymptom(name: "Vomiting", category: .nausea),
        CommonSymptom(name: "Loss of appetite", category: .nausea),
        CommonSymptom(name: "Diarrhea", category: .nausea),
        CommonSymptom(name: "Constipation", category: .nausea),
        
        // Cognitive
        CommonSymptom(name: "Brain fog", category: .cognitive),
        CommonSymptom(name: "Memory issues", category: .cognitive),
        CommonSymptom(name: "Difficulty concentrating", category: .cognitive),
        CommonSymptom(name: "Confusion", category: .cognitive),
        
        // Emotional
        CommonSymptom(name: "Anxiety", category: .emotional),
        CommonSymptom(name: "Depression", category: .emotional),
        CommonSymptom(name: "Mood swings", category: .emotional),
        CommonSymptom(name: "Irritability", category: .emotional),
        
        // Skin
        CommonSymptom(name: "Hair loss", category: .skin),
        CommonSymptom(name: "Dry skin", category: .skin),
        CommonSymptom(name: "Rash", category: .skin),
        CommonSymptom(name: "Nail changes", category: .skin),
    ]
}

// MARK: - Logged Symptom Entry
@Model
class SymptomEntry {
    var id: UUID
    var date: Date
    var symptoms: [LoggedSymptom]
    var mentalHealthScore: Int
    var notes: String
    
    init(date: Date = Date(), symptoms: [LoggedSymptom] = [], mentalHealthScore: Int = 5, notes: String = "") {
        self.id = UUID()
        self.date = date
        self.symptoms = symptoms
        self.mentalHealthScore = mentalHealthScore
        self.notes = notes
    }
    
    var dateKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - Individual Symptom with Severity
struct LoggedSymptom: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var category: SymptomCategory
    var severity: Int // 1-10
    
    init(name: String, category: SymptomCategory, severity: Int = 5) {
        self.name = name
        self.category = category
        self.severity = severity
    }
}

