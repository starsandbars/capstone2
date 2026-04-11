import SwiftUI
import SwiftData

enum LogTab { case wellbeing, symptoms }

struct SymptomLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SymptomEntry.date, order: .reverse) private var entries: [SymptomEntry]
    @State private var viewModel = SymptomLogViewModel()
    @State private var activeTab: LogTab = .wellbeing
    @State private var showingExport = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color("backgroundPrimary").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        headerSection

                        tabSwitcher
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, 4)

                        if activeTab == .wellbeing {
                            VStack(spacing: 24) {
                                mentalHealthSection
                                notesSection
                                Spacer().frame(height: 110)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        } else {
                            VStack(spacing: 24) {
                                quickActionsRow

                                if viewModel.showingCustomSymptom {
                                    CustomSymptomInputView(viewModel: viewModel)
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                }

                                if !viewModel.selectedSymptoms.isEmpty {
                                    selectedSymptomsSection
                                }

                                symptomPickerSection
                                Spacer().frame(height: 110)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                        }
                    }
                }

                saveButton
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.loadTodayEntry(from: entries)
        }
        .overlay(alignment: .top) {
            if viewModel.showingSaveConfirmation {
                SaveConfirmationBanner()
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation(.spring(response: 0.4)) {
                                viewModel.showingSaveConfirmation = false
                            }
                        }
                    }
            }
        }
        .animation(.spring(response: 0.4), value: viewModel.showingSaveConfirmation)
        .animation(.spring(response: 0.35), value: viewModel.showingCustomSymptom)
        .animation(.spring(response: 0.4), value: activeTab)
        .sheet(isPresented: $showingExport) {
            PDFExportView()
        }
    }

    // MARK: - Header
    var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Text(viewModel.todayFormatted)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color("accentTeal"))
                    .textCase(.uppercase)
                    .tracking(1.0)
                Text("log.title")
                    .font(.custom("Georgia", size: 30))
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("textPrimary"))
            }
            Spacer()
            Button { showingExport = true } label: {
                Image(systemName: "arrow.up.doc")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color("accentTeal"))
                    .frame(width: 42, height: 42)
                    .background(Color("accentTeal").opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 64)
        .padding(.bottom, 4)
    }

    // MARK: - Tab Switcher
    var tabSwitcher: some View {
        HStack(spacing: 0) {
            tabButton(
                title: NSLocalizedString("log.tab.wellbeing", comment: ""),
                icon: "heart.fill",
                tab: .wellbeing,
                badge: nil
            )
            tabButton(
                title: NSLocalizedString("log.tab.symptoms", comment: ""),
                icon: "list.bullet.clipboard",
                tab: .symptoms,
                badge: viewModel.selectedSymptoms.isEmpty ? nil : "\(viewModel.selectedSymptoms.count)"
            )
        }
        .padding(4)
        .background(Color("chipBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    func tabButton(title: String, icon: String, tab: LogTab, badge: String?) -> some View {
        let isActive = activeTab == tab
        return Button {
            withAnimation(.spring(response: 0.35)) { activeTab = tab }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                if let badge {
                    Text(badge)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(isActive ? Color.white.opacity(0.3) : Color("accentTeal"))
                        .clipShape(Capsule())
                }
            }
            .foregroundStyle(isActive ? .white : Color("textSecondary"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(
                Group {
                    if isActive {
                        RoundedRectangle(cornerRadius: 11)
                            .fill(tab == .wellbeing
                                  ? mentalHealthAccent(for: viewModel.mentalHealthScore)
                                  : Color("accentTeal"))
                            .shadow(color: (tab == .wellbeing
                                           ? mentalHealthAccent(for: viewModel.mentalHealthScore)
                                           : Color("accentTeal")).opacity(0.3),
                                    radius: 8, y: 3)
                    } else {
                        RoundedRectangle(cornerRadius: 11).fill(Color.clear)
                    }
                }
            )
        }
    }

    // MARK: - Mental Health Hero
    var mentalHealthSection: some View {
        VStack(alignment: .leading, spacing: 16) {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white.opacity(0.8))
                        Text("mental.title")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white.opacity(0.85))
                            .textCase(.uppercase)
                            .tracking(0.9)
                    }
                    Text("mental.question.overall")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 64, height: 64)
                    VStack(spacing: 0) {
                        Text("\(viewModel.mentalHealthScore)")
                            .font(.system(size: 27, weight: .bold))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                        Text("/10")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(
                LinearGradient(
                    colors: mentalHealthGradient(for: viewModel.mentalHealthScore),
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 0,
                                               bottomTrailingRadius: 0, topTrailingRadius: 20))

            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    Text(mentalHealthEmoji(for: viewModel.mentalHealthScore))
                        .font(.system(size: 48))
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.mentalHealthScore)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(viewModel.mentalHealthLabel(for: viewModel.mentalHealthScore))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(mentalHealthAccent(for: viewModel.mentalHealthScore))
                            .animation(.easeInOut(duration: 0.2), value: viewModel.mentalHealthScore)
                        Text(mentalHealthDescription(for: viewModel.mentalHealthScore))
                            .font(.system(size: 13))
                            .foregroundStyle(Color("textSecondary"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                }

                MentalHealthStepBar(value: $viewModel.mentalHealthScore)
                    .onChange(of: viewModel.mentalHealthScore) { viewModel.isSaved = false }

                HStack {
                    Text("mental.verydifficult")
                        .font(.system(size: 11))
                        .foregroundStyle(Color("textTertiary"))
                    Spacer()
                    Text("mental.feelinggreat")
                        .font(.system(size: 11))
                        .foregroundStyle(Color("textTertiary"))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(Color("cardBackground"))
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 20,
                                               bottomTrailingRadius: 20, topTrailingRadius: 0))
        }
        .shadow(color: mentalHealthAccent(for: viewModel.mentalHealthScore).opacity(0.22), radius: 16, y: 6)
        .animation(.easeInOut(duration: 0.3), value: viewModel.mentalHealthScore)

        // Divider with label
        HStack(spacing: 10) {
            Rectangle().fill(Color("borderColor")).frame(height: 1)
            Text("mental.deeper")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color("textTertiary"))
                .textCase(.uppercase)
                .tracking(0.8)
                .fixedSize()
            Rectangle().fill(Color("borderColor")).frame(height: 1)
        }
        .padding(.top, 4)

        // 4 emotional check-in questions
        EmotionalQuestionCard(
            question: NSLocalizedString("eq.anger.question", comment: ""),
            detail: NSLocalizedString("eq.anger.detail", comment: ""),
            icon: "flame.fill",
            accentColor: Color(hex: "E74C3C"),
            value: $viewModel.angerScore
        )
        .onChange(of: viewModel.angerScore) { viewModel.isSaved = false }

        EmotionalQuestionCard(
            question: NSLocalizedString("eq.anxiety.question", comment: ""),
            detail: NSLocalizedString("eq.anxiety.detail", comment: ""),
            icon: "cloud.rain.fill",
            accentColor: Color(hex: "5B85C4"),
            value: $viewModel.anxietyScore
        )
        .onChange(of: viewModel.anxietyScore) { viewModel.isSaved = false }

        EmotionalQuestionCard(
            question: NSLocalizedString("eq.loneliness.question", comment: ""),
            detail: NSLocalizedString("eq.loneliness.detail", comment: ""),
            icon: "person.fill.xmark",
            accentColor: Color(hex: "8E44AD"),
            value: $viewModel.lonelinessScore
        )
        .onChange(of: viewModel.lonelinessScore) { viewModel.isSaved = false }

        EmotionalQuestionCard(
            question: NSLocalizedString("eq.heaviness.question", comment: ""),
            detail: NSLocalizedString("eq.heaviness.detail", comment: ""),
            icon: "scalemass.fill",
            accentColor: Color(hex: "5D7A8A"),
            value: $viewModel.heavinessScore
        )
        .onChange(of: viewModel.heavinessScore) { viewModel.isSaved = false }
        } // end outer VStack
    }

    func mentalHealthGradient(for score: Int) -> [Color] {
        switch score {
        case 1...3: return [Color(hex: "B03A2E"), Color(hex: "E74C3C")]
        case 4...6: return [Color(hex: "CA6F1E"), Color(hex: "F39C12")]
        case 7...8: return [Color(hex: "1E8449"), Color(hex: "27AE60")]
        default:    return [Color(hex: "1A7A6E"), Color(hex: "2A9D8F")]
        }
    }

    func mentalHealthAccent(for score: Int) -> Color {
        switch score {
        case 1...3: return Color(hex: "E74C3C")
        case 4...6: return Color(hex: "E67E22")
        case 7...8: return Color(hex: "27AE60")
        default:    return Color("accentTeal")
        }
    }

    func mentalHealthEmoji(for score: Int) -> String {
        ["😞","😟","😕","😐","🙂","😊","😄","😁","🤩","🥳"][score - 1]
    }

    func mentalHealthDescription(for score: Int) -> String {
        switch score {
        case 1: return NSLocalizedString("mental.desc.1", comment: "")
        case 2: return NSLocalizedString("mental.desc.2", comment: "")
        case 3: return NSLocalizedString("mental.desc.3", comment: "")
        case 4: return NSLocalizedString("mental.desc.4", comment: "")
        case 5: return NSLocalizedString("mental.desc.5", comment: "")
        case 6: return NSLocalizedString("mental.desc.6", comment: "")
        case 7: return NSLocalizedString("mental.desc.7", comment: "")
        case 8: return NSLocalizedString("mental.desc.8", comment: "")
        case 9: return NSLocalizedString("mental.desc.9", comment: "")
        default: return NSLocalizedString("mental.desc.10", comment: "")
        }
    }

    // MARK: - Quick Actions
    var quickActionsRow: some View {
        HStack(spacing: 10) {
            Button {
                withAnimation(.spring(response: 0.35)) { viewModel.copyYesterdaySymptoms(from: entries) }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Label("log.copyYesterday", systemImage: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color("accentTeal"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color("accentTeal").opacity(0.09))
                    .clipShape(RoundedRectangle(cornerRadius: 13))
                    .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color("accentTeal").opacity(0.2), lineWidth: 1))
            }

            Button {
                withAnimation(.spring(response: 0.35)) { viewModel.showingCustomSymptom.toggle() }
            } label: {
                Label(viewModel.showingCustomSymptom ? NSLocalizedString("button.cancel", comment: "") : NSLocalizedString("log.addCustom", comment: ""),
                      systemImage: viewModel.showingCustomSymptom ? "xmark" : "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(viewModel.showingCustomSymptom ? Color("severityHigh") : Color("textSecondary"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(viewModel.showingCustomSymptom ? Color("severityHigh").opacity(0.08) : Color("chipBackground"))
                    .clipShape(RoundedRectangle(cornerRadius: 13))
                    .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color("borderColor"), lineWidth: 1))
            }
        }
    }

    // MARK: - Selected Symptoms
    var selectedSymptomsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text("log.loggedToday")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color("textPrimary"))
                Text("\(viewModel.selectedSymptoms.count)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color("accentTeal"))
                    .clipShape(Capsule())
                Spacer()
            }
            VStack(spacing: 10) {
                ForEach($viewModel.selectedSymptoms) { $symptom in
                    SymptomSeverityCard(symptom: $symptom) {
                        withAnimation(.spring(response: 0.3)) { viewModel.removeSymptom(symptom, context: modelContext, allEntries: entries) }
                    }
                }
            }
        }
    }

    // MARK: - Symptom Picker
    var symptomPickerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("log.browseSymptoms")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color("textPrimary"))

            let past = viewModel.pastSymptomNames(from: entries)
            if !past.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("log.recentlyLogged", systemImage: "clock")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color("textTertiary"))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(past.prefix(8)) { symptom in
                                SymptomChip(symptom: symptom, isSelected: viewModel.isSelected(symptom)) {
                                    withAnimation(.spring(response: 0.3)) { viewModel.toggleSymptom(symptom) }
                                }
                            }
                        }
                        .padding(.horizontal, 1).padding(.vertical, 2)
                    }
                }
                .padding(14)
                .background(Color("cardBackground"))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            ForEach(SymptomCategory.allCases, id: \.self) { category in
                SymptomCategorySection(
                    category: category,
                    symptoms: CommonSymptom.preloaded.filter { $0.category == category },
                    viewModel: viewModel
                )
            }
        }
    }

    // MARK: - Notes
    var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("log.notes.title", systemImage: "pencil.line")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color("textPrimary"))

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("cardBackground"))
                    .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
                if viewModel.notes.isEmpty {
                    Text("log.notes.placeholder")
                        .font(.system(size: 15))
                        .foregroundStyle(Color("textTertiary"))
                        .padding(18)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $viewModel.notes)
                    .font(.system(size: 15))
                    .foregroundStyle(Color("textPrimary"))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 96)
                    .padding(14)
                    .onChange(of: viewModel.notes) { viewModel.isSaved = false }
            }
        }
    }

    // MARK: - Save Button
    var saveButton: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color("backgroundPrimary").opacity(0), Color("backgroundPrimary")],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 28)

            Button {
                withAnimation(.spring(response: 0.4)) { viewModel.saveEntry(context: modelContext, allEntries: entries) }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: viewModel.isSaved ? "checkmark.circle.fill" : "square.and.pencil")
                        .font(.system(size: 17, weight: .semibold))
                    Text(viewModel.isSaved ? NSLocalizedString("log.saved", comment: "") : NSLocalizedString("log.save", comment: ""))
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(viewModel.isSaved ? Color("successGreen") : Color("accentTeal"))
                        .shadow(color: (viewModel.isSaved ? Color("successGreen") : Color("accentTeal")).opacity(0.4),
                                radius: 14, y: 5)
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
            .background(Color("backgroundPrimary"))
        }
        .animation(.spring(response: 0.4), value: viewModel.isSaved)
    }
}

// MARK: - Color hex init
extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        self.init(
            red: Double((int >> 16) & 0xFF) / 255,
            green: Double((int >> 8) & 0xFF) / 255,
            blue: Double(int & 0xFF) / 255
        )
    }
}
//
//import SwiftUI
//import SwiftData
//
//enum LogTab { case wellbeing, symptoms }
//
//struct SymptomLogView: View {
//    @Environment(\.modelContext) private var modelContext
//    @Query(sort: \SymptomEntry.date, order: .reverse) private var entries: [SymptomEntry]
//    @State private var viewModel = SymptomLogViewModel()
//    @State private var activeTab: LogTab = .wellbeing
//    @State private var showingExport = false
//
//    var body: some View {
//        NavigationStack {
//            ZStack(alignment: .bottom) {
//                Color("backgroundPrimary").ignoresSafeArea()
//
//                ScrollView(showsIndicators: false) {
//                    VStack(spacing: 0) {
//                       headerSection
//
//                        tabSwitcher
//                            .padding(.horizontal, 20)
//                            .padding(.top, 20)
//                            .padding(.bottom, 4)
//
//                        if activeTab == .wellbeing {
//                            VStack(spacing: 24) {
//                                mentalHealthSection
//                                notesSection
//                                Spacer().frame(height: 110)
//                            }
//                            .padding(.horizontal, 20)
//                            .padding(.top, 20)
//                            .transition(.asymmetric(
//                                insertion: .move(edge: .leading).combined(with: .opacity),
//                                removal: .move(edge: .leading).combined(with: .opacity)
//                            ))
//                        } else {
//                            VStack(spacing: 24) {
//                                quickActionsRow
//
//                                if viewModel.showingCustomSymptom {
//                                    CustomSymptomInputView(viewModel: viewModel)
//                                        .transition(.opacity.combined(with: .move(edge: .top)))
//                                }
//
//                                if !viewModel.selectedSymptoms.isEmpty {
//                                    selectedSymptomsSection
//                                }
//
//                                symptomPickerSection
//                                Spacer().frame(height: 110)
//                            }
//                            .padding(.horizontal, 20)
//                            .padding(.top, 20)
//                            .transition(.asymmetric(
//                                insertion: .move(edge: .trailing).combined(with: .opacity),
//                                removal: .move(edge: .trailing).combined(with: .opacity)
//                            ))
//                        }
//                    }
//                }
//
//                saveButton
//            }
//            .navigationBarHidden(true)
//        }
//        .onAppear {
//            viewModel.loadTodayEntry(from: entries)
//        }
//        .overlay(alignment: .top) {
//            if viewModel.showingSaveConfirmation {
//                SaveConfirmationBanner()
//                    .transition(.move(edge: .top).combined(with: .opacity))
//                    .onAppear {
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
//                            withAnimation(.spring(response: 0.4)) {
//                                viewModel.showingSaveConfirmation = false
//                            }
//                        }
//                    }
//            }
//        }
//        .animation(.spring(response: 0.4), value: viewModel.showingSaveConfirmation)
//        .animation(.spring(response: 0.35), value: viewModel.showingCustomSymptom)
//        .animation(.spring(response: 0.4), value: activeTab)
//        .sheet(isPresented: $showingExport) {
//            PDFExportView()
//        }
//    }
//
//    // MARK: - Header
//    var headerSection: some View {
//        HStack(alignment: .top) {
//            VStack(alignment: .leading, spacing: 5) {
//                Text(viewModel.todayFormatted)
//                    .font(.system(size: 13, weight: .semibold))
//                    .foregroundStyle(Color("accentTeal"))
//                    .textCase(.uppercase)
//                    .tracking(1.0)
//                Text("Daily Check-in")
//                    .font(.custom("Georgia", size: 30))
//                    .fontWeight(.semibold)
//                    .foregroundStyle(Color("textPrimary"))
//            }
//            Spacer()
//            Button { showingExport = true } label: {
//                Image(systemName: "arrow.up.doc")
//                    .font(.system(size: 16, weight: .medium))
//                    .foregroundStyle(Color("accentTeal"))
//                    .frame(width: 42, height: 42)
//                    .background(Color("accentTeal").opacity(0.1))
//                    .clipShape(Circle())
//            }
//        }
//        .padding(.horizontal, 20)
//        .padding(.top, 64)
//        .padding(.bottom, 4)
//    }
//
//    // MARK: - Tab Switcher
//    var tabSwitcher: some View {
//        HStack(spacing: 0) {
//            tabButton(
//                title: "Symptoms",
//                icon: "list.bullet.clipboard",
//                tab: .symptoms,
//                badge: viewModel.selectedSymptoms.isEmpty ? nil : "\(viewModel.selectedSymptoms.count)"
//            )
//            tabButton(
//                title: "Mental Health",
//                icon: "heart.fill",
//                tab: .wellbeing,
//                badge: nil
//            )
//        }
//        .padding(4)
//        .background(Color("chipBackground"))
//        .clipShape(RoundedRectangle(cornerRadius: 14))
//    }
//
//    func tabButton(title: String, icon: String, tab: LogTab, badge: String?) -> some View {
//        let isActive = activeTab == tab
//        return Button {
//            withAnimation(.spring(response: 0.35)) { activeTab = tab }
//        } label: {
//            HStack(spacing: 7) {
//                Image(systemName: icon)
//                    .font(.system(size: 13, weight: .semibold))
//                Text(title)
//                    .font(.system(size: 15, weight: .semibold))
//                if let badge {
//                    Text(badge)
//                        .font(.system(size: 11, weight: .bold))
//                        .foregroundStyle(.white)
//                        .padding(.horizontal, 7)
//                        .padding(.vertical, 2)
//                        .background(isActive ? Color.white.opacity(0.3) : Color("accentTeal"))
//                        .clipShape(Capsule())
//                }
//            }
//            .foregroundStyle(isActive ? .white : Color("textSecondary"))
//            .frame(maxWidth: .infinity)
//            .padding(.vertical, 11)
//            .background(
//                Group {
//                    if isActive {
//                        RoundedRectangle(cornerRadius: 11)
//                            .fill(tab == .wellbeing
//                                  ? mentalHealthAccent(for: viewModel.mentalHealthScore)
//                                  : Color("accentTeal"))
//                            .shadow(color: (tab == .wellbeing
//                                           ? mentalHealthAccent(for: viewModel.mentalHealthScore)
//                                           : Color("accentTeal")).opacity(0.3),
//                                    radius: 8, y: 3)
//                    } else {
//                        RoundedRectangle(cornerRadius: 11).fill(Color.clear)
//                    }
//                }
//            )
//        }
//    }
//
//    // MARK: - Mental Health Hero
//    var mentalHealthSection: some View {
//        VStack(alignment: .leading, spacing: 16) {
//        VStack(spacing: 0) {
//            HStack(spacing: 16) {
//                VStack(alignment: .leading, spacing: 4) {
//                    HStack(spacing: 6) {
//                        Image(systemName: "heart.fill")
//                            .font(.system(size: 11, weight: .bold))
//                            .foregroundStyle(.white.opacity(0.8))
//                        Text("Mental Wellbeing")
//                            .font(.system(size: 12, weight: .bold))
//                            .foregroundStyle(.white.opacity(0.85))
//                            .textCase(.uppercase)
//                            .tracking(0.9)
//                    }
//                    Text("How are you feeling inside today?")
//                        .font(.system(size: 16, weight: .medium))
//                        .foregroundStyle(.white)
//                }
//                Spacer()
//                ZStack {
//                    Circle()
//                        .fill(.white.opacity(0.2))
//                        .frame(width: 64, height: 64)
//                    VStack(spacing: 0) {
//                        Text("\(viewModel.mentalHealthScore)")
//                            .font(.system(size: 27, weight: .bold))
//                            .foregroundStyle(.white)
//                            .contentTransition(.numericText())
//                        Text("/10")
//                            .font(.system(size: 11))
//                            .foregroundStyle(.white.opacity(0.7))
//                    }
//                }
//            }
//            .padding(.horizontal, 20)
//            .padding(.vertical, 20)
//            .background(
//                LinearGradient(
//                    colors: mentalHealthGradient(for: viewModel.mentalHealthScore),
//                    startPoint: .topLeading, endPoint: .bottomTrailing
//                )
//            )
//            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 0,
//                                               bottomTrailingRadius: 0, topTrailingRadius: 20))
//
//            VStack(spacing: 16) {
//                HStack(spacing: 16) {
//                    Text(mentalHealthEmoji(for: viewModel.mentalHealthScore))
//                        .font(.system(size: 48))
//                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.mentalHealthScore)
//
//                    VStack(alignment: .leading, spacing: 6) {
//                        Text(viewModel.mentalHealthLabel(for: viewModel.mentalHealthScore))
//                            .font(.system(size: 20, weight: .bold))
//                            .foregroundStyle(mentalHealthAccent(for: viewModel.mentalHealthScore))
//                            .animation(.easeInOut(duration: 0.2), value: viewModel.mentalHealthScore)
//                        Text(mentalHealthDescription(for: viewModel.mentalHealthScore))
//                            .font(.system(size: 13))
//                            .foregroundStyle(Color("textSecondary"))
//                            .fixedSize(horizontal: false, vertical: true)
//                    }
//                    Spacer()
//                }
//
//                MentalHealthStepBar(value: $viewModel.mentalHealthScore)
//                    .onChange(of: viewModel.mentalHealthScore) { viewModel.isSaved = false }
//
//                HStack {
//                    Text("Very difficult")
//                        .font(.system(size: 11))
//                        .foregroundStyle(Color("textTertiary"))
//                    Spacer()
//                    Text("Feeling great")
//                        .font(.system(size: 11))
//                        .foregroundStyle(Color("textTertiary"))
//                }
//            }
//            .padding(.horizontal, 20)
//            .padding(.vertical, 20)
//            .background(Color("cardBackground"))
//            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 20,
//                                               bottomTrailingRadius: 20, topTrailingRadius: 0))
//        }
//        .shadow(color: mentalHealthAccent(for: viewModel.mentalHealthScore).opacity(0.22), radius: 16, y: 6)
//        .animation(.easeInOut(duration: 0.3), value: viewModel.mentalHealthScore)
//
//        // Divider with label
//        HStack(spacing: 10) {
//            Rectangle().fill(Color("borderColor")).frame(height: 1)
//            Text("A little deeper...")
//                .font(.system(size: 11, weight: .semibold))
//                .foregroundStyle(Color("textTertiary"))
//                .textCase(.uppercase)
//                .tracking(0.8)
//                .fixedSize()
//            Rectangle().fill(Color("borderColor")).frame(height: 1)
//        }
//        .padding(.top, 4)
//
//        // 4 emotional check-in questions
//        EmotionalQuestionCard(
//            question: "How much anger or frustration have you noticed in yourself?",
//            detail: "It's okay to feel angry. This is a safe place to be honest.",
//            icon: "flame.fill",
//            accentColor: Color(hex: "E74C3C"),
//            value: $viewModel.angerScore
//        )
//        .onChange(of: viewModel.angerScore) { viewModel.isSaved = false }
//
//        EmotionalQuestionCard(
//            question: "How worried or anxious have you felt about your recovery or health?",
//            detail: "Anxiety about recovery is very common. You're not alone in this.",
//            icon: "cloud.rain.fill",
//            accentColor: Color(hex: "5B85C4"),
//            value: $viewModel.anxietyScore
//        )
//        .onChange(of: viewModel.anxietyScore) { viewModel.isSaved = false }
//
//        EmotionalQuestionCard(
//            question: "How lonely or isolated have you been feeling?",
//            detail: "Connection matters. Sharing how you feel is a brave first step.",
//            icon: "person.fill.xmark",
//            accentColor: Color(hex: "8E44AD"),
//            value: $viewModel.lonelinessScore
//        )
//        .onChange(of: viewModel.lonelinessScore) { viewModel.isSaved = false }
//
//        EmotionalQuestionCard(
//            question: "How emotionally heavy has the day felt for you?",
//            detail: "Some days carry more weight. Noticing that takes courage.",
//            icon: "scalemass.fill",
//            accentColor: Color(hex: "5D7A8A"),
//            value: $viewModel.heavinessScore
//        )
//        .onChange(of: viewModel.heavinessScore) { viewModel.isSaved = false }
//        } // end outer VStack
//    }
//
//    func mentalHealthGradient(for score: Int) -> [Color] {
//        switch score {
//        case 1...3: return [Color(hex: "B03A2E"), Color(hex: "E74C3C")]
//        case 4...6: return [Color(hex: "CA6F1E"), Color(hex: "F39C12")]
//        case 7...8: return [Color(hex: "1E8449"), Color(hex: "27AE60")]
//        default:    return [Color(hex: "1A7A6E"), Color(hex: "2A9D8F")]
//        }
//    }
//
//    func mentalHealthAccent(for score: Int) -> Color {
//        switch score {
//        case 1...3: return Color(hex: "E74C3C")
//        case 4...6: return Color(hex: "E67E22")
//        case 7...8: return Color(hex: "27AE60")
//        default:    return Color("accentTeal")
//        }
//    }
//
//    func mentalHealthEmoji(for score: Int) -> String {
//        ["😞","😟","😕","😐","🙂","😊","😄","😁","🤩","🥳"][score - 1]
//    }
//
//    func mentalHealthDescription(for score: Int) -> String {
//        switch score {
//        case 1: return "It's a really hard day. That's okay."
//        case 2: return "Feeling very low. Be gentle with yourself."
//        case 3: return "Struggling a bit today."
//        case 4: return "Not quite yourself today."
//        case 5: return "Getting through it."
//        case 6: return "A reasonably okay day."
//        case 7: return "Feeling fairly good today."
//        case 8: return "Having a good day!"
//        case 9: return "Feeling really well!"
//        default: return "Wonderful — a great day! 🌟"
//        }
//    }
//
//    // MARK: - Quick Actions
//    var quickActionsRow: some View {
//        HStack(spacing: 10) {
//            Button {
//                withAnimation(.spring(response: 0.35)) { viewModel.copyYesterdaySymptoms(from: entries) }
//                UIImpactFeedbackGenerator(style: .light).impactOccurred()
//            } label: {
//                Label("Copy Yesterday", systemImage: "arrow.counterclockwise")
//                    .font(.system(size: 14, weight: .semibold))
//                    .foregroundStyle(Color("accentTeal"))
//                    .frame(maxWidth: .infinity)
//                    .padding(.vertical, 13)
//                    .background(Color("accentTeal").opacity(0.09))
//                    .clipShape(RoundedRectangle(cornerRadius: 13))
//                    .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color("accentTeal").opacity(0.2), lineWidth: 1))
//            }
//
//            Button {
//                withAnimation(.spring(response: 0.35)) { viewModel.showingCustomSymptom.toggle() }
//            } label: {
//                Label(viewModel.showingCustomSymptom ? "Cancel" : "Add Custom",
//                      systemImage: viewModel.showingCustomSymptom ? "xmark" : "plus")
//                    .font(.system(size: 14, weight: .semibold))
//                    .foregroundStyle(viewModel.showingCustomSymptom ? Color("severityHigh") : Color("textSecondary"))
//                    .frame(maxWidth: .infinity)
//                    .padding(.vertical, 13)
//                    .background(viewModel.showingCustomSymptom ? Color("severityHigh").opacity(0.08) : Color("chipBackground"))
//                    .clipShape(RoundedRectangle(cornerRadius: 13))
//                    .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color("borderColor"), lineWidth: 1))
//            }
//        }
//    }
//
//    // MARK: - Selected Symptoms
//    var selectedSymptomsSection: some View {
//        VStack(alignment: .leading, spacing: 14) {
//            HStack(spacing: 8) {
//                Text("Logged Today")
//                    .font(.system(size: 17, weight: .semibold))
//                    .foregroundStyle(Color("textPrimary"))
//                Text("\(viewModel.selectedSymptoms.count)")
//                    .font(.system(size: 12, weight: .bold))
//                    .foregroundStyle(.white)
//                    .padding(.horizontal, 8).padding(.vertical, 3)
//                    .background(Color("accentTeal"))
//                    .clipShape(Capsule())
//                Spacer()
//            }
//            VStack(spacing: 10) {
//                ForEach($viewModel.selectedSymptoms) { $symptom in
//                    SymptomSeverityCard(symptom: $symptom) {
//                        withAnimation(.spring(response: 0.3)) { viewModel.removeSymptom(symptom, context: modelContext, allEntries: entries) }
//                    }
//                }
//            }
//        }
//    }
//
//    // MARK: - Symptom Picker
//    var symptomPickerSection: some View {
//        VStack(alignment: .leading, spacing: 14) {
//            Text("Browse Symptoms")
//                .font(.system(size: 17, weight: .semibold))
//                .foregroundStyle(Color("textPrimary"))
//
//            let past = viewModel.pastSymptomNames(from: entries)
//            if !past.isEmpty {
//                VStack(alignment: .leading, spacing: 8) {
//                    Label("Recently logged", systemImage: "clock")
//                        .font(.system(size: 12, weight: .semibold))
//                        .foregroundStyle(Color("textTertiary"))
//
//                    ScrollView(.horizontal, showsIndicators: false) {
//                        HStack(spacing: 8) {
//                            ForEach(past.prefix(8)) { symptom in
//                                SymptomChip(symptom: symptom, isSelected: viewModel.isSelected(symptom)) {
//                                    withAnimation(.spring(response: 0.3)) { viewModel.toggleSymptom(symptom) }
//                                }
//                            }
//                        }
//                        .padding(.horizontal, 1).padding(.vertical, 2)
//                    }
//                }
//                .padding(14)
//                .background(Color("cardBackground"))
//                .clipShape(RoundedRectangle(cornerRadius: 16))
//            }
//
//            ForEach(SymptomCategory.allCases, id: \.self) { category in
//                SymptomCategorySection(
//                    category: category,
//                    symptoms: CommonSymptom.preloaded.filter { $0.category == category },
//                    viewModel: viewModel
//                )
//            }
//        }
//    }
//
//    // MARK: - Notes
//    var notesSection: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            Label("Additional Notes", systemImage: "pencil.line")
//                .font(.system(size: 17, weight: .semibold))
//                .foregroundStyle(Color("textPrimary"))
//
//            ZStack(alignment: .topLeading) {
//                RoundedRectangle(cornerRadius: 16)
//                    .fill(Color("cardBackground"))
//                    .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
//                if viewModel.notes.isEmpty {
//                    Text("Any triggers, observations, or context…")
//                        .font(.system(size: 15))
//                        .foregroundStyle(Color("textTertiary"))
//                        .padding(18)
//                        .allowsHitTesting(false)
//                }
//                TextEditor(text: $viewModel.notes)
//                    .font(.system(size: 15))
//                    .foregroundStyle(Color("textPrimary"))
//                    .scrollContentBackground(.hidden)
//                    .frame(minHeight: 96)
//                    .padding(14)
//                    .onChange(of: viewModel.notes) { viewModel.isSaved = false }
//            }
//        }
//    }
//
//    // MARK: - Save Button
//    var saveButton: some View {
//        VStack(spacing: 0) {
//            LinearGradient(
//                colors: [Color("backgroundPrimary").opacity(0), Color("backgroundPrimary")],
//                startPoint: .top, endPoint: .bottom
//            )
//            .frame(height: 28)
//
//            Button {
//                withAnimation(.spring(response: 0.4)) { viewModel.saveEntry(context: modelContext, allEntries: entries) }
//                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
//            } label: {
//                HStack(spacing: 10) {
//                    Image(systemName: viewModel.isSaved ? "checkmark.circle.fill" : "square.and.pencil")
//                        .font(.system(size: 17, weight: .semibold))
//                    Text(viewModel.isSaved ? "Saved!" : "Save Today's Log")
//                        .font(.system(size: 17, weight: .semibold))
//                }
//                .foregroundStyle(.white)
//                .frame(maxWidth: .infinity)
//                .padding(.vertical, 18)
//                .background(
//                    RoundedRectangle(cornerRadius: 18)
//                        .fill(viewModel.isSaved ? Color("successGreen") : Color("accentTeal"))
//                        .shadow(color: (viewModel.isSaved ? Color("successGreen") : Color("accentTeal")).opacity(0.4),
//                                radius: 14, y: 5)
//                )
//            }
//            .padding(.horizontal, 20)
//            .padding(.bottom, 36)
//            .background(Color("backgroundPrimary"))
//        }
//        .animation(.spring(response: 0.4), value: viewModel.isSaved)
//    }
//}
//
//// MARK: - Color hex init
//extension Color {
//    init(hex: String) {
//        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
//        var int: UInt64 = 0
//        Scanner(string: h).scanHexInt64(&int)
//        self.init(
//            red: Double((int >> 16) & 0xFF) / 255,
//            green: Double((int >> 8) & 0xFF) / 255,
//            blue: Double(int & 0xFF) / 255
//        )
//    }
//}
