//
//  QuizView.swift
//  Clarify
//
//  Created by Sebastian Rogat on 10/13/26.
//

import SwiftUI

struct QuizView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Nothing to Quiz Yet",
                systemImage: "questionmark.circle",
                description: Text("Save a few lookups and your quiz will show up here.")
            )
            .navigationTitle("Quiz")
        }
    }
}

#Preview {
    QuizView()
}
