import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("selectedLanguage") private var selectedLanguage = ""

    /// Computed property generating a standard Locale struct matched to choice patterns
    var locale: Locale {
        selectedLanguage.isEmpty ? .current : Locale(identifier: selectedLanguage)
    }

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
                    // Forces SwiftUI to rebuild MainTabView when language changes,
                    // refreshing all localized strings and text metrics instantly.
                    // Only applied post-onboarding — attaching this during onboarding
                    // would tear down OnboardingView and reset it to slide 1.
                    .id(selectedLanguage)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .environment(\.locale, locale)
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("tab.home", systemImage: "house.fill")
                }

            SymptomLogView()
                .tabItem {
                    Label("tab.log", systemImage: "note.text")
                }

            HabitView()
                .tabItem {
                    Label("tab.habits", systemImage: "checkmark.circle.fill")
                }
        }
        .tint(Color("accentTeal"))
    }
}
