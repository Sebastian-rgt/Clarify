//
//  ContentView.swift
//  Clarify
//
//  Created by Sebastian Rogat on 10/13/26.
//

import SwiftUI

enum AppTab: Hashable {
    case lookUp, library, quiz
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .lookUp
    @State private var lookUpFocusRequest = 0

    // Watches every tab tap; tapping Look Up while already on it requests focus.
    private var tabSelection: Binding<AppTab> {
        Binding(
            get: { selectedTab },
            set: { newTab in
                if newTab == selectedTab && newTab == .lookUp {
                    lookUpFocusRequest += 1
                }
                selectedTab = newTab
            }
        )
    }

    var body: some View {
        TabView(selection: tabSelection) {
            Tab("Look Up", systemImage: "text.magnifyingglass", value: .lookUp) {
                LookUpView(focusRequest: lookUpFocusRequest)
            }
            Tab("Library", systemImage: "books.vertical", value: .library) {
                LibraryView()
            }
            Tab("Quiz", systemImage: "questionmark.circle", value: .quiz) {
                QuizView()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }
}

#Preview {
    ContentView()
}
