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
                .foregroundStyle(Color.black)
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

struct RestScenarioSelector: View {
    @Binding var selection: RestScenario
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("Rest content")
                .font(.subheadline.weight(.semibold))

            ForEach(RestScenario.allCases) { scenario in
                Button {
                    selection = scenario
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: icon(for: scenario))
                            .font(.headline)
                            .frame(width: 28)
                            .foregroundStyle(selection == scenario ? accent : .white.opacity(0.66))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(title(for: scenario))
                                .font(.subheadline.weight(.semibold))
                            Text(subtitle(for: scenario))
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.64))
                        }

                        Spacer()

                        Image(systemName: selection == scenario ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selection == scenario ? accent : .white.opacity(0.28))
                    }
                    .padding(.horizontal, 13)
                    .frame(minHeight: 58)
                    .background(
                        selection == scenario ? Color.white.opacity(0.09) : Color.white.opacity(0.035),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func title(for scenario: RestScenario) -> String {
        switch scenario {
        case .plain: "Timer only"
        case .card: "Question → answer"
        case .myo: "Myo 20s"
        }
    }

    private func subtitle(for scenario: RestScenario) -> String {
        switch scenario {
        case .plain: "Plain 60-second Rest"
        case .card: "Fun fact · reveals automatically"
        case .myo: "Mechanism Rest · no card"
        }
    }

    private func icon(for scenario: RestScenario) -> String {
        switch scenario {
        case .plain: "timer"
        case .card: "rectangle.on.rectangle.angled"
        case .myo: "bolt.fill"
        }
    }
}
