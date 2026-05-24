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
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .environment(\.locale, locale)
        // 🍏 FIX: Attaching the ID pattern here forces SwiftUI to safely dismantle
        // internal navigation element hierarchies and recompute text metrics across
        // headers and tabs instantly whenever the selected language changes.
        .id(selectedLanguage)
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
