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

    /// Done has to do something here.
    ///
    /// It did not: this host passed `onDone: {}`. Eden's words — "the done
    /// button after the rising sun animation doesn't do anything" — and it is
    /// the *second* time the same bug has been found in this file the same way,
    /// after "End and discard". A review host that wires its callbacks to
    /// nothing cannot tell you whether the app's are wired either.
    @State private var done = false

    var body: some View {
        let history = Store().load().history
        let (record, celebration) = example(from: history)
        SummaryScreen(
            record: record,
            celebration: celebration,
            week: Week.progress(history: history),
            card: Cards.all.first,
            onDone: { done = true }
        )
        .overlay {
            if done {
                VStack(spacing: Space.snug) {
                    Text("Done")
                        .font(TypeScale.title)
                        .foregroundStyle(Ink.primary)
                    Text("Review only. The app returns to Home here.")
                        .font(TypeScale.body)
                        .foregroundStyle(Ink.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Surface.night)
            }
        }
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
        case .backup: BackupScreen(data: data, onRestore: { _ in }, onErase: {}, onClose: {}, onExported: {})
        }
    }
}

/// The Live Activity's Lock Screen presentation, at three rest lengths.
///
///     -screen live-activity
///
/// Not the real thing — the system composites, tints and sizes the actual
/// activity — but the layout, the type and the truncation behaviour are this
/// view's, and without this they would be the only design in the port that
/// nobody had ever seen. There is no `Simulator.app` here, so the app cannot be
/// backgrounded and the Lock Screen cannot be reached.
struct LiveActivityReviewHost: View {
    private static let now = Date(timeIntervalSince1970: 1_770_000_000)

    var body: some View {
        VStack(spacing: Space.step) {
            Text("Live Activity · lock screen")
                .font(TypeScale.microLabel)
                .foregroundStyle(Ink.tertiary)

            ForEach(Array(samples.enumerated()), id: \.offset) { _, sample in
                RestActivityLockScreen(attributes: sample, frozenAt: Self.now)
                    .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 22))
                    .frame(maxWidth: .infinity)
            }

            Spacer()
        }
        .padding(Space.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Surface.night)
    }

    /// The two shapes it actually has to hold — a long rest with a long
    /// exercise name and the 20-second myo rest — plus one it never will.
    ///
    /// `nextExercise == nil` is unreachable: `04-rules.md §1` drops trailing
    /// rests, so a rest always has a set after it. It is rendered here anyway
    /// because the type allows it and "unreachable" is a claim about today's
    /// step compiler, not about the view. It degrades to a bare countdown,
    /// which is the right way for it to fail.
    /// A real set out of the compiled program, so the detail line is whatever
    /// the app would actually show.
    private func sample(from key: String, myo: Bool, endsIn: TimeInterval) -> RestAttributes {
        let steps = StepCompiler.build(session: key)
        let sets = steps.compactMap(\.asSet)
        let set = (myo ? sets.last : sets.first { $0.load != nil }) ?? sets.first
        return RestAttributes(
            endsAt: Self.now.addingTimeInterval(endsIn),
            nextExercise: set?.exercise,
            nextDetail: set?.summaryLine,
            isMyo: myo
        )
    }

    private var samples: [RestAttributes] {
        [
            // Built from the real compiled steps, not typed out. The first
            // version of this used hardcoded strings — and they were *correct*,
            // which meant the preview showed a line the code could not produce
            // and hid the bug it existed to find.
            sample(from: "B", myo: false, endsIn: 64),
            sample(from: "B", myo: true, endsIn: 17),
            RestAttributes(
                endsAt: Self.now.addingTimeInterval(45),
                nextExercise: nil,
                nextDetail: nil,
                isMyo: false
            ),
        ]
    }
}

struct ReviewHost: View {
    /// End and Done have to actually do something here.
    ///
    /// They did not. This host passed neither `onFinish` nor `onAbandon`, so
    /// both fell back to `WorkoutHost`'s `= {}` defaults — which meant that
    /// reaching the End dialog the documented way, `-screen set -confirm-end`,
    /// and tapping "End and discard" did **nothing at all**. Same for Done on
    /// the last set. The wiring was right in the app and absent in the tool
    /// built to check it, which is the worst arrangement of the two.
    @State private var ended: String?

    let sessionKey: String?
    let progressOverride: Double?
    let slot: String?
    let reps: Int?
    let step: Int?

    var body: some View {
        let store = Store()
        let data = store.load()
        let key = sessionKey ?? NextSession.proposed(from: data.history)
        if let ended {
            VStack(spacing: Space.snug) {
                Text(ended)
                    .font(TypeScale.title)
                    .foregroundStyle(Ink.primary)
                Text("Review only. The app returns to Home here.")
                    .font(TypeScale.body)
                    .foregroundStyle(Ink.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DawnBackdrop(treatment: .atmospheric, progress: 0.2))
        } else {
            WorkoutHost(
                session: WorkoutSession(
                    sessionKey: key,
                    kg: data.loads?[key] ?? program.first { $0.key == key }?.defaultLoad,
                    history: data.history,
                    store: store
                ),
                onFinish: { ended = "Finished" },
                onAbandon: { ended = "Ended and discarded" },
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
}
