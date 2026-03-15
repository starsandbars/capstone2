//
//  ContentView.swift
//  capstone2
//
//  Created by Xiaojing Meng on 3/8/26.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingView()
                .transition(.opacity)
        }
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
#Preview {
    ContentView()
}
