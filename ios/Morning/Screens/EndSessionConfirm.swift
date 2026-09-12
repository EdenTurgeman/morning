import SwiftUI

/* ===========================================================================
 *  ENDING A SESSION, WHICH DESTROYS IT
 *  ---------------------------------------------------------------------------
 *  `04-rules.md §1`: ending discards the whole session, **including sets already
 *  logged**. It is the only destructive action in the app and the only one that
 *  cannot be undone.
 *
 *  It was a system `.alert` with a red "End and discard" button — one tap, at
 *  6:10am, with sweaty hands, beside a "Keep going" of exactly equal weight.
 *
 *  `01-motion-doctrine.md` §3.2 rules this row **Asymmetric**: *"Slow the
 *  deliberate half, snap the release. Hold-to-confirm is available and
 *  appropriate here… Destruction should cost deliberate effort."* This is that
 *  ruling built.
 *
 *  ── the asymmetry, precisely ─────────────────────────────────────────────
 *  · KEEPING is a tap, and it answers instantly. It is the safe half, it is
 *    what he wants nine times in ten, and making it cost anything would be
 *    punishing the common case to guard the rare one.
 *  · ENDING is a hold of `holdSeconds`, and it fills LINEARLY. Not eased: an
 *    eased fill misreports how much longer he has to hold, and this bar is a
 *    promise about exactly that. Same reason the study card's thinking bar is
 *    linear, and the same reason both are read off a clock rather than driven
 *    by `withAnimation` — that exact bug shipped here once and moved nothing.
 *  · LETTING GO SNAPS BACK. The fill does not drain, it is gone. Draining
 *    would suggest the hold is still worth something; it is not, and the snap
 *    is the "snap the release" half of the ruling.
 * ======================================================================== */

struct EndSessionConfirm: View {
    let onEnd: () -> Void
    let onKeepGoing: () -> Void

    /// How long the destructive half costs.
    ///
    /// 1.4 seconds. Long enough that it cannot be a mis-tap with a knuckle —
    /// the failure this exists to prevent — and short enough that someone who
    /// means it is not left wondering whether the control is broken. Apple's
    /// own long-press default is 0.5s, which is a gesture rather than a
    /// deliberation.
    static let holdSeconds: TimeInterval = 1.4

    /// When the current hold began, or nil if he is not holding.
    ///
    /// A DATE, not a fraction being animated. The fill is computed from it
    /// every frame, so if the bar is in the wrong place the number is wrong and
    /// the number can be printed. `RestScreen.filled(at:)` has the long version
    /// of why this file does not use `withAnimation`.
    @State private var holdStart: Date?
    @State private var countdown: Task<Void, Never>?
    @State private var sheetIn = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // The workout is still there, and still readable. A dim rather than
            // a blur: this world is printed, and printed things do not go out
            // of focus — they get something laid over them.
            Paper.press
                .opacity(sheetIn ? 0.55 : 0)
                .ignoresSafeArea()
                .onTapGesture(perform: keepGoing)

            sheet
                .padding(.horizontal, Space.gutter)
                .scaleEffect(sheetIn || reduceMotion ? 1 : 0.97)
                .opacity(sheetIn ? 1 : 0)
        }
        .onAppear {
            withAnimation(Motion.reveal(reduceMotion: reduceMotion)) { sheetIn = true }
            startHoldIfRequested()
        }
        .onDisappear { countdown?.cancel() }
    }

    private var sheet: some View {
        VStack(alignment: .leading, spacing: Space.step) {
            Text("END THIS SESSION?")
                .font(TypeScale.microLabel)
                .tracking(1.8)
                .foregroundStyle(Paper.press)

            // THE COST, IN THE LARGEST TYPE ON THE SHEET.
            //
            // The old alert put this in a system `message`, which is the
            // smallest, greyest text an alert has. It is the whole reason the
            // confirmation exists.
            Text("Nothing will be saved. Not even the sets you have already logged.")
                .font(TypeScale.question)
                .foregroundStyle(Paper.press)
                .fixedSize(horizontal: false, vertical: true)

            holdControl
                .padding(.top, Space.snug)

            Button("Keep going", action: keepGoing)
                .font(TypeScale.bodyEmphasis)
                .foregroundStyle(Paper.press)
                .frame(maxWidth: .infinity, minHeight: Hit.primary)
                .contentShape(Rectangle())
                .buttonStyle(PressLabelStyle())
        }
        .padding(Space.gutter)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            let sheet = TornEdge(tornTop: true, tornBottom: true, seed: 17)
            sheet
                .fill(Paper.ply)
                // THE SHADOW IS CAST BY THE SHEET, NOT BY THE FIBRE ON IT.
                // See `Ply` in `PaperTokens.swift` for the whole reason. Order is the
                // entire fix: shadow the fill, then print the fibre on top.
                .shadow(color: Paper.press.opacity(0.35), radius: 10, x: 0, y: 5)
                .overlay { Fibre().clipShape(sheet) }
        }
    }

    /// The destructive half. Held, not tapped.
    private var holdControl: some View {
        TimelineView(.animation) { context in
            // Split out rather than written inline: as one expression inside
            // the `TimelineView` closure the type checker gave up on it —
            // "generic parameter 'Content' could not be inferred".
            holdBar(filled: fraction(at: context.date))
        }
        // A FIXED HEIGHT, not a minimum. `TimelineView` takes all the space it
        // is offered and the fill `Rectangle` inside it has no intrinsic size,
        // so a `minHeight` let this grow to the whole sheet — a 1200pt
        // destructive button, which is the opposite of the ruling this file
        // exists to implement. Two `frame`s because `maxWidth:height:` is not
        // an overload SwiftUI has.
        .frame(height: Hit.primary)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .gesture(
            // `minimumDistance: 0` so it fires the instant the finger lands
            // rather than after a drag threshold. A `LongPressGesture` would
            // report only the start and the end; this reports the release too,
            // which is the half that has to snap back.
            DragGesture(minimumDistance: 0)
                .onChanged { _ in beginHold() }
                .onEnded { _ in cancelHold() }
        )
        .accessibilityRepresentation {
            Button("End and discard", action: onEnd)
                .accessibilityHint("Discards this session, including sets already logged")
        }
    }

    private func holdBar(filled: Double) -> some View {
        ZStack(alignment: .leading) {
            // The bar fills from the left in the danger red, UNDER the label,
            // so the words stay put while the ground moves beneath them — the
            // same relationship the countdown badge has with its draining rule.
            Rectangle()
                .fill(Paper.danger)
                .scaleEffect(x: filled, y: 1, anchor: .leading)

            Text(filled > 0 ? "KEEP HOLDING" : "HOLD TO END AND DISCARD")
                .font(TypeScale.microLabel)
                .tracking(1.8)
                // Knocked out of the ink once the fill has passed under it,
                // which is this world's one way of saying "this is inked now" —
                // the same move `PaperStamp` and a study card's right answer
                // both make.
                .foregroundStyle(filled > 0.5 ? Paper.ply : Paper.danger)
                .frame(maxWidth: .infinity)
                .animation(Motion.press(reduceMotion: reduceMotion), value: filled > 0.5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay { Rectangle().strokeBorder(Paper.danger, lineWidth: 2) }
    }

    /// 0…1 of the hold. Linear, because it is a promise about how much longer.
    private func fraction(at now: Date) -> Double {
        guard let holdStart else { return 0 }
        return min(1, max(0, now.timeIntervalSince(holdStart) / Self.holdSeconds))
    }

    private func beginHold() {
        guard holdStart == nil else { return }
        holdStart = .now
        Haptics.shared.rep()
        countdown = Task { @MainActor in
            try? await Task.sleep(for: .seconds(Self.holdSeconds))
            guard !Task.isCancelled else { return }
            Haptics.shared.logged()
            onEnd()
        }
    }

    /// SNAP, not drain. A partial hold is worth nothing, and a bar that emptied
    /// slowly would suggest otherwise.
    private func cancelHold() {
        countdown?.cancel()
        countdown = nil
        holdStart = nil
    }

    private func keepGoing() {
        cancelHold()
        onKeepGoing()
    }

    /// `-hold-end` starts the hold by itself, shortly after launch.
    ///
    /// **No synthesised long press reaches this simulator** — plain taps do,
    /// holds do not — so without this the fill is a state nobody can film, and
    /// this project has shipped two animations that did nothing on screen.
    /// Same reason `-demo-crossing`, `-answer-after` and `-expand-after` exist.
    private func startHoldIfRequested() {
        guard ProcessInfo.processInfo.arguments.contains("-hold-end") else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled else { return }
            beginHold()
        }
    }
}
