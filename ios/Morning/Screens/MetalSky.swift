import SwiftUI

/* ===========================================================================
 *  THE WORKOUT SKY, ON SCREEN
 *  ---------------------------------------------------------------------------
 *  W18. Thirty lines of SwiftUI in front of `Shaders/Sky.metal`, which argues
 *  the case for existing at length. This file only has three decisions in it.
 *
 *  ONE CLOCK, and it is a wall clock rather than a session clock. Everything
 *  time-dependent in the sky is drift and twinkle; none of it is state. So it
 *  reads `timeIntervalSinceReferenceDate` directly and does not care when the
 *  view appeared — which means moving between Set and Rest does not restart the
 *  clouds, and it is the reason the sky can be hoisted to `WorkoutHost` and
 *  survive every screen swap underneath it.
 *
 *  THE PALETTE IS HANDED IN. `DawnPalette`'s five stops are hand-picked and
 *  perceptually interpolated, and its own header says a formula gave an even
 *  ramp rather than a sunrise. So the ramp stays in Swift and only the physics
 *  is in Metal.
 *
 *  IT STOPS WHEN NOTHING IS WATCHING IT. `TimelineView(.animation)` redraws as
 *  fast as the display will go, and a full-screen fragment shader at 120Hz for
 *  twenty minutes is a real battery cost for drift you cannot perceive above
 *  about 20fps. `.animation(minimumInterval:)` caps it. Under Reduce Motion the
 *  shader's drift term is zeroed anyway, so the timeline drops to a still frame
 *  and the GPU stops entirely.
 * ======================================================================== */

struct MetalSky: View {
    /// Session progress, 0…1. Drives the state: colour, star density, how far
    /// the light reaches. Not the animation.
    let progress: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private var isCalm: Bool {
        reduceMotion || reduceTransparency
    }

    private var palette: DawnPalette {
        DawnPalette(progress: progress)
    }

    var body: some View {
        GeometryReader { proxy in
            // Twelve frames a second is not a compromise here. Nothing in this
            // sky moves faster than a cloud crossing the screen in three
            // minutes, and the one fast thing — the stars' twinkle — is a
            // brightness ripple that reads identically at 12fps and at 120.
            // Everything the eye actually tracks in this app (the counter, the
            // ring, the screen swaps) is drawn by SwiftUI on top of this and is
            // unaffected.
            TimelineView(.animation(minimumInterval: isCalm ? nil : 1.0 / 12.0, paused: isCalm)) { context in
                Rectangle()
                    .colorEffect(
                        ShaderLibrary.dawnSky(
                            .float2(proxy.size),
                            .float(Float(min(1, max(0, progress)))),
                            .float(Float(context.date.timeIntervalSinceReferenceDate
                                    .truncatingRemainder(dividingBy: 86400))),
                            .float(isCalm ? 1 : 0),
                            .color(palette.zenith),
                            .color(palette.middle),
                            .color(palette.horizon)
                        )
                    )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// `-screen sky` — the sky alone, at a spread of session progresses.
///
/// Built for the same reason `MetalDaybreakReviewHost` was: a sky that has to be
/// judged has to be seen without the copy sitting on top of it, and judged as a
/// PROGRESSION rather than as one frame. The workout's sky is the one surface in
/// this app nobody ever looks at deliberately, which is exactly how it ended up
/// being the weaker of the two.
///
///     -screen sky            the strip, six progresses
///     -screen sky -at 0.5    one progress, full height
///     -screen sky -calm      the Reduce Motion form
struct MetalSkyReviewHost: View {
    private let stops: [Double] = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let at = Self.singleStop {
            MetalSky(progress: at)
        } else {
            VStack(spacing: 2) {
                ForEach(stops, id: \.self) { at in
                    MetalSky(progress: at)
                        .frame(height: 140)
                        .clipped()
                        .overlay(alignment: .topLeading) {
                            Text(String(format: "%.1f", at))
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.white.opacity(0.75))
                                .padding(6)
                        }
                }
            }
            .ignoresSafeArea()
        }
    }

    private static var singleStop: Double? {
        let args = ProcessInfo.processInfo.arguments
        guard let flag = args.firstIndex(of: "-at"), args.indices.contains(flag + 1) else { return nil }
        return Double(args[flag + 1])
    }
}
