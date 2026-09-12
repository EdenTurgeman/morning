import SwiftUI

/* ===========================================================================
 *  R3 — THREE DIRECTIONS FOR THE SET SCREEN
 *  ---------------------------------------------------------------------------
 *      -screen set -variant dawn
 *      -screen set -variant far-field
 *      -screen set -variant track
 *
 *  Phase R3 of `ios/Docs/redesign-plan.md`, run on the `prototype` skill.
 *  Nothing in this file is production. `SetScreen` is untouched, and the only
 *  edit outside this file is one routing branch in `MorningApp`.
 *
 *  THE PICKER IS `-variant`, AND THAT IS A DELIBERATE DEVIATION.
 *  ---------------------------------------------------------------------------
 *  The skill's Hard Rule 4 says copy `PICKER.md` verbatim. That file is HTML,
 *  CSS and JS. `redesign-plan.md` R3 overrides it explicitly — this is a
 *  SwiftUI app, and the equivalent already exists and is better: the `-screen`
 *  review hosts plus `scripts/shoot.sh`. That satisfies the rule's *intent* —
 *  one variant at a time, full size, in realistic context, instant switching —
 *  on the right platform. Recorded here and in the handoff log so the next
 *  agent does not read it as an oversight.
 *
 *  THE THREE AXES
 *  ---------------------------------------------------------------------------
 *  Every variant answers the same question — *what am I doing, how did I do it
 *  last time, and how do I record it* — through a DIFFERENT CHANNEL. That is
 *  the divergence, and it is why these are three directions rather than three
 *  tints:
 *
 *      dawn        ATMOSPHERE carries orientation. Colour and the horizon.
 *      far-field   TYPE SIZE carries orientation. Two viewing distances.
 *      track       GEOMETRY carries orientation. Position on a visible spine.
 *
 *  What they share, because `spec.md` requires it of all three: the rep control
 *  never moves between exercises, nothing scrolls, nothing important sits in
 *  the top 15%, rep controls are >= 78pt and the primary action >= 64pt, and
 *  every one of them renders `intense` — which `spec.md` §3.3 requires and no
 *  shipped screen has ever drawn.
 * ======================================================================== */

enum SetVariant: String, CaseIterable {
    case dawn
    case farField = "far-field"
    case track
    // R4. Replacement worlds — see `PrototypeR4Worlds.swift`.
    case duplicator
    case cellar

    /// R3's three all sat on `DawnBackdrop`, which is exactly why they read as
    /// one direction. A replacement world brings its own ground or it is not a
    /// replacement world.
    var ownsBackground: Bool {
        switch self {
        case .dawn, .farField, .track: false
        case .duplicator, .cellar: true
        }
    }

    static var requested: SetVariant? {
        let args = ProcessInfo.processInfo.arguments
        guard let flag = args.firstIndex(of: "-variant"), args.indices.contains(flag + 1) else {
            return nil
        }
        return SetVariant(rawValue: args[flag + 1])
    }
}

// MARK: - Host

/// Drives a variant from a REAL `WorkoutSession` over real persisted history.
///
/// Not fixtures. The prefill, the "last time" lookup, whether the weight is
/// comparable and whether the counter is beating are all the app's own logic —
/// which is the only way the variants can be judged on anything but decoration.
/// A prototype fed hardcoded strings has already lied once on this project: the
/// Live Activity preview's samples were correct while the code they existed to
/// check was not.
struct SetVariantHost: View {
    let variant: SetVariant
    let sessionKey: String?
    let progressOverride: Double?
    let slot: String?
    let reps: Int?
    let step: Int?

    @State private var session: WorkoutSession
    @State private var applied = false

    init(
        variant: SetVariant,
        sessionKey: String?,
        progressOverride: Double?,
        slot: String?,
        reps: Int?,
        step: Int?
    ) {
        self.variant = variant
        self.sessionKey = sessionKey
        self.progressOverride = progressOverride
        self.slot = slot
        self.reps = reps
        self.step = step

        let store = Store()
        let data = store.load()
        let key = sessionKey ?? NextSession.proposed(from: data.history)
        _session = State(
            initialValue: WorkoutSession(
                sessionKey: key,
                kg: data.loads?[key] ?? program.first { $0.key == key }?.defaultLoad,
                history: data.history,
                store: store
            )
        )
    }

    var body: some View {
        Group {
            if let set = session.currentSet {
                let context = SetVariantContext(
                    setStep: set,
                    progress: progressOverride ?? sessionProgress,
                    setLabel: setLabel,
                    setsRemaining: setsRemaining,
                    reps: session.draftReps,
                    previous: session.previous,
                    isComparable: session.previousIsComparable,
                    isBeating: session.isBeatingPrevious,
                    setMarks: setMarks,
                    setIndex: completedSets,
                    setTotal: totalSets,
                    subDisambiguates: repeatedExercises.contains(set.exercise)
                )
                switch variant {
                case .dawn: DawnVariant(context: context, onAdjust: adjust, onLog: log)
                case .farField: FarFieldVariant(context: context, onAdjust: adjust, onLog: log)
                case .track: TrackVariant(context: context, onAdjust: adjust, onLog: log)
                case .duplicator: DuplicatorVariant(context: context, onAdjust: adjust, onLog: log)
                case .cellar: CellarVariant(context: context, onAdjust: adjust, onLog: log)
                }
            } else {
                Text("Not a set step. Try -step <n> on a set.")
                    .font(TypeScale.body)
                    .foregroundStyle(Ink.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background {
            if !variant.ownsBackground {
                DawnBackdrop(treatment: .atmospheric, progress: progressOverride ?? sessionProgress)
            }
        }
        .dynamicTypeSize(.large)
        // The app is `.dark` at the root because it was a night sky. A mid-tone
        // world needs dark status-bar content or the clock is white on sand.
        .preferredColorScheme(variant.ownsBackground ? .light : .dark)
        .onAppear {
            guard !applied else { return }
            applied = true
            Haptics.shared.prewarm()
            if let step {
                session.go(toStep: step)
            } else if let slot {
                session.go(toSlot: slot)
            } else {
                session.goToFirstSet()
            }
            if let reps {
                session.adjustReps(by: reps - session.draftReps)
            }
            scheduleCrossingDemoIfRequested()
        }
    }

    private func adjust(_ delta: Int) {
        session.adjustReps(by: delta)
    }

    /// `-demo-crossing` — pushes the counter past last time's number a beat
    /// after launch, so the crossing can be FILMED.
    ///
    /// This exists because no tap from an agent reaches the simulator, so the
    /// one event in this app that earns motion could not otherwise be observed
    /// at all — only reasoned about, which on this project has twice produced
    /// an animation that compiled, read correctly and did nothing on screen.
    /// It drives the real `adjustReps`, so what gets filmed is the app's own
    /// state change and not a puppet of one.
    private func scheduleCrossingDemoIfRequested() {
        guard ProcessInfo.processInfo.arguments.contains("-demo-crossing"),
              let previous = session.previous,
              session.previousIsComparable
        else {
            return
        }
        session.adjustReps(by: previous.reps - session.draftReps)
        Task {
            try? await Task.sleep(for: .seconds(2))
            session.adjustReps(by: 1)
        }
    }

    /// Advances rather than persisting. A variant is for looking at, and a lab
    /// that writes history would corrupt the very data the next shot reads.
    private func log() {
        Audio.shared.play(.confirm)
        withAnimation(Motion.stage(reduceMotion: false)) {
            session.advance()
            if session.currentSet == nil {
                session.goToFirstSet()
            }
        }
    }

    private var sessionProgress: Double {
        guard session.steps.count > 1 else { return 0 }
        return Double(session.stepIndex) / Double(session.steps.count - 1)
    }

    private var setLabel: String {
        guard let position = session.setPosition else { return "" }
        return "Set \(position.index) / \(position.total)"
    }

    private var setsRemaining: Int {
        session.steps[(session.stepIndex + 1)...].compactMap(\.asSet).count
    }

    private var totalSets: Int {
        session.steps.compactMap(\.asSet).count
    }

    /// Sets FINISHED, so the spine's current mark lands on the set you are
    /// doing rather than the one after it.
    ///
    /// The obvious `totalSets - setsRemaining` is off by one and it renders as
    /// a spine that is always one step ahead of you — which on the variant
    /// whose entire axis is "position is spatial" is not a cosmetic bug, it is
    /// the variant being wrong about the only thing it claims to do.
    private var completedSets: Int {
        max(0, totalSets - setsRemaining - 1)
    }

    private var setMarks: [Double] {
        guard session.steps.count > 1 else { return [] }
        let last = Double(session.steps.count - 1)
        return session.steps.enumerated()
            .filter { $0.element.asSet != nil }
            .map { Double($0.offset) / last }
    }

    private var repeatedExercises: Set<String> {
        var counts: [String: Int] = [:]
        var seen: Set<String> = []
        for step in session.steps {
            guard let set = step.asSet else { continue }
            let block = set.slot.split(separator: ".").first.map(String.init) ?? set.slot
            guard seen.insert("\(block)|\(set.exercise)").inserted else { continue }
            counts[set.exercise, default: 0] += 1
        }
        return Set(counts.filter { $0.value > 1 }.keys)
    }
}

/// Everything a variant is allowed to read. One struct so the three cannot
/// quietly diverge on their inputs and be compared on different data.
struct SetVariantContext {
    let setStep: SetStep
    let progress: Double
    let setLabel: String
    let setsRemaining: Int
    let reps: Int
    let previous: History.PreviousSet?
    let isComparable: Bool
    let isBeating: Bool
    let setMarks: [Double]
    let setIndex: Int
    let setTotal: Int
    let subDisambiguates: Bool

    var palette: DawnPalette {
        DawnPalette(progress: progress)
    }

    /// The load line. `spec.md` §4: loads are plates PER HANDLE and nothing may
    /// try to be clever about it.
    var loadText: String {
        if setStep.bodyweight {
            return "bodyweight"
        }
        guard let load = setStep.load else { return "" }
        return "\(Plates.format(load)) kg"
    }

    var setPositionText: String {
        "set \(setStep.n) of \(setStep.of)"
    }

    /// `spec.md` §3.3: "when there will be no rest after this set".
    var straightIntoNext: Bool {
        setStep.straightIntoNext == true
    }

    /// A cue carries the training effect when the program shouts in it — a
    /// word in caps, or the explicit failure instruction. Same test the shipped
    /// screen uses; copied rather than shared so this file touches nothing.
    func carriesEffect(_ cue: String) -> Bool {
        cue.contains("PAUSE") || cue.contains("FULL") || cue.lowercased().contains("failure")
    }
}

// MARK: - Shared parts

/// `spec.md` §3.3 requires an all-out set to be distinguishable BEFORE you
/// start it. `SetStep.intense` has been compiled into every step since W0 and
/// no shipped screen has ever read it. All three variants render it; each in
/// its own channel, which is itself a test of the three axes.
private struct AllOutMark: View {
    let style: Style

    enum Style { case inline, block }

    var body: some View {
        switch style {
        case .inline:
            Text("ALL OUT")
                .font(TypeScale.microLabel)
                .tracking(TypeScale.microTracking)
                .foregroundStyle(Semantic.urgency)
        case .block:
            HStack(spacing: Space.tight) {
                Rectangle()
                    .fill(Semantic.urgency)
                    .frame(width: 3, height: 15)
                Text("ALL OUT")
                    .font(TypeScale.microLabel)
                    .tracking(TypeScale.microTracking)
                    .foregroundStyle(Semantic.urgency)
            }
        }
    }
}

private struct VariantBadge: View {
    let name: String

    var body: some View {
        Text(name.uppercased())
            .font(.system(size: 9, weight: .semibold))
            .tracking(1.2)
            .foregroundStyle(Ink.tertiary)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Capsule().fill(.black.opacity(0.35)))
    }
}

// MARK: - 1 · DAWN

/// **Axis: atmosphere carries orientation.**
///
/// The existing idea, executed as COMPOSITION rather than as a backdrop. Today
/// the sky is wallpaper behind a top-anchored stack; here the sky is the
/// layout, and the horizon is the datum every element is placed against.
///
///   · Above the horizon — what you are about to do. Dark, quiet, reference.
///   · On the horizon — the number. The brightest band of the sky is where the
///     one thing you must read from 1.5m lives, so the sky lights the counter
///     instead of fighting it.
///   · Below — the commitment. One full-width action.
///
/// **The progress rail is gone.** In this direction it is a redundant second
/// telling of what the sky already says, and `spec.md` §2 is explicit that you
/// should be able to read your progress across the room without reading
/// anything. A rail is reading.
///
/// R2's tracking values are applied here: the counter is 92pt and large display
/// type wants NEGATIVE tracking (`apple-design` §15).
private struct DawnVariant: View {
    let context: SetVariantContext
    let onAdjust: (Int) -> Void
    let onLog: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Nothing important in the top 15%. This band is deliberately only
            // orientation, and it is the quietest thing on screen.
            HStack {
                VariantBadge(name: "dawn")
                Spacer()
                Text(context.setLabel)
                    .font(TypeScale.microLabel)
                    .tracking(TypeScale.microTracking)
                    .foregroundStyle(Ink.tertiary)
            }
            .frame(height: 44)
            .padding(.top, Space.step)

            // ONE void, and it is at the TOP, where it is sky.
            //
            // The first build put this spacer between the cues and the counter
            // and it read as a hole in the middle of the screen. The content
            // is a cluster that belongs to the counter — the thing you read and
            // the thing you act on, together — and the empty region above it is
            // the direction's whole point rather than leftover space.
            Spacer(minLength: Space.step)

            VStack(alignment: .leading, spacing: Space.snug) {
                HStack(alignment: .firstTextBaseline, spacing: Space.snug) {
                    Text(context.setStep.exercise)
                        .font(TypeScale.title)
                        .tracking(TypeScale.titleTracking)
                        .foregroundStyle(Ink.primary)
                    if context.setStep.intense {
                        AllOutMark(style: .inline)
                    }
                }

                Text(factLine)
                    .font(TypeScale.body)
                    .foregroundStyle(Ink.secondary)

                VStack(alignment: .leading, spacing: Space.tight) {
                    ForEach(context.setStep.cues, id: \.self) { cue in
                        Text(cue)
                            .font(context.carriesEffect(cue) ? TypeScale.bodyEmphasis : TypeScale.body)
                            .foregroundStyle(context.carriesEffect(cue) ? Ink.primary : Ink.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.top, Space.tight)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, Space.section)

            // The counter sits at the horizon — the brightest band the sky has.
            RepControl(
                reps: context.reps,
                previous: context.previous,
                isComparable: context.isComparable,
                isBeating: context.isBeating,
                accent: context.palette.accent,
                stepKey: context.setStep.slot,
                onAdjust: onAdjust
            )

            DawnPrimaryButton(title: "Done", treatment: .atmospheric, accent: context.palette.accent) {
                onLog()
            }
            .padding(.top, Space.step)

            Text(footer)
                .font(TypeScale.microLabel)
                .tracking(TypeScale.microTracking)
                .foregroundStyle(Ink.tertiary)
                .padding(.top, Space.snug)
        }
        .padding(.horizontal, Space.gutter)
        .safeAreaPadding(.bottom, Space.gutter)
    }

    private var factLine: String {
        var parts: [String] = []
        if context.subDisambiguates, let sub = context.setStep.sub {
            parts.append(sub)
        }
        parts.append(context.loadText)
        parts.append(context.setPositionText)
        parts.append(context.setStep.target)
        return parts.filter { !$0.isEmpty }.joined(separator: " · ")
    }

    private var footer: String {
        if context.straightIntoNext {
            return "NO REST — STRAIGHT INTO THE NEXT"
        }
        return context.setsRemaining == 1 ? "1 SET TO GO" : "\(context.setsRemaining) SETS TO GO"
    }
}

// MARK: - 2 · FAR FIELD

/// **Axis: viewing distance is the hierarchy.**
///
/// The observation this direction is built on: today almost everything on the
/// Set screen is mid-sized, so *nothing* is comfortably readable at two metres
/// and nothing is comfortably small either. Every element is competing at the
/// same volume, which is the "single hardest problem in the app" restated.
///
/// So pick a distance for every element and commit to it.
///
///   · **FAR FIELD** — readable across a room, one eye open, upside down over a
///     push-up: the exercise, the number, the target. Three things. Enormous.
///   · **NEAR FIELD** — readable only if you pick the phone up: cues, set
///     position, load, superset state. Genuinely small, and grouped into one
///     block that reads as *reference material* rather than as content.
///
/// The bet is that at 6:10am you need three facts and the rest is consulted
/// once per exercise, not once per set. The cost is that the cues are honestly
/// harder to read — that is the tradeoff, not a defect, and it is why this is a
/// direction rather than the answer.
private struct FarFieldVariant: View {
    let context: SetVariantContext
    let onAdjust: (Int) -> Void
    let onLog: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VariantBadge(name: "far field")
                Spacer()
            }
            // 92, not 44. `spec.md` §1: nothing important in the top 15% during
            // a set, because the phone is on the floor and that band is the
            // part your own body occludes when you look down at it. 15% of 874
            // is 131pt, and at 44 the exercise name started at 96pt — the one
            // element in this direction that MUST be readable was in the dead
            // zone. Measured off the render, not guessed.
            .frame(height: 92)
            .padding(.top, Space.step)

            // FAR FIELD ————————————————————————————————
            Text(context.setStep.exercise)
                .font(.system(size: 40, weight: .semibold))
                .tracking(TypeScale.titleTracking)
                .foregroundStyle(Ink.primary)
                .minimumScaleFactor(0.7)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .firstTextBaseline, spacing: Space.snug) {
                Text(context.setStep.target)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Ink.secondary)
                if context.setStep.intense {
                    AllOutMark(style: .inline)
                }
            }
            .padding(.top, Space.tight)

            // The one void, and in this direction it is doing work: it IS the
            // distance between the two tiers. Everything above it is read from
            // two metres; everything below it is read from forty centimetres.
            Spacer(minLength: Space.step)

            // NEAR FIELD ———————————————————————————————
            // One block, one size, deliberately quiet. You lean in for this or
            // you do not read it at all.
            VStack(alignment: .leading, spacing: 3) {
                Text(nearFieldHead)
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(TypeScale.microTracking)
                    .foregroundStyle(Ink.tertiary)

                ForEach(context.setStep.cues, id: \.self) { cue in
                    HStack(alignment: .top, spacing: 5) {
                        Text(context.carriesEffect(cue) ? "▪︎" : "·")
                            .font(.system(size: 11))
                            .foregroundStyle(context.carriesEffect(cue) ? context.palette.accent : Ink.tertiary)
                        Text(cue)
                            .font(.system(size: 12, weight: context.carriesEffect(cue) ? .semibold : .regular))
                            .foregroundStyle(context.carriesEffect(cue) ? Ink.secondary : Ink.tertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(Space.step)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.black.opacity(0.22))
            )
            .padding(.bottom, Space.section)

            // FAR FIELD — the number.
            //
            // `maxWidth: .infinity` because this VStack is `.leading`-aligned
            // and without it the whole rep control sat left of centre, which
            // breaks `spec.md`'s "the rep controls do not move between
            // exercises" the moment you compare it with any other direction.
            RepControl(
                reps: context.reps,
                previous: context.previous,
                isComparable: context.isComparable,
                isBeating: context.isBeating,
                accent: context.palette.accent,
                stepKey: context.setStep.slot,
                onAdjust: onAdjust
            )
            .frame(maxWidth: .infinity)

            DawnPrimaryButton(title: "Done", treatment: .atmospheric, accent: context.palette.accent) {
                onLog()
            }
            .padding(.top, Space.step)

            Text(context.straightIntoNext
                ? "NO REST — STRAIGHT INTO THE NEXT"
                : "\(context.setLabel.uppercased())  ·  \(context.setsRemaining) TO GO")
                .font(.system(size: 10, weight: .semibold))
                .tracking(TypeScale.microTracking)
                .foregroundStyle(Ink.tertiary)
                .frame(maxWidth: .infinity)
                .padding(.top, Space.snug)
        }
        .padding(.horizontal, Space.gutter)
        .safeAreaPadding(.bottom, Space.gutter)
    }

    private var nearFieldHead: String {
        var parts: [String] = []
        if let sub = context.setStep.sub {
            parts.append(sub.uppercased())
        }
        parts.append(context.loadText.uppercased())
        parts.append(context.setPositionText.uppercased())
        return parts.filter { !$0.isEmpty }.joined(separator: "  ·  ")
    }
}

// MARK: - 3 · TRACK

/// **Axis: geometry carries orientation.**
///
/// Where am I in the session, answered spatially instead of numerically. A
/// fixed spine down the left edge carries one mark per set — filled behind you,
/// hollow ahead, and the current one is a wide bar. Sets in the same block are
/// grouped, so the SHAPE of the session is visible: three push-ups, a superset
/// of six, the myo block, the finisher.
///
/// The claim: "Set 7 / 14" is a number you have to read and convert. A position
/// on a spine is a thing you see. It also makes Back legible — you can see what
/// you would be going back to.
///
/// **This is not a list of the workout**, which `spec.md` §1 forbids outright.
/// It carries no exercise names and nothing scrolls: fourteen marks always fit
/// on a fixed spine, and it shows position only. One screen still shows exactly
/// one thing to do.
///
/// The cost is honest: the spine takes ~28pt of a 402pt-wide screen permanently,
/// for information you need occasionally rather than constantly.
private struct TrackVariant: View {
    let context: SetVariantContext
    let onAdjust: (Int) -> Void
    let onLog: () -> Void

    private let spineWidth: CGFloat = 28

    var body: some View {
        HStack(alignment: .top, spacing: Space.step) {
            spine
                .frame(width: spineWidth)

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    VariantBadge(name: "track")
                    Spacer()
                    if context.straightIntoNext {
                        Text("NO REST AFTER")
                            .font(TypeScale.microLabel)
                            .tracking(TypeScale.microTracking)
                            .foregroundStyle(context.palette.accent)
                    }
                }
                .frame(height: 44)
                .padding(.top, Space.step)

                Spacer(minLength: Space.step)

                if context.setStep.intense {
                    AllOutMark(style: .block)
                        .padding(.bottom, Space.tight)
                }

                Text(context.setStep.exercise)
                    .font(TypeScale.title)
                    .tracking(TypeScale.titleTracking)
                    .foregroundStyle(Ink.primary)
                    .minimumScaleFactor(0.75)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                // Two lines on purpose, not one wrapped one. As a single
                // joined string this broke as "… set 1 of 3 · 8–" / "15 reps",
                // splitting the target range across a line break — the one
                // number on the line you actually have to act on.
                Text(setupLine)
                    .font(TypeScale.body)
                    .foregroundStyle(Ink.secondary)
                    .padding(.top, 2)

                Text(context.setStep.target)
                    .font(TypeScale.bodyEmphasis)
                    .foregroundStyle(Ink.secondary)

                VStack(alignment: .leading, spacing: Space.tight) {
                    ForEach(context.setStep.cues, id: \.self) { cue in
                        Text(cue)
                            .font(context.carriesEffect(cue) ? TypeScale.bodyEmphasis : TypeScale.body)
                            .foregroundStyle(context.carriesEffect(cue) ? Ink.primary : Ink.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.top, Space.step)
                .padding(.bottom, Space.section)

                RepControl(
                    reps: context.reps,
                    previous: context.previous,
                    isComparable: context.isComparable,
                    isBeating: context.isBeating,
                    accent: context.palette.accent,
                    stepKey: context.setStep.slot,
                    onAdjust: onAdjust
                )

                DawnPrimaryButton(title: "Done", treatment: .atmospheric, accent: context.palette.accent) {
                    onLog()
                }
                .padding(.top, Space.step)
            }
        }
        .padding(.leading, Space.step)
        .padding(.trailing, Space.gutter)
        .safeAreaPadding(.bottom, Space.gutter)
    }

    /// One mark per set, grouped by block. Filled behind, hollow ahead.
    private var spine: some View {
        GeometryReader { proxy in
            let total = max(context.setTotal, 1)
            let gap: CGFloat = 5
            let height = (proxy.size.height - gap * CGFloat(total - 1)) / CGFloat(total)

            VStack(spacing: gap) {
                ForEach(0 ..< total, id: \.self) { index in
                    let isDone = index < context.setIndex
                    let isNow = index == context.setIndex

                    RoundedRectangle(cornerRadius: 3)
                        .fill(fill(isDone: isDone, isNow: isNow))
                        .frame(width: isNow ? spineWidth : 8, height: max(height, 4))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.vertical, Space.section)
    }

    private func fill(isDone: Bool, isNow: Bool) -> Color {
        if isNow {
            return context.palette.accent
        }
        if isDone {
            return context.palette.accent.opacity(0.42)
        }
        return Ink.hairline
    }

    private var setupLine: String {
        var parts: [String] = []
        if let sub = context.setStep.sub {
            parts.append(sub)
        }
        parts.append(context.loadText)
        parts.append(context.setPositionText)
        return parts.filter { !$0.isEmpty }.joined(separator: " · ")
    }
}
