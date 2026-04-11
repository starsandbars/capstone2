import SwiftUI

// MARK: - Symptom Chip
struct SymptomChip: View {
    let symptom: CommonSymptom
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .transition(.scale.combined(with: .opacity))
                }
                Text(symptom.name)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
            }
            .foregroundStyle(isSelected ? .white : Color("textPrimary"))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(isSelected ? Color("accentTeal") : Color("chipBackground"))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(isSelected ? Color.clear : Color("borderColor"), lineWidth: 1))
            .animation(.spring(response: 0.25), value: isSelected)
        }
    }
}

// MARK: - Collapsible Category Section
struct SymptomCategorySection: View {
    let category: SymptomCategory
    let symptoms: [CommonSymptom]
    @Bindable var viewModel: SymptomLogViewModel
    @State private var isExpanded = false

    var selectedCount: Int {
        symptoms.filter { viewModel.isSelected($0) }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tappable header
            Button {
                withAnimation(.spring(response: 0.35)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 12) {
                    // Category icon badge
                    Image(systemName: category.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(category.color))
                        .frame(width: 34, height: 34)
                        .background(Color(category.color).opacity(0.13))
                        .clipShape(RoundedRectangle(cornerRadius: 9))

                    Text(category.localizedTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color("textPrimary"))

                    Spacer()

                    if selectedCount > 0 {
                        Text("\(selectedCount)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 20, height: 20)
                            .background(Color("accentTeal"))
                            .clipShape(Circle())
                    }

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color("textTertiary"))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()
                    .padding(.horizontal, 16)

                FlowLayout(spacing: 8) {
                    ForEach(symptoms) { symptom in
                        SymptomChip(symptom: symptom, isSelected: viewModel.isSelected(symptom)) {
                            withAnimation(.spring(response: 0.3)) { viewModel.toggleSymptom(symptom) }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color("cardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        .onAppear { if selectedCount > 0 { isExpanded = true } }
    }
}

// MARK: - Flow layout for chips (wraps naturally)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var rowX: CGFloat = 0
        var rowH: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if rowX + size.width > width && rowX > 0 {
                height += rowH + spacing
                rowX = 0; rowH = 0
            }
            rowX += size.width + spacing
            rowH = max(rowH, size.height)
        }
        height += rowH
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var rowX: CGFloat = bounds.minX
        var rowY: CGFloat = bounds.minY
        var rowH: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if rowX + size.width > bounds.maxX && rowX > bounds.minX {
                rowY += rowH + spacing
                rowX = bounds.minX; rowH = 0
            }
            view.place(at: CGPoint(x: rowX, y: rowY), proposal: ProposedViewSize(size))
            rowX += size.width + spacing
            rowH = max(rowH, size.height)
        }
    }
}

// MARK: - Symptom Severity Card
struct SymptomSeverityCard: View {
    @Binding var symptom: LoggedSymptom
    let onRemove: () -> Void

    var severityColor: Color {
        switch symptom.severity {
        case 1...3: return Color("severityLow")
        case 4...6: return Color("severityMed")
        default:    return Color("severityHigh")
        }
    }

    var severityLabel: String {
        switch symptom.severity {
        case 1...3: return NSLocalizedString("custom.severity.mild", comment: "")
        case 4...6: return NSLocalizedString("emotion.intensity.moderate", comment: "")
        default:    return NSLocalizedString("custom.severity.severe", comment: "")
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            // Top row
            HStack(spacing: 10) {
                // Category pill
                HStack(spacing: 5) {
                    Image(systemName: symptom.category.icon)
                        .font(.system(size: 10, weight: .semibold))
                    Text(symptom.category.localizedTitle)
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(Color(symptom.category.color))
                .padding(.horizontal, 9).padding(.vertical, 4)
                .background(Color(symptom.category.color).opacity(0.1))
                .clipShape(Capsule())

                Text(symptom.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color("textPrimary"))

                Spacer()

                // Severity badge
                Text(severityLabel)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(severityColor)
                    .padding(.horizontal, 9).padding(.vertical, 4)
                    .background(severityColor.opacity(0.1))
                    .clipShape(Capsule())

                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color("textTertiary"))
                        .frame(width: 26, height: 26)
                        .background(Color("chipBackground"))
                        .clipShape(Circle())
                }
            }

            // Slider row
            VStack(spacing: 6) {
                SeveritySlider(value: $symptom.severity, color: severityColor)

                HStack {
                    Text("Mild")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color("severityLow"))
                    Spacer()
                    Text("\(symptom.severity) / 10")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(severityColor)
                        .contentTransition(.numericText())
                    Spacer()
                    Text("Severe")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color("severityHigh"))
                }
            }
        }
        .padding(16)
        .background(Color("cardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(severityColor.opacity(0.2), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        .animation(.easeInOut(duration: 0.2), value: symptom.severity)
    }
}

// MARK: - Severity Slider
struct SeveritySlider: View {
    @Binding var value: Int
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color("sliderTrack"))
                    .frame(height: 7)

                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient(
                        colors: [Color("severityLow"), Color("severityMed"), Color("severityHigh")],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(width: geo.size.width * CGFloat(value - 1) / 9, height: 7)

                Circle()
                    .fill(.white)
                    .frame(width: 24, height: 24)
                    .shadow(color: color.opacity(0.3), radius: 5, y: 2)
                    .overlay(Circle().stroke(color, lineWidth: 2.5))
                    .offset(x: max(0, min(geo.size.width - 24, geo.size.width * CGFloat(value - 1) / 9 - 12)))
                    .gesture(DragGesture(minimumDistance: 0).onChanged { drag in
                        let newVal = Int(((drag.location.x / geo.size.width) * 9).rounded()) + 1
                        let clamped = max(1, min(10, newVal))
                        if clamped != value {
                            value = clamped
                            UISelectionFeedbackGenerator().selectionChanged()
                        }
                    })
            }
            .frame(height: 24).frame(maxHeight: .infinity, alignment: .center)
        }
        .frame(height: 24)
    }
}

// MARK: - Mental Health Step Bar
struct MentalHealthStepBar: View {
    @Binding var value: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...10, id: \.self) { i in
                Button {
                    withAnimation(.spring(response: 0.25)) { value = i }
                    UISelectionFeedbackGenerator().selectionChanged()
                } label: {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(segmentColor(for: i))
                        .frame(height: i == value ? 28 : 18)
                        .opacity(i <= value ? 1.0 : 0.25)
                        .animation(.spring(response: 0.25), value: value)
                }
            }
        }
        .frame(height: 32)
    }

    func segmentColor(for i: Int) -> Color {
        switch i {
        case 1...3: return Color(hex: "E74C3C")
        case 4...6: return Color(hex: "E67E22")
        case 7...8: return Color(hex: "27AE60")
        default:    return Color("accentTeal")
        }
    }
}

// MARK: - Custom Symptom Input (redesigned)
struct CustomSymptomInputView: View {
    @Bindable var viewModel: SymptomLogViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            // Title
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Color("accentTeal"))
                Text("custom.title")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color("textPrimary"))
            }

            // Symptom name field
            VStack(alignment: .leading, spacing: 6) {
                Text("custom.name.label")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color("textTertiary"))
                    .textCase(.uppercase)
                    .tracking(0.6)

                TextField(NSLocalizedString("custom.name.placeholder", comment: ""), text: $viewModel.customSymptomName)
                    .font(.system(size: 16))
                    .padding(14)
                    .background(Color("chipBackground"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color("borderColor"), lineWidth: 1))
            }

            // Category picker — clearly labelled
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("custom.category.label")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color("textTertiary"))
                        .textCase(.uppercase)
                        .tracking(0.6)
                    Text("custom.category.detail")
                        .font(.system(size: 12))
                        .foregroundStyle(Color("textTertiary"))
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(SymptomCategory.allCases, id: \.self) { cat in
                        Button {
                            withAnimation(.spring(response: 0.25)) {
                                viewModel.customSymptomCategory = cat
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: cat.icon)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(viewModel.customSymptomCategory == cat ? .white : Color(cat.color))
                                Text(cat.localizedTitle)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(viewModel.customSymptomCategory == cat ? .white : Color("textPrimary"))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                viewModel.customSymptomCategory == cat
                                    ? Color(cat.color)
                                    : Color(cat.color).opacity(0.08)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 11))
                            .overlay(
                                RoundedRectangle(cornerRadius: 11)
                                    .stroke(
                                        viewModel.customSymptomCategory == cat ? Color.clear : Color(cat.color).opacity(0.25),
                                        lineWidth: 1
                                    )
                            )
                            .animation(.spring(response: 0.25), value: viewModel.customSymptomCategory)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Action buttons
            HStack(spacing: 10) {
                Button(NSLocalizedString("button.cancel", comment: "")) {
                    withAnimation { viewModel.showingCustomSymptom = false }
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color("textSecondary"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color("chipBackground"))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    withAnimation { viewModel.addCustomSymptom() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                        Text("custom.button.add")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        viewModel.customSymptomName.isEmpty
                            ? Color("accentTeal").opacity(0.4)
                            : Color("accentTeal")
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(viewModel.customSymptomName.isEmpty)
            }
        }
        .padding(18)
        .background(Color("cardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.08), radius: 16, y: 6)
    }
}

// MARK: - Save Confirmation Banner
struct SaveConfirmationBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(Color("successGreen"))
            VStack(alignment: .leading, spacing: 1) {
                Text("log.saved.banner")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color("textPrimary"))
                Text("log.saved.banner.sub")
                    .font(.system(size: 13))
                    .foregroundStyle(Color("textSecondary"))
            }
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("cardBackground"))
                .shadow(color: .black.opacity(0.12), radius: 14, y: 4)
        )
        .padding(.horizontal, 20)
        .padding(.top, 58)
    }
}



// MARK: - Emotional Question Card
struct EmotionalQuestionCard: View {
    let question: String
    let detail: String          // soft explanatory subtext
    let icon: String
    let accentColor: Color
    @Binding var value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Question header
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(accentColor)
                    .frame(width: 36, height: 36)
                    .background(accentColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 3) {
                    Text(question)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color("textPrimary"))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(detail)
                        .font(.system(size: 12))
                        .foregroundStyle(Color("textTertiary"))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()

                // Score pill
                Text("\(value)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(accentColor)
                    .frame(width: 38, height: 38)
                    .background(accentColor.opacity(0.1))
                    .clipShape(Circle())
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.25), value: value)
            }

            // Dot-step selector
            HStack(spacing: 5) {
                ForEach(1...10, id: \.self) { i in
                    Button {
                        withAnimation(.spring(response: 0.25)) { value = i }
                        UISelectionFeedbackGenerator().selectionChanged()
                    } label: {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(i <= value ? accentColor : Color("sliderTrack"))
                            .frame(height: i == value ? 20 : 10)
                            .animation(.spring(response: 0.2), value: value)
                    }
                }
            }
            .frame(height: 22)

            // Low / High labels
            HStack {
                Text(NSLocalizedString("eq.notatall", comment: ""))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color("textTertiary"))
                Spacer()
                Text(highLabel)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color("textTertiary"))
            }
        }
        .padding(18)
        .background(Color("cardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(value >= 7 ? accentColor.opacity(0.3) : Color("borderColor"), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        .animation(.easeInOut(duration: 0.2), value: value)
    }

    var highLabel: String {
        switch icon {
        case "flame.fill":         return NSLocalizedString("eq.anger.high", comment: "")
        case "cloud.rain.fill":    return NSLocalizedString("eq.anxiety.high", comment: "")
        case "person.fill.xmark":  return NSLocalizedString("eq.loneliness.high", comment: "")
        case "scalemass.fill":     return NSLocalizedString("eq.heaviness.high", comment: "")
        default:                   return NSLocalizedString("eq.heaviness.high", comment: "")
        }
    }
}

