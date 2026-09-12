import Foundation

/* ===========================================================================
 *  EVERYTHING THE APP CAN DO
 *  ---------------------------------------------------------------------------
 *  Extracted out of `AppRoot` so it can be TESTED.
 *
 *  It lived as eight `private func`s on a `View` struct, which meant no test
 *  could reach any of them — starting a session, finishing one, abandoning one,
 *  deleting a record, erasing everything, restoring a backup, changing the
 *  working weight, stamping an export. The model underneath each was covered;
 *  the actions themselves were not, and neither was the wiring from a button to
 *  one of them.
 *
 *  That is not a hypothetical gap. "End and discard" ran an empty closure for
 *  several workstreams — `ReviewHost` never passed `onAbandon`, so the button
 *  reached a `= {}` default. It was found by Eden tapping it, because no tap
 *  reaches this app in the development environment and nothing on screen
 *  distinguishes a wired callback from an unwired one.
 *
 *  Two defences came out of that. `WorkoutHost` no longer defaults its
 *  callbacks, so omitting one is a compile error. And every action lives here,
 *  where a test can call it and check what it did to the store.
 *
 *  `AppRoot` keeps only what is genuinely view state: which sheet is open.
 * ======================================================================== */

/// What the summary needs after a session ends.
struct FinishedSession {
    let record: SessionRecord
    let celebration: Celebration
    let card: Card?
}

@Observable
@MainActor
final class AppModel {
    private(set) var data: AppData
    private(set) var session: WorkoutSession?
    private(set) var finished: FinishedSession?
    /// Surfaced, never swallowed. A session that vanished silently is the one
    /// thing this app must never do.
    var saveError: String?

    private let store: Store
    /// Giving back the idle timer, the audio session and the Lock Screen
    /// countdown. Injected so tests are not driving UIKit.
    private let release: () -> Void

    init(store: Store = Store(), release: @escaping () -> Void = {}) {
        self.store = store
        self.release = release
        data = store.load()
        // Resume before anything is drawn, so an interrupted session never
        // flashes Home on its way back to where it was.
        session = store.loadInProgress().flatMap { saved in
            WorkoutSession(
                restoring: saved,
                kg: store.load().loads?[saved.sessionKey],
                history: store.load().history,
                store: store
            )
        }
    }

    // MARK: - Derived

    var nextKey: String {
        NextSession.proposed(from: data.history)
    }

    func load(for key: String) -> Double? {
        data.loads?[key] ?? program.first { $0.key == key }?.defaultLoad
    }

    // MARK: - The session

    func start(_ key: String) {
        lastAbandon = nil
        session = WorkoutSession(
            sessionKey: key,
            kg: load(for: key),
            history: data.history,
            store: store
        )
    }

    /// Writes EXACTLY ONE history record, then clears the in-progress file.
    ///
    /// Order matters: the record first. Clearing first and then failing to save
    /// loses the session, which `04-rules.md §8` calls the one unacceptable
    /// failure mode.
    func finish() {
        guard let session else { return }
        let record = session.finish()

        var updated = data
        updated.history.append(record)
        // THE STUDY LOG RIDES OUT WITH THE HISTORY.
        //
        // `Deck` writes each answer to its own store the moment it is given,
        // which is where the app reads it from. Folding it into `AppData` here
        // is what puts it in the BACKUP FILE — mastery has never been exported,
        // so a restore used to bring back every workout and none of the study.
        //
        // Here rather than on every answer because this is already the moment
        // the session is committed, and one write that cannot half-happen beats
        // two that can.
        updated.studyAnswers = Deck.answers()
        updated.studySightings = Deck.sightings()
        do {
            try store.save(updated)
            try store.saveInProgress(nil)
            data = updated
        } catch {
            saveError = error.localizedDescription
            return
        }

        self.session = nil
        release()

        // The celebration is computed from the history WITH this session in it,
        // because a lifetime threshold fires by diffing the ledger with and
        // without — it has to be able to see both.
        finished = FinishedSession(
            record: record,
            celebration: Celebrations.forSession(record, history: updated.history),
            // The session's THIRD card, and the only one with no timer to beat.
            // `.open` takes whatever the deck wants most, which is usually the
            // hardest thing in the queue — the right place for it.
            card: Deck.draw(preferring: Deck.intent(forCardNumber: 2))
        )
    }

    /// Nothing is written to history. `04-rules.md §1`: not even sets already
    /// logged.
    func abandon() {
        // WHAT WAS THROWN AWAY, captured before it is. Home says one true thing
        // about it and cannot say anything at all once the session is gone.
        lastAbandon = AbandonNote(reps: session?.log.values.reduce(0, +) ?? 0)
        session?.abandon()
        session = nil
        release()
    }

    /// What Home says after a session was ended and discarded, or nil.
    ///
    /// Ending is the only destructive action in the app and until now the app
    /// said NOTHING about it — `abandon()` cleared the session and Home
    /// appeared, silent, as though the morning had not happened. Eden, asking
    /// for the opposite: *"not make it all sad."*
    ///
    /// Cleared when the next session starts rather than on a timer. It is a
    /// fact about the morning, and the morning moves on when he does.
    private(set) var lastAbandon: AbandonNote?

    func dismissSummary() {
        finished = nil
    }

    // MARK: - The data

    /// Deletion keys off `ts`, the record's identity — never an index, which
    /// would delete the wrong session the moment the list is sorted differently
    /// from the file.
    func delete(_ record: SessionRecord) {
        var updated = data
        updated.history.removeAll { $0.timestamp == record.timestamp }
        commit(updated)
    }

    /// Replaces the history wholesale, after the caller has confirmed the swap.
    ///
    /// BOTH study logs come back — what he answered, and what he was shown —
    /// and mastery and the whole schedule are read back off them. Each is
    /// restored only if the file HAS it: a file with no `studyAnswers` (every
    /// web export, and every backup this app wrote before the log existed) or
    /// no `studySightings` (every backup written before the scheduler) leaves
    /// that log alone rather than wiping it. Absent is not the same as empty,
    /// and the one thing an import must never do is destroy something it has no
    /// replacement for.
    func restore(_ incoming: AppData) {
        if let log = incoming.studyAnswers {
            Deck.restoreAnswers(log)
        }
        if let log = incoming.studySightings {
            Deck.restoreSightings(log)
        }
        commit(incoming)
    }

    func erase() {
        do {
            try store.save(.empty)
            try store.saveInProgress(nil)
            data = .empty
        } catch {
            saveError = error.localizedDescription
        }
    }

    /// The working weight for one session key. Recorded against each finished
    /// session's `kg` as well, so changing it never retroactively rewrites what
    /// was lifted last month — `04-rules.md §4`.
    func setLoad(_ kg: Double, for key: String) {
        var updated = data
        var loads = updated.loads ?? [:]
        loads[key] = kg
        updated.loads = loads
        commit(updated)
    }

    /// Records that a copy left the phone. Never surfaced as an error: the
    /// export itself already succeeded, and losing the timestamp is not worth
    /// an alert over the file the user just saved.
    func stampBackup() {
        var updated = data
        updated.lastBackup = ISO8601DateFormatter().string(from: Date())
        if (try? store.save(updated)) != nil {
            data = updated
        }
    }

    private func commit(_ updated: AppData) {
        do {
            try store.save(updated)
            data = updated
        } catch {
            saveError = error.localizedDescription
        }
    }
}
