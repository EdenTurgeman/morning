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
            card: Deck.draw()
        )
    }

    /// Nothing is written to history. `04-rules.md §1`: not even sets already
    /// logged.
    func abandon() {
        session?.abandon()
        session = nil
        release()
    }

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
    func restore(_ incoming: AppData) {
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
