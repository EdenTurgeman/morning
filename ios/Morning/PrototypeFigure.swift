import SwiftUI

// ---------------------------------------------------------------------------
//  THE EXERCISE FIGURE
//
//  `02-design-brief.md §7`: *"The current figures are SVG stick figures animated
//  with SMIL and the user has said twice that they need work — this is your
//  chance… They should look like a body, not a diagram."*
//
//  Twice is the part that matters. The first native pass reproduced the same
//  problem in Swift: uniform 5pt round-capped strokes and a circle for a head.
//  What makes that read as a diagram is not the abstraction — it is that every
//  line is the same width and every joint is a corner. Real limbs taper toward
//  the extremity, a torso has mass and a waist, and joints are round because
//  there is a bone end inside them.
//
//  So this draws the same poses as FILLED, TAPERED shapes rather than strokes.
//  No assets, no dependency, no anatomy library — the pose coordinates and the
//  motion model are unchanged, only the rendering has weight now.
//
//  It stays deliberately abstract. This is a movement reminder glanced at from
//  1.5m at 6:10am, not an anatomical illustration, and detail it does not need
//  would only compete with the rep counter.
// ---------------------------------------------------------------------------

/// A pose in normalised bay coordinates: x across the bay, y down it.
/// The floor a movement is performed against.
struct FigureGround {
    let fromX: Double
    let toX: Double
    let y: Double
}

struct FigurePose {
    /// Centre of the head.
    var head: (Double, Double)
    /// Base of the neck — the top of the torso mass.
    var neck: (Double, Double)
    /// Centre of the hips — the bottom of the torso mass.
    var hip: (Double, Double)
    /// Shoulder → elbow → hand. The limb the exercise is about.
    var arms: [[(Double, Double)]] = []
    /// Hip → knee → foot.
    var legs: [[(Double, Double)]] = []
    /// Where a dumbbell bar sits, if the movement is loaded.
    var dumbbells: [(Double, Double)] = []
    /// A floor line, for movements done lying down or on the hands.
    var ground: FigureGround?
    /// Rotation of the torso mass, in degrees, for bent-over positions.
    var lean: Double = 0
}

struct FigureRenderer {
    let pose: FigurePose
    let limbColor: Color
    let bodyColor: Color
    let size: CGSize

    /// Widths are a fraction of the bay's height so the figure keeps its
    /// proportions whatever the bay is; the coordinate space itself is
    /// non-uniform, which is why nothing here derives a width from x.
    private var unit: Double {
        size.height
    }

    func draw(into context: inout GraphicsContext) {
        if let ground = pose.ground {
            drawGround(ground, into: &context)
        }

        // Legs sit behind the torso, so the hip joint reads as one mass.
        for leg in pose.legs {
            drawLimb(leg, widths: [0.033, 0.025, 0.018], color: bodyColor, into: &context)
        }

        drawNeck(into: &context)
        drawTorso(into: &context)
        drawHead(into: &context)

        // The working limb is drawn last and in the accent, because it is the
        // thing the cue is talking about.
        for arm in pose.arms {
            drawLimb(arm, widths: [0.030, 0.022, 0.017], color: limbColor, into: &context)
        }

        for bar in pose.dumbbells {
            drawDumbbell(at: bar, into: &context)
        }
    }

    // MARK: - Parts

    private func drawTorso(into context: inout GraphicsContext) {
        let neck = cgPoint(pose.neck)
        let hip = cgPoint(pose.hip)

        let shoulderHalf = 0.062 * unit
        let waistHalf = 0.042 * unit
        let hipHalf = 0.050 * unit

        // The torso's own axis, so a bent-over row's mass leans with it rather
        // than staying upright while the limbs rotate around it.
        let axis = CGVector(dx: hip.x - neck.x, dy: hip.y - neck.y)
        let length = max(1, hypot(axis.dx, axis.dy))
        let along = CGVector(dx: axis.dx / length, dy: axis.dy / length)
        let across = CGVector(dx: -along.dy, dy: along.dx)

        func offset(_ base: CGPoint, _ distance: Double, _ half: Double) -> (CGPoint, CGPoint) {
            let centre = CGPoint(x: base.x + along.dx * distance, y: base.y + along.dy * distance)
            return (
                CGPoint(x: centre.x + across.dx * half, y: centre.y + across.dy * half),
                CGPoint(x: centre.x - across.dx * half, y: centre.y - across.dy * half)
            )
        }

        let (shoulderL, shoulderR) = offset(neck, 0, shoulderHalf)
        let (waistL, waistR) = offset(neck, length * 0.58, waistHalf)
        let (hipL, hipR) = offset(neck, length, hipHalf)

        // Curved sides, so the silhouette is a body rather than a trapezoid.
        var path = Path()
        path.move(to: shoulderL)
        path.addQuadCurve(to: waistL, control: CGPoint(x: shoulderL.x, y: (shoulderL.y + waistL.y) / 2))
        path.addQuadCurve(to: hipL, control: CGPoint(x: waistL.x, y: (waistL.y + hipL.y) / 2))
        path.addLine(to: hipR)
        path.addQuadCurve(to: waistR, control: CGPoint(x: waistR.x, y: (waistR.y + hipR.y) / 2))
        path.addQuadCurve(to: shoulderR, control: CGPoint(x: shoulderR.x, y: (shoulderR.y + waistR.y) / 2))
        path.closeSubpath()

        context.fill(path, with: .color(bodyColor))

        // Shoulders and hips are round because there are joints in them.
        cap(at: neck, radius: shoulderHalf * 0.92, color: bodyColor, into: &context)
        cap(at: hip, radius: hipHalf * 0.94, color: bodyColor, into: &context)
    }

    /// Without this the head reads as a ball hovering above the shoulders.
    private func drawNeck(into context: inout GraphicsContext) {
        let head = cgPoint(pose.head)
        let neck = cgPoint(pose.neck)
        let half = 0.026 * unit
        let axis = CGVector(dx: neck.x - head.x, dy: neck.y - head.y)
        let length = max(0.001, hypot(axis.dx, axis.dy))
        let across = CGVector(dx: -axis.dy / length, dy: axis.dx / length)

        var path = Path()
        path.move(to: CGPoint(x: head.x + across.dx * half, y: head.y + across.dy * half))
        path.addLine(to: CGPoint(x: neck.x + across.dx * half, y: neck.y + across.dy * half))
        path.addLine(to: CGPoint(x: neck.x - across.dx * half, y: neck.y - across.dy * half))
        path.addLine(to: CGPoint(x: head.x - across.dx * half, y: head.y - across.dy * half))
        path.closeSubpath()
        context.fill(path, with: .color(bodyColor))
    }

    private func drawHead(into context: inout GraphicsContext) {
        let centre = cgPoint(pose.head)
        // Slightly taller than wide. A circle reads as a ball on a stick.
        let width = 0.088 * unit
        let height = 0.104 * unit
        let rect = CGRect(
            x: centre.x - width / 2,
            y: centre.y - height / 2,
            width: width,
            height: height
        )
        context.fill(Path(ellipseIn: rect), with: .color(bodyColor))
    }

    /// A limb as a chain of tapered quads with round joints, so it thins toward
    /// the hand and bends rather than kinking.
    private func drawLimb(
        _ joints: [(Double, Double)],
        widths: [Double],
        color: Color,
        into context: inout GraphicsContext
    ) {
        guard joints.count >= 2 else { return }
        let points = joints.map(cgPoint)

        for index in 0 ..< points.count - 1 {
            let start = points[index]
            let end = points[index + 1]
            let startHalf = widths[min(index, widths.count - 1)] * unit
            let endHalf = widths[min(index + 1, widths.count - 1)] * unit

            let axis = CGVector(dx: end.x - start.x, dy: end.y - start.y)
            let length = max(0.001, hypot(axis.dx, axis.dy))
            let across = CGVector(dx: -axis.dy / length, dy: axis.dx / length)

            var path = Path()
            path.move(to: CGPoint(x: start.x + across.dx * startHalf, y: start.y + across.dy * startHalf))
            path.addLine(to: CGPoint(x: end.x + across.dx * endHalf, y: end.y + across.dy * endHalf))
            path.addLine(to: CGPoint(x: end.x - across.dx * endHalf, y: end.y - across.dy * endHalf))
            path.addLine(to: CGPoint(x: start.x - across.dx * startHalf, y: start.y - across.dy * startHalf))
            path.closeSubpath()
            context.fill(path, with: .color(color))

            cap(at: start, radius: startHalf, color: color, into: &context)
            cap(at: end, radius: endHalf, color: color, into: &context)
        }
    }

    private func drawDumbbell(at location: (Double, Double), into context: inout GraphicsContext) {
        let centre = cgPoint(location)
        let half = 0.052 * unit
        let barHalf = 0.011 * unit
        let plate = 0.030 * unit

        var bar = Path()
        bar.addRoundedRect(
            in: CGRect(x: centre.x - half, y: centre.y - barHalf, width: half * 2, height: barHalf * 2),
            cornerSize: CGSize(width: barHalf, height: barHalf)
        )
        context.fill(bar, with: .color(.white.opacity(0.9)))

        // Plates, so it reads as a loaded dumbbell rather than a held rod.
        for side in [-1.0, 1.0] {
            let rect = CGRect(
                x: centre.x + side * half - barHalf * 1.5,
                y: centre.y - plate,
                width: barHalf * 3,
                height: plate * 2
            )
            context.fill(
                Path(roundedRect: rect, cornerSize: CGSize(width: barHalf, height: barHalf)),
                with: .color(.white.opacity(0.9))
            )
        }
    }

    private func drawGround(_ ground: FigureGround, into context: inout GraphicsContext) {
        let start = cgPoint((ground.fromX, ground.y))
        let end = cgPoint((ground.toX, ground.y))
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        context.stroke(
            path,
            with: .color(bodyColor.opacity(0.45)),
            style: StrokeStyle(lineWidth: 0.014 * unit, lineCap: .round)
        )
    }

    private func cap(at point: CGPoint, radius: Double, color: Color, into context: inout GraphicsContext) {
        let rect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: rect), with: .color(color))
    }

    private func cgPoint(_ coordinate: (Double, Double)) -> CGPoint {
        CGPoint(x: size.width * coordinate.0, y: size.height * coordinate.1)
    }
}
