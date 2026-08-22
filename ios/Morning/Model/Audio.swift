import AVFoundation
import Foundation

/* ===========================================================================
 *  SOUND
 *  ---------------------------------------------------------------------------
 *  Six cues, synthesised. `05-platform.md §3`.
 *
 *  THE MISTAKE THIS FILE EXISTS TO AVOID, because the same one is available
 *  natively: the web version claimed the equivalent of `.playback` and held a
 *  silent looping element open for the life of the page, which told iOS "this
 *  is what the user is listening to" — so Music stopped and stayed stopped.
 *  Eden reported it as *"working, and not letting me play music"*.
 *
 *  What he asked for, verbatim:
 *
 *      "I want music to seamlessly stop when the app counts down from 5 and
 *       come back after it's done, same with every sound."
 *
 *  So the session is activated AROUND cues and deactivated after, with
 *  `.notifyOthersOnDeactivation`. An always-active session ducks music for the
 *  whole twenty minutes.
 *
 *  And the countdown's last five seconds are SIX SOUNDS THAT MUST BE ONE DUCK.
 *  Six separate activate/deactivate pairs would pump the music five times on
 *  the way to zero. Every cue pushes a shared release deadline forward instead,
 *  and one task deactivates when it finally passes — so the music dips once at
 *  five and returns once after zero.
 *
 *  The count-in ASCENDS on purpose: a rising line reads as tension building
 *  toward "go", a falling one as winding down, which is the opposite of what
 *  you want two seconds before a set. Each step is louder and longer than the
 *  last so you can tell where you are without listening for pitch — the phone
 *  is on the floor and you are face-down over it.
 *
 *  Eden chose countdown reliability over respecting the silent switch, so this
 *  is `.playback` rather than `.ambient`. See `technical-decisions.md`.
 *
 *  The study card is SILENT, deliberately. The app's audio vocabulary is
 *  entirely about time; a card making a noise during the last five seconds of a
 *  countdown would be actively misleading.
 * ======================================================================== */

// MARK: - When the session may be released

/// Tracks the shared release deadline that turns six countdown cues into one
/// duck. Separated from playback so the rule can be tested without a device:
/// what matters is *when* the session is allowed to go, not what it sounded
/// like.
struct DuckWindow {
    /// How long after the last cue the session is held open. Long enough to
    /// bridge one second between countdown ticks, short enough that the music
    /// comes back promptly after zero.
    static let hold: TimeInterval = 1.6

    private(set) var releaseAt: Date?

    /// Every cue pushes the deadline forward rather than opening its own
    /// window.
    mutating func extend(from now: Date = Date(), by hold: TimeInterval = DuckWindow.hold) {
        let candidate = now.addingTimeInterval(hold)
        releaseAt = max(releaseAt ?? candidate, candidate)
    }

    func shouldRelease(at now: Date) -> Bool {
        guard let releaseAt else { return false }
        return now >= releaseAt
    }

    mutating func close() {
        releaseAt = nil
    }
}

// MARK: - The cues

enum Cue {
    /// One of the last five seconds. `second` counts 5 down to 1.
    case countdown(second: Int)
    /// Zero.
    case go
    /// A set was logged.
    case confirm
    /// The counter passed last time's number.
    case beatIt
    /// Session complete, on Daybreak.
    case chime

    /// One note in a cue.
    struct Note {
        let frequency: Double
        let start: TimeInterval
        let duration: TimeInterval
        let gain: Float
    }

    /// C5 · D5 · E5 · G5 · A5 for the count-in — a pentatonic rise, so no two
    /// adjacent ticks form a semitone and the line reads as climbing rather
    /// than as an alarm.
    var notes: [Note] {
        switch self {
        case let .countdown(second):
            let step = max(0, min(4, 5 - second))
            let ladder = [523.25, 587.33, 659.25, 783.99, 880.00]
            return [Note(
                frequency: ladder[step],
                start: 0,
                duration: 0.09 + 0.012 * Double(step),
                gain: 0.22 + 0.05 * Float(step)
            )]

        case .go:
            // Longer and louder than any tick, with the octave below under it
            // so it lands as an arrival rather than a sixth tick.
            return [
                Note(frequency: 1046.50, start: 0, duration: 0.42, gain: 0.50),
                Note(frequency: 523.25, start: 0, duration: 0.42, gain: 0.32),
            ]

        case .confirm:
            // Short, dry, quiet — an acknowledgement, not an event.
            return [Note(frequency: 659.25, start: 0, duration: 0.06, gain: 0.16)]

        case .beatIt:
            // Two rising notes. The visual and the haptic carry this moment;
            // the sound only has to agree with them.
            return [
                Note(frequency: 659.25, start: 0, duration: 0.10, gain: 0.30),
                Note(frequency: 880.00, start: 0.10, duration: 0.16, gain: 0.34),
            ]

        case .chime:
            // A major arpeggio resolving up the octave.
            return [
                Note(frequency: 523.25, start: 0.00, duration: 0.30, gain: 0.34),
                Note(frequency: 659.25, start: 0.12, duration: 0.30, gain: 0.34),
                Note(frequency: 783.99, start: 0.24, duration: 0.34, gain: 0.36),
                Note(frequency: 1046.50, start: 0.36, duration: 0.70, gain: 0.40),
            ]
        }
    }

    var length: TimeInterval {
        notes.map { $0.start + $0.duration }.max() ?? 0
    }
}

// MARK: - Playback

@MainActor
final class Audio {
    static let shared = Audio()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var started = false
    private var window = DuckWindow()
    private var release: Task<Void, Never>?
    /// True once the session is configured and active. Without it `activate()`
    /// re-ran `setCategory` and `setActive` on EVERY cue — five times per rest,
    /// during the animating countdown.
    private var sessionActive = false
    /// Set when `engine.start()` throws, so a cue-per-second countdown does not
    /// retry it a cue-per-second. Cleared by the next `prepare()`.
    ///
    /// This is what actually caused the fault storm. `AVAudioEngine.start()`
    /// activates the session internally, on the main thread, so an engine that
    /// cannot start turns every cue into two hang-risk faults — and the
    /// headless simulator has no audio route at all (`error -10879`), so it
    /// never starts and never stops trying.
    private var engineFailed = false

    /// Set false to keep the app silent without unpicking the call sites.
    var isEnabled = true

    private init() {
        // An interruption — a phone call mid-rest, which the device checklist
        // asks for explicitly — deactivates the session out from under us and
        // stops the engine. Without this, `engineFailed` would latch and the
        // rest of the session would be silent. Clearing both flags means the
        // next cue simply rebuilds everything.
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in Audio.shared.interrupted() }
        }
    }

    private func interrupted() {
        sessionActive = false
        engineFailed = false
        // `started` deliberately stays true. An interruption stops the engine,
        // it does not detach the player — re-running `engine.attach` on a node
        // that is already attached is not something to find out about at 6am.
        // `startEngineIfNeeded` restarts a stopped engine on its own.
    }

    /// Called when a workout opens, so the session is ready long before the
    /// first cue needs it.
    ///
    /// The session work happens OFF the main thread. A full-session run
    /// produced this runtime fault the first time a cue played:
    ///
    ///     AVAudioSession Hang Risk — this method can lead to UI
    ///     unresponsiveness if called on the main thread.
    ///
    /// And the moment it was landing on was the worst available: the last five
    /// seconds of a rest, while `TimelineView(.animation)` drives the ring at
    /// 120Hz. `07-acceptance.md` asks for no dropped frames while a timer runs.
    func prepare() {
        guard !sessionActive else { return }
        sessionActive = true
        engineFailed = false
        // Optimistic, so a burst of cues does not queue a burst of requests —
        // but cleared again if the activation actually failed, because the old
        // synchronous path retried on every cue and losing that would make one
        // bad activation permanent for the whole session.
        Task.detached(priority: .userInitiated) {
            let ok = Self.configureSession()
            if !ok {
                await MainActor.run { Audio.shared.sessionActive = false }
            }
        }
    }

    /// Not `private`: swiftformat wants `private nonisolated` and swiftlint
    /// wants `nonisolated private`, so the pair is unwinnable. Dropping
    /// `private` costs nothing on a final class.
    ///
    /// `AVAudioSession` is not `Sendable`, so this takes the shared instance on
    /// whatever thread it runs on rather than capturing one across isolation.
    nonisolated static func configureSession() -> Bool {
        let session = AVAudioSession.sharedInstance()
        do {
            // `.mixWithOthers` + `.duckOthers` is the whole point: music DIPS,
            // it does not stop. `.playback` alone was the bug Eden reported
            // against the web build — "working, and not letting me play music."
            try session.setCategory(.playback, options: [.mixWithOthers, .duckOthers])
            try session.setActive(true)
            return true
        } catch {
            // A cue that cannot sound must never take a rep with it.
            return false
        }
    }

    func play(_ cue: Cue, now: Date = Date()) {
        guard isEnabled else { return }
        // Session first (idempotent, off-thread), engine second. Starting the
        // engine here keeps a cue that arrives on a cold session audible rather
        // than silent — but ONCE, not once per cue.
        prepare()
        if !engineFailed {
            do {
                try startEngineIfNeeded()
            } catch {
                engineFailed = true
            }
        }
        window.extend(from: now, by: DuckWindow.hold + cue.length)
        scheduleRelease()

        guard let buffer = render(cue) else { return }
        if !player.isPlaying {
            player.play()
        }
        player.scheduleBuffer(buffer, completionHandler: nil)
    }

    /// End of session, or abandoning it. Lets the music back immediately rather
    /// than waiting out the window.
    func stop() {
        release?.cancel()
        release = nil
        window.close()
        deactivate()
    }

    // MARK: - Session

    private func deactivate() {
        player.stop()
        engine.pause()
        // `.notifyOthersOnDeactivation` is what makes the other app's audio
        // come back promptly instead of after its own timeout.
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        sessionActive = false
    }

    /// One task, rescheduled. Each cue pushes the deadline; only the last one
    /// gets to release.
    private func scheduleRelease() {
        release?.cancel()
        guard let releaseAt = window.releaseAt else { return }
        let wait = max(0, releaseAt.timeIntervalSinceNow)
        release = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(wait))
            guard !Task.isCancelled, let self else { return }
            guard window.shouldRelease(at: Date()) else { return }
            window.close()
            deactivate()
        }
    }

    private func startEngineIfNeeded() throws {
        if !started {
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: nil)
            started = true
        }
        if !engine.isRunning {
            try engine.start()
        }
    }

    // MARK: - Synthesis

    /// Sine tones with a short attack and an exponential decay. Baked audio
    /// files were allowed once the bundle-size rule died, but a tone this
    /// simple is more legible as code than as a binary nobody can inspect.
    private func render(_ cue: Cue) -> AVAudioPCMBuffer? {
        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        let rate = format.sampleRate
        let frames = AVAudioFrameCount((cue.length + 0.05) * rate)
        guard frames > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)
        else {
            return nil
        }
        buffer.frameLength = frames

        guard let channels = buffer.floatChannelData else { return nil }
        for channel in 0 ..< Int(format.channelCount) {
            for frame in 0 ..< Int(frames) {
                channels[channel][frame] = 0
            }
        }

        for note in cue.notes {
            let start = Int(note.start * rate)
            let count = Int(note.duration * rate)
            for frame in 0 ..< count {
                let index = start + frame
                guard index < Int(frames) else { break }
                let time = Double(frame) / rate
                // 6ms attack, so a tone never clicks on.
                let attack = min(1.0, time / 0.006)
                let decay = exp(-3.2 * time / note.duration)
                let value = Float(sin(2 * .pi * note.frequency * time)) * note.gain
                    * Float(attack) * Float(decay)
                for channel in 0 ..< Int(format.channelCount) {
                    channels[channel][index] += value
                }
            }
        }
        return buffer
    }
}
