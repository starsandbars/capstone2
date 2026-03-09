import SwiftUI
import SwiftData

struct SymptomLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SymptomEntry.date, order: .reverse) private var entries: [SymptomEntry]
    @State private var viewModel = SymptomLogViewModel()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color("backgroundPrimary").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        headerSection

                        VStack(spacing: 28) {
                            mentalHealthSection
                            quickActionsRow

                            if viewModel.showingCustomSymptom {
                                CustomSymptomInputView(viewModel: viewModel)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }

                            if !viewModel.selectedSymptoms.isEmpty {
                                selectedSymptomsSection
                            }

                            symptomPickerSection
                            notesSection
                            Spacer().frame(height: 110)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                    }
                }

                saveButton
            }
            .navigationBarHidden(true)
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
                Text("Daily Check-in")
                    .font(.custom("Georgia", size: 30))
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("textPrimary"))
            }
            Spacer()
            Button { } label: {
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

    // MARK: - Mental Health Hero
    var mentalHealthSection: some View {
        VStack(spacing: 0) {
            // Gradient header band
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white.opacity(0.8))
                        Text("Mental Wellbeing")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white.opacity(0.85))
                            .textCase(.uppercase)
                            .tracking(0.9)
                    }
                    Text("How are you feeling inside today?")
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

            // Slider body
            VStack(spacing: 16) {
                // Emoji + label side by side
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
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(Color("textSecondary"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                }

                MentalHealthStepBar(value: $viewModel.mentalHealthScore)

                HStack {
                    Text("Very difficult")
                        .font(.system(size: 11))
                        .foregroundStyle(Color("textTertiary"))
                    Spacer()
                    Text("Feeling great")
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
        case 1: return "It's a really hard day. That's okay."
        case 2: return "Feeling very low. Be gentle with yourself."
        case 3: return "Struggling a bit today."
        case 4: return "Not quite yourself today."
        case 5: return "Getting through it."
        case 6: return "A reasonably okay day."
        case 7: return "Feeling fairly good today."
        case 8: return "Having a good day!"
        case 9: return "Feeling really well!"
        default: return "Wonderful — a great day! 🌟"
        }
    }

    // MARK: - Quick Actions
    var quickActionsRow: some View {
        HStack(spacing: 10) {
            Button {
                withAnimation(.spring(response: 0.35)) { viewModel.copyYesterdaySymptoms(from: entries) }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Label("Copy Yesterday", systemImage: "arrow.counterclockwise")
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
                Label(viewModel.showingCustomSymptom ? "Cancel" : "Add Custom",
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
                Text("Logged Today")
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
                        withAnimation(.spring(response: 0.3)) { viewModel.removeSymptom(symptom) }
                    }
                }
            }
        }
    }

    // MARK: - Symptom Picker
    var symptomPickerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Browse Symptoms")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color("textPrimary"))

            let past = viewModel.pastSymptomNames(from: entries)
            if !past.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Recently logged", systemImage: "clock")
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
            Label("Additional Notes", systemImage: "pencil.line")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color("textPrimary"))

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("cardBackground"))
                    .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
                if viewModel.notes.isEmpty {
                    Text("Any triggers, observations, or context…")
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
                withAnimation(.spring(response: 0.4)) { viewModel.saveEntry(context: modelContext) }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: viewModel.isSaved ? "checkmark.circle.fill" : "square.and.pencil")
                        .font(.system(size: 17, weight: .semibold))
                    Text(viewModel.isSaved ? "Saved!" : "Save Today's Log")
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
