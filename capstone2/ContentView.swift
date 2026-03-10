//
//  ContentView.swift
//  capstone2
//
//  Created by Xiaojing Meng on 3/8/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView{
            HomeView()
                .tabItem{
                    Label("Home", systemImage: "house.fill")
                }
            SymptomLogView()
                .tabItem{
                    Label("Log", systemImage: "note.text")
                }
            HabitView()
                .tabItem{Label("Habits", systemImage: "checkmark.circle.fill")}

        }
    }
}

#Preview {
    ContentView()
}
