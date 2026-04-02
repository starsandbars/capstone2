import SwiftUI
import SwiftData
import UserNotifications

// MARK: - Onboarding slide index
enum OnboardingSlide: Int, CaseIterable {
    case language      = 0
    case welcome       = 1
    case name          = 2
    case tour          = 3
    case habits        = 4
    case notifications = 5
    case ready         = 6
}

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("patientName") private var storedName = ""
    @Environment(\.modelContext) private var modelContext

    @State private var currentSlide: OnboardingSlide = .language
    @State private var nameInput = ""
    @State private var selectedHabits: Set<UUID> = []
    @State private var notificationGranted: Bool? = nil
    @State private var slideOffset: CGFloat = 0
    @State private var animateContent = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background shifts per slide
                slideBackground
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.6), value: currentSlide)

                VStack(spacing: 0) {
                    // Progress dots
                    progressDots
                        .padding(.top, 60)
                        .padding(.bottom, 8)

                    // Slides — laid out in a horizontal row, shifted by currentSlide index
                    HStack(spacing: 0) {
                        LanguageSlide(onNext: nextSlide)
                            .frame(width: geo.size.width)
                        WelcomeSlide(onNext: nextSlide)
                            .frame(width: geo.size.width)
                        NameSlide(nameInput: $nameInput, onNext: nextSlide)
                            .frame(width: geo.size.width)
                        TourSlide(onNext: nextSlide)
                            .frame(width: geo.size.width)
                        HabitsSlide(selectedHabits: $selectedHabits, onNext: nextSlide)
                            .frame(width: geo.size.width)
                        NotificationsSlide(granted: $notificationGranted, onNext: nextSlide)
                            .frame(width: geo.size.width)
                        ReadySlide(name: nameInput, onFinish: finish)
                            .frame(width: geo.size.width)
                    }
                    .frame(width: geo.size.width, alignment: .leading)
                    .offset(x: -CGFloat(currentSlide.rawValue) * geo.size.width)
                    .animation(.spring(response: 0.5, dampingFraction: 0.85), value: currentSlide)
                }
            }
        }
        .ignoresSafeArea(.keyboard)
    }

    // MARK: - Background gradient per slide
    var slideBackground: some View {
        let colors: [Color] = {
            switch currentSlide {
            case .language:      return [Color(hex: "0D3A5C"), Color(hex: "1E5F8C")]
            case .welcome:       return [Color(hex: "1A7A6E"), Color(hex: "0D4F47")]
            case .name:          return [Color(hex: "1E5F8C"), Color(hex: "0D3A5C")]
            case .tour:          return [Color(hex: "27AE60"), Color(hex: "145A32")]
            case .habits:        return [Color(hex: "8E44AD"), Color(hex: "4A235A")]
            case .notifications: return [Color(hex: "CA6F1E"), Color(hex: "784212")]
            case .ready:         return [Color(hex: "1A7A6E"), Color(hex: "0D4F47")]
            }
        }()
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // MARK: - Progress dots
    var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(OnboardingSlide.allCases, id: \.self) { slide in
                Capsule()
                    .fill(currentSlide == slide ? Color.white : Color.white.opacity(0.3))
                    .frame(width: currentSlide == slide ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.35), value: currentSlide)
            }
        }
    }

    // MARK: - Navigation
    func nextSlide() {
        let next = currentSlide.rawValue + 1
        if let slide = OnboardingSlide(rawValue: next) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                currentSlide = slide
            }
        }
    }

    func finish() {
        // Save name
        storedName = nameInput.trimmingCharacters(in: .whitespaces)

        // Add selected suggested habits to SwiftData
        for suggestion in SuggestedHabit.all where selectedHabits.contains(suggestion.id) {
            let habit = Habit(
                title: suggestion.title,
                description: suggestion.description,
                category: suggestion.category,
                frequency: suggestion.frequency,
                isSuggested: true,
                emoji: suggestion.emoji
            )
            modelContext.insert(habit)
        }
        try? modelContext.save()

        withAnimation(.easeInOut(duration: 0.4)) {
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - Shared slide scaffold
struct SlideScaffold<Content: View>: View {
    let emoji: String
    let title: String
    let subtitle: String
    let buttonLabel: String
    let buttonEnabled: Bool
    let onButton: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Emoji
            Text(emoji)
                .font(.system(size: 72))
                .padding(.bottom, 24)

            // Title
            Text(title)
                .font(.custom("Georgia", size: 30))
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Subtitle
            Text(subtitle)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 36)
                .padding(.top, 12)

            // Custom content
            content()
                .padding(.top, 32)

            Spacer()

            // CTA button
            Button(action: onButton) {
                Text(buttonLabel)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(buttonEnabled ? Color(hex: "1A7A6E") : Color.white.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(buttonEnabled ? Color.white : Color.white.opacity(0.15))
                            .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
                    )
            }
            .disabled(!buttonEnabled)
            .padding(.horizontal, 28)
            .padding(.bottom, 52)
            .animation(.spring(response: 0.3), value: buttonEnabled)
        }
    }
}

// MARK: - Slide 1: Welcome
struct WelcomeSlide: View {
    let onNext: () -> Void
    @State private var appeared = false

    var body: some View {
        SlideScaffold(
            emoji: "🌱",
            title: "Welcome to\nYour Recovery",
            subtitle: "This app is your gentle companion through cancer recovery — tracking how you feel, building small habits, and keeping your care team informed.",
            buttonLabel: "Let's get started",
            buttonEnabled: true,
            onButton: onNext
        ) {
            // Feature pills
            VStack(spacing: 10) {
                featurePill(icon: "note.text",          text: "Log symptoms daily")
                featurePill(icon: "checkmark.circle",   text: "Build healthy habits")
                featurePill(icon: "chart.bar.fill",     text: "Track your progress")
                featurePill(icon: "doc.richtext",       text: "Share reports with your doctor")
            }
            .padding(.horizontal, 28)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .animation(.spring(response: 0.6).delay(0.3), value: appeared)
            .onAppear { appeared = true }
        }
    }

    func featurePill(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.15))
                .clipShape(Circle())
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
            Spacer()
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Slide 2: Name
struct NameSlide: View {
    @Binding var nameInput: String
    let onNext: () -> Void
    @FocusState private var focused: Bool

    var body: some View {
        SlideScaffold(
            emoji: "👋",
            title: "What should\nwe call you?",
            subtitle: "Your name will appear on exported reports to share with your care team. You can skip this if you prefer.",
            buttonLabel: nameInput.trimmingCharacters(in: .whitespaces).isEmpty ? "Skip for now" : "Continue",
            buttonEnabled: true,
            onButton: onNext
        ) {
            VStack(spacing: 16) {
                TextField("Your first name…", text: $nameInput)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color(hex: "1A7A6E"))
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 18)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
                    .focused($focused)
                    .submitLabel(.done)
                    .onSubmit { if !nameInput.isEmpty { onNext() } }
                    .padding(.horizontal, 28)

                if !nameInput.isEmpty {
                    Text("Hi \(nameInput.trimmingCharacters(in: .whitespaces))! We're glad you're here 💚")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .animation(.spring(response: 0.4), value: nameInput.isEmpty)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { focused = true }
            }
        }
    }
}

// MARK: - Slide 3: Tour
struct TourSlide: View {
    let onNext: () -> Void
    @State private var appeared = false

    let tabs: [(String, String, String, String)] = [
        ("house.fill",              "Home",    "accentTeal",      "Weekly summaries, symptom trends, and your mood over time."),
        ("note.text",               "Log",     "1E5F8C",          "Log your symptoms and mental wellbeing each day."),
        ("checkmark.circle.fill",   "Habits",  "27AE60",          "Build small daily habits and track your streaks."),
    ]

    var body: some View {
        SlideScaffold(
            emoji: "🗺️",
            title: "Here's what's\ninside",
            subtitle: "Three simple sections — everything you need, nothing you don't.",
            buttonLabel: "Got it!",
            buttonEnabled: true,
            onButton: onNext
        ) {
            VStack(spacing: 12) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                    tourCard(icon: tab.0, title: tab.1, colorHex: tab.2, description: tab.3, delay: Double(index) * 0.12)
                }
            }
            .padding(.horizontal, 28)
            .opacity(appeared ? 1 : 0)
            .onAppear { withAnimation(.spring(response: 0.5).delay(0.2)) { appeared = true } }
        }
    }

    func tourCard(icon: String, title: String, colorHex: String, description: String, delay: Double) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(Color(hex: colorHex))
                .clipShape(RoundedRectangle(cornerRadius: 13))
                .shadow(color: Color(hex: colorHex).opacity(0.4), radius: 6, y: 3)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                Text(description)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay + 0.2), value: appeared)
    }
}

// MARK: - Slide 4: Habits
struct HabitsSlide: View {
    @Binding var selectedHabits: Set<UUID>
    let onNext: () -> Void

    // Show a curated short list — 6 habits
    let featured: [SuggestedHabit] = Array(SuggestedHabit.all.prefix(6))

    var body: some View {
        SlideScaffold(
            emoji: "✨",
            title: "Pick a few\nhabits to start",
            subtitle: "Small steps make a big difference. Choose the ones that feel right for you today — you can always add more later.",
            buttonLabel: selectedHabits.isEmpty ? "Skip for now" : "Add \(selectedHabits.count) habit\(selectedHabits.count == 1 ? "" : "s")",
            buttonEnabled: true,
            onButton: onNext
        ) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(featured) { habit in
                        OnboardingHabitRow(
                            habit: habit,
                            isSelected: selectedHabits.contains(habit.id)
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                if selectedHabits.contains(habit.id) {
                                    selectedHabits.remove(habit.id)
                                } else {
                                    selectedHabits.insert(habit.id)
                                }
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 8)
            }
            .frame(maxHeight: 340)
        }
    }
}

struct OnboardingHabitRow: View {
    let habit: SuggestedHabit
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text(habit.emoji)
                    .font(.system(size: 22))
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(isSelected ? 0.25 : 0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(habit.category.rawValue)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.65))
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(isSelected ? Color.white : Color.clear)
                        .frame(width: 26, height: 26)
                    Circle()
                        .stroke(Color.white.opacity(isSelected ? 0 : 0.5), lineWidth: 2)
                        .frame(width: 26, height: 26)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color(hex: "8E44AD"))
                    }
                }
                .animation(.spring(response: 0.25), value: isSelected)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.white.opacity(0.18) : Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Color.white.opacity(0.5) : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Slide 5: Notifications
struct NotificationsSlide: View {
    @Binding var granted: Bool?
    let onNext: () -> Void
    @State private var requesting = false

    var body: some View {
        SlideScaffold(
            emoji: "🔔",
            title: "Stay gently\nreminded",
            subtitle: "Allow notifications so we can remind you to log symptoms, take medications, and complete your daily habits.",
            buttonLabel: buttonLabel,
            buttonEnabled: !requesting,
            onButton: handleButton
        ) {
            VStack(spacing: 14) {
                notifFeature(icon: "note.text",        text: "Daily symptom check-in reminder")
                notifFeature(icon: "pills.fill",       text: "Medication reminders")
                notifFeature(icon: "checkmark.circle", text: "Habit nudges at your chosen time")

                if granted == false {
                    Text("You can enable notifications later in Settings → Notifications → SymptomTracker")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .padding(.top, 4)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 28)
        }
    }

    var buttonLabel: String {
        switch granted {
        case .none:  return requesting ? "Requesting…" : "Allow notifications"
        case .some(true):  return "Notifications enabled ✓"
        case .some(false): return "Continue without notifications"
        }
    }

    func handleButton() {
        if granted != nil {
            onNext(); return
        }
        requesting = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, _ in
            DispatchQueue.main.async {
                requesting = false
                granted = success
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { onNext() }
            }
        }
    }

    func notifFeature(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(Color.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 9))
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Slide 6: Ready
struct ReadySlide: View {
    let name: String
    let onFinish: () -> Void
    @State private var appeared = false

    var greeting: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "You're all set" : "You're all set, \(trimmed)"
    }

    var body: some View {
        SlideScaffold(
            emoji: "💚",
            title: greeting,
            subtitle: "Recovery takes courage. We're here to help you take it one gentle day at a time.",
            buttonLabel: "Open the app",
            buttonEnabled: true,
            onButton: onFinish
        ) {
            VStack(spacing: 16) {
                affirmation("Every step forward counts, no matter how small.")
                affirmation("You don't have to have it all figured out today.")
                affirmation("This app is here for you — at your own pace.")
            }
            .padding(.horizontal, 28)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
            .animation(.spring(response: 0.6).delay(0.3), value: appeared)
            .onAppear { appeared = true }
        }
    }

    func affirmation(_ text: String) -> some View {
        HStack(spacing: 10) {
            Text("🌿")
                .font(.system(size: 16))
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(14)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 13))
    }
}

// MARK: - Supported Languages
struct AppLanguage: Identifiable, Hashable {
    let id: String          // BCP-47 locale identifier
    let displayName: String
    let flag: String

    static let all: [AppLanguage] = [
        AppLanguage(id: "en",      displayName: "English",    flag: "🇬🇧"),
        AppLanguage(id: "es",      displayName: "Español",    flag: "🇪🇸"),
        AppLanguage(id: "fr",      displayName: "Français",   flag: "🇫🇷"),
        AppLanguage(id: "zh-Hans", displayName: "简体中文",    flag: "🇨🇳"),
        AppLanguage(id: "pt-BR",      displayName: "Português",  flag: "🇧🇷"),
    ]

    /// Best match from the device's preferred language list
    static var systemMatch: AppLanguage {
        for lang in Locale.preferredLanguages {
            if lang.hasPrefix("zh") { return all.first { $0.id == "zh-Hans" }! }
            let code = String(lang.prefix(2))
            if let match = all.first(where: { $0.id == code }) { return match }
        }
        return all[0]
    }
}

// MARK: - Language Selection Slide
struct LanguageSlide: View {
    let onNext: () -> Void
    @AppStorage("selectedLanguage") private var selectedLanguage = ""
    @State private var selected: AppLanguage = AppLanguage.systemMatch

    var body: some View {
        SlideScaffold(
            emoji: "🌍",
            title: "Choose your\nlanguage",
            subtitle: "Choisissez · Elija · 选择语言 · Escolha",
            buttonLabel: "Continue",
            buttonEnabled: true,
            onButton: {
                selectedLanguage = selected.id
                onNext()
            }
        ) {
            VStack(spacing: 10) {
                ForEach(AppLanguage.all) { language in
                    Button {
                        withAnimation(.spring(response: 0.25)) { selected = language }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        HStack(spacing: 14) {
                            Text(language.flag)
                                .font(.system(size: 28))

                            Text(language.displayName)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(selected == language ? Color(hex: "1A7A6E") : .white)

                            Spacer()

                            ZStack {
                                Circle()
                                    .fill(selected == language ? Color.white : Color.clear)
                                    .frame(width: 26, height: 26)
                                Circle()
                                    .stroke(Color.white.opacity(selected == language ? 0 : 0.5), lineWidth: 2)
                                    .frame(width: 26, height: 26)
                                if selected == language {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(Color(hex: "1A7A6E"))
                                }
                            }
                            .animation(.spring(response: 0.25), value: selected)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(selected == language
                                      ? Color.white
                                      : Color.white.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(selected == language
                                        ? Color.clear
                                        : Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 28)
            .onAppear {
                // Pre-select saved language if returning to onboarding
                if !selectedLanguage.isEmpty,
                   let saved = AppLanguage.all.first(where: { $0.id == selectedLanguage }) {
                    selected = saved
                }
            }
        }
    }
}
