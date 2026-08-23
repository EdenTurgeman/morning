import SwiftUI

/* ===========================================================================
 *  THE SHADER, ON SCREEN
 *  ---------------------------------------------------------------------------
 *  W13. `Shaders/Daybreak.metal` computes the whole frame — sky, cloud strata,
 *  crepuscular rays and the sun — from one elapsed value. This is the thirty
 *  lines of SwiftUI that hand it that value.
 *
 *  `elapsed` is passed in rather than read here, so this view has no clock of
 *  its own. That is the rule the original Daybreak header spends its length on:
 *  every stage reads one number, so no two stages can drift. A `TimelineView`
 *  inside this view would quietly break it.
 * ======================================================================== */

struct MetalDaybreakSky: View {
    let elapsed: TimeInterval
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { proxy in
            Rectangle()
                .colorEffect(
                    ShaderLibrary.daybreakSky(
                        .float2(proxy.size),
                        .float(Float(elapsed)),
                        .float(reduceMotion ? 1 : 0)
                    )
                )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Compiles the shader before anything needs it.
///
/// SwiftUI builds a Metal pipeline the first time a shader is drawn, and that
/// cost lands on whatever frame asks for it. Measured: with the shader wired
/// into Daybreak and nothing warmed, the app's first frame moved from ~3.3s
/// after launch to ~5.2s — and Daybreak's clock starts when its view appears,
/// so **the entire choreography played behind the launch screen** and the first
/// thing on screen was a settled sun.
///
/// A one-point instance costs nothing and pays the compile before the moment
/// that needs it. It sits at app root, so by the time a session ends the
/// pipeline is twenty minutes old.
struct MetalDaybreakWarmup: View {
    var body: some View {
        MetalDaybreakSky(elapsed: 0, reduceMotion: true)
            .frame(width: 1, height: 1)
            .opacity(0.001)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// `-screen metal` — the shader alone, at a spread of moments.
///
/// Built before wiring it into `Daybreak`, because a sunrise that has to be
/// judged has to be seen first, and seeing it inside the finished screen means
/// judging it through the copy sitting on top of it.
struct MetalDaybreakReviewHost: View {
    /// Frozen times rather than a running clock, so a screenshot is
    /// reproducible and a change is a diff rather than an impression.
    private let moments: [Double] = [0.20, 0.45, 0.70, 0.95, 1.40, 2.40]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isCalm: Bool {
        reduceMotion || ProcessInfo.processInfo.arguments.contains("-calm")
    }

    var body: some View {
        if let at = Self.singleMoment {
            // One moment, full height. The strip below squashes each frame to
            // 140pt, which moves the horizon and makes the composition a lie —
            // useful for reading the progression, useless for judging it.
            MetalDaybreakSky(elapsed: at, reduceMotion: isCalm)
        } else if ProcessInfo.processInfo.arguments.contains("-live") {
            TimelineView(.animation) { context in
                MetalDaybreakSky(
                    elapsed: context.date.timeIntervalSince(Self.start),
                    reduceMotion: isCalm
                )
            }
        } else {
            VStack(spacing: 2) {
                ForEach(moments, id: \.self) { at in
                    MetalDaybreakSky(elapsed: at, reduceMotion: isCalm)
                        .frame(height: 140)
                        .clipped()
                        .overlay(alignment: .topLeading) {
                            Text(String(format: "%.2fs", at))
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.white.opacity(0.75))
                                .padding(6)
                        }
                }
            }
            .ignoresSafeArea()
        }
    }

    private static let start = Date()

    /// `-at 1.4`
    private static var singleMoment: Double? {
        let args = ProcessInfo.processInfo.arguments
        guard let flag = args.firstIndex(of: "-at"), args.indices.contains(flag + 1) else { return nil }
        return Double(args[flag + 1])
    }
}
