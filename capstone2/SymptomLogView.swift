import SwiftUI
import SwiftData

struct SymptomLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SymptomEntry.date, order: .reverse) private var entries: [SymptomEntry]
    @State private var viewModel = SymptomLogViewModel()
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color("backgroundPrimary")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        headerSection

                        VStack(spacing: 20) {
                            // Quick Actions
                            quickActionsRow

                            // Selected Symptoms with severity sliders
                            if !viewModel.selectedSymptoms.isEmpty {
                                selectedSymptomsSection
                            }

                            // Symptom Picker Grid
                            symptomPickerSection

                            // Mental Health Score
                            mentalHealthSection

                            // Notes
                            notesSection

                            // Bottom padding for save button
                            Spacer().frame(height: 100)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }

                // Floating Save Button
                saveButton
            }
            .navigationBarHidden(true)
        }
        // Save confirmation
        .overlay(alignment: .top) {
            if viewModel.showingSaveConfirmation {
                SaveConfirmationBanner()
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation { viewModel.showingSaveConfirmation = false }
                        }
                    }
            }
        }
        .animation(.spring(response: 0.4), value: viewModel.showingSaveConfirmation)
    }

    // MARK: - Header
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("How are you feeling?")
                        .font(.custom("Georgia", size: 28))
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("textPrimary"))
                    Text(viewModel.todayFormatted)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color("textSecondary"))
                }
                Spacer()
                // PDF Export button
                Button {
                    // PDF export action (implemented in PDFExportView)
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color("accentTeal"))
                        .frame(width: 44, height: 44)
                        .background(Color("accentTeal").opacity(0.12))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 8)
    }

    // MARK: - Quick Actions Row
    var quickActionsRow: some View {
        VStack(spacing: 10) {
        HStack(spacing: 12) {
            // Copy from yesterday
            Button {
                withAnimation(.spring(response: 0.35)) {
                    viewModel.copyYesterdaySymptoms(from: entries)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Copy Yesterday")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(Color("accentTeal"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color("accentTeal").opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color("accentTeal").opacity(0.25), lineWidth: 1)
                )
            }

            // Add custom
            Button {
                withAnimation { viewModel.showingCustomSymptom.toggle() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Add Custom")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(Color("textSecondary"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color("cardBackground"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color("borderColor"), lineWidth: 1)
                )
            }
        }

        // Custom symptom input
        if viewModel.showingCustomSymptom {
            CustomSymptomInputView(viewModel: viewModel)
                .transition(.opacity.combined(with: .move(edge: .top)))
        }
        } // end VStack
    }

    // MARK: - Selected Symptoms Section
    var selectedSymptomsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Logged Today", count: viewModel.selectedSymptoms.count)

            VStack(spacing: 10) {
                ForEach($viewModel.selectedSymptoms) { $symptom in
                    SymptomSeverityCard(symptom: $symptom) {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.removeSymptom(symptom)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Symptom Picker
    var symptomPickerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Common Symptoms")

            // Past symptoms quick row (if any)
            let past = viewModel.pastSymptomNames(from: entries)
            if !past.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color("textTertiary"))
                        .textCase(.uppercase)
                        .tracking(0.8)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(past.prefix(8)) { symptom in
                                SymptomChip(
                                    symptom: symptom,
                                    isSelected: viewModel.isSelected(symptom)
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        viewModel.toggleSymptom(symptom)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 1)
                    }
                }
            }

            // By category
            ForEach(SymptomCategory.allCases, id: \.self) { category in
                let categorySymptoms = CommonSymptom.preloaded.filter { $0.category == category }
                SymptomCategorySection(
                    category: category,
                    symptoms: categorySymptoms,
                    viewModel: viewModel
                )
            }
        }
    }

    // MARK: - Mental Health Section
    var mentalHealthSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Mental Wellbeing")

            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("How are you feeling emotionally?")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color("textPrimary"))
                        Text(viewModel.mentalHealthLabel(for: viewModel.mentalHealthScore))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(viewModel.mentalHealthColor(for: viewModel.mentalHealthScore))
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(viewModel.mentalHealthColor(for: viewModel.mentalHealthScore).opacity(0.15))
                            .frame(width: 56, height: 56)
                        Text("\(viewModel.mentalHealthScore)")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(viewModel.mentalHealthColor(for: viewModel.mentalHealthScore))
                    }
                }

                // Custom slider
                MentalHealthSlider(value: $viewModel.mentalHealthScore)
            }
            .padding(18)
            .background(Color("cardBackground"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        }
    }

    // MARK: - Notes Section
    var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Additional Notes")

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("cardBackground"))
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 2)

                if viewModel.notes.isEmpty {
                    Text("Any other observations, triggers, or context…")
                        .font(.system(size: 15))
                        .foregroundStyle(Color("textTertiary"))
                        .padding(18)
                }

                TextEditor(text: $viewModel.notes)
                    .font(.system(size: 15))
                    .foregroundStyle(Color("textPrimary"))
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 100)
                    .padding(14)
            }
        }
    }

    // MARK: - Save Button
    var saveButton: some View {
        Button {
            withAnimation(.spring(response: 0.4)) {
                viewModel.saveEntry(context: modelContext)
            }
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: viewModel.isSaved ? "checkmark.circle.fill" : "square.and.pencil")
                    .font(.system(size: 18, weight: .semibold))
                Text(viewModel.isSaved ? "Saved!" : "Save Today's Log")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(viewModel.isSaved ? Color("successGreen") : Color("accentTeal"))
                    .shadow(color: Color("accentTeal").opacity(0.35), radius: 12, y: 4)
            )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
        .animation(.spring(response: 0.4), value: viewModel.isSaved)
    }
}

#Preview {
    SymptomLogView()
}
