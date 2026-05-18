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

    var localizedTitle: String {
        switch self {
        case .fatigue:   return NSLocalizedString("category.fatigue",   comment: "")
        case .pain:      return NSLocalizedString("category.pain",      comment: "")
        case .nausea:    return NSLocalizedString("category.nausea",    comment: "")
        case .cognitive: return NSLocalizedString("category.cognitive", comment: "")
        case .emotional: return NSLocalizedString("category.emotional", comment: "")
        case .skin:      return NSLocalizedString("category.skin",      comment: "")
        case .other:     return NSLocalizedString("category.other",     comment: "")
        }
    }
}

// MARK: - Common Symptom
struct CommonSymptom: Identifiable, Hashable {
    let id = UUID()
    let name: String          // localisation key for preloaded; raw text for custom
    let category: SymptomCategory

    /// Display name — localised if a key exists, otherwise raw text (custom symptoms)
    var localizedName: String {
        let attempt = NSLocalizedString(name, comment: "")
        return attempt == name ? name : attempt   // falls back to raw if key not found
    }

    static let preloaded: [CommonSymptom] = [
        // Fatigue
        CommonSymptom(name: "symptom.tiredness", category: .fatigue),
        CommonSymptom(name: "symptom.weakness", category: .fatigue),
        CommonSymptom(name: "symptom.shortness_of_breath", category: .fatigue),
        CommonSymptom(name: "symptom.low_energy", category: .fatigue),

        // Pain
        CommonSymptom(name: "symptom.headache", category: .pain),
        CommonSymptom(name: "symptom.joint_pain", category: .pain),
        CommonSymptom(name: "symptom.muscle_aches", category: .pain),
        CommonSymptom(name: "symptom.chest_pain", category: .pain),
        CommonSymptom(name: "symptom.back_pain", category: .pain),

        // Nausea
        CommonSymptom(name: "symptom.nausea", category: .nausea),
        CommonSymptom(name: "symptom.vomiting", category: .nausea),
        CommonSymptom(name: "symptom.loss_of_appetite", category: .nausea),
        CommonSymptom(name: "symptom.diarrhea", category: .nausea),
        CommonSymptom(name: "symptom.constipation", category: .nausea),

        // Cognitive
        CommonSymptom(name: "symptom.brain_fog", category: .cognitive),
        CommonSymptom(name: "symptom.memory_issues", category: .cognitive),
        CommonSymptom(name: "symptom.difficulty_concentrating", category: .cognitive),
        CommonSymptom(name: "symptom.confusion", category: .cognitive),

        // Emotional
        CommonSymptom(name: "symptom.anxiety", category: .emotional),
        CommonSymptom(name: "symptom.depression", category: .emotional),
        CommonSymptom(name: "symptom.mood_swings", category: .emotional),
        CommonSymptom(name: "symptom.irritability", category: .emotional),

        // Skin
        CommonSymptom(name: "symptom.hair_loss", category: .skin),
        CommonSymptom(name: "symptom.dry_skin", category: .skin),
        CommonSymptom(name: "symptom.rash", category: .skin),
        CommonSymptom(name: "symptom.nail_changes", category: .skin),
    ]
}

// MARK: - Logged Symptom Entry
@Model
class SymptomEntry {
    var id: UUID
    var date: Date
    var symptoms: [LoggedSymptom]
    var mentalHealthScore: Int   // overall wellbeing
    var angerScore: Int          // anger / frustration
    var anxietyScore: Int        // worry / anxiety about recovery
    var lonelinessScore: Int     // loneliness / isolation
    var heavinessScore: Int      // emotional heaviness of the day
    var notes: String

    init(date: Date = Date(),
         symptoms: [LoggedSymptom] = [],
         mentalHealthScore: Int = 5,
         angerScore: Int = 5,
         anxietyScore: Int = 5,
         lonelinessScore: Int = 5,
         heavinessScore: Int = 5,
         notes: String = "") {
        self.id = UUID()
        self.date = date
        self.symptoms = symptoms
        self.mentalHealthScore = mentalHealthScore
        self.angerScore = angerScore
        self.anxietyScore = anxietyScore
        self.lonelinessScore = lonelinessScore
        self.heavinessScore = heavinessScore
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
    var name: String          // key for preloaded symptoms; raw text for custom
    var category: SymptomCategory
    var severity: Int // 1-10

    /// Display name — localised if a key exists, otherwise the raw stored text
    var localizedName: String {
        let attempt = NSLocalizedString(name, comment: "")
        return attempt == name ? name : attempt
    }

    init(name: String, category: SymptomCategory, severity: Int = 5) {
        self.name = name
        self.category = category
        self.severity = severity
    }
}
