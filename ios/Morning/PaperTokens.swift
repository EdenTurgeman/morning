import SwiftUI

/* ===========================================================================
 *  THE DESIGN SYSTEM — PAPER
 *  ---------------------------------------------------------------------------
 *  The replacement visual world, chosen by Eden on 2026-08-27 from two running
 *  Set screens. Derivation: `ios/Docs/redesign/05-candidates.md` (candidate 3,
 *  "Duplicator"). Prototype of record: `PrototypeR4Worlds.swift`, frozen.
 *
 *  Spot ink on newsprint, built up as pasted plies. Club newsletters, race
 *  bibs, mimeographed training schedules — the one graphic tradition where a
 *  huge cheap numeral is the hero, and a world that CANNOT PRODUCE A GRADIENT.
 *  That last part is not a stylistic preference; it is the structural fix for
 *  why R3 was rejected. If a gradient appears in this world, the world is gone.
 *
 *  WHAT THIS REPLACES
 *  ---------------------------------------------------------------------------
 *  `DesignTokens.swift`'s `DawnPalette`, `Ink`, `Surface`, `Control` and
 *  `Scrim` were all functions of a night sky. They stay in the file while the
 *  surfaces are converted one at a time; a surface is converted when it reaches
 *  for `Paper` and nothing else.
 *
 *  WHAT SURVIVES FROM IT, UNCHANGED
 *  ---------------------------------------------------------------------------
 *  `Hit` (68/82/64pt targets), `Space`, and the TRACKING values Eden named
 *  unprompted as the thing he liked: `counterTracking -1.5`, `titleTracking
 *  -0.4`, `microTracking 0.6`. Weight-led hierarchy survives too. This world
 *  changes the ground and the ink, not the typographic discipline.
 *
 *  EVERY FIGURE BELOW WAS MEASURED ON A RENDERED SIMULATOR FRAME
 *  ---------------------------------------------------------------------------
 *  with `ios/Tools/measure-contrast.py`, never calculated and never judged by
 *  eye. Both have already lied on this project. Note that the tool's ZONE ROWS
 *  are tuned to the old layout — check the printed row ranges against the frame
 *  before quoting it, as its own footer says.
 * ======================================================================== */

// MARK: - The inks

/// Three inks, and each has exactly one job on every surface. A fourth value
/// exists but is not a fourth ink: it is what two of them make where they
/// overprint, which is how this world says "you passed it" without reaching for
/// a colour it does not own.
enum Paper {
    // MARK: Grounds

    /// Newsprint. Mid-tone by material — newsprint is never white, which is how
    /// this world satisfies `04-direction-reset.md` §2.1 without trying.
    static let stock = Color(red: 0.788, green: 0.749, blue: 0.675)

    /// The pasted ply. A second sheet laid over the stock.
    ///
    /// This is the whole "paper mâché" idea in one token: the material is
    /// LAYERS WITH EDGES, not a texture on a flat ground. It also pays for
    /// itself twice — press black measures **11.35:1** on the ply against
    /// 7.74:1 on the stock — so the contrast and the material are one decision.
    static let ply = Color(red: 0.929, green: 0.902, blue: 0.847)

    // MARK: Inks

    /// Press black. Every glyph that is being READ, and the primary action's
    /// block. 7.74:1 on stock, 11.35:1 on ply.
    static let press = Color(red: 0.180, green: 0.169, blue: 0.149)

    /// Blue. Everything ALREADY TRUE — last time's figure, finished steps,
    /// history that has been logged.
    ///
    /// Darkened from a first value of #1F4E8C, which measured 4.56:1 on stock.
    /// 7.02:1 now.
    static let blue = Color(red: 0.059, green: 0.188, blue: 0.400)

    /// Orange. Everything HAPPENING NOW — **and it is a MARK, never a glyph.**
    ///
    /// Measured, this orange carries text at **2.14:1** on stock: under the
    /// house floor and under WCAG's 3:1 large-text bar too, so a 152pt orange
    /// numeral was never available however good it looked. That is the same
    /// split `DawnPalette` had already learned from the other side — the raw
    /// accent LIGHTS and a lifted one WRITES. Here it resolves more simply:
    /// **orange lights, press black writes.** On newsprint a giant black
    /// numeral is the bib.
    static let orange = Color(red: 0.878, green: 0.322, blue: 0.110)

    /// Orange printed over blue. Not chosen — mixed, then deepened until a
    /// knocked-out label cleared the floor on it. Carries the stamps, and
    /// floods the counter's ply at the crossing: **10.2:1** knocked out in ply.
    static let overprint = Color(red: 0.340, green: 0.130, blue: 0.170)

    /// Destruction, and "you have no copy of this".
    ///
    /// The one ink outside the three-job law, and it earns the exception:
    /// deleting a session must never be confusable with the crossing, and the
    /// overprint already owns the crossing. A pure red against the overprint's
    /// plum, measured at 6.77:1 on stock. They never appear on the same
    /// surface, which is the other half of why this is safe.
    static let danger = Color(red: 0.450, green: 0.050, blue: 0.050)

    /// A hairline that is furniture, never a glyph.
    static let rule = Color(red: 0.180, green: 0.169, blue: 0.149).opacity(0.30)
}

// MARK: - Type, in this world's voice

/// The paper world's type roles.
///
/// `TypeScale` still owns the tracking constants and the reading-screen styles;
/// this adds the display voice, which is SF at `.black`. A grotesque cut at
/// poster weight is what a duplicator prints, and SF's heaviest weights are a
/// credible one — which matters, because the brand commitment is to keep SF.
enum PaperType {
    /// The bib. The number you read from 1.5m.
    static func counter(_ size: CGFloat = 152) -> Font {
        .system(size: size, weight: .black).monospacedDigit()
    }

    /// The exercise name, and any surface's headline.
    static let title = Font.system(size: 32, weight: .black)

    /// A figure that is not the hero — last time's number, a total.
    static func figure(_ size: CGFloat = 30) -> Font {
        .system(size: size, weight: .black).monospacedDigit()
    }

    /// Body and cue text.
    static let body = Font.callout
    static let bodyEmphasis = Font.callout.weight(.semibold)

    /// The all-caps micro-label. Takes `TypeScale.microTracking`.
    static let micro = Font.caption.weight(.semibold)
}

// MARK: - The material

/// A sheet with torn edges. Paper mâché is pasted layers, and a layer is only
/// legible where its edge is.
///
/// The jitter is **deterministic** — hashed from the segment index, never
/// random. A torn edge recomputed per frame shimmers, and on a screen that is
/// otherwise completely still that reads as a rendering fault rather than as
/// paper. Pass a different `seed` per sheet so two plies do not tear alike.
nonisolated struct TornEdge: Shape {
    var tornTop = false
    var tornBottom = true
    var amplitude: CGFloat = 3.5
    var seed: UInt64 = 1

    private func jitter(_ index: Int) -> CGFloat {
        var x = UInt64(bitPattern: Int64(index)) &+ seed &* 0x9E37_79B9_7F4A_7C15
        x ^= x >> 30
        x = x &* 0xBF58_476D_1CE4_E5B9
        x ^= x >> 27
        x = x &* 0x94D0_49BB_1331_11EB
        x ^= x >> 31
        return CGFloat(Double(x % 1000) / 1000.0)
    }

    func path(in rect: CGRect) -> Path {
        let steps = 44
        let dx = rect.width / CGFloat(steps)
        var path = Path()

        if tornTop {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY + jitter(0) * amplitude))
            for index in 1 ... steps {
                path.addLine(to: CGPoint(
                    x: rect.minX + dx * CGFloat(index),
                    y: rect.minY + jitter(index) * amplitude
                ))
            }
        } else {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }

        if tornBottom {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - jitter(steps + 1) * amplitude))
            for index in stride(from: steps, through: 0, by: -1) {
                path.addLine(to: CGPoint(
                    x: rect.minX + dx * CGFloat(index),
                    y: rect.maxY - jitter(index + 101) * amplitude
                ))
            }
        } else {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        }

        path.closeSubpath()
        return path
    }
}

/// The stock's tooth. A dot grid, not a noise field: this world is a duplicator
/// and a duplicator makes dots.
struct Halftone: View {
    var tint: Color = Paper.press
    var pitch: CGFloat = 5
    var alpha: Double = 0.16

    var body: some View {
        Canvas { context, size in
            // ONE PATH, ONE FILL — not one fill per dot.
            //
            // This drew each dot with its own `Path(ellipseIn:)` and its own
            // `context.fill`. At a 5pt pitch on a 402x874 screen that is
            // **14,175 fill calls and 14,175 path allocations every time the
            // canvas redraws**, and the ground redraws whenever the view it is
            // attached to resizes or is composited at a changing opacity —
            // which is exactly what a step transition does.
            //
            // Eden, the first morning he ran this on a phone rather than the
            // simulator: *"i'm noticing some stutter and lag in the
            // animations… when clicking done on an exercise."* The simulator
            // never showed it because it does not run at 120Hz and its timing
            // is not representative — `device-checklist.md` has said so all
            // along.
            //
            // Accumulating into a single path and filling once is the same
            // picture from one draw call. Verified pixel-identical against a
            // capture taken before the change.
            let radius: CGFloat = 0.62
            var dots = Path()
            var y: CGFloat = 0
            var row = 0
            while y < size.height {
                var x: CGFloat = row.isMultiple(of: 2) ? 0 : pitch / 2
                while x < size.width {
                    dots.addEllipse(in: CGRect(x: x, y: y, width: radius * 2, height: radius * 2))
                    x += pitch
                }
                y += pitch
                row += 1
            }
            context.fill(dots, with: .color(tint.opacity(alpha)))
        }
        // RASTERISED ONCE, then composited as a texture.
        //
        // Without this the vector ops are replayed by the compositor every time
        // the layer is blended — and during a screen swap it is blended on
        // every frame, at a changing opacity, while a second copy of it fades
        // out underneath.
        .drawingGroup()
        .allowsHitTesting(false)
    }
}

/// Paper fibre. Short strokes at low alpha, deterministic for the same reason
/// the torn edge is. Static, and deliberately kept out of animated subtrees.
struct Fibre: View {
    var tint: Color = Paper.press
    var count = 420

    /// The drawing space, and it is DELIBERATELY NOT THE VIEW'S OWN SIZE.
    ///
    /// Larger than any ply this app pastes on a 402pt-wide screen, so a fixed
    /// canvas still covers whatever it is asked to fill.
    private static let sheet = CGSize(width: 440, height: 1000)

    var body: some View {
        Canvas { context, size in
            // One path, one stroke — see `Halftone` for the long version. 420
            // separate `context.stroke` calls became one, and it matters more
            // here than the count suggests: every pasted ply carries a `Fibre`,
            // and the study card's ply RESIZES as a question opens, so this
            // canvas was redrawing on every frame of that animation.
            var seed: UInt64 = 0x2545_F491_4F6C_DD1D
            var strokes = Path()
            var index = 0
            while index < count {
                seed ^= seed << 13
                seed ^= seed >> 7
                seed ^= seed << 17
                let x = CGFloat(Double(seed % 10000) / 10000.0) * size.width
                let y = CGFloat(Double((seed >> 16) % 10000) / 10000.0) * size.height
                let length = 3 + CGFloat(Double((seed >> 32) % 100) / 100.0) * 9
                strokes.move(to: CGPoint(x: x, y: y))
                strokes.addLine(to: CGPoint(x: x + length, y: y + 0.5))
                index += 1
            }
            context.stroke(strokes, with: .color(tint.opacity(0.07)), lineWidth: 0.7)
        }
        // A FIXED CANVAS INSIDE A FLEXIBLE VIEW.
        //
        // Batching the strokes into one path made each redraw cheap. It did not
        // stop the redraws: `size` is an INPUT to the closure, so while this
        // canvas filled its parent, every frame of the study card's growth
        // handed it a size it had never seen and there was nothing to reuse. A
        // leaf whose inputs change every frame can never be elided.
        //
        // Fixed, the inputs stop changing, and an unchanged leaf is work
        // SwiftUI can skip. The outer flexible frame is what keeps the call
        // sites honest — they all read `Fibre().clipShape(sheet)`, and that clip
        // is struck in this view's own rect, so this view must still report the
        // ply's size rather than the canvas's.
        //
        // It is also the more truthful model. Fibre density is a property of
        // the PAPER, not of the piece you tore off it: 420 strokes per ply meant
        // a small ply was made of finer stock than a large one.
        .frame(width: Self.sheet.width, height: Self.sheet.height, alignment: .topLeading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        // NO `drawingGroup` HERE, and that is the opposite of `Halftone`.
        //
        // `drawingGroup` rasterises into an offscreen buffer. That pays when a
        // layer is composited repeatedly at a FIXED size — which the ground is.
        // Every `Fibre` in this app is inside a pasted ply, and the study
        // card's ply **resizes on every frame while a question opens or an
        // answer is revealed**, so the buffer was being reallocated and
        // repainted 120 times a second.
        //
        // Measured on the device with Instruments' Animation Hitches template:
        // an 83ms hitch during a rest, which is ten dropped frames. Adding
        // `drawingGroup` here was my own regression from the pass before this
        // one; the single-path batching above is the part that was worth
        // keeping, and it stays.
        .allowsHitTesting(false)
    }
}

/// The ground every surface in this world sits on: stock, under one press run.
///
/// The halftone is an overlay rather than a background so the dot falls across
/// the plies too. A duplicator does not stop printing at a pasted edge.
struct PaperGround: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Paper.stock)
            .overlay(Halftone())
    }
}

/// A pasted ply.
///
/// The shadow is real — an offset and a blur, never a zero-offset halo — because
/// what makes a torn edge read as a torn edge is the light under it.
struct Ply<Content: View>: View {
    var fill: Color = Paper.ply
    var tornTop = false
    var tornBottom = true
    var seed: UInt64 = 11
    @ViewBuilder var content: Content

    var body: some View {
        let sheet = TornEdge(tornTop: tornTop, tornBottom: tornBottom, seed: seed)
        content
            .frame(maxWidth: .infinity)
            .background {
                sheet
                    .fill(fill)
                    // THE SHADOW IS CAST BY THE SHEET, NOT BY THE FIBRE ON IT.
                    //
                    // `.shadow` is a filter over everything drawn beneath it,
                    // and without a compositing group it is applied to EACH
                    // leaf. With the fibre already overlaid, this asked for a
                    // 3pt blur around **420 individual hairline strokes** as
                    // well as around the sheet — on every pasted ply in the app,
                    // on every frame any of them was composited.
                    //
                    // Nobody saw it, because 420 shadows at 22% under strokes at
                    // 7% is invisible. It was pure cost. Every ply in this app
                    // was paying it.
                    //
                    // ORDER IS THE ENTIRE FIX. The shadow goes on the fill, so
                    // one shape casts one shadow — which Core Animation can take
                    // as a shadow path rather than an offscreen pass — and the
                    // fibre is printed on top afterwards, casting nothing.
                    // Pixel-identical to the intent, and it is what the doc
                    // string above always claimed was happening.
                    .shadow(color: Paper.press.opacity(0.22), radius: 3, x: 0, y: 2)
                    .overlay { Fibre().clipShape(sheet) }
            }
    }
}

extension View {
    func paperGround() -> some View {
        modifier(PaperGround())
    }
}

// MARK: - Controls

/// A printed key. Takes the ink while it is held.
///
/// Press feedback is the one thing exempt from the motion doctrine's frequency
/// gate — at 6:10am it is often the only proof a knuckle tap landed — and it is
/// deliberately INSTANT. `01-motion-doctrine.md` §1.2 asks for ≤160ms, and an
/// instant ink flip is what a stamp does. Do not give this a duration.
struct PressKeyStyle: ButtonStyle {
    var ink: Color = Paper.press
    var knockout: Color = Paper.ply
    var borderWidth: CGFloat = 2.5

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(configuration.isPressed ? knockout : ink)
            .background(
                Rectangle()
                    .fill(configuration.isPressed ? ink : Color.clear)
                    .overlay(Rectangle().strokeBorder(ink, lineWidth: borderWidth))
            )
            // THE WHOLE CONTROL IS TAPPABLE, NOT JUST ITS GLYPHS.
            //
            // SwiftUI hit-tests a label's rendered content. A `Text` given a
            // frame still answers only where the letters are, so every button
            // in this app had a target the size of its word sitting inside a
            // box the size of a thumb.
            //
            // `PressKeyStyle` was the worst of them: it fills with `Color.clear`
            // when unpressed, so `+15S` and `SKIP` were dead in the middle and
            // live only on the border and the letters. Eden, twice: *"seems
            // like the clickable area is the text of the button not the button
            // itself, this feels bad to click."*
            //
            // Fixed HERE rather than at each call site, because a style is what
            // every control already shares — and the call sites are where this
            // kind of thing gets missed one at a time.
            .contentShape(Rectangle())
            // A pressed key MOVES. The ink flip alone is a colour change, and a
            // colour change is not a press. `scaleEffect` scales children too,
            // so the glyph goes down with the key rather than sitting still on
            // top of it.
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.10), value: configuration.isPressed)
    }
}

/// A solid inked block — the primary action.
///
/// It is press black rather than orange, and that is measured rather than
/// preferred: knocked out of orange, a label reads **2.14:1**, and press-on-
/// orange only reaches 3.61:1. On this stock only the press black is dark
/// enough to carry a knocked-out label (7.73:1), so the loudest thing this
/// world can print is a solid black bar — which on newsprint it is. Orange
/// still says "this is the live one", as the rule above it, where it is a mark
/// and not a glyph.
struct PressBlockStyle: ButtonStyle {
    var fill: Color = Paper.press

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(fill.opacity(configuration.isPressed ? 0.78 : 1))
            .contentShape(Rectangle())
            // Less than a key takes. A full-width bar scaled 0.97 reads as the
            // whole screen flinching; it still has to move, just less.
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.10), value: configuration.isPressed)
    }
}

/// A large surface being pressed: a card, a row, a sheet.
///
/// An ink WASH rather than a fill, because these surfaces carry text you are
/// reading and it has to stay readable with a thumb on it.
///
/// `scale` is a parameter because the right factor depends on how wide the
/// thing is. 0.97 on a 68pt key reads as a press; 0.97 on a full-width sheet
/// reads as the whole screen flinching. 0.98 on a 350pt row moves each edge
/// 3.5pt, which is the least that still registers — it was 0.985 and at 2.6pt
/// the ink wash was doing the whole job alone.
struct PressSheetStyle: ButtonStyle {
    var scale: CGFloat = 0.98

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Paper.press.opacity(0.14) : Color.clear)
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.easeOut(duration: 0.10), value: configuration.isPressed)
    }
}

/// A bare word being pressed, where there is no shape to flip.
///
/// Opacity, not a wash. The chrome sits directly on the stock, and a rectangle
/// of ink appearing behind a word floating on the background reads as a
/// rendering fault rather than as a press. The scale is present but small — at
/// 10pt it is the opacity doing the work.
struct PressLabelStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.45 : 1)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.10), value: configuration.isPressed)
    }
}

/// The primary action, in this world's vocabulary.
struct PaperPrimaryButton: View {
    let title: String
    var enabled = true
    /// Defaults to the house primary target. The Set screen overrides it: its
    /// Done is the most-pressed control in the app, hit with a knuckle at
    /// 6:10am on a phone that is on the floor.
    var height: CGFloat = Hit.primary
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Paper.orange).frame(height: 5)
            Button(action: action) {
                Text(title.uppercased())
                    .font(.system(size: 22, weight: .black))
                    .tracking(0.5)
                    .foregroundStyle(Paper.ply)
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
            }
            .buttonStyle(PressBlockStyle())
            .disabled(!enabled)
        }
    }
}

/// A stamp. Knocked out of the overprint, because that is the only ink on this
/// ground dark enough to carry a label at the floor.
struct PaperStamp: View {
    let text: String
    var fill: Color = Paper.overprint

    var body: some View {
        Text(text.uppercased())
            .font(PaperType.micro)
            .tracking(TypeScale.microTracking)
            .foregroundStyle(Paper.ply)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(fill)
    }
}

/// The session as one printed diagram — every step, always visible, so "where
/// am I" never needs a progress bar.
///
/// **This does not animate.** It changes ~28 times a session, which
/// `01-motion-doctrine.md` §1's frequency gate puts in the tier where motion is
/// removed. The temptation to ink each mark as it completes is the exact
/// finding that gate exists to reject.
struct StepBlock: View {
    /// One mark per set, at its TRUE position in the session — not evenly
    /// spaced. Superset partners sit adjacent with no rest between them, so
    /// their marks bunch, and the shape of the row shows the structure of the
    /// session without a word. W15 #3 restored this from the web build after
    /// the port kept only the bar; do not regularise it.
    let marks: [Double]
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Paper.press.opacity(0.18))
                    .frame(height: 3)
                Rectangle()
                    .fill(Paper.blue)
                    .frame(width: proxy.size.width * min(max(progress, 0), 1), height: 3)

                ForEach(Array(marks.enumerated()), id: \.offset) { _, at in
                    Rectangle()
                        .fill(at <= progress ? Paper.blue : Paper.press.opacity(0.32))
                        .frame(width: 3, height: 11)
                        .offset(x: (proxy.size.width - 3) * at)
                }

                Rectangle()
                    .fill(Paper.orange)
                    .frame(width: 5, height: 15)
                    .offset(x: (proxy.size.width - 5) * min(max(progress, 0), 1))
            }
            .frame(height: 15, alignment: .center)
        }
        .frame(height: 15)
    }
}

/// A subordinate action — `+15s` beside `Skip`.
///
/// An outlined key rather than a filled block: only one thing on a surface is
/// the primary, and in this world that is the solid inked bar. `quiet` thins
/// the rule rather than fading the ink, because a level recedes by weight here,
/// never by transparency.
struct PaperSecondaryButton: View {
    let title: String
    var quiet = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(PaperType.micro)
                .tracking(TypeScale.microTracking)
                .frame(maxWidth: .infinity)
                .frame(height: Hit.minimum)
        }
        .buttonStyle(PressKeyStyle(borderWidth: quiet ? 1.5 : 2.5))
    }
}
