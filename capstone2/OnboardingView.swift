import SwiftUI
import SwiftData
import UserNotifications

// MARK: - Onboarding slide index
enum OnboardingSlide: Int, CaseIterable {
    case welcome       = 0
    case name          = 1
    case tour          = 2
    case habits        = 3
    case notifications = 4
    case language      = 5
    case ready         = 6
}

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("patientName") private var storedName = ""
    @Environment(\.modelContext) private var modelContext

    @State private var currentSlide: OnboardingSlide = .welcome
    @State private var nameInput = ""
    @State private var selectedHabits: Set<UUID> = []
    @State private var notificationGranted: Bool? = nil
    @State private var slideOffset: CGFloat = 0
    @State private var animateContent = false

    var body: some View {
        ZStack {
            // Background shifts subtly per slide
            slideBackground
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.6), value: currentSlide)

            VStack(spacing: 0) {
                // Progress dots
                progressDots
                    .padding(.top, 60)
                    .padding(.bottom, 8)

                // Slide content
                TabView(selection: $currentSlide) {
                    WelcomeSlide(onNext: nextSlide)
                        .tag(OnboardingSlide.welcome)
                    NameSlide(nameInput: $nameInput, onNext: nextSlide)
                        .tag(OnboardingSlide.name)
                    TourSlide(onNext: nextSlide)
                        .tag(OnboardingSlide.tour)
                    HabitsSlide(selectedHabits: $selectedHabits, onNext: nextSlide)
                        .tag(OnboardingSlide.habits)
                    NotificationsSlide(granted: $notificationGranted, onNext: nextSlide)
                        .tag(OnboardingSlide.notifications)
                    LanguageSlide(onNext: nextSlide)
                        .tag(OnboardingSlide.language)
                    ReadySlide(name: nameInput, onFinish: finish)
                        .tag(OnboardingSlide.ready)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.82), value: currentSlide)
            }
        }
    }

    // MARK: - Background gradient per slide
    var slideBackground: some View {
        let colors: [Color] = {
            switch currentSlide {
            case .welcome:       return [Color(hex: "1A7A6E"), Color(hex: "0D4F47")]
            case .name:          return [Color(hex: "1E5F8C"), Color(hex: "0D3A5C")]
            case .tour:          return [Color(hex: "27AE60"), Color(hex: "145A32")]
            case .habits:        return [Color(hex: "8E44AD"), Color(hex: "4A235A")]
            case .notifications: return [Color(hex: "CA6F1E"), Color(hex: "784212")]
            case .language:      return [Color(hex: "0D3A5C"), Color(hex: "1E5F8C")]
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
            title: NSLocalizedString("onboarding.welcome.title", comment: ""),
            subtitle: NSLocalizedString("onboarding.welcome.subtitle", comment: ""),
            buttonLabel: NSLocalizedString("onboarding.welcome.button", comment: ""),
            buttonEnabled: true,
            onButton: onNext
        ) {
            // Feature pills
            VStack(spacing: 10) {
                featurePill(icon: "note.text",          text: NSLocalizedString("onboarding.welcome.f1", comment: ""))
                featurePill(icon: "checkmark.circle",   text: NSLocalizedString("onboarding.welcome.f2", comment: ""))
                featurePill(icon: "chart.bar.fill",     text: NSLocalizedString("onboarding.welcome.f3", comment: ""))
                featurePill(icon: "doc.richtext",       text: NSLocalizedString("onboarding.welcome.f4", comment: ""))
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
            title: NSLocalizedString("onboarding.name.title", comment: ""),
            subtitle: NSLocalizedString("onboarding.name.subtitle", comment: ""),
            buttonLabel: nameInput.trimmingCharacters(in: .whitespaces).isEmpty ? NSLocalizedString("onboarding.name.skip", comment: "") : NSLocalizedString("onboarding.name.continue", comment: ""),
            buttonEnabled: true,
            onButton: onNext
        ) {
            VStack(spacing: 16) {
                TextField(NSLocalizedString("onboarding.name.placeholder", comment: ""), text: $nameInput)
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
                    Text(String(format: NSLocalizedString("onboarding.name.greeting", comment: ""), nameInput.trimmingCharacters(in: .whitespaces)))
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

    var tabs: [(String, String, String, String)] {[
        ("house.fill",              NSLocalizedString("onboarding.tour.home.title", comment: ""),    "accentTeal",      NSLocalizedString("onboarding.tour.home.desc", comment: "")),
        ("note.text",               NSLocalizedString("onboarding.tour.log.title", comment: ""),     "1E5F8C",          NSLocalizedString("onboarding.tour.log.desc", comment: "")),
        ("checkmark.circle.fill",   NSLocalizedString("onboarding.tour.habits.title", comment: ""),  "27AE60",          NSLocalizedString("onboarding.tour.habits.desc", comment: "")),
    ]}

    var body: some View {
        SlideScaffold(
            emoji: "🗺️",
            title: NSLocalizedString("onboarding.tour.title", comment: ""),
            subtitle: NSLocalizedString("onboarding.tour.subtitle", comment: ""),
            buttonLabel: NSLocalizedString("onboarding.tour.button", comment: ""),
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
    var featured: [SuggestedHabit] { Array(SuggestedHabit.all.prefix(6)) }

    var body: some View {
        SlideScaffold(
            emoji: "✨",
            title: NSLocalizedString("onboarding.habits.title", comment: ""),
            subtitle: NSLocalizedString("onboarding.habits.subtitle", comment: ""),
            buttonLabel: selectedHabits.isEmpty ? NSLocalizedString("onboarding.habits.button.skip", comment: "") : selectedHabits.count == 1 ? NSLocalizedString("onboarding.habits.button.add.one", comment: "") : String(format: NSLocalizedString("onboarding.habits.button.add.many", comment: ""), selectedHabits.count),
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
            title: NSLocalizedString("onboarding.notif.title", comment: ""),
            subtitle: NSLocalizedString("onboarding.notif.subtitle", comment: ""),
            buttonLabel: buttonLabel,
            buttonEnabled: !requesting,
            onButton: handleButton
        ) {
            VStack(spacing: 14) {
                notifFeature(icon: "note.text",        text: NSLocalizedString("onboarding.notif.f1", comment: ""))
                notifFeature(icon: "pills.fill",       text: NSLocalizedString("onboarding.notif.f2", comment: ""))
                notifFeature(icon: "checkmark.circle", text: NSLocalizedString("onboarding.notif.f3", comment: ""))

                if granted == false {
                    Text("onboarding.notif.settings")
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
        case .none:  return requesting ? NSLocalizedString("onboarding.notif.button.requesting", comment: "") : NSLocalizedString("onboarding.notif.button.allow", comment: "")
        case .some(true):  return NSLocalizedString("onboarding.notif.button.enabled", comment: "")
        case .some(false): return NSLocalizedString("onboarding.notif.button.without", comment: "")
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
                if success {
                    // Schedule the 9pm daily symptom reminder immediately
                    SymptomReminderScheduler.schedule()
                }
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
        return trimmed.isEmpty ? NSLocalizedString("onboarding.ready.greeting", comment: "") : String(format: NSLocalizedString("onboarding.ready.greeting.named", comment: ""), trimmed)
    }

    var body: some View {
        SlideScaffold(
            emoji: "💚",
            title: greeting,
            subtitle: NSLocalizedString("onboarding.ready.title", comment: ""),
            buttonLabel: NSLocalizedString("onboarding.ready.button", comment: ""),
            buttonEnabled: true,
            onButton: onFinish
        ) {
            VStack(spacing: 16) {
                affirmation(NSLocalizedString("onboarding.ready.a1", comment: ""))
                affirmation(NSLocalizedString("onboarding.ready.a2", comment: ""))
                affirmation(NSLocalizedString("onboarding.ready.a3", comment: ""))
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
        AppLanguage(id: "pt-BR",   displayName: "Português",  flag: "🇧🇷"),
    ]

    /// Best match from the device's preferred language list
    static var systemMatch: AppLanguage {
        for lang in Locale.preferredLanguages {
            if lang.hasPrefix("zh") { return all.first { $0.id == "zh-Hans" }! }
            if lang.hasPrefix("pt") { return all.first { $0.id == "pt-BR" }! }
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
            title: NSLocalizedString("onboarding.language.title", comment: ""),
            subtitle: NSLocalizedString("onboarding.language.subtitle", comment: ""),
            buttonLabel: NSLocalizedString("onboarding.name.continue", comment: ""),
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
