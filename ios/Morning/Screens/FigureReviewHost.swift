import SwiftUI

/// `-screen figures` — every movement, at both ends of its travel.
///
/// Built because Eden said the animations "look goofy" and there was no way to
/// see them side by side. Each one lived inside a MOVEMENT bay on a set screen
/// you have to navigate to, at whatever size that bay happened to be, playing a
/// 3.2-second loop. Six movements times two extremes is twelve things to judge
/// and they were never once on the same screen.
///
///     -screen figures          start and finish, side by side
///     -screen figures -live    all six animating
struct FigureReviewHost: View {
    private let movements = [
        "Overhead press", "Push-up", "Lateral raise",
        "Rear-delt fly", "Bent-over row", "Curl",
        "Hammer curl", "Floor fly",
    ]

    private var isLive: Bool {
        ProcessInfo.processInfo.arguments.contains("-live")
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(movements, id: \.self) { name in
                    HStack(spacing: 6) {
                        if isLive {
                            bay(name, phase: nil)
                            bay(name, phase: nil)
                        } else {
                            bay(name, phase: 0)
                            bay(name, phase: 1)
                        }
                    }
                    .overlay(alignment: .topLeading) {
                        Text(name)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(5)
                    }
                }
            }
            .padding(8)
        }
        .background(Color(red: 0.04, green: 0.04, blue: 0.07))
    }

    private func bay(_ name: String, phase: Double?) -> some View {
        ExerciseMotionBay(
            treatment: .atmospheric,
            exercise: name,
            accent: Color(red: 0.85, green: 0.55, blue: 0.95),
            frozenPhase: phase
        )
        .frame(height: 96)
    }
}
