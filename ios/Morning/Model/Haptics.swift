import CoreHaptics
import Foundation

/* ===========================================================================
 *  THE HAPTIC ENGINE
 *  ---------------------------------------------------------------------------
 *  One engine, playing the vocabulary in `DesignHaptics.swift`. The vocabulary
 *  is data and this is the only thing that turns it into sensation, so the
 *  design can be argued about without reading playback code and the playback
 *  can be fixed without touching the design.
 *
 *  `02-design-brief.md §7` calls haptics *"the single biggest felt upgrade
 *  available"*, and it is not an exaggeration: the web build's `buzz()` is a
 *  silent no-op on iOS, so every tap in the shipped app is mute to the hand.
 *
 *  The engine is fragile in ways that only show up in use, and all of them are
 *  handled here rather than at each call site:
 *
 *  · It stops when the system tears it down — a phone call, an interruption,
 *    an audio-session change. `stoppedHandler` drops the cached players so the
 *    next event rebuilds rather than playing into a dead engine.
 *  · It can reset underneath you. `resetHandler` re-prepares.
 *  · Prepared players are cached per pattern, because building one on every rep
 *    is the difference between a detent and a stutter.
 *  · A failed play re-prepares and retries ONCE. Not in a loop: a haptic that
 *    cannot fire is not worth hanging a rep on.
 * ======================================================================== */

@MainActor
final class Haptics {
    static let shared = Haptics()

    private var engine: CHHapticEngine?
    private var players: [String: any CHHapticPatternPlayer] = [:]

    private init() {
        prepare()
    }

    /// Start the engine before the first event, so the first rep of the session
    /// feels like every other one.
    func prewarm() {
        try? engine?.start()
    }

    // MARK: - The vocabulary

    func rep() {
        play("rep", HapticVocabulary.rep)
    }

    func threshold() {
        play("threshold", HapticVocabulary.threshold)
    }

    func logged() {
        play("logged", HapticVocabulary.logged)
    }

    func reveal() {
        play("reveal", HapticVocabulary.reveal)
    }

    func zero() {
        play("zero", HapticVocabulary.zero)
    }

    func complete() {
        play("complete", HapticVocabulary.complete)
    }

    /// `second` counts 5 down to 1. Intensity and sharpness both climb, so the
    /// approach of zero is felt as a ramp rather than counted.
    func countdown(second: Int) {
        play("countdown-\(second)", HapticVocabulary.countdown(second: second))
    }

    // MARK: - Playback

    func play(_ key: String, _ beats: [HapticBeat], retry: Bool = true) {
        guard let engine else {
            prepare()
            if retry {
                play(key, beats, retry: false)
            }
            return
        }

        do {
            try engine.start()
            let player: any CHHapticPatternPlayer
            if let prepared = players[key] {
                player = prepared
            } else {
                let pattern = try CHHapticPattern(events: beats.map(\.event), parameters: [])
                let prepared = try engine.makePlayer(with: pattern)
                players[key] = prepared
                player = prepared
            }
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            prepare()
            if retry {
                play(key, beats, retry: false)
            }
        }
    }

    private func prepare() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            let engine = try CHHapticEngine()
            engine.isAutoShutdownEnabled = true
            engine.resetHandler = { [weak self] in
                Task { @MainActor in self?.prepare() }
            }
            engine.stoppedHandler = { [weak self] _ in
                Task { @MainActor in
                    self?.engine = nil
                    self?.players.removeAll()
                }
            }
            try engine.start()
            self.engine = engine
            players.removeAll()
        } catch {
            engine = nil
            players.removeAll()
        }
    }
}
