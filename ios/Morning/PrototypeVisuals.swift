import SwiftUI

struct DawnBackdrop: View {
    let treatment: DawnTreatment
    let progress: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var breathing = false

    private var palette: DawnPalette {
        DawnPalette(progress: progress)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                switch treatment {
                case .atmospheric:
                    Color(red: 0.012, green: 0.018, blue: 0.05)

                    MeshGradient(
                        width: 3,
                        height: 3,
                        points: [
                            .init(0, 0), .init(0.5, 0), .init(1, 0),
                            .init(0, 0.48), .init(0.52, 0.44), .init(1, 0.48),
                            .init(0, 1), .init(0.5, 1), .init(1, 1),
                        ],
                        colors: [
                            palette.zenith, palette.zenith, palette.zenith,
                            palette.middle.opacity(0.5), palette.middle, palette.middle.opacity(0.5),
                            palette.horizon.opacity(0.28),
                            palette.horizon.opacity(0.72),
                            palette.horizon.opacity(0.28),
                        ],
                        smoothsColors: true
                    )

                    Stars(progress: progress)

                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [
                                    palette.accent.opacity(0.44),
                                    palette.accent.opacity(0.12),
                                    .clear,
                                ],
                                center: .center,
                                startRadius: 3,
                                endRadius: 170
                            )
                        )
                        .frame(width: 360, height: 250)
                        .scaleEffect(breathing && !reduceMotion ? 1.05 : 0.97)
                        .position(
                            x: proxy.size.width / 2,
                            y: proxy.size.height * (0.79 - progress * 0.08)
                        )
                        .blendMode(.screen)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.white, palette.accent, palette.accent.opacity(0.1)],
                                center: .center,
                                startRadius: 1,
                                endRadius: 28
                            )
                        )
                        .frame(width: 54, height: 54)
                        .position(
                            x: proxy.size.width / 2,
                            y: proxy.size.height * (0.79 - progress * 0.08)
                        )
                        .opacity(0.36 + progress * 0.42)
                        .blendMode(.screen)

                    Rectangle()
                        .fill(palette.accent.opacity(0.5))
                        .frame(height: 1)
                        .position(
                            x: proxy.size.width / 2,
                            y: proxy.size.height * (0.79 - progress * 0.08)
                        )

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
                            palette.accent.opacity(reduceTransparency ? 0.08 : 0.22),
                            palette.zenith,
                        ]
                    )

                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [palette.accent.opacity(reduceTransparency ? 0.16 : 0.5), .clear],
                                center: .center,
                                startRadius: 4,
                                endRadius: 190
                            )
                        )
                        .frame(width: 390, height: 310)
                        .scaleEffect(breathing && !reduceMotion ? 1.025 : 0.99)
                        .position(x: proxy.size.width / 2, y: proxy.size.height * 0.69)
                        .blendMode(.screen)
                }

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, Color.black.opacity(0.08), Color.black.opacity(0.34)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                    breathing = true
                }
            }
        }
        .ignoresSafeArea()
    }
}

private struct Stars: View {
    let progress: Double

    var body: some View {
        Canvas { context, size in
            for i in 0 ..< 34 {
                let x = (Double((i * 83) % 97) / 97) * size.width
                let y = (Double((i * 47) % 61) / 61) * size.height * 0.66
                let diameter = i.isMultiple(of: 7) ? 1.7 : 1.05
                let rect = CGRect(x: x, y: y, width: diameter, height: diameter)
                context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.42)))
            }
        }
        .opacity(max(0.08, 0.72 - progress * 0.58))
        .allowsHitTesting(false)
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
                    .foregroundStyle(.white.opacity(0.62))
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.1))
                    Capsule()
                        .fill(palette.accent)
                        .frame(width: proxy.size.width * progress)
                        .shadow(
                            color: palette.accent.opacity(treatment == .precise ? 0.45 : 0.75),
                            radius: treatment == .precise ? 2 : 6
                        )
                }
            }
            .frame(height: treatment == .precise ? 2 : 3)
        }
        .frame(height: 72)
    }
}
