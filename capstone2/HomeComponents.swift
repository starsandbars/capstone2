import SwiftUI

// MARK: - Section Header with subtitle
struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var count: Int? = nil

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color("textPrimary"))
                    if let count {
                        Text("\(count)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Color("accentTeal"))
                            .clipShape(Capsule())
                    }
                }
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color("textTertiary"))
                }
            }
            Spacer()
        }
    }
}

// MARK: - At-a-Glance Card
struct GlanceCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 36, height: 36)
                .background(iconColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Spacer()

            // Value
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color("textPrimary"))
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            // Label + subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color("textSecondary"))
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color("textTertiary"))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .background(Color("cardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }
}

// MARK: - Severity Bar Chart
struct SeverityBarChart: View {
    let days: [DaySeverity]
    @State private var animateIn = false

    // Fill all 7 days, padding missing ones as nil
    var allDays: [(label: String, value: Double?)] {
        let letters = ["M", "T", "W", "T", "F", "S", "S"]
        var result: [(String, Double?)] = letters.map { ($0, nil) }

        let calendar = Calendar.current
        for day in days {
            let weekday = calendar.component(.weekday, from: day.date)
            // weekday: 1=Sun, 2=Mon... map to 0-based Mon-Sun
            let idx = (weekday + 5) % 7
            if idx < 7 {
                result[idx] = (day.dayLetter, day.averageSeverity)
            }
        }
        return result
    }

    func barColor(for value: Double) -> Color {
        switch value {
        case 0..<4: return Color("severityLow")
        case 4..<7: return Color("severityMed")
        default: return Color("severityHigh")
        }
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(Array(allDays.enumerated()), id: \.offset) { index, day in
                VStack(spacing: 6) {
                    if let value = day.value {
                        // Value label on top of bar
                        Text(String(format: "%.0f", value))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(barColor(for: value))
                            .opacity(animateIn ? 1 : 0)

                        // Bar
                        RoundedRectangle(cornerRadius: 6)
                            .fill(barColor(for: value))
                            .frame(
                                height: animateIn ? CGFloat(value / 10.0) * 90 + 8 : 4
                            )
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.7)
                                .delay(Double(index) * 0.06),
                                value: animateIn
                            )
                    } else {
                        // Empty day
                        Spacer()
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color("sliderTrack"))
                            .frame(height: 4)
                    }

                    Text(day.label)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(day.value != nil ? Color("textSecondary") : Color("textTertiary"))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateIn = true
            }
        }
        .onChange(of: days.count) {
            animateIn = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                animateIn = true
            }
        }
    }
}

// MARK: - Legend Dot
struct LegendDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color("textTertiary"))
        }
    }
}

// MARK: - Frequency Row (most common symptoms)
struct FrequencyRow: View {
    let rank: Int
    let name: String
    let category: SymptomCategory
    let count: Int
    let maxCount: Int

    @State private var animateBar = false

    var fillFraction: CGFloat {
        maxCount > 0 ? CGFloat(count) / CGFloat(maxCount) : 0
    }

    var body: some View {
        HStack(spacing: 12) {
            // Rank number
            Text("\(rank)")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(rank == 1 ? Color("accentTeal") : Color("textTertiary"))
                .frame(width: 20, alignment: .center)

            // Name + category
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color("textPrimary"))
                Text(category.localizedTitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(category.color))
            }

            Spacer()

            // Bar + count
            HStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color("sliderTrack"))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(category.color))
                            .frame(width: animateBar ? geo.size.width * fillFraction : 0, height: 6)
                            .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(Double(rank) * 0.08), value: animateBar)
                    }
                    .frame(height: 6)
                    .frame(maxHeight: .infinity, alignment: .center)
                }
                .frame(width: 80)

                Text("\(count)x")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color("textSecondary"))
                    .frame(width: 28, alignment: .trailing)
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                animateBar = true
            }
        }
    }
}

// MARK: - Mental Health Arc Row (day-by-day mood)
struct MentalHealthArcRow: View {
    let entries: [SymptomEntry]
    @State private var animateIn = false

    var sortedEntries: [SymptomEntry] {
        entries.sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(spacing: 14) {
            // Day bubbles
            HStack(spacing: 6) {
                ForEach(sortedEntries) { entry in
                    MoodBubble(score: entry.mentalHealthScore, date: entry.date, animate: animateIn)
                }
                // Empty placeholders
                if sortedEntries.count < 7 {
                    ForEach(0..<(7 - sortedEntries.count), id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color("sliderTrack"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                    }
                }
            }

            // Average label
            if !sortedEntries.isEmpty {
                let avg = Double(sortedEntries.map(\.mentalHealthScore).reduce(0, +)) / Double(sortedEntries.count)
                HStack {
                    Text("Weekly average:")
                        .font(.system(size: 13))
                        .foregroundStyle(Color("textSecondary"))
                    Text(String(format: "%.1f / 10", avg))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(moodColor(for: avg))
                    Spacer()
                    Text(moodLabel(for: avg))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(moodColor(for: avg))
                        .clipShape(Capsule())
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateIn = true
            }
        }
    }

    func moodColor(for value: Double) -> Color {
        if value >= 7 { return Color("severityLow") }
        if value >= 4 { return Color("severityMed") }
        return Color("severityHigh")
    }

    func moodLabel(for value: Double) -> String {
        if value >= 7 { return "Good" }
        if value >= 4 { return "Moderate" }
        return "Difficult"
    }
}

// MARK: - Individual Mood Bubble
struct MoodBubble: View {
    let score: Int
    let date: Date
    let animate: Bool

    let emojis = ["😞","😟","😕","😐","🙂","😊","😄","😁","🤩","🥳"]

    var bubbleColor: Color {
        switch score {
        case 1...3: return Color("severityHigh").opacity(0.15)
        case 4...6: return Color("severityMed").opacity(0.15)
        default: return Color("severityLow").opacity(0.15)
        }
    }

    var dayLabel: String {
        let f = DateFormatter()
        f.dateFormat = "E"
        return String(f.string(from: date).prefix(1))
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(bubbleColor)
                    .frame(height: 52)

                VStack(spacing: 1) {
                    Text(emojis[score - 1])
                        .font(.system(size: 20))
                        .scaleEffect(animate ? 1 : 0.3)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.1), value: animate)
                    Text("\(score)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color("textSecondary"))
                }
            }

            Text(dayLabel)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color("textTertiary"))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Emotional Score Row (home summary)
struct EmotionalScoreRow: View {
    let label: String
    let icon: String
    let colorHex: String
    let score: Double
    @State private var animate = false

    var color: Color { Color(hex: colorHex) }

    var levelLabel: String {
        switch score {
        case 0..<3:  return NSLocalizedString("emotion.intensity.low", comment: "")
        case 3..<5:  return "Mild"
        case 5..<7:  return NSLocalizedString("emotion.intensity.moderate", comment: "")
        case 7..<9:  return NSLocalizedString("emotion.intensity.high", comment: "")
        default:     return "Very high"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(label)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color("textPrimary"))
                    Spacer()
                    Text(String(format: "%.1f", score))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(color)
                    Text("/ 10")
                        .font(.system(size: 11))
                        .foregroundStyle(Color("textTertiary"))
                }

                // Fill bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color("sliderTrack"))
                            .frame(height: 5)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(color)
                            .frame(width: animate ? geo.size.width * CGFloat(score / 10.0) : 0, height: 5)
                            .animation(.spring(response: 0.55, dampingFraction: 0.75).delay(0.1), value: animate)
                    }
                }
                .frame(height: 5)
            }

            // Level pill
            Text(levelLabel)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color.opacity(0.1))
                .clipShape(Capsule())
        }
        .onAppear { animate = true }
        .onChange(of: score) { animate = false; DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { animate = true } }
    }
}

// MARK: - Emotional Summary Row (for home weekly breakdown)
struct EmotionalSummaryRow: View {
    let icon: String
    let label: String
    let score: Double      // 0–10 average
    let color: Color
    @State private var animateBar = false

    var intensityLabel: String {
        switch score {
        case 0..<2:  return NSLocalizedString("emotion.intensity.minimal", comment: "")
        case 2..<4:  return "Low"
        case 4..<6:  return "Moderate"
        case 6..<8:  return NSLocalizedString("emotion.intensity.elevated", comment: "")
        default:     return "High"
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 28, height: 28)
                    .background(color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 7))

                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color("textPrimary"))

                Spacer()

                HStack(spacing: 4) {
                    Text(String(format: "%.1f", score))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(color)
                    Text("/10")
                        .font(.system(size: 11))
                        .foregroundStyle(Color("textTertiary"))
                    Text("·")
                        .foregroundStyle(Color("textTertiary"))
                    Text(intensityLabel)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(color)
                }
            }

            // Animated fill bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color("sliderTrack"))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.6), color],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: animateBar ? geo.size.width * CGFloat(score / 10.0) : 0, height: 6)
                        .animation(.spring(response: 0.55, dampingFraction: 0.75).delay(0.1), value: animateBar)
                }
            }
            .frame(height: 6)
        }
        .onAppear { animateBar = true }
        .onChange(of: score) {
            animateBar = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { animateBar = true }
        }
    }
}
