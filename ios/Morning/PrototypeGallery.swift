import CoreHaptics
import Foundation
import SwiftUI

enum DawnTreatment: String, CaseIterable, Identifiable {
    case atmospheric
    case precise
    case tactile

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .atmospheric: "Atmospheric Dawn"
        case .precise: "Precise Dawn"
        case .tactile: "Tactile Dawn"
        }
    }

    var subtitle: String {
        switch self {
        case .atmospheric: "The room gets lighter."
        case .precise: "Progress becomes calibrated light."
        case .tactile: "One object changes state in your hand."
        }
    }
}

private enum PrototypeMode: String, CaseIterable, Identifiable {
    case set
    case rest

    var id: Self {
        self
    }
}

enum SetScenario: String, CaseIterable, Identifiable {
    case firstRun = "First run"
    case comparable = "Comparable"
    case changedWeight = "Changed weight"
    case superset = "Superset"
    case myo = "Myo"
    case longContent = "Longest content"

    var id: Self {
        self
    }
}

enum RestScenario: String, CaseIterable, Identifiable {
    case plain = "Plain 60s"
    case card = "Study card"
    case myo = "Myo 20s"

    var id: Self {
        self
    }
}

struct PrototypeLabView: View {
    @State private var treatment = DawnTreatment.atmospheric
    @State private var mode = PrototypeMode.set
    @State private var setScenario = SetScenario.comparable
    @State private var restScenario = RestScenario.plain
    @State private var progress = 0.42
    @State private var isPresentingPrototype = false

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flag = arguments.firstIndex(of: "-prototype"),
              arguments.indices.contains(flag + 1)
        else {
            return
        }

        let value = arguments[flag + 1]
        let selectedTreatment = DawnTreatment.allCases.first { value.hasPrefix($0.rawValue) } ?? .atmospheric
        let selectedMode: PrototypeMode = value.contains("rest") || value.contains("card") ? .rest : .set
        let selectedRestScenario: RestScenario = if value.contains("myo") {
            .myo
        } else if value.contains("card") {
            .card
        } else {
            .plain
        }

        _treatment = State(initialValue: selectedTreatment)
        _mode = State(initialValue: selectedMode)
        _restScenario = State(initialValue: selectedRestScenario)
        _progress = State(initialValue: selectedRestScenario == .myo ? 0.74 : 0.42)
        _isPresentingPrototype = State(initialValue: true)
    }

    var body: some View {
        if isPresentingPrototype {
            PrototypeStage(
                treatment: treatment,
                mode: mode,
                setScenario: setScenario,
                restScenario: restScenario,
                progress: progress,
                onClose: { isPresentingPrototype = false }
            )
            .id("\(treatment.rawValue)-\(mode.rawValue)-\(setScenario.rawValue)-\(restScenario.rawValue)")
        } else {
            PrototypeMenu(
                treatment: $treatment,
                mode: $mode,
                setScenario: $setScenario,
                restScenario: $restScenario,
                progress: $progress,
                onOpen: { isPresentingPrototype = true }
            )
        }
    }
}

private struct PrototypeMenu: View {
    @Binding var treatment: DawnTreatment
    @Binding var mode: PrototypeMode
    @Binding var setScenario: SetScenario
    @Binding var restScenario: RestScenario
    @Binding var progress: Double
    let onOpen: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        ZStack {
            Color(red: 0.025, green: 0.03, blue: 0.065)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Morning")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                        Text("Native Dawn direction lab")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 10) {
                        ForEach(DawnTreatment.allCases) { item in
                            Button {
                                treatment = item
                            } label: {
                                HStack(spacing: 14) {
                                    Circle()
                                        .fill(DawnPalette(progress: progress).accent)
                                        .frame(width: 15, height: 15)
                                        .shadow(
                                            color: DawnPalette(progress: progress).accent.opacity(0.7),
                                            radius: treatment == item ? 9 : 0
                                        )

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(item.title)
                                            .font(.headline)
                                        Text(item.subtitle)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: treatment == item ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(
                                            treatment == item
                                                ? DawnPalette(progress: progress).accent
                                                : Color.secondary
                                        )
                                }
                                .padding(16)
                                .background(
                                    treatment == item
                                        ? Color.white.opacity(0.09)
                                        : Color.white.opacity(0.045),
                                    in: RoundedRectangle(cornerRadius: 20)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        Picker("Screen", selection: $mode) {
                            ForEach(PrototypeMode.allCases) { item in
                                Text(item.rawValue.capitalized).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)

                        if mode == .set {
                            Picker("Set state", selection: $setScenario) {
                                ForEach(SetScenario.allCases) { item in
                                    Text(item.rawValue).tag(item)
                                }
                            }
                        } else {
                            Picker("Rest state", selection: $restScenario) {
                                ForEach(RestScenario.allCases) { item in
                                    Text(item.rawValue).tag(item)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Session progress")
                                Spacer()
                                Text(progress, format: .percent.precision(.fractionLength(0)))
                                    .monospacedDigit()
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                            Slider(value: $progress, in: 0 ... 1)
                                .tint(DawnPalette(progress: progress).accent)
                        }
                    }

                    HStack {
                        Label(
                            reduceMotion ? "Reduce Motion on" : "Full motion",
                            systemImage: reduceMotion ? "figure.walk.motion" : "waveform.path"
                        )
                        Spacer()
                        Label(
                            reduceTransparency ? "Opaque" : "Transparency",
                            systemImage: "circle.lefthalf.filled"
                        )
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Button(action: onOpen) {
                        Text("Open \(mode.rawValue.capitalized) prototype")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                            .foregroundStyle(.black.opacity(0.78))
                            .background(
                                DawnPalette(progress: progress).accent,
                                in: RoundedRectangle(cornerRadius: 22)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct PrototypeStage: View {
    let treatment: DawnTreatment
    let mode: PrototypeMode
    let setScenario: SetScenario
    let restScenario: RestScenario
    let progress: Double
    let onClose: () -> Void

    var body: some View {
        ZStack {
            DawnBackdrop(treatment: treatment, progress: progress)

            switch mode {
            case .set:
                SetPrototypeView(
                    treatment: treatment,
                    scenario: setScenario,
                    progress: progress,
                    onClose: onClose
                )
            case .rest:
                RestPrototypeView(
                    treatment: treatment,
                    scenario: restScenario,
                    progress: progress,
                    onClose: onClose
                )
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct DawnBackdrop: View {
    let treatment: DawnTreatment
    let progress: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathing = false

    private var palette: DawnPalette {
        DawnPalette(progress: progress)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color(red: 0.015, green: 0.02, blue: 0.045)

                MeshGradient(
                    width: 3,
                    height: 3,
                    points: [
                        .init(0, 0), .init(0.5, 0), .init(1, 0),
                        .init(0, 0.52), .init(0.5, 0.48), .init(1, 0.52),
                        .init(0, 1), .init(0.5, 1), .init(1, 1),
                    ],
                    colors: [
                        palette.zenith, palette.zenith, palette.zenith,
                        palette.middle.opacity(0.72), palette.middle, palette.middle.opacity(0.72),
                        palette.horizon.opacity(0.45), palette.horizon.opacity(0.7), palette.horizon.opacity(0.45),
                    ],
                    smoothsColors: true
                )
                .opacity(treatment == .precise ? 0.72 : 1)

                Stars(progress: progress)

                if treatment != .precise {
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [
                                    palette.accent.opacity(treatment == .tactile ? 0.68 : 0.54),
                                    palette.accent.opacity(0.16),
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
                            y: proxy.size.height * (0.79 - progress * 0.14)
                        )
                        .blendMode(.screen)
                }

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, Color.black.opacity(0.12), Color.black.opacity(0.42)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                if treatment == .precise {
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(palette.accent.opacity(0.55))
                            .frame(height: 1)
                            .shadow(color: palette.accent.opacity(0.8), radius: 5)
                            .padding(.bottom, proxy.size.height * 0.19)
                    }
                }
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

private struct PrototypeChrome: View {
    let progress: Double
    let treatment: DawnTreatment
    let step: String
    let onBack: () -> Void

    private var palette: DawnPalette {
        DawnPalette(progress: progress)
    }

    var body: some View {
        VStack(spacing: 9) {
            HStack {
                Button(action: onBack) {
                    Label("Back", systemImage: "chevron.left")
                        .labelStyle(.titleAndIcon)
                        .font(.caption.weight(.medium))
                }

                Spacer()

                Text(step.uppercased())
                    .font(.caption2.weight(.semibold))
                    .tracking(1.8)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("End", action: onBack)
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(.white.opacity(0.78))

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
        .frame(height: 44)
    }
}

private struct SetPrototypeView: View {
    let treatment: DawnTreatment
    let scenario: SetScenario
    let progress: Double
    let onClose: () -> Void

    @State private var reps: Int
    @State private var direction = 1
    @State private var loggedPulse = false

    private let fixture: SetFixture

    init(
        treatment: DawnTreatment,
        scenario: SetScenario,
        progress: Double,
        onClose: @escaping () -> Void
    ) {
        self.treatment = treatment
        self.scenario = scenario
        self.progress = progress
        self.onClose = onClose
        fixture = SetFixture.fixture(for: scenario)
        _reps = State(initialValue: fixture.initialReps)
    }

    private var palette: DawnPalette {
        DawnPalette(progress: progress)
    }

    private var isComparable: Bool {
        fixture.previous != nil && fixture.previousKg == nil
    }

    private var isBeating: Bool {
        isComparable && reps > (fixture.previous ?? .max)
    }

    var body: some View {
        VStack(spacing: 0) {
            PrototypeChrome(
                progress: progress,
                treatment: treatment,
                step: "Set 8 / 21",
                onBack: onClose
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(fixture.exercise)
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .tracking(-1.1)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)

                    if fixture.intense {
                        Text("MYO")
                            .font(.caption2.weight(.bold))
                            .tracking(1.4)
                            .foregroundStyle(palette.accent)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(palette.accent.opacity(0.14), in: Capsule())
                    }
                }

                if let sub = fixture.sub {
                    Text(sub)
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.68))
                }

                Text(fixture.meta)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.5))

                if fixture.straightIntoNext {
                    Text("No rest after this — straight into the next one.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(palette.accent)
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 14)

            Spacer(minLength: 8)

            CueList(cues: fixture.cues, accent: palette.accent)

            Spacer(minLength: 8)

            VStack(spacing: 5) {
                Text("TARGET · \(fixture.target.uppercased())")
                    .font(.caption2.weight(.semibold))
                    .tracking(1.6)
                    .foregroundStyle(.white.opacity(0.48))

                RepObject(
                    treatment: treatment,
                    reps: reps,
                    direction: direction,
                    previous: isComparable ? fixture.previous : nil,
                    isBeating: isBeating,
                    accent: palette.accent,
                    onStep: step
                )

                comparisonCopy
                    .font(.subheadline)
                    .frame(height: 22)
            }

            Spacer(minLength: 8)

            DawnPrimaryButton(
                title: "Done",
                treatment: treatment,
                accent: palette.accent
            ) {
                PrototypeHaptics.shared.confirm()
                withAnimation(.spring(duration: 0.32, bounce: 0.24)) {
                    loggedPulse.toggle()
                }
            }
            .scaleEffect(loggedPulse ? 0.985 : 1)

            Text("6 sets to go")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.white.opacity(0.38))
                .padding(.top, 8)
        }
        .padding(.horizontal, 22)
        .safeAreaPadding(.top, 4)
        .safeAreaPadding(.bottom, 6)
    }

    @ViewBuilder
    private var comparisonCopy: some View {
        if let previous = fixture.previous, let previousKg = fixture.previousKg {
            Text("Last time: \(previous) at \(previousKg.formatted()) kg — different weight now")
                .foregroundStyle(.white.opacity(0.64))
        } else if let previous = fixture.previous {
            if isBeating {
                Text("Beating last time's \(previous)")
                    .foregroundStyle(palette.accent)
            } else {
                Text("Last time: \(previous) — beat it")
                    .foregroundStyle(.white.opacity(0.7))
            }
        } else {
            Text("First time — just go to failure")
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private func step(_ delta: Int) {
        let oldValue = reps
        direction = delta
        reps = max(0, reps + delta)

        if let previous = fixture.previous,
           fixture.previousKg == nil,
           oldValue <= previous,
           reps > previous
        {
            PrototypeHaptics.shared.threshold()
        } else {
            PrototypeHaptics.shared.rep()
        }
    }
}

private struct CueList: View {
    let cues: [String]
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(cues, id: \.self) { cue in
                HStack(alignment: .firstTextBaseline, spacing: 11) {
                    Circle()
                        .fill(carriesTrainingEffect(cue) ? accent : Color.white.opacity(0.25))
                        .frame(width: 5, height: 5)

                    Text(cue)
                        .font(.system(size: 17, weight: carriesTrainingEffect(cue) ? .semibold : .regular))
                        .foregroundStyle(
                            carriesTrainingEffect(cue)
                                ? Color.white.opacity(0.94)
                                : Color.white.opacity(0.68)
                        )
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func carriesTrainingEffect(_ cue: String) -> Bool {
        intensityWords.contains { cue.contains($0) }
    }
}

private struct RepObject: View {
    let treatment: DawnTreatment
    let reps: Int
    let direction: Int
    let previous: Int?
    let isBeating: Bool
    let accent: Color
    let onStep: (Int) -> Void

    var body: some View {
        HStack(spacing: treatment == .tactile ? 14 : 20) {
            RepStepButton(
                symbol: "−",
                accessibilityLabel: "One rep fewer",
                treatment: treatment,
                accent: accent,
                action: { onStep(-1) }
            )

            readout
                .frame(maxWidth: treatment == .tactile ? 180 : 150)

            RepStepButton(
                symbol: "+",
                accessibilityLabel: "One rep more",
                treatment: treatment,
                accent: accent,
                action: { onStep(1) }
            )
        }
        .frame(height: treatment == .tactile ? 174 : 142)
    }

    @ViewBuilder
    private var readout: some View {
        switch treatment {
        case .atmospheric:
            VStack(spacing: 0) {
                Text(reps, format: .number)
                    .font(.system(size: 92, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: direction < 0))
                    .foregroundStyle(isBeating ? accent : .white)
                    .shadow(color: isBeating ? accent.opacity(0.72) : .clear, radius: 18)
                Text("REPS")
                    .font(.caption2.weight(.semibold))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.45))
            }
        case .precise:
            VStack(spacing: 10) {
                Text(reps, format: .number)
                    .font(.system(size: 88, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: direction < 0))
                    .foregroundStyle(isBeating ? accent : .white)

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(.white.opacity(0.16))
                            .frame(height: 1)

                        if previous != nil {
                            Rectangle()
                                .fill(isBeating ? accent : .white.opacity(0.56))
                                .frame(width: 2, height: 13)
                                .offset(x: proxy.size.width * 0.52)
                        }

                        Circle()
                            .fill(isBeating ? accent : .white)
                            .frame(width: 8, height: 8)
                            .offset(x: proxy.size.width * min(0.86, 0.1 + Double(reps) / 25))
                    }
                }
                .frame(height: 13)

                Text("REPS · CALIBRATED")
                    .font(.caption2.weight(.semibold))
                    .tracking(1.7)
                    .foregroundStyle(.white.opacity(0.42))
            }
        case .tactile:
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.16),
                                Color.black.opacity(0.32),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        Circle()
                            .stroke(
                                isBeating ? accent : Color.white.opacity(0.18),
                                lineWidth: isBeating ? 3 : 1
                            )
                    }
                    .shadow(color: .black.opacity(0.42), radius: 22, y: 14)
                    .shadow(color: isBeating ? accent.opacity(0.48) : .clear, radius: 18)

                VStack(spacing: 0) {
                    Text(reps, format: .number)
                        .font(.system(size: 76, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText(countsDown: direction < 0))
                    Text("REPS")
                        .font(.caption2.weight(.semibold))
                        .tracking(1.8)
                        .foregroundStyle(.white.opacity(0.48))
                }
            }
            .frame(width: 164, height: 164)
        }
    }
}

private struct RepStepButton: View {
    let symbol: String
    let accessibilityLabel: String
    let treatment: DawnTreatment
    let accent: Color
    let action: () -> Void

    @State private var repeatTask: Task<Void, Never>?

    var body: some View {
        Group {
            if treatment == .tactile {
                label
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24))
            } else {
                label
                    .background(
                        treatment == .precise
                            ? Color.black.opacity(0.32)
                            : Color.white.opacity(0.07),
                        in: RoundedRectangle(cornerRadius: treatment == .precise ? 16 : 24)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: treatment == .precise ? 16 : 24)
                            .stroke(
                                treatment == .precise
                                    ? accent.opacity(0.42)
                                    : Color.white.opacity(0.1),
                                lineWidth: 1
                            )
                    }
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in beginRepeating() }
                .onEnded { _ in stopRepeating() }
        )
        .onDisappear(perform: stopRepeating)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }

    private var label: some View {
        Text(symbol)
            .font(.system(size: 34, weight: .medium, design: .rounded))
            .frame(width: 82, height: 82)
            .foregroundStyle(.white)
    }

    private func beginRepeating() {
        guard repeatTask == nil else { return }
        action()
        repeatTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(380))
            var delay = 210
            while !Task.isCancelled {
                action()
                try? await Task.sleep(for: .milliseconds(delay))
                delay = max(60, Int(Double(delay) * 0.78))
            }
        }
    }

    private func stopRepeating() {
        repeatTask?.cancel()
        repeatTask = nil
    }
}

private struct RestPrototypeView: View {
    let treatment: DawnTreatment
    let scenario: RestScenario
    let progress: Double
    let onClose: () -> Void

    @State private var endDate = Date()
    @State private var answerRevealed = false

    private let fixture: RestFixture

    init(
        treatment: DawnTreatment,
        scenario: RestScenario,
        progress: Double,
        onClose: @escaping () -> Void
    ) {
        self.treatment = treatment
        self.scenario = scenario
        self.progress = progress
        self.onClose = onClose
        fixture = RestFixture.fixture(for: scenario)
    }

    private var palette: DawnPalette {
        DawnPalette(progress: progress)
    }

    var body: some View {
        VStack(spacing: 0) {
            PrototypeChrome(
                progress: progress,
                treatment: treatment,
                step: "Rest · 9 / 21",
                onBack: onClose
            )

            Text("REST")
                .font(.caption2.weight(.semibold))
                .tracking(2.2)
                .foregroundStyle(.white.opacity(0.42))
                .padding(.top, 8)

            Spacer(minLength: 8)

            TimelineView(.animation) { context in
                let remaining = max(0, endDate.timeIntervalSince(context.date))
                RestTimerObject(
                    treatment: treatment,
                    remaining: remaining,
                    total: Double(fixture.seconds),
                    compact: fixture.question != nil && answerRevealed,
                    accent: palette.accent
                )
            }

            if scenario == .myo {
                Text("The 20-second rest IS the mechanism. Don't stretch it.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.accent)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .padding(.top, 12)
            }

            if let question = fixture.question {
                StudyCardPrototype(
                    treatment: treatment,
                    topic: fixture.topic ?? "",
                    question: question,
                    answer: fixture.answer ?? "",
                    revealed: answerRevealed,
                    accent: palette.accent,
                    onReveal: revealAnswer
                )
                .padding(.top, 10)
            } else {
                Spacer(minLength: 8)
            }

            Spacer(minLength: 10)

            VStack(spacing: 3) {
                Text("NEXT")
                    .font(.caption2.weight(.semibold))
                    .tracking(1.8)
                    .foregroundStyle(.white.opacity(0.4))

                HStack(spacing: 5) {
                    Text(fixture.nextExercise)
                        .font(.headline)
                    if let sub = fixture.nextSub {
                        Text("· \(sub)")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.62))
                    }
                }
                .lineLimit(1)
                .minimumScaleFactor(0.8)

                Text(fixture.nextMeta)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.5))
            }

            HStack(spacing: 10) {
                DawnSecondaryButton(
                    title: "+15s",
                    treatment: treatment,
                    accent: palette.accent
                ) {
                    endDate = endDate.addingTimeInterval(15)
                    PrototypeHaptics.shared.rep()
                }

                DawnSecondaryButton(
                    title: "Skip →",
                    treatment: treatment,
                    accent: palette.accent
                ) {
                    PrototypeHaptics.shared.confirm()
                    resetTimer()
                }
            }
            .padding(.top, 12)
        }
        .padding(.horizontal, 22)
        .safeAreaPadding(.top, 4)
        .safeAreaPadding(.bottom, 8)
        .onAppear(perform: resetTimer)
        .task(id: scenario) {
            guard fixture.question != nil else { return }
            try? await Task.sleep(for: .milliseconds(9600))
            guard !Task.isCancelled else { return }
            revealAnswer()
        }
    }

    private func resetTimer() {
        endDate = Date().addingTimeInterval(Double(fixture.seconds))
        answerRevealed = false
    }

    private func revealAnswer() {
        guard !answerRevealed else { return }
        PrototypeHaptics.shared.reveal()
        withAnimation(.spring(duration: 0.5, bounce: 0.12)) {
            answerRevealed = true
        }
    }
}

private struct RestTimerObject: View {
    let treatment: DawnTreatment
    let remaining: TimeInterval
    let total: Double
    let compact: Bool
    let accent: Color

    private var fraction: Double {
        total > 0 ? min(1, max(0, remaining / total)) : 0
    }

    private var size: Double {
        compact ? 104 : (treatment == .tactile ? 216 : 204)
    }

    var body: some View {
        ZStack {
            if treatment == .atmospheric {
                Circle()
                    .stroke(.white.opacity(0.1), lineWidth: 7)
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(
                        accent,
                        style: StrokeStyle(lineWidth: 7, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: accent.opacity(0.65), radius: 12)
            } else if treatment == .precise {
                Circle()
                    .stroke(.white.opacity(0.12), lineWidth: 1)
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(
                        accent,
                        style: StrokeStyle(lineWidth: 3, lineCap: .square, dash: [2, 5])
                    )
                    .rotationEffect(.degrees(-90))
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.16), .black.opacity(0.34)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        Circle()
                            .trim(from: 0, to: fraction)
                            .stroke(
                                accent,
                                style: StrokeStyle(lineWidth: 5, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                    }
                    .shadow(color: .black.opacity(0.45), radius: 24, y: 14)
                    .shadow(color: accent.opacity(0.34), radius: 16)
            }

            VStack(spacing: -2) {
                Text(Int(ceil(remaining)), format: .number)
                    .font(.system(size: compact ? 46 : 82, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: true))
                Text("SEC")
                    .font(.caption2.weight(.semibold))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.42))
            }
        }
        .frame(width: size, height: size)
        .animation(.spring(duration: 0.55, bounce: 0.1), value: compact)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Int(ceil(remaining))) seconds remaining")
    }
}

private struct StudyCardPrototype: View {
    let treatment: DawnTreatment
    let topic: String
    let question: String
    let answer: String
    let revealed: Bool
    let accent: Color
    let onReveal: () -> Void

    var body: some View {
        Button(action: onReveal) {
            VStack(alignment: .leading, spacing: 9) {
                Text(topic)
                    .font(.caption2.weight(.semibold))
                    .tracking(1.8)
                    .foregroundStyle(accent)

                Text(question)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(.white.opacity(0.13))
                        .frame(height: 1)
                    Rectangle()
                        .fill(revealed ? .white.opacity(0.24) : accent)
                        .frame(width: revealed ? nil : 92, height: revealed ? 1 : 2)
                }

                if revealed {
                    Text(answer)
                        .font(.system(size: 14.5))
                        .foregroundStyle(.white.opacity(0.68))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.blurReplace.combined(with: .opacity))
                } else {
                    Text("Tap if you have it")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.42))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(
            treatment == .tactile && revealed
                ? EdgeInsets(top: 13, leading: 15, bottom: 14, trailing: 15)
                : EdgeInsets()
        )
        .background(
            treatment == .tactile && revealed
                ? Color.black.opacity(0.22)
                : .clear,
            in: RoundedRectangle(cornerRadius: 20)
        )
        .accessibilityLabel(revealed ? "\(question) \(answer)" : "\(question). Reveal answer.")
    }
}

private struct DawnPrimaryButton: View {
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
                .foregroundStyle(treatment == .tactile ? Color.white : Color.black.opacity(0.78))
                .background {
                    if treatment != .tactile {
                        RoundedRectangle(cornerRadius: treatment == .precise ? 16 : 22)
                            .fill(accent)
                            .shadow(
                                color: accent.opacity(treatment == .atmospheric ? 0.42 : 0.18),
                                radius: 13,
                                y: 6
                            )
                    }
                }
        }
        .buttonStyle(.plain)
        .modifier(TactileGlassButton(treatment: treatment, accent: accent))
    }
}

private struct DawnSecondaryButton: View {
    let title: String
    let treatment: DawnTreatment
    let accent: Color
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
                            .fill(Color.black.opacity(treatment == .precise ? 0.32 : 0.16))
                            .overlay {
                                RoundedRectangle(cornerRadius: treatment == .precise ? 15 : 20)
                                    .stroke(
                                        treatment == .precise
                                            ? accent.opacity(0.4)
                                            : Color.white.opacity(0.12),
                                        lineWidth: 1
                                    )
                            }
                    }
                }
        }
        .buttonStyle(.plain)
        .modifier(TactileGlassButton(treatment: treatment, accent: accent))
    }
}

private struct TactileGlassButton: ViewModifier {
    let treatment: DawnTreatment
    let accent: Color

    func body(content: Content) -> some View {
        if treatment == .tactile {
            content
                .glassEffect(
                    .regular.tint(accent.opacity(0.22)).interactive(),
                    in: .rect(cornerRadius: 22)
                )
        } else {
            content
        }
    }
}
