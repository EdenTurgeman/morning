import SwiftUI

/* ===========================================================================
 *  THE PAPER SUNRISE
 *  ---------------------------------------------------------------------------
 *  The completion moment, imagined from scratch for the Paper world rather than
 *  ported from the atmosphere that preceded it.
 *
 *  THE IDEA, IN ONE SENTENCE
 *  ---------------------------------------------------------------------------
 *  **The sun is a folded paper fan, and the fan IS the sun.**
 *
 *  Not a disc with rays attached — that is two ideas glued together, and it is
 *  what every sunrise graphic does. Paper mâché's characteristic act is a
 *  folded sheet opening into a form, so the fan is pinned below the horizon,
 *  folded shut, and it RISES AND OPENS IN THE SAME MOTION. That makes
 *  "unfolding and rising at the same time" literal rather than decorative, and
 *  it is why the two beats are one beat here.
 *
 *  WHY NOT METAL, HAVING HAD IT BEFORE
 *  ---------------------------------------------------------------------------
 *  `Daybreak.metal` earned itself when the sun was an ATMOSPHERE: sky colour
 *  from scattering against the sun's altitude, crepuscular rays as light
 *  surviving a cloud field. Those are per-pixel physics and a shader is the
 *  honest tool for them.
 *
 *  Paper has no atmosphere. It is flat ink, torn edges and pasted layers, and
 *  this world structurally cannot produce a gradient. Computing flat wedges
 *  through a fragment shader would spend the whole complexity budget on nothing
 *  and keep a dead pipeline alive. Shapes are the cheapest tool that works,
 *  which is the rule.
 *
 *  `Celebration.rays` HAS A READER AT LAST
 *  ---------------------------------------------------------------------------
 *  `spec.md` §9 says the bottom five tiers must be visibly quieter than the top
 *  four, and that distinction is the entire reason the tiers exist. It has been
 *  unrendered since W17: every tier bloomed identically.
 *
 *  Here the flag IS the fan. A quiet tier opens five blades across 78°; a top
 *  tier opens eleven across 150°. You can tell them apart from across the room
 *  without reading anything, which is the same bar the dawn ramp had to meet.
 *
 *  `milestoneBurst` adds a SECOND IMPRESSION — a paler fan printed behind the
 *  first and slightly off-register. A milestone is visibly bigger without a
 *  second visual language, and misregistration is this world's own vocabulary
 *  rather than confetti borrowed from another one.
 * ======================================================================== */

// MARK: - Geometry

/// One blade of the fan: a wedge from the pivot with a torn outer edge.
///
/// Deterministic jitter, like every other torn edge in this world — a rim
/// recomputed per frame shimmers, and during a 3-second animation that reads as
/// a rendering fault rather than as paper.
nonisolated struct SunRay: Shape {
    /// Half-width at the BASE, in degrees. The ray tapers from here to a point.
    var halfAngle: Double
    /// Where the ray starts, as a fraction of the radius. Rays begin at the
    /// disc's edge — nothing is hidden underneath the body, so the sun has no
    /// secret mass making it look heavier than it is.
    var inner: CGFloat = 0.42
    /// How far the tip lags the base, in degrees, against the direction of
    /// travel. Driven from the spring's velocity, so the ray bends while it is
    /// moving and straightens once it settles.
    var lag: Double = 0
    var seed: UInt64
    var tear: CGFloat = 0.07

    private func jitter(_ index: Int) -> CGFloat {
        var x = UInt64(bitPattern: Int64(index)) &+ seed &* 0x9E37_79B9_7F4A_7C15
        x ^= x >> 30
        x = x &* 0xBF58_476D_1CE4_E5B9
        x ^= x >> 27
        x = x &* 0x94D0_49BB_1331_11EB
        x ^= x >> 31
        return CGFloat(Double(x % 1000) / 1000.0)
    }

    /// Half-width at a given fraction of the way out.
    ///
    /// **This is the whole fix.** A wedge struck from the pivot is narrowest at
    /// its base and widest at its tip — the opposite of a sun ray, and the
    /// reason the fan read as heavy no matter how much it was scaled down. A
    /// ray is wide where it leaves the body and comes to a point.
    private func width(at f: CGFloat) -> Double {
        let t = Double((f - inner) / max(1 - inner, 0.001))
        return halfAngle * (1 - t * 0.86)
    }

    func path(in rect: CGRect) -> Path {
        let centre = CGPoint(x: rect.midX, y: rect.maxY)
        let radius = min(rect.width / 2, rect.height)
        let ribs = 7
        var path = Path()

        func point(_ f: CGFloat, _ side: Double, jit: CGFloat = 0) -> CGPoint {
            // Quadratic in the fraction out, because a cantilever bends more
            // toward its free end.
            let bend = -lag * Double(f) * Double(f)
            let angle = (side * width(at: f) + bend) * .pi / 180
            let r = radius * f * (1 - tear + jit * tear)
            return CGPoint(
                x: centre.x + CGFloat(sin(angle)) * r,
                y: centre.y - CGFloat(cos(angle)) * r
            )
        }

        // Out along one edge, a torn tip, back down the other.
        for index in 0 ... ribs {
            let f = inner + (1 - inner) * CGFloat(index) / CGFloat(ribs)
            let p = point(f, -1, jit: index == ribs ? jitter(index) : 0)
            index == 0 ? path.move(to: p) : path.addLine(to: p)
        }
        path.addLine(to: point(1, 0, jit: jitter(99)))
        for index in stride(from: ribs, through: 0, by: -1) {
            let f = inner + (1 - inner) * CGFloat(index) / CGFloat(ribs)
            path.addLine(to: point(f, 1, jit: index == ribs ? jitter(index + 40) : 0))
        }

        path.closeSubpath()
        return path
    }
}

/// The sun's body: a small, clean torn disc.
///
/// Without it the rays converge on a bare point, which reads as a fan. With it
/// too large, the body swallows the rays and reads as a dome. It is small, and
/// its rim barely wanders — a wobbly disc looks chubby at any size.
nonisolated struct TornDisc: Shape {
    var seed: UInt64
    var tear: CGFloat = 0.035

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
        let centre = CGPoint(x: rect.midX, y: rect.maxY)
        let radius = min(rect.width / 2, rect.height)
        let steps = 40
        var path = Path()

        for index in 0 ... steps {
            let angle = Double(index) / Double(steps) * 2 * .pi
            let r = radius * (1 - tear + jitter(index) * tear)
            let point = CGPoint(
                x: centre.x + CGFloat(sin(angle)) * r,
                y: centre.y - CGFloat(cos(angle)) * r
            )
            index == 0 ? path.move(to: point) : path.addLine(to: point)
        }

        path.closeSubpath()
        return path
    }
}

// MARK: - The fan

struct PaperSunrise: View {
    /// The single elapsed clock. This view owns no clock of its own — every
    /// beat derives from one value, so no two can desynchronise.
    let elapsed: TimeInterval
    /// When the rise-and-unfold begins. Owned by `Daybreak.Beats`, which owns
    /// every beat in this moment, so nothing here can drift out of step.
    let fanStart: TimeInterval
    let rays: Bool
    let milestoneBurst: Bool
    let reduceMotion: Bool

    /// The leaf's physics.
    ///
    /// `DesignMotion`'s `commit` token sets the house rule: start critically
    /// damped, and add bounce ONLY when the gesture itself carried momentum. A
    /// knuckle tap carries none, which is why bounce is off everywhere else in
    /// this app. **A fan flicked open carries momentum by definition** — this is
    /// the exception that rule describes rather than a breach of it.
    ///
    /// 0.14 is inside the 0.1–0.3 band and at the stiff end of it, because
    /// paper mâché is pasted layers dried hard. It is card, not a leaf.
    private static let leaf = Spring(duration: 0.85, bounce: 0.14)

    /// The flag, rendered. Five blades against eleven is legible at 1.5m.
    private var bladeCount: Int {
        // 5/11 → 11/21 → 15/29, twice on Eden's read of a rendered frame. Five
        // rays is not a sun, it is a hand.
        //
        // With the spread fixed at 176° for both tiers, this count is the ONLY
        // thing carrying the tier — 15 rays against 29 across the same arc. It
        // reads as the same sun with more of it, rather than as two different
        // shapes, which is the better signal.
        // 5/11 → 11/21 → 15/29 → 23/41, each step on Eden's read of a real
        // frame. This is only affordable because `halfBlade` is an ABSOLUTE
        // angle now — while width was a fraction of the slot, every one of
        // these increases silently thinned the rays.
        //
        // At 41 rays the slot is 4.3° and the widest rays overlap their
        // neighbours near the base. That is fine and slightly lucky: `inner` is
        // 0.33 and the disc covers to 0.34, so the overlap happens exactly
        // where the disc hides it, and they have tapered apart by the time they
        // emerge.
        rays ? 41 : 23
    }

    /// Degrees the open fan spans. A quiet tier is narrow as well as sparse:
    /// two channels saying the same thing, because one of them has to survive
    /// being glanced at.
    private var spread: Double {
        // Wider than it was. Five rays over 78° clustered straight up and read
        // as a paw; the same five over 110° read as a sun. The tier is still
        // unmistakable — 5 rays across 110° against 11 across 168°.
        // 176°, and the SAME at both tiers.
        //
        // The disc's centre sits on the tear, so a ray at ±88° lies just above
        // horizontal — level with the ground, half-caught by the torn edge that
        // is drawn over it. At 152/108 the outermost rays stopped well short of
        // that and left a bald gap either side: Eden, *"they stop way before
        // the horizon… it needs the rays to actually go all around the sun."*
        //
        // Spread no longer carries the tier — DENSITY does, 11 rays against 21
        // across the same arc. That is the better signal anyway: the sun is the
        // same sun on an ordinary morning and on a milestone, there is simply
        // more of it. An arc that grew made them two different shapes.
        176
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            // The pivot sits below the horizon, so the fan is genuinely behind
            // it when folded and genuinely clears it when open.
            // Measured against a rendered frame, not chosen. The fan must top
            // out BELOW the copy: press black on orange is 3.61:1, so any text
            // that lands on a blade is text you cannot read. Topping out at
            // 0.56h keeps the copy on stock and still leaves ~0.18h of fan
            // standing above the horizon, which is what makes it a sunrise
            // rather than a glow behind a wall.
            // THE DISC'S CENTRE SITS BELOW THE HORIZON — 0.762h against a tear
            // at 0.74h.
            //
            // Centre ON the line showed the whole top half and read as a ball
            // resting on a shelf. Below it, only a shallow arc clears the tear —
            // about a third of the disc — which is what a sun actually looks
            // like coming up. Eden: *"the sun is too high on the horizon,
            // should be lower on it."*
            //
            // It pays a second time on the rays. They radiate from a centre
            // that is now underground, so the ones nearest horizontal are
            // progressively swallowed by the ply drawn over them: rays out to
            // about ±83° clear the tear and the last few do not. Nothing
            // special had to be written for that — it falls out of the geometry
            // and it is exactly how a real sunrise loses its lowest rays.
            let pivot = CGPoint(x: size.width / 2, y: size.height * 0.762)
            let radius = size.height * 0.175

            // ONE FAN. The milestone's second impression moved to the DISC.
            //
            // It used to be a whole pale fan printed behind this one and offset
            // — and at 41 long rays it stopped reading as an off-register
            // impression and started reading as a second set of white spikes
            // competing with the real ones. Eden: *"let's get rid of the
            // background white rays."*
            //
            // `milestoneBurst` still has a reader, and it had to: `04-rules.md`
            // §5 requires a lifetime threshold or a completed week to be
            // visibly bigger than an ordinary morning, and this app has already
            // shipped three flags that nothing rendered. The misregistration is
            // just applied where it stays quiet — see `body(ink:)`.
            fan(radius: radius, ink: Paper.orange, seedOffset: 0)
                .frame(width: radius * 2, height: radius)
                .position(x: pivot.x, y: pivot.y - radius / 2)
                .offset(y: rise)
        }
        .allowsHitTesting(false)
    }

    private func fan(radius: CGFloat, ink: Color, seedOffset: UInt64) -> some View {
        let step = spread / Double(max(bladeCount - 1, 1))
        // AN ABSOLUTE ANGLE, NOT A FRACTION OF THE SLOT.
        //
        // This was `step * 0.30`, and `step` shrinks as the count grows — so
        // every request for MORE rays silently made them THINNER. Eden asked
        // for more rays three times and then, correctly, *"they're a little too
        // thin now, i wanted more rays but around the same thickness."* The two
        // knobs were the same knob.
        //
        // 2.2° of half-width, so a ray is ~4.4° wide before its own multiplier
        // and the count can move without touching the weight. At 29 rays across
        // 176° the slot is 6.3°, so the widest rays just meet their neighbours
        // near the disc — which is what a corona does, and they taper apart
        // immediately.
        let halfBlade = 2.5

        // BOTTOM-ALIGNED, and this is load-bearing.
        //
        // Every ray and the disc carry their own `.frame`, and each shape puts
        // its origin at the BOTTOM-CENTRE of the frame it is given. Centred —
        // the ZStack default — a short ray and the small disc each compute
        // their origin from the middle of their own box, so nothing shares a
        // centre: the disc floated clear of the horizon and the rays splayed
        // off-axis. Bottom alignment makes every origin land on the same point.
        return ZStack(alignment: .bottom) {
            ForEach(0 ..< bladeCount, id: \.self) { index in
                let vary = variation(index)
                // The nominal slot, PLUS this ray's own offset. Perfectly even
                // spacing is the single strongest tell that a sun was generated
                // rather than drawn; real rays cluster and gap.
                let target = -spread / 2 + step * Double(index) + vary.angle * step
                let swing = motion(for: index)

                // RAYS EXTEND. THEY DO NOT SWING OPEN.
                //
                // The fan-open was a leftover from the idea this replaced — when
                // the sun WAS a folded paper fan, hinging was the whole conceit.
                // It is a sunburst now: a disc with a corona, and rays radiating
                // from a body do not hinge. Light does not swing open. Eden:
                // *"the fanning out is weird."*
                //
                // So the angle is fixed from the first frame and the LENGTH is
                // what moves. Each ray grows from `discReach` — where it is
                // entirely swallowed by the disc — out to its own full length.
                // Nothing appears from nothing: the rays are already there,
                // behind the body, and they emerge from under it.
                let grown = discReach + (vary.length - discReach) * CGFloat(swing.position)

                // The tip trails as the ray shoots out and straightens as it
                // settles — the same velocity coupling as before, moved from a
                // swing to an extension. Signed per ray so they do not all whip
                // the same way.
                let whip = (vary.angle > 0 ? 1.0 : -1.0) * swing.velocity * 2.4
                let lag = min(9, max(-9, whip))
                let angle = target + sway(for: index)

                // ONE PLY PER RAY, not two.
                //
                // The rays used to be a face sheet over a wider under-sheet,
                // which gave a fat wedge visible depth. At this width and this
                // count it does the opposite — 21 thin rays each with a wider
                // ghost behind them is mush, not layers — and it doubles the
                // shape count on the heaviest thing this app draws. The paper
                // depth now comes from the varied rays themselves, the disc
                // pasted over their roots, and the milestone fan's second
                // impression.
                // A FIXED FRAME AND A TRANSFORM, not a frame that animates.
                //
                // This was `height: radius * grown`, and `grown` changes on
                // every frame of the extension. Forty-one rays each resizing
                // their own frame means SwiftUI re-runs layout for the whole
                // fan 120 times a second AND re-tessellates forty-one
                // procedurally torn paths, because a `Shape`'s path is derived
                // from the rect it is handed. The `ZStack` above resized with
                // them, so the churn propagated upward too.
                //
                // Eden, on this screen: *"the element appear and do their thing
                // but with some dropped frames, again it's not heavy it just
                // needs optimization."* It WAS heavy. This is why.
                //
                // A uniform scale about the apex is not an approximation of the
                // old behaviour — it is ALGEBRAICALLY THE SAME PICTURE. The
                // wedge is defined in angles struck from the pivot
                // (`width(at:)` returns degrees; `point` places every rib at
                // `radius * f`), and `tear` is a fraction of `r`. Scaling
                // uniformly about that pivot preserves every angle and every
                // proportion and changes only the reach — which is exactly what
                // `grown` was changing. The path is now built ONCE per ray.
                SunRay(
                    halfAngle: halfBlade * vary.width,
                    lag: lag,
                    seed: UInt64(index) &+ 17 &+ seedOffset &+ boilSeed,
                    tear: 0.07
                )
                .fill(ink)
                .frame(width: radius * 2, height: radius * vary.length)
                .scaleEffect(grown / vary.length, anchor: .bottom)
                .rotationEffect(
                    .degrees(angle),
                    // The pivot is the bottom of the ray, not its middle:
                    // a fan opens from where it is held.
                    anchor: .bottom
                )
            }

            // ON TOP of the ray roots, not behind them. A paper-cut sun is
            // built that way — the body is the last piece pasted down, and it
            // is what hides the point all the rays converge on.
            //
            // Small and CLEAN: the rays reach roughly three times the body's
            // radius, and a low tear keeps the rim a circle, because a wobbly
            // disc looks chubby however small it is.
            // THE MILESTONE'S SECOND IMPRESSION.
            //
            // The same disc printed twice, a few points off-register in the
            // overprint — which is literally what a duplicator does when a
            // sheet shifts between passes, and it is the vocabulary this world
            // already uses for "you passed it". Present only on a milestone,
            // and quiet enough to sit under the copy rather than fight it.
            if milestoneBurst {
                TornDisc(seed: 907 &+ seedOffset &+ boilSeed, tear: 0.035)
                    .fill(Paper.overprint)
                    .frame(width: radius * 0.88, height: radius * 0.44)
                    .offset(x: 6, y: -5)
            }

            TornDisc(seed: 401 &+ seedOffset &+ boilSeed, tear: 0.035)
                .fill(ink)
                // 0.34 of the ray radius, which is exactly `SunRay.inner`, so
                // the rays leave the body's edge with no gap.
                // 0.42 of the ray radius, and `SunRay.inner` matches it
                // exactly so the rays leave the body's edge with no gap.
                .frame(width: radius * 0.84, height: radius * 0.42)
        }
    }

    /// Where a ray is completely hidden by the body.
    ///
    /// `SunRay` measures from the pivot, so a ray whose frame is this tall
    /// spans entirely inside the disc and cannot be seen. It is the START of
    /// the extension, and it is why the entrance needs no fade: the rays are
    /// occluded, not transparent.
    ///
    /// Must stay equal to the disc's own reach — the `TornDisc` frame below and
    /// `SunRay.inner` are the other two places this number lives. If they drift,
    /// either a gap opens between the body and its rays or the rays start
    /// visibly poking out before they should.
    private var discReach: CGFloat {
        0.42
    }

    /// Everything that makes one ray different from its neighbours.
    ///
    /// **Hashed from the ray's index and NOTHING else — deliberately excluding
    /// `boilSeed`.** The boil belongs to the torn RIM; if it reached these
    /// values the rays would change length, width and angle eight times a
    /// second, which is a completely different and much worse effect than a
    /// wandering edge. Stable per ray, for the life of the moment.
    ///
    /// Before this, every ray was the same width, evenly spaced, and one of
    /// exactly TWO lengths — Eden: *"too few rays, they are all too thick and
    /// they are super symmetrically placed and evenly spaced… no variation
    /// between the rays."* All four of those were one cause: nothing about a
    /// ray depended on which ray it was.
    private func variation(_ index: Int) -> RayVariation {
        func hash(_ salt: UInt64) -> Double {
            var x = UInt64(index) &+ salt &* 0x9E37_79B9_7F4A_7C15
            x ^= x >> 30
            x = x &* 0xBF58_476D_1CE4_E5B9
            x ^= x >> 27
            x = x &* 0x94D0_49BB_1331_11EB
            x ^= x >> 31
            return Double(x % 1000) / 1000.0
        }
        return RayVariation(
            // Up to ±31% of a slot. Enough to break the grid without letting
            // two rays cross.
            angle: (hash(11) - 0.5) * 0.62,
            // CONTINUOUS, 0.50…0.90 of the radius. It was binary — 1.0 or
            // 0.78, strictly alternating — which reads as a pattern, and a
            // pattern reads as machinery.
            //
            // Shortened three times on Eden's read — 1.0 → 0.90 → 0.81 → 0.62
            // at the top, ending on *"they still are way too tall."* The floor
            // moves with the ceiling every time; a range that only loses its
            // ceiling ends up uniform, which is the thing this function exists
            // to prevent.
            //
            // THE PROPORTION IS THE POINT, and I had it wrong.
            //
            // Chasing "too tall" I ended at 0.32…0.62 against a disc of 0.34 —
            // so the longest ray reached less than ONE disc-radius past the
            // body. That is not a short sunburst, it is a different object: a
            // spiky ball. Eden, correctly: *"these look terrible… all the rays
            // are too small."*
            //
            // 0.62…1.0 from an `inner` of 0.42 puts the longest ray about 1.4
            // disc-radii clear of the body, which is the classic sunburst
            // proportion. The rays are LONGER than before in absolute terms and
            // the sun still reads lower, because the growth went into the body
            // and the depth into the ground rather than into height.
            //
            // Tightened again on the render: max 1.0 → 0.86 and the SPREAD
            // narrowed from 0.38 to 0.20. Eden: *"the MAX length is still too
            // much, the variation between the rays is too big."* Variation was
            // the whole point of this function, but past a certain range it
            // stops reading as a natural corona and starts reading as rays of
            // two different kinds.
            length: CGFloat(0.66 + hash(29) * 0.20),
            // 0.50…1.40 of the base half-width, so the fan carries genuine
            // slivers between fuller rays instead of one repeated wedge.
            width: 0.60 + hash(47) * 0.70,
            phase: hash(83)
        )
    }

    /// One ray's share of the randomness. A struct rather than a tuple because
    /// four members is past where a tuple stops documenting itself — and
    /// SwiftLint says so too.
    private struct RayVariation {
        let angle: Double
        let length: CGFloat
        let width: Double
        let phase: Double
    }

    // MARK: - The two motions, which are one motion

    /// How far this blade has swung out of the fold, 0…1.
    ///
    /// Staggered from the CENTRE OUTWARD rather than left to right: a fan opens
    /// from the middle, and a left-to-right sweep would read as a wipe. 55ms
    /// apart, inside the 30–80ms band where stagger reads as cascade rather
    /// than as queueing.
    private func motion(for index: Int) -> (position: Double, velocity: Double) {
        // Reduce Motion: open, still, and FLAT. A blade frozen mid-bend is a
        // broken shape rather than a calm one, so the lag must be exactly zero
        // on this path — "calmer, never broken" fails here if it is not.
        guard !reduceMotion else { return (1, 0) }

        let centre = Double(bladeCount - 1) / 2
        let rank = abs(Double(index) - centre)
        // Leaves rub. The outermost opens ~24% slower than the innermost, which
        // is what makes the fan open as one material instead of as N parts.
        let drag = 1 + (rank / max(centre, 1)) * 0.24
        // NORMALISED, so the stagger does not grow with the ray count. At a
        // fixed 55ms per rank, going from 11 rays to 21 would have stretched
        // the opening from 0.28s to 0.55s and turned a cascade into a queue.
        // The whole fan opens across ~0.40s whatever the tier, plus a little
        // per-ray phase so no two neighbours move in lockstep.
        let spacing = 0.40 / max(centre, 1)
        let t = elapsed - (fanStart + rank * spacing + variation(index).phase * 0.045)
        guard t > 0 else { return (0, 0) }

        let spring = Spring(duration: Self.leaf.duration * drag, bounce: 0.14)
        return (
            spring.value(target: 1, time: t),
            spring.velocity(target: 1, time: t)
        )
    }

    /// The rise. Decelerating, because a thing that clears a horizon slows as
    /// it does — and because ease-out puts the movement where the eye already
    /// is, at the start.
    private var rise: CGFloat {
        guard !reduceMotion else { return 0 }
        // The same object, so the same physics — one spring for one thing,
        // just slower because it is carrying the whole fan.
        let rising = Spring(duration: 1.5, bounce: 0.10)
        let since = elapsed - fanStart
        let t = since > 0 ? rising.value(target: 1, time: since) : 0
        // Starts fully below its resting place and travels up to it. Never
        // from zero size — this world has no scale(0) equivalent; the fan is
        // always a real object, just folded and lower down.
        return 132 * (1 - t)
    }

    /// BOIL — the torn rims redraw on a stepped cadence, the way a hand-drawn
    /// outline does.
    ///
    /// **Stepped is the whole point.** An earlier note in this file says a rim
    /// recomputed per frame shimmers and reads as a rendering fault, and that is
    /// still true: at 60fps this is noise. At 8fps it is boil, which is a
    /// technique animators have used for a century, and the difference between
    /// the two is entirely the cadence.
    ///
    /// Off under Reduce Motion. Continuous ambient jitter is precisely what that
    /// setting exists to switch off, and the fan keeps its whole shape without
    /// it.
    private var boilSeed: UInt64 {
        guard !reduceMotion else { return 0 }
        return UInt64(max(0, Int(elapsed * 8)))
    }

    /// FOLLOW-THROUGH — paper does not stop when the swing stops.
    ///
    /// A decaying sway, phase-offset per blade so the fan never moves as one
    /// board. It is under a degree at its widest and gone within about two
    /// seconds, which is enough to keep the sheet alive while the copy lands
    /// and not enough to compete with it for attention.
    private func sway(for index: Int) -> Double {
        guard !reduceMotion else { return 0 }
        let t = elapsed - fanStart
        guard t > 0 else { return 0 }
        let phase = Double(index) * 1.7
        return sin(t * 3.1 + phase) * 0.85 * exp(-t / 1.15)
    }

    private func ramp(from: TimeInterval, over: TimeInterval) -> Double {
        min(1, max(0, (elapsed - from) / over))
    }

    private func easeOutStrong(_ t: Double) -> Double {
        Motion.easeOutStrong.value(at: t)
    }
}
