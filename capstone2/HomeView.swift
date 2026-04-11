import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SymptomEntry.date, order: .reverse) private var entries: [SymptomEntry]
    @State private var viewModel = HomeViewModel()

    var summary: WeeklySummary {
        viewModel.weeklySummary(from: entries, offset: viewModel.selectedWeekOffset)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("backgroundPrimary").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        headerSection
                            .padding(.bottom, 24)

                        VStack(spacing: 24) {
                            // Week selector
                            weekSelectorRow

                            if summary.totalDaysLogged == 0 {
                                emptyStateView
                            } else {
                                // At-a-glance cards
                                atAGlanceRow

                                // Severity chart
                                severityChartSection

                                // Most common symptoms
                                mostCommonSection

                                // Mental health arc
                                mentalHealthSection

                                // Wellbeing message
                                wellbeingMessageCard
                            }
                        }
                        .padding(.horizontal, 20)

                        Spacer().frame(height: 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Header
    var headerSection: some View {
        ZStack(alignment: .bottomLeading) {
            // Soft gradient background
            LinearGradient(
                colors: [Color("accentTeal").opacity(0.18), Color("backgroundPrimary")],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 180)

            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.greetingText())
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color("accentTeal"))
                    .textCase(.uppercase)
                    .tracking(1.2)

                Text("home.title")
                    .font(.custom("Georgia", size: 32))
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("textPrimary"))
                    .lineSpacing(2)

                // Streak pill
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.orange)
                    Text(String(format: NSLocalizedString("home.streak", comment: ""), consecutiveStreak))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color("textSecondary"))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color("cardBackground"))
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    var consecutiveStreak: Int {
        var count = 0
        let calendar = Calendar.current
        var checkDate = Date()
        for _ in 0..<30 {
            if entries.contains(where: { calendar.isDate($0.date, inSameDayAs: checkDate) }) {
                count += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else { break }
        }
        return count
    }

    // MARK: - Week Selector
    var weekSelectorRow: some View {
        HStack(spacing: 0) {
            // Previous week
            Button {
                withAnimation(.spring(response: 0.35)) {
                    viewModel.selectedWeekOffset -= 1
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color("textSecondary"))
                    .frame(width: 40, height: 40)
            }

            Spacer()

            VStack(spacing: 2) {
                Text(viewModel.selectedWeekOffset == 0 ? NSLocalizedString("home.week.this", comment: "") :
                     viewModel.selectedWeekOffset == -1 ? NSLocalizedString("home.week.last", comment: "") :
                     String(format: NSLocalizedString("home.week.ago", comment: ""), abs(viewModel.selectedWeekOffset)))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color("textPrimary"))
                Text(summary.weekLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color("textTertiary"))
            }

            Spacer()

            // Next week (disabled if current)
            Button {
                withAnimation(.spring(response: 0.35)) {
                    if viewModel.selectedWeekOffset < 0 {
                        viewModel.selectedWeekOffset += 1
                    }
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(viewModel.selectedWeekOffset == 0 ? Color("borderColor") : Color("textSecondary"))
                    .frame(width: 40, height: 40)
            }
            .disabled(viewModel.selectedWeekOffset == 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(Color("cardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    // MARK: - At-a-glance cards
    var atAGlanceRow: some View {
        HStack(spacing: 12) {
            GlanceCard(
                icon: "calendar.badge.checkmark",
                iconColor: Color("accentTeal"),
                value: "\(summary.totalDaysLogged)/7",
                label: NSLocalizedString("home.card.logged", comment: ""),
                subtitle: summary.totalDaysLogged >= 5 ? NSLocalizedString("home.consistency.great", comment: "") : NSLocalizedString("home.consistency.keepup", comment: "")
            )

            worriedSymptomCard

            GlanceCard(
                icon: "heart.fill",
                iconColor: mentalHealthColor,
                value: String(format: "%.1f", summary.averageMentalHealth),
                label: NSLocalizedString("home.card.mood", comment: ""),
                subtitle: NSLocalizedString("home.card.outof10", comment: "")
            )
        }
    }

    @ViewBuilder
    var worriedSymptomCard: some View {
        if let worried = summary.mostWorriedSymptom {
            GlanceCard(
                icon: "exclamationmark.triangle.fill",
                iconColor: Color("severityHigh"),
                value: worried.percentIncreaseLabel,
                label: worried.name,
                subtitle: String(format: "Severity %.1f/10", worried.currentAvg)
            )
        } else {
            GlanceCard(
                icon: summary.overallSeverityTrend.icon,
                iconColor: summary.overallSeverityTrend.color,
                value: summary.overallSeverityTrend.label,
                label: NSLocalizedString("home.card.trend", comment: ""),
                subtitle: NSLocalizedString("home.card.trend.vs", comment: "")
            )
        }
    }

    var mentalHealthColor: Color {
        let avg = summary.averageMentalHealth
        if avg >= 7 { return Color("severityLow") }
        if avg >= 4 { return Color("severityMed") }
        return Color("severityHigh")
    }


    // MARK: - Severity Chart
    var severityChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: NSLocalizedString("home.section.severity", comment: ""), subtitle: NSLocalizedString("home.section.severity.subtitle", comment: ""))

            if summary.averageSeverityByDay.isEmpty {
                Text("home.nodata")
                    .font(.system(size: 14))
                    .foregroundStyle(Color("textTertiary"))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 30)
            } else {
                SeverityBarChart(days: summary.averageSeverityByDay)
                    .frame(height: 140)
            }

            // Legend
            HStack(spacing: 16) {
                LegendDot(color: Color("severityLow"), label: NSLocalizedString("home.severity.mild", comment: ""))
                LegendDot(color: Color("severityMed"), label: NSLocalizedString("home.severity.moderate", comment: ""))
                LegendDot(color: Color("severityHigh"), label: NSLocalizedString("home.severity.severe", comment: ""))
            }
        }
        .padding(18)
        .background(Color("cardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    // MARK: - Most Common Symptoms
    var mostCommonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: NSLocalizedString("home.section.frequency", comment: ""), subtitle: NSLocalizedString("home.section.frequency.subtitle", comment: ""))

            if summary.mostCommonSymptoms.isEmpty {
                Text("home.nosymptoms")
                    .font(.system(size: 14))
                    .foregroundStyle(Color("textTertiary"))
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(summary.mostCommonSymptoms.enumerated()), id: \.offset) { index, symptom in
                        FrequencyRow(
                            rank: index + 1,
                            name: symptom.name,
                            category: symptom.category,
                            count: symptom.count,
                            maxCount: summary.mostCommonSymptoms.first?.count ?? 1
                        )
                    }
                }
            }
        }
        .padding(18)
        .background(Color("cardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    // MARK: - Mental Health Section
    var mentalHealthSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: NSLocalizedString("home.section.mental", comment: ""), subtitle: NSLocalizedString("home.section.mental.subtitle", comment: ""))

            // Overall mood bubbles row
            MentalHealthArcRow(entries: summary.entries)

            // Divider
            HStack(spacing: 10) {
                Rectangle().fill(Color("borderColor")).frame(height: 1)
                Text("home.section.emotional")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color("textTertiary"))
                    .textCase(.uppercase)
                    .tracking(0.8)
                    .fixedSize()
                Rectangle().fill(Color("borderColor")).frame(height: 1)
            }

            // 4 emotional dimension bars
            VStack(spacing: 12) {
                EmotionalSummaryRow(
                    icon: "flame.fill",
                    label: "Anger / Frustration",
                    score: summary.averageAnger,
                    color: Color(hex: "E74C3C")
                )
                EmotionalSummaryRow(
                    icon: "cloud.rain.fill",
                    label: "Worry / Anxiety",
                    score: summary.averageAnxiety,
                    color: Color(hex: "5B85C4")
                )
                EmotionalSummaryRow(
                    icon: "person.fill.xmark",
                    label: "Loneliness",
                    score: summary.averageLoneliness,
                    color: Color(hex: "8E44AD")
                )
                EmotionalSummaryRow(
                    icon: "scalemass.fill",
                    label: "Emotional Heaviness",
                    score: summary.averageHeaviness,
                    color: Color(hex: "5D7A8A")
                )
            }

            // Elevated emotion callout (if any dimension avg >= 4)
            if let elevated = summary.mostElevatedEmotion {
                HStack(spacing: 12) {
                    Image(systemName: elevated.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: elevated.color))
                        .frame(width: 34, height: 34)
                        .background(Color(hex: elevated.color).opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("home.elevated.title")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color(hex: elevated.color))
                            .textCase(.uppercase)
                            .tracking(0.6)
                        Text("\(elevated.label) averaged \(String(format: "%.1f", elevated.score))/10 — consider sharing this with your care team.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color("textSecondary"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(14)
                .background(Color(hex: elevated.color).opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color(hex: elevated.color).opacity(0.2), lineWidth: 1))
            }
        }
        .padding(18)
        .background(Color("cardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    // MARK: - Wellbeing message
    var wellbeingMessageCard: some View {
        HStack(spacing: 16) {
            Text("💬")
                .font(.system(size: 32))

            VStack(alignment: .leading, spacing: 4) {
                Text("home.section.reflection")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color("accentTeal"))
                    .textCase(.uppercase)
                    .tracking(0.8)
                Text(viewModel.wellbeingMessage(for: summary))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color("textPrimary"))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color("accentTeal").opacity(0.12), Color("accentTeal").opacity(0.04)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color("accentTeal").opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Empty State
    var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 52))
                .foregroundStyle(Color("accentTeal").opacity(0.4))

            VStack(spacing: 8) {
                Text("home.empty.title")
                    .font(.custom("Georgia", size: 22))
                    .foregroundStyle(Color("textPrimary"))
                Text("home.empty.subtitle")
                    .font(.system(size: 15))
                    .foregroundStyle(Color("textSecondary"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
        }
        .padding(.vertical, 50)
    }
}
//import SwiftUI
//import SwiftData
//
//struct HomeView: View {
//    @Environment(\.modelContext) private var modelContext
//    @Query(sort: \SymptomEntry.date, order: .reverse) private var entries: [SymptomEntry]
//    @State private var viewModel = HomeViewModel()
//
//    var summary: WeeklySummary {
//        viewModel.weeklySummary(from: entries, offset: viewModel.selectedWeekOffset)
//    }
//
//    var body: some View {
//        NavigationStack {
//            ZStack {
//                Color("backgroundPrimary").ignoresSafeArea()
//
//                ScrollView(showsIndicators: false) {
//                    VStack(spacing: 0) {
//                        headerSection
//                            .padding(.bottom, 24)
//
//                        VStack(spacing: 24) {
//                            // Week selector
//                            weekSelectorRow
//
//                            if summary.totalDaysLogged == 0 {
//                                emptyStateView
//                            } else {
//                                // At-a-glance cards
//                                atAGlanceRow
//
//                                // Severity chart
//                                severityChartSection
//
//                                // Most common symptoms
//                                mostCommonSection
//
//                                // Mental health arc
//                                mentalHealthSection
//
//                                // Wellbeing message
//                                wellbeingMessageCard
//                            }
//                        }
//                        .padding(.horizontal, 20)
//
//                        Spacer().frame(height: 100)
//                    }
//                }
//            }
//            .navigationBarHidden(true)
//        }
//    }
//
//    // MARK: - Header
//    var headerSection: some View {
//        ZStack(alignment: .bottomLeading) {
//            // Soft gradient background
//            LinearGradient(
//                colors: [Color("accentTeal").opacity(0.18), Color("backgroundPrimary")],
//                startPoint: .top,
//                endPoint: .bottom
//            )
//            .frame(height: 180)
//
//            VStack(alignment: .leading, spacing: 6) {
//                Text(viewModel.greetingText())
//                    .font(.system(size: 14, weight: .semibold))
//                    .foregroundStyle(Color("accentTeal"))
//                    .textCase(.uppercase)
//                    .tracking(1.2)
//
//                Text("Your Health\nOverview")
//                    .font(.custom("Georgia", size: 32))
//                    .fontWeight(.semibold)
//                    .foregroundStyle(Color("textPrimary"))
//                    .lineSpacing(2)
//
//                // Streak pill
//                HStack(spacing: 6) {
//                    Image(systemName: "flame.fill")
//                        .font(.system(size: 13))
//                        .foregroundStyle(.orange)
//                    Text("\(consecutiveStreak) day logging streak")
//                        .font(.system(size: 13, weight: .semibold))
//                        .foregroundStyle(Color("textSecondary"))
//                }
//                .padding(.horizontal, 12)
//                .padding(.vertical, 6)
//                .background(Color("cardBackground"))
//                .clipShape(Capsule())
//                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
//            }
//            .padding(.horizontal, 20)
//            .padding(.bottom, 20)
//        }
//    }
//
//    var consecutiveStreak: Int {
//        var count = 0
//        let calendar = Calendar.current
//        var checkDate = Date()
//        for _ in 0..<30 {
//            if entries.contains(where: { calendar.isDate($0.date, inSameDayAs: checkDate) }) {
//                count += 1
//                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
//            } else { break }
//        }
//        return count
//    }
//
//    // MARK: - Week Selector
//    var weekSelectorRow: some View {
//        HStack(spacing: 0) {
//            // Previous week
//            Button {
//                withAnimation(.spring(response: 0.35)) {
//                    viewModel.selectedWeekOffset -= 1
//                }
//            } label: {
//                Image(systemName: "chevron.left")
//                    .font(.system(size: 14, weight: .semibold))
//                    .foregroundStyle(Color("textSecondary"))
//                    .frame(width: 40, height: 40)
//            }
//
//            Spacer()
//
//            VStack(spacing: 2) {
//                Text(viewModel.selectedWeekOffset == 0 ? "This Week" :
//                     viewModel.selectedWeekOffset == -1 ? "Last Week" :
//                     "\(abs(viewModel.selectedWeekOffset)) weeks ago")
//                    .font(.system(size: 16, weight: .bold))
//                    .foregroundStyle(Color("textPrimary"))
//                Text(summary.weekLabel)
//                    .font(.system(size: 12, weight: .medium))
//                    .foregroundStyle(Color("textTertiary"))
//            }
//
//            Spacer()
//
//            // Next week (disabled if current)
//            Button {
//                withAnimation(.spring(response: 0.35)) {
//                    if viewModel.selectedWeekOffset < 0 {
//                        viewModel.selectedWeekOffset += 1
//                    }
//                }
//            } label: {
//                Image(systemName: "chevron.right")
//                    .font(.system(size: 14, weight: .semibold))
//                    .foregroundStyle(viewModel.selectedWeekOffset == 0 ? Color("borderColor") : Color("textSecondary"))
//                    .frame(width: 40, height: 40)
//            }
//            .disabled(viewModel.selectedWeekOffset == 0)
//        }
//        .padding(.horizontal, 8)
//        .padding(.vertical, 10)
//        .background(Color("cardBackground"))
//        .clipShape(RoundedRectangle(cornerRadius: 14))
//        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
//    }
//
//    // MARK: - At-a-glance cards
//    var atAGlanceRow: some View {
//        HStack(spacing: 12) {
//            GlanceCard(
//                icon: "calendar.badge.checkmark",
//                iconColor: Color("accentTeal"),
//                value: "\(summary.totalDaysLogged)/7",
//                label: "Days Logged",
//                subtitle: summary.totalDaysLogged >= 5 ? "Great consistency!" : "Keep it up"
//            )
//
//            worriedSymptomCard
//
//            GlanceCard(
//                icon: "heart.fill",
//                iconColor: mentalHealthColor,
//                value: String(format: "%.1f", summary.averageMentalHealth),
//                label: "Avg Mood",
//                subtitle: "out of 10"
//            )
//        }
//    }
//
//    @ViewBuilder
//    var worriedSymptomCard: some View {
//        if let worried = summary.mostWorriedSymptom {
//            GlanceCard(
//                icon: "exclamationmark.triangle.fill",
//                iconColor: Color("severityHigh"),
//                value: worried.percentIncreaseLabel,
//                label: worried.name,
//                subtitle: String(format: "Severity %.1f/10", worried.currentAvg)
//            )
//        } else {
//            GlanceCard(
//                icon: summary.overallSeverityTrend.icon,
//                iconColor: summary.overallSeverityTrend.color,
//                value: summary.overallSeverityTrend.label,
//                label: "Symptom Trend",
//                subtitle: "vs. last week"
//            )
//        }
//    }
//
//    var mentalHealthColor: Color {
//        let avg = summary.averageMentalHealth
//        if avg >= 7 { return Color("severityLow") }
//        if avg >= 4 { return Color("severityMed") }
//        return Color("severityHigh")
//    }
//
//
//    // MARK: - Severity Chart
//    var severityChartSection: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            SectionHeader(title: "Daily Severity", subtitle: "Average across all symptoms")
//
//            if summary.averageSeverityByDay.isEmpty {
//                Text("No data for this week")
//                    .font(.system(size: 14))
//                    .foregroundStyle(Color("textTertiary"))
//                    .frame(maxWidth: .infinity, alignment: .center)
//                    .padding(.vertical, 30)
//            } else {
//                SeverityBarChart(days: summary.averageSeverityByDay)
//                    .frame(height: 140)
//            }
//
//            // Legend
//            HStack(spacing: 16) {
//                LegendDot(color: Color("severityLow"), label: "Mild (1–3)")
//                LegendDot(color: Color("severityMed"), label: "Moderate (4–6)")
//                LegendDot(color: Color("severityHigh"), label: "Severe (7–10)")
//            }
//        }
//        .padding(18)
//        .background(Color("cardBackground"))
//        .clipShape(RoundedRectangle(cornerRadius: 18))
//        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
//    }
//
//    // MARK: - Most Common Symptoms
//    var mostCommonSection: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            SectionHeader(title: "Most Frequent", subtitle: "Symptoms this week")
//
//            if summary.mostCommonSymptoms.isEmpty {
//                Text("No symptoms logged yet")
//                    .font(.system(size: 14))
//                    .foregroundStyle(Color("textTertiary"))
//            } else {
//                VStack(spacing: 10) {
//                    ForEach(Array(summary.mostCommonSymptoms.enumerated()), id: \.offset) { index, symptom in
//                        FrequencyRow(
//                            rank: index + 1,
//                            name: symptom.name,
//                            category: symptom.category,
//                            count: symptom.count,
//                            maxCount: summary.mostCommonSymptoms.first?.count ?? 1
//                        )
//                    }
//                }
//            }
//        }
//        .padding(18)
//        .background(Color("cardBackground"))
//        .clipShape(RoundedRectangle(cornerRadius: 18))
//        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
//    }
//
//    // MARK: - Mental Health Section
//    var mentalHealthSection: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            SectionHeader(title: "Mental Wellbeing", subtitle: "Daily mood scores")
//
//            MentalHealthArcRow(entries: summary.entries)
//        }
//        .padding(18)
//        .background(Color("cardBackground"))
//        .clipShape(RoundedRectangle(cornerRadius: 18))
//        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
//    }
//
//    // MARK: - Wellbeing message
//    var wellbeingMessageCard: some View {
//        HStack(spacing: 16) {
//            Text("💬")
//                .font(.system(size: 32))
//
//            VStack(alignment: .leading, spacing: 4) {
//                Text("Weekly Reflection")
//                    .font(.system(size: 12, weight: .bold))
//                    .foregroundStyle(Color("accentTeal"))
//                    .textCase(.uppercase)
//                    .tracking(0.8)
//                Text(viewModel.wellbeingMessage(for: summary))
//                    .font(.system(size: 14, weight: .medium))
//                    .foregroundStyle(Color("textPrimary"))
//                    .fixedSize(horizontal: false, vertical: true)
//            }
//        }
//        .padding(18)
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .background(
//            LinearGradient(
//                colors: [Color("accentTeal").opacity(0.12), Color("accentTeal").opacity(0.04)],
//                startPoint: .topLeading,
//                endPoint: .bottomTrailing
//            )
//        )
//        .clipShape(RoundedRectangle(cornerRadius: 18))
//        .overlay(
//            RoundedRectangle(cornerRadius: 18)
//                .stroke(Color("accentTeal").opacity(0.2), lineWidth: 1)
//        )
//    }
//
//    // MARK: - Empty State
//    var emptyStateView: some View {
//        VStack(spacing: 20) {
//            Image(systemName: "doc.text.magnifyingglass")
//                .font(.system(size: 52))
//                .foregroundStyle(Color("accentTeal").opacity(0.4))
//
//            VStack(spacing: 8) {
//                Text("No data this week")
//                    .font(.custom("Georgia", size: 22))
//                    .foregroundStyle(Color("textPrimary"))
//                Text("Start logging your symptoms daily\nto see your weekly summary here.")
//                    .font(.system(size: 15))
//                    .foregroundStyle(Color("textSecondary"))
//                    .multilineTextAlignment(.center)
//                    .lineSpacing(3)
//            }
//        }
//        .padding(.vertical, 50)
//    }
//}
////import SwiftUI
////import SwiftData
////
////struct HomeView: View {
////    @Environment(\.modelContext) private var modelContext
////    @Query(sort: \SymptomEntry.date, order: .reverse) private var entries: [SymptomEntry]
////    @State private var viewModel = HomeViewModel()
////
////    var summary: WeeklySummary {
////        viewModel.weeklySummary(from: entries, offset: viewModel.selectedWeekOffset)
////    }
////
////    var body: some View {
////        NavigationStack {
////            ZStack {
////                Color("backgroundPrimary").ignoresSafeArea()
////
////                ScrollView(showsIndicators: false) {
////                    VStack(spacing: 0) {
////                        headerSection
////                            .padding(.bottom, 24)
////
////                        VStack(spacing: 24) {
////                            // Week selector
////                            weekSelectorRow
////
////                            if summary.totalDaysLogged == 0 {
////                                emptyStateView
////                            } else {
////                                // At-a-glance cards
////                                atAGlanceRow
////
////                                // Severity chart
////                                severityChartSection
////
////                                // Most common symptoms
////                                mostCommonSection
////
////                                // Mental health arc
////                                mentalHealthSection
////
////                                // Wellbeing message
////                                wellbeingMessageCard
////                            }
////                        }
////                        .padding(.horizontal, 20)
////
////                        Spacer().frame(height: 100)
////                    }
////                }
////            }
////            .navigationBarHidden(true)
////        }
////    }
////
////    // MARK: - Header
////    var headerSection: some View {
////        ZStack(alignment: .bottomLeading) {
////            // Soft gradient background
////            LinearGradient(
////                colors: [Color("accentTeal").opacity(0.18), Color("backgroundPrimary")],
////                startPoint: .top,
////                endPoint: .bottom
////            )
////            .frame(height: 180)
////
////            VStack(alignment: .leading, spacing: 6) {
////                Text(viewModel.greetingText())
////                    .font(.system(size: 14, weight: .semibold))
////                    .foregroundStyle(Color("accentTeal"))
////                    .textCase(.uppercase)
////                    .tracking(1.2)
////
////                Text("Your Health\nOverview")
////                    .font(.custom("Georgia", size: 32))
////                    .fontWeight(.semibold)
////                    .foregroundStyle(Color("textPrimary"))
////                    .lineSpacing(2)
////
////                // Streak pill
////                HStack(spacing: 6) {
////                    Image(systemName: "flame.fill")
////                        .font(.system(size: 13))
////                        .foregroundStyle(.orange)
////                    Text("\(consecutiveStreak) day logging streak")
////                        .font(.system(size: 13, weight: .semibold))
////                        .foregroundStyle(Color("textSecondary"))
////                }
////                .padding(.horizontal, 12)
////                .padding(.vertical, 6)
////                .background(Color("cardBackground"))
////                .clipShape(Capsule())
////                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
////            }
////            .padding(.horizontal, 20)
////            .padding(.bottom, 20)
////        }
////    }
////
////    var consecutiveStreak: Int {
////        var count = 0
////        let calendar = Calendar.current
////        var checkDate = Date()
////        for _ in 0..<30 {
////            if entries.contains(where: { calendar.isDate($0.date, inSameDayAs: checkDate) }) {
////                count += 1
////                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
////            } else { break }
////        }
////        return count
////    }
////
////    // MARK: - Week Selector
////    var weekSelectorRow: some View {
////        HStack(spacing: 0) {
////            // Previous week
////            Button {
////                withAnimation(.spring(response: 0.35)) {
////                    viewModel.selectedWeekOffset -= 1
////                }
////            } label: {
////                Image(systemName: "chevron.left")
////                    .font(.system(size: 14, weight: .semibold))
////                    .foregroundStyle(Color("textSecondary"))
////                    .frame(width: 40, height: 40)
////            }
////
////            Spacer()
////
////            VStack(spacing: 2) {
////                Text(viewModel.selectedWeekOffset == 0 ? "This Week" :
////                     viewModel.selectedWeekOffset == -1 ? "Last Week" :
////                     "\(abs(viewModel.selectedWeekOffset)) weeks ago")
////                    .font(.system(size: 16, weight: .bold))
////                    .foregroundStyle(Color("textPrimary"))
////                Text(summary.weekLabel)
////                    .font(.system(size: 12, weight: .medium))
////                    .foregroundStyle(Color("textTertiary"))
////            }
////
////            Spacer()
////
////            // Next week (disabled if current)
////            Button {
////                withAnimation(.spring(response: 0.35)) {
////                    if viewModel.selectedWeekOffset < 0 {
////                        viewModel.selectedWeekOffset += 1
////                    }
////                }
////            } label: {
////                Image(systemName: "chevron.right")
////                    .font(.system(size: 14, weight: .semibold))
////                    .foregroundStyle(viewModel.selectedWeekOffset == 0 ? Color("borderColor") : Color("textSecondary"))
////                    .frame(width: 40, height: 40)
////            }
////            .disabled(viewModel.selectedWeekOffset == 0)
////        }
////        .padding(.horizontal, 8)
////        .padding(.vertical, 10)
////        .background(Color("cardBackground"))
////        .clipShape(RoundedRectangle(cornerRadius: 14))
////        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
////    }
////
////    // MARK: - At-a-glance cards
////    var atAGlanceRow: some View {
////        HStack(spacing: 12) {
////            GlanceCard(
////                icon: "calendar.badge.checkmark",
////                iconColor: Color("accentTeal"),
////                value: "\(summary.totalDaysLogged)/7",
////                label: "Days Logged",
////                subtitle: summary.totalDaysLogged >= 5 ? "Great consistency!" : "Keep it up"
////            )
////
////            GlanceCard(
////                icon: summary.overallSeverityTrend.icon,
////                iconColor: summary.overallSeverityTrend.color,
////                value: summary.overallSeverityTrend.label,
////                label: "Symptom Trend",
////                subtitle: trendSubtitle
////            )
////
////            GlanceCard(
////                icon: "heart.fill",
////                iconColor: mentalHealthColor,
////                value: String(format: "%.1f", summary.averageMentalHealth),
////                label: "Avg Mood",
////                subtitle: "out of 10"
////            )
////        }
////    }
////
////    var trendSubtitle: String {
////        let avg = summary.averageSeverityByDay.map(\.averageSeverity).reduce(0, +) / Double(max(summary.averageSeverityByDay.count, 1))
////        return String(format: "Avg severity %.1f", avg)
////    }
////
////    var mentalHealthColor: Color {
////        let avg = summary.averageMentalHealth
////        if avg >= 7 { return Color("severityLow") }
////        if avg >= 4 { return Color("severityMed") }
////        return Color("severityHigh")
////    }
////
////    // MARK: - Severity Chart
////    var severityChartSection: some View {
////        VStack(alignment: .leading, spacing: 16) {
////            SectionHeader(title: "Daily Severity", subtitle: "Average across all symptoms")
////
////            if summary.averageSeverityByDay.isEmpty {
////                Text("No data for this week")
////                    .font(.system(size: 14))
////                    .foregroundStyle(Color("textTertiary"))
////                    .frame(maxWidth: .infinity, alignment: .center)
////                    .padding(.vertical, 30)
////            } else {
////                SeverityBarChart(days: summary.averageSeverityByDay)
////                    .frame(height: 140)
////            }
////
////            // Legend
////            HStack(spacing: 16) {
////                LegendDot(color: Color("severityLow"), label: "Mild (1–3)")
////                LegendDot(color: Color("severityMed"), label: "Moderate (4–6)")
////                LegendDot(color: Color("severityHigh"), label: "Severe (7–10)")
////            }
////        }
////        .padding(18)
////        .background(Color("cardBackground"))
////        .clipShape(RoundedRectangle(cornerRadius: 18))
////        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
////    }
////
////    // MARK: - Most Common Symptoms
////    var mostCommonSection: some View {
////        VStack(alignment: .leading, spacing: 16) {
////            SectionHeader(title: "Most Frequent", subtitle: "Symptoms this week")
////
////            if summary.mostCommonSymptoms.isEmpty {
////                Text("No symptoms logged yet")
////                    .font(.system(size: 14))
////                    .foregroundStyle(Color("textTertiary"))
////            } else {
////                VStack(spacing: 10) {
////                    ForEach(Array(summary.mostCommonSymptoms.enumerated()), id: \.offset) { index, symptom in
////                        FrequencyRow(
////                            rank: index + 1,
////                            name: symptom.name,
////                            category: symptom.category,
////                            count: symptom.count,
////                            maxCount: summary.mostCommonSymptoms.first?.count ?? 1
////                        )
////                    }
////                }
////            }
////        }
////        .padding(18)
////        .background(Color("cardBackground"))
////        .clipShape(RoundedRectangle(cornerRadius: 18))
////        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
////    }
////
////    // MARK: - Mental Health Section
////    var mentalHealthSection: some View {
////        VStack(alignment: .leading, spacing: 16) {
////            SectionHeader(title: "Mental Wellbeing", subtitle: "Daily mood scores")
////
////            MentalHealthArcRow(entries: summary.entries)
////        }
////        .padding(18)
////        .background(Color("cardBackground"))
////        .clipShape(RoundedRectangle(cornerRadius: 18))
////        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
////    }
////
////    // MARK: - Wellbeing message
////    var wellbeingMessageCard: some View {
////        HStack(spacing: 16) {
////            Text("💬")
////                .font(.system(size: 32))
////
////            VStack(alignment: .leading, spacing: 4) {
////                Text("Weekly Reflection")
////                    .font(.system(size: 12, weight: .bold))
////                    .foregroundStyle(Color("accentTeal"))
////                    .textCase(.uppercase)
////                    .tracking(0.8)
////                Text(viewModel.wellbeingMessage(for: summary))
////                    .font(.system(size: 14, weight: .medium))
////                    .foregroundStyle(Color("textPrimary"))
////                    .fixedSize(horizontal: false, vertical: true)
////            }
////        }
////        .padding(18)
////        .frame(maxWidth: .infinity, alignment: .leading)
////        .background(
////            LinearGradient(
////                colors: [Color("accentTeal").opacity(0.12), Color("accentTeal").opacity(0.04)],
////                startPoint: .topLeading,
////                endPoint: .bottomTrailing
////            )
////        )
////        .clipShape(RoundedRectangle(cornerRadius: 18))
////        .overlay(
////            RoundedRectangle(cornerRadius: 18)
////                .stroke(Color("accentTeal").opacity(0.2), lineWidth: 1)
////        )
////    }
////
////    // MARK: - Empty State
////    var emptyStateView: some View {
////        VStack(spacing: 20) {
////            Image(systemName: "doc.text.magnifyingglass")
////                .font(.system(size: 52))
////                .foregroundStyle(Color("accentTeal").opacity(0.4))
////
////            VStack(spacing: 8) {
////                Text("No data this week")
////                    .font(.custom("Georgia", size: 22))
////                    .foregroundStyle(Color("textPrimary"))
////                Text("Start logging your symptoms daily\nto see your weekly summary here.")
////                    .font(.system(size: 15))
////                    .foregroundStyle(Color("textSecondary"))
////                    .multilineTextAlignment(.center)
////                    .lineSpacing(3)
////            }
////        }
////        .padding(.vertical, 50)
////    }
////}
