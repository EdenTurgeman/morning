import SwiftUI
import UIKit

/* ===========================================================================
 *  THE APP
 *  ---------------------------------------------------------------------------
 *  Home, then a workout, then back to Home. Everything the app does so far.
 *
 *  A workout in progress SURVIVES relaunching. `04-rules.md §1` requires it and
 *  `06-data.md §4` stores it separately from the history for exactly this
 *  reason: a crash, a phone call or a force-quit mid-session must cost nothing.
 *  So the first thing this does is look for one and resume it.
 *
 *  Finishing writes the record BEFORE clearing the in-progress file. Clearing
 *  first and then failing to save loses the session, which `04-rules.md §8`
 *  calls the one unacceptable failure mode.
 * ======================================================================== */

struct AppRoot: View {
    @State private var store = Store()
    @State private var data: AppData
    @State private var session: WorkoutSession?
    @State private var saveError: String?
    @State private var destination: HomeDestination?
    /// The session just finished, held so the summary can show it. Cleared when
    /// the summary is dismissed.
    @State private var finished: FinishedSession?

    /// What the summary needs after a session ends.
    struct FinishedSession {
        let record: SessionRecord
        let celebration: Celebration
        let card: Card?
    }

    init() {
        let store = Store()
        _store = State(initialValue: store)
        _data = State(initialValue: store.load())
        // Resume before anything is drawn, so an interrupted session never
        // flashes Home on its way back to where it was.
        _session = State(initialValue: store.loadInProgress().flatMap { saved in
            WorkoutSession(
                restoring: saved,
                kg: store.load().loads?[saved.sessionKey],
                history: store.load().history,
                store: store
            )
        })
    }

    var body: some View {
        Group {
            if let finished {
                SummaryScreen(
                    record: finished.record,
                    celebration: finished.celebration,
                    week: Week.progress(history: data.history),
                    card: finished.card,
                    onDone: { self.finished = nil }
                )
            } else if let session {
                WorkoutHost(session: session, onFinish: finish, onAbandon: abandon)
            } else {
                HomeScreen(
                    nextSession: nextKey,
                    otherSession: nextKey == "A" ? "B" : "A",
                    load: load(for: nextKey),
                    progress: Week.progress(history: data.history),
                    lastSession: data.history.max { $0.timestamp < $1.timestamp },
                    onStart: start,
                    onOpen: { destination = $0 }
                )
                .sheet(item: $destination) { which in
                    reading(which)
                }
            }
        }
        .alert("Could not save", isPresented: .constant(saveError != nil)) {
            Button("OK") { saveError = nil }
        } message: {
            // Surfaced, never swallowed. A session that vanished silently is
            // the one thing this app must never do.
            Text(saveError ?? "")
        }
    }

    @ViewBuilder
    private func reading(_ which: HomeDestination) -> some View {
        let close = { destination = nil }
        switch which {
        case .history:
            HistoryScreen(history: data.history, onDelete: delete, onClose: close)
        case .ledger:
            LedgerScreen(history: data.history, onClose: close)
        case .guide:
            GuideScreen(onClose: close)
        case .backup:
            BackupScreen(data: data, onRestore: restore, onErase: erase, onClose: close)
        }
    }

    /// Replaces the history wholesale, after the caller has confirmed the swap.
    private func restore(_ incoming: AppData) {
        do {
            try store.save(incoming)
            data = incoming
            destination = nil
        } catch {
            saveError = error.localizedDescription
        }
    }

    private func erase() {
        do {
            try store.save(.empty)
            try store.saveInProgress(nil)
            data = .empty
            destination = nil
        } catch {
            saveError = error.localizedDescription
        }
    }

    private var nextKey: String {
        NextSession.proposed(from: data.history)
    }

    private func load(for key: String) -> Double? {
        data.loads?[key] ?? program.first { $0.key == key }?.defaultLoad
    }

    private func start(_ key: String) {
        session = WorkoutSession(
            sessionKey: key,
            kg: load(for: key),
            history: data.history,
            store: store
        )
    }

    private func finish() {
        guard let session else { return }
        let record = session.finish()

        var updated = data
        updated.history.append(record)
        do {
            // Order matters: the record first, the in-progress file second.
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

    private func abandon() {
        session?.abandon()
        session = nil
        release()
    }

    /// Deletion keys off `ts`, the record's identity — never an index, which
    /// would delete the wrong session the moment the list is sorted differently
    /// from the file.
    private func delete(_ record: SessionRecord) {
        var updated = data
        updated.history.removeAll { $0.timestamp == record.timestamp }
        do {
            try store.save(updated)
            data = updated
        } catch {
            saveError = error.localizedDescription
        }
    }

    private func release() {
        UIApplication.shared.isIdleTimerDisabled = false
        Audio.shared.stop()
    }
}
