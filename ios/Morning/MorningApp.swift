//
//  MorningApp.swift
//
//  Scaffold entry point. Deliberately almost empty.
//
//  Do NOT build screens from here yet. ios-port/02-design-brief.md §11 sets the
//  order of deliverables and the first one is research, not code:
//
//    1. research-notes.md
//    2. two or three RUNNING direction prototypes of the Set and Rest screens
//    3. agreement with the user on a direction
//    4. a written design system
//    5. the app, Set → Rest → Home → Summary + Daybreak → History → Ledger →
//       Guide → Backup
//
//  Porting screens one by one from the web app is explicitly the wrong move.
//

import SwiftUI

@main
struct MorningApp: App {
    var body: some Scene {
        WindowGroup {
            ScaffoldView()
                .preferredColorScheme(.dark) // used before sunrise; dark by default
        }
    }
}

/// Placeholder. The first agent to reach deliverable 2 replaces this with the
/// direction prototypes. Nothing here is a design decision.
struct ScaffoldView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Morning")
                .font(.largeTitle.weight(.semibold))
            Text("Scaffold only — no screens built yet.")
                .foregroundStyle(.secondary)
            Divider()
            Text("Start at CLAUDE.md, then ios/Agents/00-handoff-log.md.")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview {
    ScaffoldView()
}
