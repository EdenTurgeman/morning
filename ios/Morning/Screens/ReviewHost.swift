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

    private static func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = .current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
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
            let first = make(150, kg: 7.5, ts: 1000)
            let second = make(150, kg: 7.5, ts: 2000)
            let third = make(150, kg: 7.5, ts: 3000)
            return (third, Celebrations.forSession(third, history: [first, second, third]))
        case "record":
            let earlier = make(100, kg: 7.5, ts: 1000)
            let best = make(200, kg: 7.5, ts: 2000)
            return (best, Celebrations.forSession(best, history: [earlier, best]))
        case "weight-changed":
            let before = make(150, kg: 7.5, ts: 1000)
            let heavier = make(120, kg: 10, ts: 2000)
            return (heavier, Celebrations.forSession(heavier, history: [before, heavier]))
        case "week-complete":
            // Five sessions inside the current week, so the tier that earns a
            // burst is reachable for review at all. Without this there was no
            // way to look at `milestoneBurst`, which is how it went unrendered.
            let calendar = Calendar.current
            let now = Date()
            let week = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            var built: [SessionRecord] = []
            for day in 0 ..< 5 {
                let when = calendar.date(byAdding: .day, value: day, to: week) ?? now
                built.append(
                    SessionRecord(
                        date: Self.dateString(when),
                        sessionKey: day.isMultiple(of: 2) ? "A" : "B",
                        log: [slot: 40 + day],
                        minutes: 17,
                        reps: 40 + day,
                        timestamp: Int(when.timeIntervalSince1970 * 1000),
                        kg: 7.5
                    )
                )
            }
            let last = built[built.count - 1]
            return (last, Celebrations.forSession(last, history: built))
        case "first":
            let only = make(163, kg: 7.5, ts: 1000)
            return (only, Celebrations.forSession(only, history: [only]))
        default:
            let latest = history.max { $0.timestamp < $1.timestamp } ?? make(163, kg: 7.5, ts: 1000)
            return (latest, Celebrations.forSession(latest, history: history))
        }
    }
}

/// Boots one reading screen directly. `-screen history|ledger|guide|backup`
struct ReadingReviewHost: View {
    let which: HomeDestination

    var body: some View {
        let data = Store().load()
        switch which {
        case .history: HistoryScreen(history: data.history, onDelete: { _ in }, onClose: {})
        case .ledger: LedgerScreen(history: data.history, onClose: {})
        case .guide: GuideScreen(onClose: {})
        case .backup: BackupScreen(data: data, onRestore: { _ in }, onErase: {}, onClose: {})
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
            step: step,
            // `-screen set` means the Set screen. The app itself starts on the
            // warm-up; see `WorkoutHost.startAtFirstSet`.
            startAtFirstSet: true
        )
    }
}
