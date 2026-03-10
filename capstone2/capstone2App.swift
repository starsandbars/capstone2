//
//  capstone2App.swift
//  capstone2
//
//  Created by Xiaojing Meng on 3/8/26.
//

import SwiftUI
import SwiftData

@main
struct capstone2App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [SymptomEntry.self, Habit.self])
    }
}


