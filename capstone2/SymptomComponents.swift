import SwiftUI

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    var count: Int? = nil
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color("textPrimary"))
            if let count {
                Text("\(count)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color("accentTeal"))
                    .clipShape(Capsule())
            }
            Spacer()
        }
    }
}

// MARK: - Symptom Chip (for selection)
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
                }
                Text(symptom.name)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
            }
            .foregroundStyle(isSelected ? .white : Color("textPrimary"))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(isSelected ? Color("accentTeal") : Color("chipBackground"))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color("borderColor"), lineWidth: 1)
            )
            .scaleEffect(isSelected ? 1.0 : 0.98)
            .animation(.spring(response: 0.25), value: isSelected)
        }
    }
}

// MARK: - Category Section (collapsible)
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
            // Header row
            Button {
                withAnimation(.spring(response: 0.35)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: category.icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color(category.color))
                        .frame(width: 32, height: 32)
                        .background(Color(category.color).opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Text(category.rawValue)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color("textPrimary"))
                    
                    Spacer()
                    
                    if selectedCount > 0 {
                        Text("\(selectedCount) selected")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color("accentTeal"))
                    }
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color("textTertiary"))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            
            if isExpanded {
                // Symptom chips grid
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 8
                ) {
                    ForEach(symptoms) { symptom in
                        SymptomChip(
                            symptom: symptom,
                            isSelected: viewModel.isSelected(symptom)
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                viewModel.toggleSymptom(symptom)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color("cardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        .onAppear {
            // Auto-expand if category has selected symptoms
            if selectedCount > 0 { isExpanded = true }
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
        case 7...10: return Color("severityHigh")
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // Category dot
                Circle()
                    .fill(Color(symptom.category.color))
                    .frame(width: 8, height: 8)
                
                Text(symptom.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color("textPrimary"))
                
                Spacer()
                
                // Severity badge
                HStack(spacing: 4) {
                    Text("\(symptom.severity)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(severityColor)
                    Text("/10")
                        .font(.system(size: 12))
                        .foregroundStyle(Color("textTertiary"))
                }
                
                // Remove button
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color("textTertiary"))
                        .frame(width: 28, height: 28)
                        .background(Color("chipBackground"))
                        .clipShape(Circle())
                }
            }
            
            // Severity slider
            HStack(spacing: 12) {
                Text("Mild")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color("severityLow"))
                
                SeveritySlider(value: $symptom.severity, color: severityColor)
                
                Text("Severe")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color("severityHigh"))
            }
        }
        .padding(16)
        .background(Color("cardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(severityColor.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }
}

// MARK: - Severity Slider (custom, stepped 1–10)
struct SeveritySlider: View {
    @Binding var value: Int
    let color: Color
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color("sliderTrack"))
                    .frame(height: 6)
                
                // Fill
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [Color("severityLow"), Color("severityMed"), Color("severityHigh")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * CGFloat(value - 1) / 9, height: 6)
                
                // Thumb
                Circle()
                    .fill(.white)
                    .frame(width: 22, height: 22)
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 1)
                    .overlay(Circle().stroke(color, lineWidth: 2))
                    .offset(x: geo.size.width * CGFloat(value - 1) / 9 - 11)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { drag in
                                let newVal = Int(((drag.location.x / geo.size.width) * 9).rounded()) + 1
                                let clamped = max(1, min(10, newVal))
                                if clamped != value {
                                    value = clamped
                                    let impact = UISelectionFeedbackGenerator()
                                    impact.selectionChanged()
                                }
                            }
                    )
            }
            .frame(height: 22)
        }
        .frame(height: 22)
    }
}

// MARK: - Mental Health Slider (emoji-based)
struct MentalHealthSlider: View {
    @Binding var value: Int
    
    let emojis = ["😞", "😟", "😕", "😐", "🙂", "😊", "😄", "😁", "🤩", "🥳"]
    
    var body: some View {
        VStack(spacing: 12) {
            // Emoji display
            Text(emojis[value - 1])
                .font(.system(size: 44))
                .animation(.spring(response: 0.3), value: value)
            
            // Stepped dot indicators
            HStack(spacing: 0) {
                ForEach(1...10, id: \.self) { i in
                    Button {
                        withAnimation(.spring(response: 0.25)) { value = i }
                        let impact = UISelectionFeedbackGenerator()
                        impact.selectionChanged()
                    } label: {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(i <= value ? Color("accentTeal") : Color("sliderTrack"))
                            .frame(height: i == value ? 22 : 14)
                            .animation(.spring(response: 0.25), value: value)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 24)
            
            HStack {
                Text("1 — Very Low")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color("textTertiary"))
                Spacer()
                Text("10 — Excellent")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color("textTertiary"))
            }
        }
    }
}

// MARK: - Custom Symptom Input
struct CustomSymptomInputView: View {
    @Bindable var viewModel: SymptomLogViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            TextField("Symptom name…", text: $viewModel.customSymptomName)
                .font(.system(size: 15))
                .padding(14)
                .background(Color("chipBackground"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Picker("Category", selection: $viewModel.customSymptomCategory) {
                ForEach(SymptomCategory.allCases, id: \.self) { cat in
                    Text(cat.rawValue).tag(cat)
                }
            }
            .pickerStyle(.segmented)
            
            HStack(spacing: 10) {
                Button("Cancel") {
                    withAnimation { viewModel.showingCustomSymptom = false }
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color("textSecondary"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color("chipBackground"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Button("Add Symptom") {
                    withAnimation { viewModel.addCustomSymptom() }
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color("accentTeal"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(viewModel.customSymptomName.isEmpty)
                .opacity(viewModel.customSymptomName.isEmpty ? 0.5 : 1)
            }
        }
        .padding(16)
        .background(Color("cardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
    }
}

// MARK: - Save Confirmation Banner
struct SaveConfirmationBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color("successGreen"))
            Text("Symptoms logged successfully")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color("textPrimary"))
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color("cardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 12, y: 4)
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }
}
