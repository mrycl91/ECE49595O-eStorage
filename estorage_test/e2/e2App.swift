//
//  e2App.swift
//  e2
//
//  Created by 李京樺 on 2024/1/28.
//

import SwiftUI
import SwiftData

@main
struct e2App: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
           // Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
