import SwiftUI

struct DawnBackdrop: View {
    let treatment: DawnTreatment
    let progress: Double

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private var palette: DawnPalette {
        DawnPalette(progress: progress)
    }

    var body: some View {
        GeometryReader { _ in
            ZStack {
                switch treatment {
                case .atmospheric:
                    AtmosphericSky(progress: progress, palette: palette)

                case .precise:
                    Color(red: 0.018, green: 0.02, blue: 0.032)

                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.24),
                            palette.accent.opacity(0.055),
                            Color.black.opacity(0.34),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    PrecisionGrid(accent: palette.accent)

                case .tactile:
                    Color(red: 0.018, green: 0.02, blue: 0.038)

                    MeshGradient(
                        width: 2,
                        height: 2,
                        points: [.init(0, 0), .init(1, 0), .init(0, 1), .init(1, 1)],
                        colors: [
                            palette.zenith,
                            Color.black,
                            palette.accent.opacity(reduceTransparency ? 0.04 : 0.1),
                            palette.zenith,
                        ]
                    )
                }

                LegibilityScrim(treatment: treatment, progress: progress)
            }
        }
        .ignoresSafeArea()
    }
}

private struct PrecisionGrid: View {
    let accent: Color

    var body: some View {
        Canvas { context, size in
            for row in 1 ..< 12 {
                let y = size.height * Double(row) / 12
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(.white.opacity(row.isMultiple(of: 3) ? 0.045 : 0.018)))
            }

            var progressPath = Path()
            progressPath.move(to: CGPoint(x: 1, y: size.height * 0.12))
            progressPath.addLine(to: CGPoint(x: 1, y: size.height * 0.88))
            context.stroke(progressPath, with: .color(accent.opacity(0.22)), lineWidth: 1)
        }
        .allowsHitTesting(false)
    }
}

struct PrototypeChrome: View {
    let progress: Double
    let treatment: DawnTreatment
    let step: String
    let onBack: () -> Void

    private var palette: DawnPalette {
        DawnPalette(progress: progress)
    }

    var body: some View {
        VStack(spacing: 9) {
            ZStack {
                HStack {
                    Button(action: onBack) {
                        Label("Back", systemImage: "chevron.left")
                            .labelStyle(.titleAndIcon)
                            .font(.caption.weight(.medium))
                            .frame(minWidth: 64, minHeight: 64, alignment: .leading)
                    }

                    Spacer()

                    Button("End", action: onBack)
                        .font(.caption.weight(.medium))
                        .frame(minWidth: 64, minHeight: 64, alignment: .trailing)
                }
                .foregroundStyle(.white.opacity(0.78))

                Text(step)
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.72))
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.1))
                    Capsule()
                        .fill(palette.accent)
                        .frame(width: proxy.size.width * progress)
                        .shadow(
                            color: palette.accent.opacity(treatment == .precise ? 0.28 : 0.38),
                            radius: treatment == .precise ? 1 : 3
                        )
                }
            }
            .frame(height: treatment == .precise ? 2 : 3)
        }
        .frame(height: 72)
    }
}

private struct WorkObjectContinuity: ViewModifier {
    let id: String
    let namespace: Namespace.ID

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.matchedGeometryEffect(id: id, in: namespace)
        }
    }
}

extension View {
    func workObjectContinuity(id: String, in namespace: Namespace.ID) -> some View {
        modifier(WorkObjectContinuity(id: id, namespace: namespace))
    }
}

/// The sky gets bright enough near the bottom to swallow secondary text sitting
/// over it — the web build carries the same layer for the same reason. It sits
/// BEHIND the content, so it lowers the background luminance without touching
/// the glyphs, which is what makes it buy contrast rather than cost it.
///
/// The first native version ramped the wrong way: it was heaviest at the top,
/// where the sky is already near-black, and lightest at 62%, right where the
/// horizon warmth peaks. Measured against the rendered frames, that shape put
/// the cue text, the Reps label and the footer under the brief's tertiary bar.
private struct LegibilityScrim: View {
    let treatment: DawnTreatment
    let progress: Double

    /// Near-black, faintly blue — pure black flattens the night out of the sky.
    private static let ink = Color(red: 0.016, green: 0.02, blue: 0.039)

    private var stops: [Gradient.Stop] {
        switch treatment {
        case .atmospheric:
            // Follows the Atmospheric sky's own luminance: quiet where the sky
            // is dark, strongest across the bottom third where it is warmest.
            //
            // It also scales with progress, because the sky it is holding back
            // does. Measured on rendered frames, a fixed scrim that cleared the
            // bar at twilight let the cue text, the Reps label and the footer
            // fall to 6.2-6.5:1 by the time the palette reached gold.
            let ramp = min(1, max(0, progress))
            return [
                .init(color: Self.ink.opacity(0.30), location: 0),
                .init(color: Self.ink.opacity(0.14 + 0.04 * ramp), location: 0.38),
                .init(color: Self.ink.opacity(0.20 + 0.08 * ramp), location: 0.58),
                .init(color: Self.ink.opacity(0.48 + 0.08 * ramp), location: 0.78),
                .init(color: Self.ink.opacity(0.64 + 0.07 * ramp), location: 1),
            ]
        case .precise, .tactile:
            // These backdrops carry far less light, so they keep the gentler
            // original shape.
            return [
                .init(color: Self.ink.opacity(0.36), location: 0),
                .init(color: Self.ink.opacity(0.16), location: 0.42),
                .init(color: Self.ink.opacity(0.10), location: 0.62),
                .init(color: Self.ink.opacity(0.38), location: 1),
            ]
        }
    }

    var body: some View {
        Rectangle()
            .fill(LinearGradient(stops: stops, startPoint: .top, endPoint: .bottom))
            .allowsHitTesting(false)
    }
}
