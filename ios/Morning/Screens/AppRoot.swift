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
    /// Every action the app can perform lives in `AppModel`, where a test can
    /// reach it. See that file's header — this view used to own eight private
    /// methods that nothing could call.
    @State private var model = AppModel(release: {
        UIApplication.shared.isIdleTimerDisabled = false
        Audio.shared.stop()
        RestActivityController.shared.end()
    })
    @State private var destination: HomeDestination?

    var body: some View {
        Group {
            if let finished = model.finished {
                SummaryScreen(
                    record: finished.record,
                    celebration: finished.celebration,
                    week: Week.progress(history: model.data.history),
                    card: finished.card,
                    onDone: model.dismissSummary
                )
            } else if let session = model.session {
                WorkoutHost(session: session, onFinish: model.finish, onAbandon: model.abandon)
            } else {
                HomeScreen(
                    nextSession: model.nextKey,
                    otherSession: model.nextKey == "A" ? "B" : "A",
                    load: model.load(for: model.nextKey),
                    progress: Week.progress(history: model.data.history),
                    lastSession: model.data.history.max { $0.timestamp < $1.timestamp },
                    onStart: model.start,
                    onOpen: { destination = $0 },
                    onLoadChange: { model.setLoad($0, for: model.nextKey) }
                )
                .sheet(item: $destination) { which in
                    reading(which)
                }
            }
        }
        .onAppear { autorunIfAsked() }
        .alert("Could not save", isPresented: .constant(model.saveError != nil)) {
            Button("OK") { model.saveError = nil }
        } message: {
            // Surfaced, never swallowed. A session that vanished silently is
            // the one thing this app must never do.
            Text(model.saveError ?? "")
        }
    }

    @ViewBuilder
    private func reading(_ which: HomeDestination) -> some View {
        let close = { destination = nil }
        switch which {
        case .history:
            HistoryScreen(history: model.data.history, onDelete: model.delete, onClose: close)
        case .ledger:
            LedgerScreen(history: model.data.history, onClose: close)
        case .guide:
            GuideScreen(onClose: close)
        case .backup:
            BackupScreen(
                data: model.data,
                onRestore: { model.restore($0); destination = nil },
                onErase: { model.erase(); destination = nil },
                onClose: close,
                onExported: model.stampBackup
            )
        }
    }

    /// `-autorun` plays a whole session from Home, hands-free, and it starts
    /// here rather than inside the workout so the smoke test covers the real
    /// entry path — Home, start, warm-up, every set and rest, finish, Daybreak,
    /// Summary. `07-acceptance.md` asks for "a full session of A and a full
    /// session of B, start to finish, zero glitches", and with no Simulator UI
    /// on this machine there was no way to ask until now.
    private func autorunIfAsked() {
        let args = ProcessInfo.processInfo.arguments
        guard args.contains("-autorun"), model.session == nil, model.finished == nil else { return }
        let key = args.firstIndex(of: "-session")
            .flatMap { args.indices.contains($0 + 1) ? args[$0 + 1] : nil } ?? model.nextKey
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            guard model.session == nil else { return }
            model.start(key)
        }
    }
}
