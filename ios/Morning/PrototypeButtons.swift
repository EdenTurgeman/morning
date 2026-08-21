import SwiftUI

struct DawnPrimaryButton: View {
    let title: String
    let treatment: DawnTreatment
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 68)
                .foregroundStyle(Color.black.opacity(0.82))
                .background {
                    if treatment == .tactile {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(
                                LinearGradient(
                                    colors: [accent.opacity(0.92), accent.opacity(0.68)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(.white.opacity(0.16), lineWidth: 1)
                            }
                    } else {
                        RoundedRectangle(cornerRadius: treatment == .precise ? 16 : 22)
                            .fill(accent)
                            .shadow(
                                color: accent.opacity(treatment == .atmospheric ? 0.2 : 0.1),
                                radius: 6,
                                y: 3
                            )
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

struct DawnSecondaryButton: View {
    let title: String
    let treatment: DawnTreatment
    let accent: Color
    var quiet = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .foregroundStyle(.white)
                .background {
                    if treatment != .tactile {
                        RoundedRectangle(cornerRadius: treatment == .precise ? 15 : 20)
                            .fill(Color.black.opacity(quiet ? 0.2 : (treatment == .precise ? 0.32 : 0.16)))
                            .overlay {
                                RoundedRectangle(cornerRadius: treatment == .precise ? 15 : 20)
                                    .stroke(
                                        quiet
                                            ? Color.white.opacity(0.12)
                                            : treatment == .precise
                                            ? accent.opacity(0.4)
                                            : Color.white.opacity(0.12),
                                        lineWidth: 1
                                    )
                            }
                    }
                }
        }
        .buttonStyle(.plain)
        .modifier(TactileGlassButton(treatment: treatment, accent: accent, quiet: quiet))
    }
}

private struct TactileGlassButton: ViewModifier {
    let treatment: DawnTreatment
    let accent: Color
    let quiet: Bool
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        if treatment == .tactile {
            if reduceTransparency {
                content
                    .background(
                        Color.white.opacity(quiet ? 0.1 : 0.18),
                        in: RoundedRectangle(cornerRadius: 22)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(.white.opacity(0.24), lineWidth: 1)
                    }
            } else {
                content
                    .glassEffect(
                        .regular.tint(accent.opacity(quiet ? 0.08 : 0.2)).interactive(),
                        in: .rect(cornerRadius: 22)
                    )
            }
        } else {
            content
        }
    }
}
