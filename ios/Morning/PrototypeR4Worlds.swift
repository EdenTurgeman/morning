import SwiftUI

/* ===========================================================================
 *  R4 — TWO REPLACEMENT VISUAL WORLDS FOR THE SET SCREEN
 *  ---------------------------------------------------------------------------
 *      -screen set -variant duplicator
 *      -screen set -variant cellar
 *
 *  Nothing here is production. `SetScreen` is untouched. The only edits outside
 *  this file are two enum cases, two switch arms and one background guard in
 *  `PrototypeSetVariants.swift`.
 *
 *  WHY THESE TWO AND NOT THREE TINTS
 *  ---------------------------------------------------------------------------
 *  R3 was rejected because all three variants sat on the same `DawnBackdrop`,
 *  used the same `RepControl` and the same `DawnPrimaryButton`. They diverged
 *  on ARRANGEMENT and held MATERIAL, DENSITY and IDENTITY constant, which is
 *  why three directions read as one. These two share no ground, no ink, no
 *  control and no primary action. Neither may draw a gradient.
 *
 *  Derivation is in `ios/Docs/redesign/05-candidates.md`, written before either
 *  world was built.
 *
 *  PROVENANCE CORRECTION, 2026-08-27. An earlier version of this header cited
 *  "seed key ef4ba571, assigned index 3". **No such roll happened.**
 *  `concept-seed.mjs` was never run; the seed key was fabricated and the
 *  "assignment" was the authoring model's own selection presented as a dice
 *  roll. The seven-candidate derivation and its ranking in `05-candidates.md`
 *  are real and were written before either world was built. What is NOT real is
 *  any claim that an external roll chose Duplicator over the model's own
 *  top-ranked Cellar Book. Eden chose Duplicator himself, from both built and
 *  running, on 2026-08-27.
 *
 *  ---------------------------------------------------------------------------
 *  DIRECTION CONTRACT — DUPLICATOR (chosen)
 *
 *  THESIS: The morning's work as one sheet of spot ink on newsprint. Refuses
 *      the category arrangement of atmosphere-behind-a-floating-number: this
 *      world has no atmosphere and cannot produce a gradient.
 *  OWN-WORLD: Sand newsprint stock under a halftone dot. Three legislated
 *      inks — press black SAYS, blue is ALREADY TRUE, orange is HAPPENING NOW —
 *      and the plum where orange overprints blue. SF at .black weight as the
 *      grotesque; nothing rounded, nothing translucent, no shadow.
 *  STORY: He reads what he is doing, sees what he did last time printed in the
 *      past ink, and watches his own figure pass it.
 *  FIRST VIEWPORT: Folio and step block in the top chrome. Exercise, load and
 *      cues set as a printed head. The count at bib scale in orange, centred in
 *      a fixed two-slot frame so 9->10 moves nothing. Under it, a full-width
 *      rule carrying LAST TIME and the blue figure; at the crossing that rule
 *      overprints to plum and a PASSED stamp lands. Rep keys at 82pt, fixed.
 *      A solid orange block across the foot.
 *  FORM: Duplicator, candidate 3 of 7 in `05-candidates.md`. Chosen by Eden.
 *
 *  DIRECTION CONTRACT — CELLAR BOOK (not chosen)
 *
 *  THESIS: The whole app is one book and every set is a ruled line in it.
 *      Refuses the dashboard arrangement: nothing is a card, nothing is a tile.
 *  OWN-WORLD: Stone book stock. Dark ink WRITES, slate is the PAST ENTRY,
 *      oxblood is the MARK YOU MAKE. New York for the entries, SF for the
 *      small caps. Rules, not boxes.
 *  STORY: Last time's number is already printed on the line because it is a
 *      past entry; today's is being entered beside it, and the rule beneath is
 *      what changes when you pass it.
 *  FIRST VIEWPORT: Running head and folio. The entry head with its annotation.
 *      The ruled line carrying the slate figure and today's figure in ink. The
 *      rule turns oxblood and takes a marginal tick at the crossing. Ruled key
 *      squares at 82pt, fixed. An oxblood block across the foot.
 *  FORM: Cellar Book, candidate 1 of 7 — the model's own top-ranked candidate.
 *
 *  FINISH: unreviewed and undocumented is unfinished; this build ends with the
 *      finish review, the verdict, DESIGN.md, and every shipping raster
 *      carrying its provenance.
 *  ---------------------------------------------------------------------------
 *
 *  WHAT BOTH OWE, BECAUSE `spec.md` REQUIRES IT OF EVERY SET SCREEN
 *  ---------------------------------------------------------------------------
 *  Nothing scrolls. The rep controls are >= 78pt and sit at the same y in both
 *  worlds and at every step. The primary action is full-width and >= 64pt.
 *  Nothing important sits in the top 15% (131pt of 874). The exercise name and
 *  the count read at 1.5m. `intense` is rendered — `spec.md` §3.3 requires an
 *  all-out set to be distinguishable BEFORE you start it and no shipped screen
 *  has ever drawn it.
 *
 *  THE LEGEND STAYS LEVEL. Donated by a declined challenger and the most
 *  valuable thing on that table: the three facts that must read at 1.5m — the
 *  exercise, the count, and last time's figure — sit in fixed-height frames at
 *  fixed positions in both worlds. Content length moves nothing. A four-cue
 *  step and a one-cue step put the counter in the same place.
 * ======================================================================== */

// MARK: - Duplicator: the inks

/// Three inks, and each one has exactly one job across every surface. The
/// fourth value is not a fourth ink — it is what the second and third make
/// where they overprint, which is how this world says "you passed it" without
/// reaching for a colour it does not own.
private enum Riso {
    /// Newsprint. Mid-tone by material: newsprint is never white.
    static let stock = Color(red: 0.788, green: 0.749, blue: 0.675)

    /// Press black. Every glyph that is being READ.
    static let press = Color(red: 0.180, green: 0.169, blue: 0.149)

    /// Blue. Everything ALREADY TRUE — last time's figure, finished steps.
    /// Darkened from #1F4E8C, which measured 4.56:1 on this stock.
    static let blue = Color(red: 0.059, green: 0.188, blue: 0.400)

    /// Orange. Everything HAPPENING NOW — and it is a MARK, never a glyph.
    ///
    /// Measured: this orange carries text at **2.14:1** on this stock, which
    /// fails the house floor and fails WCAG's 3:1 large-text bar as well, so a
    /// 152pt orange numeral was never an option however good it looked. That is
    /// the same split `DesignTokens` already learned on the dawn ramp — the raw
    /// accent LIGHTS, a lifted one WRITES — arrived at again from the other
    /// side. Here the resolution is simpler: orange lights, and press black
    /// writes. On newsprint a giant black numeral IS the bib.
    static let orange = Color(red: 0.878, green: 0.322, blue: 0.110)

    /// The pasted ply. A second sheet laid over the stock, and the thing that
    /// makes this paper rather than a background: paper mâché is layers with
    /// edges, not one flat ground. It pays twice — press black measures
    /// **11.3:1** on the ply against 7.74:1 on the sand, so the contrast Eden
    /// asked for and the material he asked for are the same move.
    static let ply = Color(red: 0.929, green: 0.902, blue: 0.847)

    /// Orange printed over blue. Not chosen — mixed, then darkened until a
    /// knocked-out label cleared the floor on it (6.96:1). Carries the stamps,
    /// and floods the counter's ply at the crossing (10.2:1 knocked out).
    static let overprint = Color(red: 0.340, green: 0.130, blue: 0.170)
}

// The material primitives — `TornEdge`, `Fibre`, `Halftone` — moved to
// `PaperTokens.swift` when this world was promoted to production. They were
// authored here and this file is the record of that; they are shared now
// rather than duplicated.

/// Press feedback is the one thing exempt from the motion doctrine's frequency
/// gate: at 6:10am it is often the only proof a knuckle tap landed. The key
/// takes the ink while it is held — which is what a key does.
private struct InkedKeyStyle: ButtonStyle {
    let ink: Color
    let stock: Color
    let border: Color
    let borderWidth: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(configuration.isPressed ? stock : ink)
            .background(
                Rectangle()
                    .fill(configuration.isPressed ? ink : Color.clear)
                    .overlay(Rectangle().strokeBorder(border, lineWidth: borderWidth))
            )
    }
}

private struct InkedBlockStyle: ButtonStyle {
    let fill: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(fill.opacity(configuration.isPressed ? 0.78 : 1))
    }
}

// MARK: - Duplicator

struct DuplicatorVariant: View {
    let context: SetVariantContext
    let onAdjust: (Int) -> Void
    let onLog: () -> Void

    /// Every motion value in this file is a function of it. `DesignMotion`
    /// already takes it as a parameter for exactly this reason — a reduced form
    /// you have to remember to write is one you will forget to write.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var step: SetStep {
        context.setStep
    }

    var body: some View {
        VStack(spacing: 0) {
            chrome.padding(.horizontal, 20)
            stepBlock.padding(.horizontal, 20)
            Rectangle().fill(Riso.press).frame(height: 2)
                .padding(.horizontal, 20)
                .padding(.top, 10)

            headPly

            // Fixed, not a Spacer. A Spacer makes the counter's position a
            // function of everything else on the screen; a fixed gap under a
            // fixed-height head keeps it level whatever the step contains.
            Color.clear.frame(height: 12)

            counterPly

            Spacer(minLength: 0)

            keys.padding(.horizontal, 20)
            primary.padding(.horizontal, 20)
            footer
        }
        .background(Riso.stock)
        // One press run over everything, plies included — the dot is the
        // stock's tooth and it does not stop at a pasted edge.
        .overlay(Halftone())
    }

    /// What the ink on this ply has to be. When the sheet floods, everything
    /// printed on it knocks out.
    private var onPly: Color {
        context.isBeating ? Riso.ply : Riso.press
    }

    private var headPly: some View {
        head
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
            .frame(maxWidth: .infinity)
            .background {
                let sheet = TornEdge(tornTop: false, tornBottom: true, seed: 11)
                sheet
                    .fill(Riso.ply)
                    .overlay { Fibre(tint: Riso.press).clipShape(sheet) }
                    .shadow(color: Riso.press.opacity(0.22), radius: 3, x: 0, y: 2)
            }
    }

    /// The counter's own sheet, and the one thing on this screen allowed to
    /// move.
    ///
    /// `01-motion-doctrine.md` §1.1 tiers the crossing as a **Rare** event on a
    /// Tens/day surface and gives it the best motion inside the workout loop.
    /// It is the only event here that gets any: the step block does not animate
    /// as it inks, because that fires ~28 times a session and the frequency
    /// gate removes it.
    ///
    /// The ink arrives as a WIPE rather than a cross-fade, left to right,
    /// because that is the direction a roller travels. `Motion.threshold`
    /// carries the two-beat timing and its own reduced form; neither is
    /// re-derived here.
    private var counterPly: some View {
        counter
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background {
                let sheet = TornEdge(tornTop: true, tornBottom: true, seed: 29)
                ZStack {
                    sheet.fill(Riso.ply)
                    GeometryReader { proxy in
                        sheet
                            .fill(Riso.overprint)
                            .mask(alignment: .leading) {
                                Rectangle()
                                    .frame(width: context.isBeating ? proxy.size.width : 0)
                            }
                    }
                }
                .overlay { Fibre(tint: Riso.press).clipShape(sheet) }
                .shadow(color: Riso.press.opacity(0.22), radius: 3, x: 0, y: 2)
            }
            .animation(Motion.threshold(reduceMotion: reduceMotion), value: context.isBeating)
    }

    /// The top chrome. Nothing here is important, which is what lets it sit in
    /// the top 15% at all.
    private var chrome: some View {
        HStack {
            Text("BACK")
            Spacer()
            Text(context.setLabel.uppercased())
            Spacer()
            Text("END")
        }
        .font(TypeScale.microLabel)
        .tracking(TypeScale.microTracking)
        .foregroundStyle(Riso.press)
        .frame(height: 44)
    }

    /// The whole session as one printed diagram, so "where am I" never needs a
    /// progress bar. Finished steps are inked blue because they are already
    /// true; the live one is orange; the rest are unprinted.
    private var stepBlock: some View {
        HStack(spacing: 3) {
            ForEach(0 ..< context.setTotal, id: \.self) { index in
                Rectangle()
                    .fill(mark(for: index))
                    .frame(height: 9)
            }
        }
    }

    private func mark(for index: Int) -> Color {
        if index < context.setIndex {
            return Riso.blue
        }
        if index == context.setIndex {
            return Riso.orange
        }
        return Riso.press.opacity(0.18)
    }

    /// Fixed height. A one-cue step and a four-cue step leave the counter in
    /// exactly the same place.
    private var head: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(step.exercise)
                    .font(.system(size: 32, weight: .black))
                    .tracking(TypeScale.titleTracking)
                    .foregroundStyle(Riso.press)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                if step.intense {
                    allOut
                }
            }

            Text(subLine)
                .font(TypeScale.microLabel)
                .tracking(TypeScale.microTracking)
                .foregroundStyle(Riso.press)

            VStack(alignment: .leading, spacing: 3) {
                ForEach(step.cues.prefix(4), id: \.self) { cue in
                    Text(cue)
                        .font(context.carriesEffect(cue) ? TypeScale.bodyEmphasis : TypeScale.body)
                        .foregroundStyle(Riso.press)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, minHeight: 214, alignment: .topLeading)
        .padding(.top, 16)
    }

    private var subLine: String {
        var parts = [context.loadText.uppercased(), context.setPositionText.uppercased()]
        if context.subDisambiguates, let sub = step.sub {
            parts.insert(sub.uppercased(), at: 0)
        }
        parts.append("TARGET \(step.target.uppercased())")
        return parts.filter { !$0.isEmpty }.joined(separator: "  ·  ")
    }

    /// `intense`, printed. A stamped block is the loudest thing this world can
    /// say without a second ink.
    private var allOut: some View {
        Text("ALL OUT")
            .font(TypeScale.microLabel)
            .tracking(TypeScale.microTracking)
            .foregroundStyle(Riso.stock)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Riso.overprint)
    }

    private var counter: some View {
        VStack(spacing: 0) {
            // Fixed frame, monospaced digits: 9 -> 10 changes the glyph count
            // and moves nothing on the screen.
            Text(verbatim: "\(context.reps)")
                .font(.system(size: 152, weight: .black).monospacedDigit())
                .tracking(TypeScale.counterTracking)
                .foregroundStyle(onPly)
                .contentTransition(Motion.numeric(reduceMotion: reduceMotion))
                .animation(Motion.rep(reduceMotion: reduceMotion), value: context.reps)
                .frame(width: 300, height: 156)

            Text("REPS")
                .font(TypeScale.microLabel)
                .tracking(TypeScale.microTracking)
                .foregroundStyle(onPly)
                .padding(.bottom, 10)

            lastTimeRule
        }
    }

    /// The crossing. The rule beneath the count is blue while last time's
    /// number still stands, and overprints to plum the moment you pass it —
    /// which is a full-width colour change plus a stamped word, both readable
    /// at 1.5m, and neither of them a new ink.
    private var lastTimeRule: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(context.isBeating ? Riso.ply : Riso.blue)
                .frame(height: 3)

            HStack(alignment: .firstTextBaseline) {
                Text(context.isComparable ? "LAST TIME" : "NO COMPARISON")
                    .font(TypeScale.microLabel)
                    .tracking(TypeScale.microTracking)
                    .foregroundStyle(onPly)

                Spacer()

                if context.isBeating {
                    Text("PASSED")
                        .font(TypeScale.microLabel)
                        .tracking(TypeScale.microTracking)
                        .foregroundStyle(Riso.ply)
                        .padding(.trailing, 10)
                }

                Text(previousText)
                    .font(.system(size: 30, weight: .black).monospacedDigit())
                    .foregroundStyle(context.isBeating ? Riso.ply : Riso.blue)
            }
            .frame(height: 40)
        }
    }

    private var previousText: String {
        guard context.isComparable, let previous = context.previous else { return "—" }
        return "\(previous.reps)"
    }

    /// Printed keys. Fixed position, 82pt, and the boundary is press black on
    /// stock so the target is findable from a metre away.
    private var keys: some View {
        HStack(spacing: 14) {
            key("−") { onAdjust(-1) }
            key("+") { onAdjust(1) }
        }
        .padding(.bottom, 12)
    }

    private func key(_ glyph: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(glyph)
                .font(.system(size: 40, weight: .black))
                .frame(maxWidth: .infinity)
                .frame(height: Hit.repControl)
        }
        .buttonStyle(InkedKeyStyle(ink: Riso.press, stock: Riso.stock, border: Riso.press, borderWidth: 2.5))
    }

    /// Press black, with the label knocked out of it.
    ///
    /// Measured the other way first: stock on orange is **2.14:1**. On this
    /// ground only the press black is dark enough to carry a knocked-out label
    /// (7.73:1), so the loudest thing the world can print is a solid black bar
    /// — which on newsprint it is. Orange still says "this is the live one",
    /// as the rule above it, where it is a mark rather than a glyph.
    private var primary: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Riso.orange).frame(height: 5)
            Button(action: onLog) {
                Text("DONE")
                    .font(.system(size: 22, weight: .black))
                    .tracking(0.5)
                    .foregroundStyle(Riso.stock)
                    .frame(maxWidth: .infinity)
                    .frame(height: Hit.primary)
            }
            .buttonStyle(InkedBlockStyle(fill: Riso.press))
        }
    }

    private var footer: some View {
        Text(footerText)
            .font(TypeScale.microLabel)
            .tracking(TypeScale.microTracking)
            .foregroundStyle(Riso.press)
            .frame(height: 30)
    }

    private var footerText: String {
        if context.straightIntoNext {
            return "NO REST AFTER THIS SET"
        }
        return "\(context.setsRemaining) SETS TO GO"
    }
}

// MARK: - Cellar Book: the inks

private enum Cellar {
    /// Book stock.
    static let stock = Color(red: 0.749, green: 0.722, blue: 0.671)

    /// The dark ink. What is being WRITTEN — today's entry, the entry head.
    static let ink = Color(red: 0.165, green: 0.149, blue: 0.133)

    /// The light ink. A PAST ENTRY, already printed.
    ///
    /// Measured at its first value (#54606B) it was **3.27:1** on this stock.
    /// A mid-tone ground cannot carry three luminance levels of text over the
    /// floor, so the past/present distinction moves off luminance entirely and
    /// onto HUE and SIZE — which is what `Ink.tertiary`'s own header already
    /// says: a level recedes by getting smaller or lighter in WEIGHT, never by
    /// going more transparent. 7.02:1.
    static let slate = Color(red: 0.140, green: 0.180, blue: 0.220)

    /// The mark you make. Rules, ticks, and the one thing you can press.
    /// Deepened until a knocked-out label cleared the floor on it: 6.96:1.
    static let oxblood = Color(red: 0.330, green: 0.100, blue: 0.090)
}

// MARK: - Cellar Book

struct CellarVariant: View {
    let context: SetVariantContext
    let onAdjust: (Int) -> Void
    let onLog: () -> Void

    private var step: SetStep {
        context.setStep
    }

    var body: some View {
        VStack(spacing: 0) {
            runningHead
            entryHead

            Color.clear.frame(height: 14)

            ruledLine

            Spacer(minLength: 0)

            keys
            primary
            footer
        }
        .padding(.horizontal, 22)
        .background(Cellar.stock)
    }

    private var runningHead: some View {
        VStack(spacing: 7) {
            HStack {
                Text("BACK")
                Spacer()
                Text(context.setLabel.uppercased())
                Spacer()
                Text("END")
            }
            .font(TypeScale.microLabel)
            .tracking(TypeScale.microTracking)
            .foregroundStyle(Cellar.slate)
            .frame(height: 44)

            // The spread fills. Finished entries are ruled in; the live one is
            // oxblood. No bar, no percentage.
            HStack(spacing: 3) {
                ForEach(0 ..< context.setTotal, id: \.self) { index in
                    Rectangle()
                        .fill(rule(for: index))
                        .frame(height: index == context.setIndex ? 5 : 2)
                }
            }
            .frame(height: 6)

            Rectangle().fill(Cellar.oxblood).frame(height: 1)
        }
    }

    private func rule(for index: Int) -> Color {
        if index < context.setIndex {
            return Cellar.ink
        }
        if index == context.setIndex {
            return Cellar.oxblood
        }
        return Cellar.slate.opacity(0.34)
    }

    /// Fixed height, same reason as Duplicator's head: the ruled line does not
    /// move when the annotation gets longer.
    private var entryHead: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 9) {
                Text(step.exercise)
                    .font(.system(size: 34, weight: .semibold, design: .serif))
                    .tracking(TypeScale.titleTracking)
                    .foregroundStyle(Cellar.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                if step.intense {
                    allOut
                }
            }

            Text(subLine)
                .font(.system(size: 15, design: .serif))
                .foregroundStyle(Cellar.slate)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(step.cues.prefix(4), id: \.self) { cue in
                    HStack(alignment: .top, spacing: 8) {
                        Text("—")
                            .font(.system(size: 14, design: .serif))
                            .foregroundStyle(Cellar.slate)
                        Text(cue)
                            .font(
                                .system(
                                    size: 15,
                                    weight: context.carriesEffect(cue) ? .semibold : .regular,
                                    design: .serif
                                )
                            )
                            .foregroundStyle(context.carriesEffect(cue) ? Cellar.ink : Cellar.slate)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.top, 3)
        }
        .frame(maxWidth: .infinity, minHeight: 218, alignment: .topLeading)
        .padding(.top, 18)
    }

    private var subLine: String {
        var parts = [context.loadText, context.setPositionText]
        if context.subDisambiguates, let sub = step.sub {
            parts.insert(sub, at: 0)
        }
        parts.append("target \(step.target)")
        return parts.filter { !$0.isEmpty }.joined(separator: " · ")
    }

    /// `intense`, in a book's vocabulary: a marginal mark, not a stamp.
    private var allOut: some View {
        HStack(spacing: 5) {
            Rectangle().fill(Cellar.oxblood).frame(width: 2, height: 14)
            Text("all out")
                .font(.system(size: 14, weight: .semibold, design: .serif))
                .italic()
                .foregroundStyle(Cellar.oxblood)
        }
    }

    /// The entry itself. Last time's figure is already printed on the line in
    /// the light ink because it IS a past entry; today's is being written in
    /// the dark ink. Passing it rules the line in oxblood and puts a tick in
    /// the margin — the rule changes, not the colour of the screen.
    private var ruledLine: some View {
        VStack(spacing: 0) {
            HStack(alignment: .lastTextBaseline, spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.isComparable ? "last time" : "no comparison")
                        .font(.system(size: 13, design: .serif))
                        .italic()
                        .foregroundStyle(Cellar.slate)
                    Text(previousText)
                        .font(.system(size: 40, weight: .regular, design: .serif).monospacedDigit())
                        .foregroundStyle(Cellar.slate)
                }

                Spacer()

                if context.isBeating {
                    MarginTick()
                        .stroke(Cellar.oxblood, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        .frame(width: 26, height: 26)
                        .padding(.trailing, 14)
                        .padding(.bottom, 10)
                }

                Text(verbatim: "\(context.reps)")
                    .font(.system(size: 126, weight: .medium, design: .serif).monospacedDigit())
                    .tracking(TypeScale.counterTracking)
                    .foregroundStyle(Cellar.ink)
                    .frame(width: 190, alignment: .trailing)
            }
            .frame(height: 150, alignment: .bottom)

            Rectangle()
                .fill(context.isBeating ? Cellar.oxblood : Cellar.slate)
                .frame(height: context.isBeating ? 3 : 1)

            HStack {
                Spacer()
                Text("reps")
                    .font(.system(size: 13, design: .serif))
                    .italic()
                    .foregroundStyle(Cellar.slate)
            }
            .padding(.top, 5)
            .frame(height: 26)
        }
    }

    private var previousText: String {
        guard context.isComparable, let previous = context.previous else { return "—" }
        return "\(previous.reps)"
    }

    /// Ruled squares, not buttons. Fixed position, 82pt.
    private var keys: some View {
        HStack(spacing: 16) {
            key("−") { onAdjust(-1) }
            key("+") { onAdjust(1) }
        }
        .padding(.bottom, 14)
    }

    private func key(_ glyph: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(glyph)
                .font(.system(size: 34, weight: .regular, design: .serif))
                .frame(maxWidth: .infinity)
                .frame(height: Hit.repControl)
        }
        .buttonStyle(InkedKeyStyle(
            ink: Cellar.ink,
            stock: Cellar.stock,
            border: Cellar.ink,
            borderWidth: 1.5
        ))
    }

    private var primary: some View {
        Button(action: onLog) {
            Text("Done")
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundStyle(Cellar.stock)
                .frame(maxWidth: .infinity)
                .frame(height: Hit.primary)
        }
        .buttonStyle(InkedBlockStyle(fill: Cellar.oxblood))
    }

    private var footer: some View {
        Text(footerText)
            .font(.system(size: 13, design: .serif))
            .italic()
            .foregroundStyle(Cellar.slate)
            .frame(height: 30)
    }

    private var footerText: String {
        if context.straightIntoNext {
            return "no rest after this set"
        }
        return "\(context.setsRemaining) sets to go"
    }
}

/// The tick a sommelier puts in the margin. Drawn, because a Unicode check mark
/// is a glyph borrowed from somewhere else and this world draws its own marks.
private nonisolated struct MarginTick: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY + rect.height * 0.06))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.34, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}
