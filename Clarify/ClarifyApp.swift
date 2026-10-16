//
//  ClarifyApp.swift
//  Clarify
//
//  Created by Sebastian Rogat on 10/13/26.
//

import SwiftUI
import SwiftData

@main
struct ClarifyApp: App {
    init() {
        UISegmentedControl.appearance().backgroundColor = .clear
        
        #if os(iOS)
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor { traits in
            if traits.userInterfaceStyle == .dark {
                return UIColor(white: 0.0375, alpha: 1.0)
            } else {
                return .white
            }
        }
        #endif
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
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
