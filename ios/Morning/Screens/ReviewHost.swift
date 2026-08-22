import SwiftUI

/// Boots a workout directly, for review.
///
/// There is no Simulator UI on this machine — only the headless `simctl`
/// runtime — so no tap ever reaches the app. Reaching a given state has to be
/// done at launch, which is what this is for:
///
///     -screen set -session B -step 15 -progress 0.62
///     -screen set -slot 4.0.0 -reps 15
///
/// Not part of the product. `AppRoot` is.
/// Boots the summary for a synthesised finished session, so Daybreak and the
/// tier copy can be looked at without playing a whole workout through a UI that
/// cannot receive taps.
///
///     -screen summary -tier plateau
struct SummaryReviewHost: View {
    let tier: String?

    var body: some View {
        let history = Store().load().history
        let (record, celebration) = example(from: history)
        SummaryScreen(
            record: record,
            celebration: celebration,
            week: Week.progress(history: history),
            card: Cards.all.first,
            onDone: {}
        )
    }

    /// Builds the history a given tier actually needs, rather than faking a
    /// `Celebration` — the point of looking at it is to see what the real tier
    /// logic produces.
    private func example(from history: [SessionRecord]) -> (SessionRecord, Celebration) {
        let slot = StepCompiler.build(session: "A").compactMap(\.asSet).first?.slot ?? "1.0.0"

        func make(_ reps: Int, kg: Double?, ts: Int) -> SessionRecord {
            SessionRecord(
                date: "2026-08-18", sessionKey: "A", log: [slot: reps],
                minutes: 16, reps: reps, timestamp: ts, kg: kg
            )
        }

        switch tier {
        case "plateau":
            let a = make(150, kg: 7.5, ts: 1000)
            let b = make(150, kg: 7.5, ts: 2000)
            let c = make(150, kg: 7.5, ts: 3000)
            return (c, Celebrations.forSession(c, history: [a, b, c]))
        case "record":
            let a = make(100, kg: 7.5, ts: 1000)
            let b = make(200, kg: 7.5, ts: 2000)
            return (b, Celebrations.forSession(b, history: [a, b]))
        case "weight-changed":
            let a = make(150, kg: 7.5, ts: 1000)
            let b = make(120, kg: 10, ts: 2000)
            return (b, Celebrations.forSession(b, history: [a, b]))
        case "first":
            let only = make(163, kg: 7.5, ts: 1000)
            return (only, Celebrations.forSession(only, history: [only]))
        default:
            let latest = history.max { $0.timestamp < $1.timestamp } ?? make(163, kg: 7.5, ts: 1000)
            return (latest, Celebrations.forSession(latest, history: history))
        }
    }
}

struct ReviewHost: View {
    let sessionKey: String?
    let progressOverride: Double?
    let slot: String?
    let reps: Int?
    let step: Int?

    var body: some View {
        let store = Store()
        let data = store.load()
        let key = sessionKey ?? NextSession.proposed(from: data.history)
        WorkoutHost(
            session: WorkoutSession(
                sessionKey: key,
                kg: data.loads?[key] ?? program.first { $0.key == key }?.defaultLoad,
                history: data.history,
                store: store
            ),
            progressOverride: progressOverride,
            slot: slot,
            reps: reps,
            step: step
        )
    }
}
