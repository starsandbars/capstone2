import SwiftUI
import SwiftData

// MARK: - Habit Row
struct HabitRow: View {
    let habit: Habit
    let onToggle: () -> Void
    let onTap: () -> Void
    let onDelete: () -> Void

    @State private var pressing = false

    var body: some View {
        HStack(spacing: 14) {
            // Completion button
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .stroke(habit.isCompletedForPeriod ? Color.clear : habit.category.color.opacity(0.4), lineWidth: 2)
                        .frame(width: 44, height: 44)
                    Circle()
                        .fill(habit.isCompletedForPeriod ? habit.category.color : habit.category.color.opacity(0.08))
                        .frame(width: 44, height: 44)

                    if habit.isCompletedForPeriod {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Text(habit.emoji)
                            .font(.system(size: 20))
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: habit.isCompletedForPeriod)
            }
            .buttonStyle(.plain)

            // Content
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(habit.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(habit.isCompletedForPeriod ? Color("textTertiary") : Color("textPrimary"))
                            .strikethrough(habit.isCompletedForPeriod, color: Color("textTertiary"))

                        Spacer()

                        // Streak badge (only for daily with streak > 0)
                        if habit.frequency == .daily && habit.currentStreak > 0 {
                            HStack(spacing: 3) {
                                Text("🔥")
                                    .font(.system(size: 11))
                                Text("\(habit.currentStreak)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Color(hex: "E67E22"))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(hex: "E67E22").opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }

                    HStack(spacing: 8) {
                        // Category pill
                        HStack(spacing: 4) {
                            Image(systemName: habit.category.icon)
                                .font(.system(size: 9, weight: .semibold))
                            Text(habit.category.rawValue)
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(habit.category.color)

                        // Frequency pill
                        HStack(spacing: 4) {
                            Image(systemName: habit.frequency.icon)
                                .font(.system(size: 9, weight: .semibold))
                            Text(habit.frequency.rawValue)
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(Color("textTertiary"))

                        Spacer()

                        // Mini 7-day grid
                        if habit.frequency == .daily {
                            HStack(spacing: 3) {
                                ForEach(Array(habit.last7Days.enumerated()), id: \.offset) { _, done in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(done ? habit.category.color : Color("sliderTrack"))
                                        .frame(width: 8, height: 8)
                                }
                            }
                        }
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color("cardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(habit.isCompletedForPeriod ? habit.category.color.opacity(0.15) : Color("borderColor"), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 5, y: 2)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button(action: onToggle) {
                Label(habit.isCompletedForPeriod ? "Undo" : "Done",
                      systemImage: habit.isCompletedForPeriod ? "arrow.uturn.backward" : "checkmark")
            }
            .tint(Color("accentTeal"))
        }
    }
}

// MARK: - Add Habit Sheet
struct AddHabitSheet: View {
    @Bindable var viewModel: HabitViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var existingHabits: [Habit]

    var alreadyAddedTitles: Set<String> {
        Set(existingHabits.map(\.title))
    }


    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {

                    // Title + description
                    VStack(spacing: 12) {
                        TextField("Habit name…", text: $viewModel.newTitle)
                            .font(.system(size: 17, weight: .semibold))
                            .padding(16)
                            .background(Color("chipBackground"))
                            .clipShape(RoundedRectangle(cornerRadius: 13))

                        TextField("Description (optional)", text: $viewModel.newDescription)
                            .font(.system(size: 15))
                            .padding(16)
                            .background(Color("chipBackground"))
                            .clipShape(RoundedRectangle(cornerRadius: 13))
                    }

                    // Frequency
                    sheetSection(title: "How often?") {
                        HStack(spacing: 10) {
                            ForEach(HabitFrequency.allCases, id: \.self) { freq in
                                Button {
                                    withAnimation(.spring(response: 0.25)) { viewModel.newFrequency = freq }
                                } label: {
                                    VStack(spacing: 6) {
                                        Image(systemName: freq.icon)
                                            .font(.system(size: 16, weight: .semibold))
                                        Text(freq.rawValue)
                                            .font(.system(size: 13, weight: .semibold))
                                    }
                                    .foregroundStyle(viewModel.newFrequency == freq ? .white : Color("textSecondary"))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(viewModel.newFrequency == freq ? Color("accentTeal") : Color("chipBackground"))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Category
                    sheetSection(title: "Category") {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(HabitCategory.allCases, id: \.self) { cat in
                                Button {
                                    withAnimation(.spring(response: 0.25)) { viewModel.newCategory = cat }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: cat.icon)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(viewModel.newCategory == cat ? .white : cat.color)
                                        Text(cat.rawValue)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(viewModel.newCategory == cat ? .white : Color("textPrimary"))
                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(viewModel.newCategory == cat ? cat.color : cat.color.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 11))
                                    .overlay(RoundedRectangle(cornerRadius: 11)
                                        .stroke(viewModel.newCategory == cat ? Color.clear : cat.color.opacity(0.25), lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                                .animation(.spring(response: 0.25), value: viewModel.newCategory)
                            }
                        }
                    }

                    // Notification time
                    if viewModel.newFrequency != .once {
                        sheetSection(title: "Daily reminder") {
                            VStack(spacing: 12) {
                                Toggle("Enable reminder", isOn: $viewModel.newNotifEnabled)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Color("textPrimary"))
                                    .tint(Color("accentTeal"))

                                if viewModel.newNotifEnabled {
                                    HStack {
                                        Text("Remind me at")
                                            .font(.system(size: 14))
                                            .foregroundStyle(Color("textSecondary"))
                                        Spacer()
                                        DatePicker("",
                                                   selection: Binding(
                                                    get: {
                                                        var c = Calendar.current.dateComponents([.hour, .minute], from: Date())
                                                        c.hour = viewModel.newNotifHour
                                                        c.minute = viewModel.newNotifMinute
                                                        return Calendar.current.date(from: c) ?? Date()
                                                    },
                                                    set: { date in
                                                        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
                                                        viewModel.newNotifHour = c.hour ?? 9
                                                        viewModel.newNotifMinute = c.minute ?? 0
                                                    }),
                                                   displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .tint(Color("accentTeal"))
                                    }
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                            .padding(14)
                            .background(Color("chipBackground"))
                            .clipShape(RoundedRectangle(cornerRadius: 13))
                            .animation(.spring(response: 0.3), value: viewModel.newNotifEnabled)
                        }
                    }

                    // Suggested habits
                    sheetSection(title: "Or pick a suggested habit") {
                        VStack(spacing: 8) {
                            ForEach(SuggestedHabit.all) { suggestion in
                                InlineSuggestionRow(
                                    suggestion: suggestion,
                                    isAdded: alreadyAddedTitles.contains(suggestion.title)
                                ) {
                                    viewModel.addSuggested(suggestion, context: modelContext)
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    dismiss()
                                }
                            }
                        }
                    }

                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.resetForm()
                        dismiss()
                    }
                    .foregroundStyle(Color("textSecondary"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        viewModel.saveHabit(context: modelContext)
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(viewModel.newTitle.isEmpty ? Color("textTertiary") : Color("accentTeal"))
                    .disabled(viewModel.newTitle.isEmpty)
                }
            }
            .background(Color("backgroundPrimary"))
        }
    }

    func sheetSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color("textTertiary"))
                .textCase(.uppercase)
                .tracking(0.7)
            content()
        }
    }
}

// MARK: - Suggestions Sheet
struct SuggestionsSheet: View {
    @Bindable var viewModel: HabitViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var existingHabits: [Habit]

    var alreadyAdded: Set<String> {
        Set(existingHabits.map(\.title))
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Intro
                    HStack(spacing: 12) {
                        Text("💡")
                            .font(.system(size: 28))
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Recovery-friendly habits")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color("textPrimary"))
                            Text("Curated small steps to rebuild daily life.")
                                .font(.system(size: 13))
                                .foregroundStyle(Color("textSecondary"))
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(Color(hex: "F39C12").opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "F39C12").opacity(0.2), lineWidth: 1))

                    // Group by category
                    ForEach(HabitCategory.allCases, id: \.self) { category in
                        let suggestions = SuggestedHabit.all.filter { $0.category == category }
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 7) {
                                Image(systemName: category.icon)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(category.color)
                                Text(category.rawValue)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(category.color)
                                    .textCase(.uppercase)
                                    .tracking(0.7)
                            }

                            ForEach(suggestions) { suggestion in
                                SuggestionRow(
                                    suggestion: suggestion,
                                    isAdded: alreadyAdded.contains(suggestion.title)
                                ) {
                                    viewModel.addSuggested(suggestion, context: modelContext)
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .navigationTitle("Suggested Habits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color("accentTeal"))
                        .fontWeight(.semibold)
                }
            }
            .background(Color("backgroundPrimary"))
        }
    }
}

struct SuggestionRow: View {
    let suggestion: SuggestedHabit
    let isAdded: Bool
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(suggestion.emoji)
                .font(.system(size: 22))
                .frame(width: 40, height: 40)
                .background(suggestion.category.color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(suggestion.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color("textPrimary"))
                Text(suggestion.description)
                    .font(.system(size: 12))
                    .foregroundStyle(Color("textSecondary"))
                    .lineLimit(2)
            }
            Spacer()

            Button(action: onAdd) {
                Image(systemName: isAdded ? "checkmark" : "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(isAdded ? Color("successGreen") : Color("accentTeal"))
                    .frame(width: 32, height: 32)
                    .background(isAdded ? Color("successGreen").opacity(0.1) : Color("accentTeal").opacity(0.1))
                    .clipShape(Circle())
            }
            .disabled(isAdded)
        }
        .padding(14)
        .background(Color("cardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

// MARK: - Habit Detail Sheet
struct HabitDetailSheet: View {
    let habit: Habit
    @Bindable var viewModel: HabitViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {

                    // Hero card
                    VStack(spacing: 16) {
                        Text(habit.emoji)
                            .font(.system(size: 52))
                        Text(habit.title)
                            .font(.custom("Georgia", size: 24))
                            .fontWeight(.semibold)
                            .foregroundStyle(Color("textPrimary"))
                            .multilineTextAlignment(.center)
                        if !habit.habitDescription.isEmpty {
                            Text(habit.habitDescription)
                                .font(.system(size: 14))
                                .foregroundStyle(Color("textSecondary"))
                                .multilineTextAlignment(.center)
                        }

                        // Category + frequency
                        HStack(spacing: 10) {
                            Label(habit.category.rawValue, systemImage: habit.category.icon)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(habit.category.color)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(habit.category.color.opacity(0.1))
                                .clipShape(Capsule())

                            Label(habit.frequency.rawValue, systemImage: habit.frequency.icon)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color("textSecondary"))
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(Color("chipBackground"))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.top, 8)

                    // Stats row
                    HStack(spacing: 12) {
                        statCard(value: "\(habit.currentStreak)", label: "Streak", icon: "🔥")
                        statCard(value: "\(habit.totalCompletions)", label: "Total done", icon: "✅")
                    }

                    // 7-day history
                    if habit.frequency == .daily {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Last 7 Days")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color("textPrimary"))

                            HStack(spacing: 6) {
                                ForEach(Array(zip(habit.last7DayLabels, habit.last7Days).enumerated()), id: \.offset) { _, pair in
                                    let (label, done) = pair
                                    VStack(spacing: 5) {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(done ? habit.category.color : Color("sliderTrack"))
                                            .frame(height: done ? 36 : 20)
                                            .animation(.spring(response: 0.4), value: done)
                                        Text(label)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundStyle(done ? habit.category.color : Color("textTertiary"))
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .frame(height: 52, alignment: .bottom)
                        }
                        .padding(16)
                        .background(Color("cardBackground"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color("textSecondary"))
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button {
                        viewModel.deleteHabit(habit, context: modelContext)
                        dismiss()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(Color("severityHigh"))
                    }
                }
            }
            .background(Color("backgroundPrimary"))
        }
    }

    func statCard(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Text(icon)
                .font(.system(size: 24))
            Text(value)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Color("textPrimary"))
                .contentTransition(.numericText())
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color("textSecondary"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Color("cardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 5, y: 2)
    }
}

// MARK: - Inline Suggestion Row (inside AddHabitSheet)
struct InlineSuggestionRow: View {
    let suggestion: SuggestedHabit
    let isAdded: Bool
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(suggestion.emoji)
                .font(.system(size: 20))
                .frame(width: 38, height: 38)
                .background(suggestion.category.color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isAdded ? Color("textTertiary") : Color("textPrimary"))
                HStack(spacing: 6) {
                    Text(suggestion.category.rawValue)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(suggestion.category.color)
                    Text("·")
                        .foregroundStyle(Color("textTertiary"))
                    Text(suggestion.frequency.rawValue)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color("textTertiary"))
                }
            }

            Spacer()

            if isAdded {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color("successGreen"))
                    .frame(width: 32, height: 32)
                    .background(Color("successGreen").opacity(0.1))
                    .clipShape(Circle())
            } else {
                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color("accentTeal"))
                        .frame(width: 32, height: 32)
                        .background(Color("accentTeal").opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color("chipBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 13))
        .opacity(isAdded ? 0.6 : 1)
    }
}
