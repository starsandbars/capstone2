import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("selectedLanguage") private var selectedLanguage = ""

    /// The active locale — uses stored preference if set, otherwise system default.
    var locale: Locale {
        selectedLanguage.isEmpty ? .current : Locale(identifier: selectedLanguage)
    }

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
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
                    Label("Home", systemImage: "house.fill")
                }

            SymptomLogView()
                .tabItem {
                    Label("Log", systemImage: "note.text")
                }

            HabitView()
                .tabItem {
                    Label("Habits", systemImage: "checkmark.circle.fill")
                }
        }
        .tint(Color("accentTeal"))
    }
}
