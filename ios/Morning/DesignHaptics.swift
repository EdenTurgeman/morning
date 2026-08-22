import CoreHaptics
import Foundation

// ---------------------------------------------------------------------------
//  THE DESIGN SYSTEM — haptics
//
//  `02-design-brief.md §7` calls this *"the single biggest felt upgrade
//  available"*, and it is not an exaggeration: the web build has no haptics at
//  all on iOS — its `buzz()` is a silent no-op — so every tap in the shipped
//  app is currently mute to the hand.
//
//  §9 sets the discipline: choreographed, never sprinkled, and written down
//  beside the animation timings. That is what this file is. The vocabulary is
//  DATA here, separate from the engine that plays it, so the design can be read
//  and argued about without reading playback code.
//
//  The one requirement that shapes every pattern below: `05-platform.md §3`
//  says passing last time's number must be tellable from an ordinary rep
//  **with the phone face down**. That rules out patterns that differ only in
//  intensity — the hand reads rhythm and sharpness far better than amplitude —
//  which is why the threshold is two events and a rep is one.
//
//  Sound and haptics say different things: sound is for events you might not be
//  looking at, haptics confirm something you just did. The study card is the
//  one place where a haptic is welcome and sound is banned outright.
// ---------------------------------------------------------------------------

/// One event in a pattern. `duration` promotes it from a transient to a
/// continuous event.
struct HapticBeat {
    let time: TimeInterval
    let intensity: Float
    let sharpness: Float
    var duration: TimeInterval?

    init(time: TimeInterval = 0, intensity: Float, sharpness: Float, duration: TimeInterval? = nil) {
        self.time = time
        self.intensity = intensity
        self.sharpness = sharpness
        self.duration = duration
    }

    var event: CHHapticEvent {
        let parameters: [CHHapticEventParameter] = [
            .init(parameterID: .hapticIntensity, value: intensity),
            .init(parameterID: .hapticSharpness, value: sharpness),
        ]
        guard let duration else {
            return CHHapticEvent(eventType: .hapticTransient, parameters: parameters, relativeTime: time)
        }
        return CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: parameters,
            relativeTime: time,
            duration: duration
        )
    }
}

/// The full vocabulary. Every entry names the moment it belongs to, because a
/// haptic that is not tied to one moment is the "generic `.impact(.light)`
/// sprinkled everywhere" the brief specifically rules out.
enum HapticVocabulary {
    /// **Rep increment or decrement.** A detent, not a buzz. Single event, so
    /// the two-event threshold below is unmistakably different from it.
    static let rep = [HapticBeat(intensity: 0.52, sharpness: 0.42)]

    /// **Passing last time's number.** The emotional centre of the app.
    /// Two events 45ms apart: rhythm, not volume, is what the hand can tell
    /// apart with the phone face down on the floor.
    static let threshold = [
        HapticBeat(time: 0, intensity: 0.85, sharpness: 0.62),
        HapticBeat(time: 0.045, intensity: 0.95, sharpness: 0.86),
    ]

    /// **Set logged.** Confirming, with a little weight behind it.
    static let logged = [HapticBeat(intensity: 0.62, sharpness: 0.42)]

    /// **Card reveal.** Soft. Deliberately the quietest thing in the vocabulary
    /// — it is an answer arriving, not an action you took.
    static let reveal = [HapticBeat(intensity: 0.20, sharpness: 0.26)]

    /// **The countdown's last five seconds.** One tick per second, intensity
    /// and sharpness both climbing, so the approach of zero is felt as a ramp
    /// rather than counted.
    ///
    /// `second` is 5 down to 1. The sound cue does the same job for someone not
    /// looking at the phone; this is for someone who is.
    static func countdown(second: Int) -> [HapticBeat] {
        let step = Float(max(0, min(4, 5 - second))) / 4
        return [HapticBeat(intensity: 0.35 + 0.40 * step, sharpness: 0.50 + 0.30 * step)]
    }

    /// **Zero.** Unmistakable: a hard transient with a short continuous decay
    /// under it, so it lands and then releases rather than clicking and
    /// vanishing.
    static let zero = [
        HapticBeat(time: 0, intensity: 0.90, sharpness: 0.62),
        HapticBeat(time: 0.025, intensity: 0.38, sharpness: 0.24, duration: 0.18),
    ]

    /// **Session complete.** Choreographed against Daybreak rather than a
    /// canned success pattern: three rising transients as the light comes up,
    /// then a long soft swell as the sun clears the horizon.
    ///
    /// Defined here because the vocabulary is the deliverable; it is wired to a
    /// screen in W7, whose job is the Daybreak choreography this must land
    /// against.
    static let complete = [
        HapticBeat(time: 0.00, intensity: 0.55, sharpness: 0.30),
        HapticBeat(time: 0.16, intensity: 0.70, sharpness: 0.40),
        HapticBeat(time: 0.34, intensity: 0.88, sharpness: 0.52),
        HapticBeat(time: 0.42, intensity: 0.42, sharpness: 0.18, duration: 0.85),
    ]
}
