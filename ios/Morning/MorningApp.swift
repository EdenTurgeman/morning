//
//  MorningApp.swift
//
//  W1 direction-prototype entry point.
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
    init() {
        Self.applySeedIfRequested()
    }

    var body: some Scene {
        WindowGroup {
            // The app is Home now. `-screen set` boots straight into a workout
            // for review, and `-screen lab` still opens the W1 direction lab —
            // it is the record of how the look was chosen and stays runnable.
            Group {
                if Self.requestedScreen == "set" {
                    ReviewHost(
                        sessionKey: Self.value(after: "-session"),
                        progressOverride: Self.progressOverride,
                        slot: Self.value(after: "-slot"),
                        reps: Self.value(after: "-reps").flatMap(Int.init),
                        step: Self.value(after: "-step").flatMap(Int.init)
                    )
                } else if Self.requestedScreen == "lab" {
                    PrototypeLabView()
                } else {
                    AppRoot()
                }
            }
            .preferredColorScheme(.dark) // used before sunrise; dark by default
        }
    }

    private static var requestedScreen: String? {
        value(after: "-screen")
    }

    private static var progressOverride: Double? {
        value(after: "-progress").flatMap(Double.init).map { min(1, max(0, $0)) }
    }

    private static func value(after flag: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: flag),
              arguments.indices.contains(index + 1)
        else {
            return nil
        }
        return arguments[index + 1]
    }

    /// `-seed six-months` replaces the stored history with a fixture, so the
    /// screens that read history can be reviewed at empty, one week and six
    /// months without logging six months of workouts.
    ///
    /// `06-data.md §2`: *"You cannot design the Ledger, the year grid or the
    /// history list against nothing, and you should not design them against
    /// three sessions either."*
    private static func applySeedIfRequested() {
        #if DEBUG
            guard let seed = Seed.fromLaunchArguments else { return }
            guard let data = seed.load() else {
                assertionFailure("seed \(seed.rawValue) failed to load")
                return
            }
            do {
                try Store().save(data)
                try Store().saveInProgress(nil)
            } catch {
                // Surfaced rather than swallowed even here: a seeder that
                // silently did nothing sends you looking for a bug in the screen.
                assertionFailure("seeding failed: \(error.localizedDescription)")
            }
        #endif
    }
}

/// The original placeholder remains useful for confirming a minimal project
/// launch while the W1 prototype lab is the active root.
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
