import SwiftUI
import SwiftData

struct HabitView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.createdAt, order: .forward) private var habits: [Habit]
    @State private var viewModel = HabitViewModel()

    var filteredHabits: [Habit] {
        viewModel.habits(from: habits, filter: viewModel.activeFilter)
    }

    var completedToday: Int { viewModel.completedCount(from: habits) }
    var totalDue: Int { habits.filter { !$0.isArchived }.count }
    var progressFraction: Double {
        guard totalDue > 0 else { return 0 }
        return Double(completedToday) / Double(totalDue)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color("backgroundPrimary").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        headerSection
                        progressSection
                            .padding(.horizontal, 20)
                            .padding(.top, 20)

                        filterBar
                            .padding(.horizontal, 20)
                            .padding(.top, 18)
                            .padding(.bottom, 8)

                        if filteredHabits.isEmpty {
                            emptyState
                                .padding(.top, 40)
                        } else {
                            habitsList
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                        }

                        Spacer().frame(height: 100)
                    }
                }

                addButton
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $viewModel.showingAddHabit) {
            AddHabitSheet(viewModel: viewModel)
        }
        .sheet(item: $viewModel.showingDetail) { habit in
            HabitDetailSheet(habit: habit, viewModel: viewModel)
        }
        .onAppear {
            viewModel.requestNotificationPermission()
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
                Text("habits.title")
                    .font(.custom("Georgia", size: 30))
                    .fontWeight(.semibold)
                    .foregroundStyle(Color("textPrimary"))
                Text(viewModel.motivationalMessage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color("textSecondary"))
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 64)
        .padding(.bottom, 4)
    }

    // MARK: - Progress ring section
    var progressSection: some View {
        HStack(spacing: 20) {
            // Ring
            ZStack {
                Circle()
                    .stroke(Color("sliderTrack"), lineWidth: 8)
                    .frame(width: 72, height: 72)
                Circle()
                    .trim(from: 0, to: progressFraction)
                    .stroke(
                        LinearGradient(colors: [Color("accentTeal"), Color(hex: "57B894")],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 72, height: 72)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6), value: progressFraction)

                VStack(spacing: 0) {
                    Text("\(completedToday)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color("textPrimary"))
                        .contentTransition(.numericText())
                    Text("/ \(totalDue)")
                        .font(.system(size: 11))
                        .foregroundStyle(Color("textTertiary"))
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(progressTitle)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color("textPrimary"))
                Text(progressSubtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color("textSecondary"))
                    .fixedSize(horizontal: false, vertical: true)

                // Mini progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4).fill(Color("sliderTrack")).frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient(colors: [Color("accentTeal"), Color(hex: "57B894")],
                                                  startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * progressFraction, height: 6)
                            .animation(.spring(response: 0.6), value: progressFraction)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(18)
        .background(Color("cardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
    }

    var progressTitle: String {
        if totalDue == 0 { return NSLocalizedString("habits.progress.none", comment: "") }
        if completedToday == totalDue { return NSLocalizedString("habits.progress.alldone", comment: "") }
        if completedToday == 0 { return NSLocalizedString("habits.progress.ready", comment: "") }
        return String(format: NSLocalizedString("habits.progress.count", comment: ""), completedToday, totalDue)
    }

    var progressSubtitle: String {
        let remaining = totalDue - completedToday
        if completedToday == totalDue && totalDue > 0 { return NSLocalizedString("habits.progress.wonderful", comment: "") }
        if remaining == 1 { return NSLocalizedString("habits.progress.remaining.one", comment: "") }
        return String(format: NSLocalizedString("habits.progress.remaining", comment: ""), remaining)
    }

    // MARK: - Filter bar
    var filterBar: some View {
        HStack(spacing: 8) {
            ForEach(HabitViewModel.Filter.allCases, id: \.self) { filter in
                Button {
                    withAnimation(.spring(response: 0.3)) { viewModel.activeFilter = filter }
                } label: {
                    Text(filter.localizedTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(viewModel.activeFilter == filter ? .white : Color("textSecondary"))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                        .background(
                            viewModel.activeFilter == filter
                                ? Color("accentTeal")
                                : Color("chipBackground")
                        )
                        .clipShape(Capsule())
                }
            }
            Spacer()
        }
    }

    // MARK: - Habits list
    var habitsList: some View {
        VStack(spacing: 10) {
            ForEach(filteredHabits) { habit in
                HabitRow(habit: habit) {
                    withAnimation(.spring(response: 0.35)) {
                        if habit.isCompletedForPeriod {
                            habit.unmarkComplete()
                        } else {
                            habit.markComplete()
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                        try? modelContext.save()
                    }
                } onTap: {
                    viewModel.showingDetail = habit
                } onDelete: {
                    withAnimation { viewModel.deleteHabit(habit, context: modelContext) }
                }
            }
        }
    }

    // MARK: - Empty state
    var emptyState: some View {
        VStack(spacing: 20) {
            Text("🌱")
                .font(.system(size: 56))
            VStack(spacing: 8) {
                Text(viewModel.activeFilter == .done ? NSLocalizedString("habits.empty.nodone", comment: "") : NSLocalizedString("habits.empty.nohabits", comment: ""))
                    .font(.custom("Georgia", size: 22))
                    .foregroundStyle(Color("textPrimary"))
                Text(viewModel.activeFilter == .done
                     ? NSLocalizedString("habits.empty.sub.nodone", comment: "")
                     : NSLocalizedString("habits.empty.sub.nohabits", comment: ""))
                    .font(.system(size: 14))
                    .foregroundStyle(Color("textSecondary"))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Add button
    var addButton: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color("backgroundPrimary").opacity(0), Color("backgroundPrimary")],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 28)

            Button {
                viewModel.showingAddHabit = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .bold))
                    Text("habits.add")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color("accentTeal"))
                        .shadow(color: Color("accentTeal").opacity(0.4), radius: 14, y: 5)
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
            .background(Color("backgroundPrimary"))
        }
    }
}
