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
