import CoreGraphics
import SwiftUI

// ---------------------------------------------------------------------------
//  THE SKY
//
//  A dawn, layered the way a real one is. The first native pass was a single
//  MeshGradient plus 34 fixed dots, and it read as flat for the reason the web
//  build's Sky.tsx already documents: actual dawn skies have structure — haze
//  banding near the horizon, wispy cloud catching light from underneath, an
//  ozone band between the blue zenith and the warm ground.
//
//  Three decisions worth knowing about.
//
//  1. The zenith does NOT take the accent hue. Rayleigh scattering is
//     wavelength-dependent, so the top of the sky stays deep blue even at the
//     height of a sunrise; only light coming through the thickest atmosphere,
//     at the horizon, turns warm. Tinting the whole sky with the live accent is
//     what made an earlier web version read as a coloured wash rather than sky.
//
//  2. Cloud noise is BAKED, not live. The texture is rasterised once into a
//     tiling CGImage and after that the layer is a bitmap being translated,
//     which the compositor handles for free. Generating noise per frame would
//     re-run across every pixel of a screen held awake for twenty minutes.
//
//  3. Drift runs on repeating transform animations, not on a per-frame clock.
//     Only the stars — a small Canvas — sit inside TimelineView, because they
//     twinkle and occasionally throw a meteor. Nothing here mutates observable
//     state per frame, and nothing animates blur radius or a mask.
//
//  There is deliberately no sun disc and no bottom halo. Both were removed
//  after Eden read them as decoration competing with the copy; the warmth that
//  remains lives in the gradient and the haze, where it reads as sky.
// ---------------------------------------------------------------------------

// MARK: - Baked cloud texture

/// Deterministic tiling fractal noise, rasterised once per configuration.
///
/// The tile is wide and short, and the noise runs at a LOW frequency across x
/// and a HIGH one down y. That ratio is what makes cloud rather than static:
/// the web build reaches the same shape with feTurbulence baseFrequency
/// "0.006 0.021". Getting it the other way round produces vertical streaks,
/// which read as screen noise.
enum CloudTexture {
    /// One field's shape. Grouping these keeps the generator's signature honest
    /// — six loose numeric parameters at a call site say nothing about which is
    /// which.
    struct Recipe {
        let seed: UInt32
        /// Lattice periods across the tile. `x` wraps so tiles meet seamlessly;
        /// `y` is a plain frequency because the band never repeats vertically.
        let xPeriod: Int
        let yFrequency: Int
        let octaves: Int
        /// Reproduces the web build's feColorMatrix: together these push most of
        /// the field transparent so only the denser parts survive as cloud.
        let contrast: Double
        let bias: Double
    }

    /// Wispy, far bank.
    static let far = make(Recipe(seed: 11, xPeriod: 3, yFrequency: 11, octaves: 5, contrast: 2.30, bias: -1.15))
    /// Coarser, higher-contrast noise for the nearer bank.
    static let near = make(Recipe(seed: 29, xPeriod: 5, yFrequency: 16, octaves: 4, contrast: 2.90, bias: -1.30))
    /// Fine monochrome grain that stops the gradients banding on OLED.
    static let grain = make(Recipe(seed: 7, xPeriod: 128, yFrequency: 128, octaves: 1, contrast: 1.0, bias: -0.44))

    static let width = 1024
    static let height = 256

    static func make(_ recipe: Recipe) -> CGImage? {
        var pixels = [UInt8](repeating: 0, count: width * height * 4)

        for row in 0 ..< height {
            for column in 0 ..< width {
                var amplitude = 1.0
                var total = 0.0
                var range = 0.0
                var period = recipe.xPeriod
                var frequency = Double(recipe.yFrequency)

                for octave in 0 ..< recipe.octaves {
                    let sampleX = Double(column) / Double(width) * Double(period)
                    let sampleY = Double(row) / Double(height) * frequency
                    total += amplitude * value(
                        sampleX: sampleX,
                        sampleY: sampleY,
                        period: period,
                        seed: recipe.seed &+ UInt32(octave)
                    )
                    range += amplitude
                    amplitude *= 0.55
                    period *= 2
                    frequency *= 2
                }

                let noise = range > 0 ? total / range : 0
                let alpha = min(1, max(0, recipe.contrast * noise + recipe.bias))
                let index = (row * width + column) * 4
                let level = UInt8(alpha * 255)
                pixels[index] = level // premultiplied white
                pixels[index + 1] = level
                pixels[index + 2] = level
                pixels[index + 3] = level
            }
        }

        let info = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let provider = CGDataProvider(data: Data(pixels) as CFData),
              let space = CGColorSpace(name: CGColorSpace.sRGB)
        else {
            return nil
        }

        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: space,
            bitmapInfo: info,
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
    }

    /// Smoothstep-interpolated value noise on a lattice that wraps at `period`
    /// in x, so neighbouring tiles meet without a seam.
    private static func value(sampleX: Double, sampleY: Double, period: Int, seed: UInt32) -> Double {
        let cellX = Int(floor(sampleX)), cellY = Int(floor(sampleY))
        let fractionX = sampleX - Double(cellX), fractionY = sampleY - Double(cellY)
        let easedX = fractionX * fractionX * (3 - 2 * fractionX)
        let easedY = fractionY * fractionY * (3 - 2 * fractionY)

        let topLeft = corner(cellX, cellY, period, seed)
        let topRight = corner(cellX + 1, cellY, period, seed)
        let bottomLeft = corner(cellX, cellY + 1, period, seed)
        let bottomRight = corner(cellX + 1, cellY + 1, period, seed)

        let top = topLeft + (topRight - topLeft) * easedX
        let bottom = bottomLeft + (bottomRight - bottomLeft) * easedX
        return top + (bottom - top) * easedY
    }

    private static func corner(_ x: Int, _ y: Int, _ period: Int, _ seed: UInt32) -> Double {
        let wrapped = period > 0 ? ((x % period) + period) % period : x
        var bits = UInt32(truncatingIfNeeded: wrapped &* 374_761_393)
        bits = bits &+ UInt32(truncatingIfNeeded: y &* 668_265_263)
        bits = bits &+ seed &* 2_246_822_519
        bits ^= bits >> 13
        bits = bits &* 1_274_126_177
        bits ^= bits >> 16
        return Double(bits) / Double(UInt32.max)
    }
}

// MARK: - Drifting cloud bank

/// One bank of cloud. The noise tile masks a tinted gradient, so the cloud
/// takes the sky's live colour instead of being painted on top of it.
///
/// The tile is scaled so exactly ONE of it covers the band vertically — a
/// vertically repeating tile reads as banding, which is the opposite of cloud.
/// It then repeats horizontally and travels exactly one tile width per cycle,
/// so the loop point lands on an identical frame and never shows a seam.
struct CloudBank: View {
    let texture: CGImage?
    let tint: LinearGradient
    let bandHeight: CGFloat
    let opacity: Double
    let period: Double

    @State private var drift: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var tileWidth: CGFloat {
        bandHeight * CGFloat(CloudTexture.width) / CGFloat(CloudTexture.height)
    }

    var body: some View {
        guard let texture else {
            return AnyView(EmptyView())
        }

        return AnyView(
            tint
                .frame(width: tileWidth * 2, height: bandHeight)
                .mask {
                    Image(decorative: texture, scale: CGFloat(CloudTexture.height) / bandHeight)
                        .resizable(resizingMode: .tile)
                        .frame(width: tileWidth * 2, height: bandHeight)
                }
                .offset(x: drift)
                .opacity(opacity)
                .allowsHitTesting(false)
                .onAppear {
                    guard !reduceMotion else { return }
                    withAnimation(.linear(duration: period).repeatForever(autoreverses: false)) {
                        drift = -tileWidth
                    }
                }
        )
    }
}

// MARK: - Stars

/// Stars thin out as the sun comes up. They twinkle, and while the sky is still
/// dark enough to hold them a meteor crosses now and then — the one piece of
/// motion here that is genuinely unpredictable, which is what stops the sky
/// reading as a loop.
struct StarField: View {
    let progress: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var visibility: Double {
        max(0, 0.92 - progress * 0.86)
    }

    var body: some View {
        if reduceMotion {
            Canvas { context, size in
                draw(in: &context, size: size, time: 0, twinkle: false)
            }
            .opacity(visibility)
            .allowsHitTesting(false)
        } else {
            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                Canvas { context, size in
                    draw(in: &context, size: size, time: time, twinkle: true)
                    if visibility > 0.12 {
                        drawMeteor(in: &context, size: size, time: time)
                    }
                }
            }
            .opacity(visibility)
            .allowsHitTesting(false)
        }
    }

    private func draw(in context: inout GraphicsContext, size: CGSize, time: Double, twinkle: Bool) {
        for i in 0 ..< 96 {
            let x = (Double((i &* 83) % 97) / 97) * size.width
            let y = (Double((i &* 47) % 61) / 61) * size.height * 0.46
            let big = i.isMultiple(of: 7)
            let diameter = big ? 2.1 : 1.2

            // Each star breathes on its own phase, so the field shimmers
            // instead of pulsing in unison.
            var alpha = big ? 0.85 : 0.55
            if twinkle {
                let phase = Double(i) * 1.7
                alpha *= 0.72 + 0.28 * sin(time * 0.9 + phase)
            }

            let rect = CGRect(x: x, y: y, width: diameter, height: diameter)
            context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(alpha)))
        }
    }

    private func drawMeteor(in context: inout GraphicsContext, size: CGSize, time: Double) {
        let cycle = Motion.Drift.meteorCycle
        let slot = floor(time / cycle)
        let local = time - slot * cycle
        let flight = Motion.Drift.meteorFlight
        guard local < flight else { return }

        // Deterministic per slot, so it never lands in the same place twice.
        let seed = abs(sin(slot * 12.9898) * 43758.5453)
        let startX = (seed - floor(seed)) * size.width
        let startY = (seed * 7).truncatingRemainder(dividingBy: 1) * size.height * 0.4
        let t = local / flight
        let travel = size.width * 0.34

        let head = CGPoint(x: startX - travel * t, y: startY + travel * t * 0.62)
        let tail = CGPoint(x: head.x + travel * 0.22, y: head.y - travel * 0.14)

        var path = Path()
        path.move(to: tail)
        path.addLine(to: head)

        // Fades in and out across its own flight so it never pops.
        let fade = sin(.pi * t)
        context.stroke(
            path,
            with: .linearGradient(
                Gradient(colors: [.white.opacity(0), .white.opacity(0.72 * fade)]),
                startPoint: tail,
                endPoint: head
            ),
            lineWidth: 1.6
        )
    }
}

// MARK: - Crepuscular rays

/// Light fanning up from a sun that has not cleared the ground yet. Feathered
/// wedges rather than hard edges — abrupt stops read as a pinwheel, not light.
/// The fan converges below the fold and rotates almost imperceptibly.
struct CrepuscularRays: View {
    let accent: Color
    let strength: Double

    @State private var angle: Double = -1.6
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Canvas { context, size in
            let origin = CGPoint(x: size.width * 0.5, y: size.height * 1.12)
            let reach = size.height * 1.35

            for i in 0 ..< 11 {
                let spread = Double(i - 5) * 9.5 + angle
                let radians = (spread - 90) * .pi / 180
                let half = 2.1 * .pi / 180

                var path = Path()
                path.move(to: origin)
                path.addLine(
                    to: CGPoint(
                        x: origin.x + cos(radians - half) * reach,
                        y: origin.y + sin(radians - half) * reach
                    )
                )
                path.addLine(
                    to: CGPoint(
                        x: origin.x + cos(radians + half) * reach,
                        y: origin.y + sin(radians + half) * reach
                    )
                )
                path.closeSubpath()

                // Rays nearest the centre carry the most light.
                let falloff = 1 - abs(Double(i - 5)) / 6.5
                context.fill(path, with: .color(accent.opacity(0.13 * falloff * strength)))
            }
        }
        .blur(radius: 13) // static radius — never animated
        .mask {
            RadialGradient(
                stops: [
                    .init(color: .black, location: 0.06),
                    .init(color: .black.opacity(0.62), location: 0.38),
                    .init(color: .black.opacity(0.22), location: 0.66),
                    .init(color: .clear, location: 0.88),
                ],
                center: UnitPoint(x: 0.5, y: 1.12),
                startRadius: 0,
                endRadius: 1060
            )
        }
        .allowsHitTesting(false)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: Motion.Drift.rays).repeatForever(autoreverses: true)) {
                angle = 1.6
            }
        }
    }
}

// MARK: - The composed sky

/// The Atmospheric backdrop, layered bottom to top. Order is the order a real
/// dawn stacks in: sky, ozone, haze, stars, light, cloud, grain.
struct AtmosphericSky: View {
    let progress: Double
    let palette: DawnPalette

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    /// The ozone band peaks partway through twilight rather than at either end,
    /// so its strength follows a curve, not a ramp.
    private var ozone: Double {
        0.16 + sin(.pi * min(1, progress * 0.86 + 0.07)) * 0.42
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                Surface.night

                // 1. The sky proper. The zenith stays deep blue at every
                //    progress; only the horizon takes the live warmth.
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
                        palette.horizon.opacity(0.46),
                        palette.horizon.opacity(0.58),
                        palette.horizon.opacity(0.46),
                    ],
                    smoothsColors: true
                )

                // 2. The ozone band — the purple-pink layer between the blue
                //    zenith and the warm ground. It is the layer most often
                //    missing from a painted sky.
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: Color(red: 0.62, green: 0.28, blue: 0.52).opacity(0.55), location: 0.34),
                        .init(color: Color(red: 0.50, green: 0.26, blue: 0.55).opacity(0.26), location: 0.62),
                        .init(color: .clear, location: 0.92),
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: size.height * 0.46)
                .position(x: size.width / 2, y: size.height * 0.63)
                .opacity(ozone)

                // 3. Haze. Atmosphere is denser near the ground, so the bottom
                //    of the sky lifts everywhere, not only where the sun is.
                LinearGradient(
                    stops: [
                        .init(color: palette.accent.opacity(0.30), location: 0),
                        .init(color: palette.accent.opacity(0.09), location: 0.44),
                        .init(color: .clear, location: 0.82),
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )

                // 4. Stars, thinning out as the sun comes up.
                StarField(progress: progress)

                // 5. Crepuscular rays. They STRENGTHEN with progress — the sun
                //    is getting closer to the horizon, so its light reaches
                //    further up the sky. Motion that carries no state is just
                //    motion; this fan is the one piece of sun the design keeps
                //    after the disc and the bottom halo were removed.
                if !reduceTransparency {
                    CrepuscularRays(accent: palette.accent, strength: 0.35 + progress * 0.65)
                }

                // 6. Two cloud banks at different scales and speeds. The
                //    parallax is what gives the sky depth rather than looking
                //    like a backdrop; the near bank is lit from below, so it is
                //    tinted warmer.
                CloudBank(
                    texture: CloudTexture.far,
                    tint: LinearGradient(
                        stops: [
                            .init(color: palette.accent.opacity(0.46), location: 0),
                            .init(color: palette.accent.opacity(0.12), location: 0.62),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    ),
                    bandHeight: size.height * 0.46,
                    opacity: reduceTransparency ? 0.30 : 0.58,
                    period: Motion.Drift.cloudFar
                )
                .position(x: size.width / 2, y: size.height * 0.40)

                CloudBank(
                    texture: CloudTexture.near,
                    tint: LinearGradient(
                        stops: [
                            .init(color: palette.horizon.opacity(0.62), location: 0),
                            .init(color: palette.accent.opacity(0.14), location: 0.58),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    ),
                    bandHeight: size.height * 0.34,
                    opacity: reduceTransparency ? 0.26 : 0.52,
                    period: Motion.Drift.cloudNear
                )
                .position(x: size.width / 2, y: size.height * 0.68)

                // 7. Grain, over everything, so the gradients do not band on
                //    OLED. Static: a moving grain field reads as noise on the
                //    screen rather than as texture in the image.
                if let grain = CloudTexture.grain {
                    Image(decorative: grain, scale: 1)
                        .resizable(resizingMode: .tile)
                        .opacity(0.035)
                        .blendMode(.overlay)
                        .allowsHitTesting(false)
                }
            }
            .clipped()
        }
    }
}
