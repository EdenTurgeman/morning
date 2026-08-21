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

enum PrototypeMode: String, CaseIterable, Identifiable {
    case set
    case rest

    var id: Self {
        self
    }
}

enum SetScenario: String, CaseIterable, Identifiable {
    case firstRun = "First run"
    case loadedFirstRun = "Loaded first run"
    case comparable = "Comparable"
    case beating = "13 → 14"
    case changedWeight = "Changed weight"
    case superset = "Superset"
    case supersetSecond = "Superset 2 of 2"
    case myo = "Myo"
    case myoSecond = "Myo set 2"
    case longContent = "Longest content"

    var id: Self {
        self
    }

    static func scenario(for launchValue: String) -> SetScenario {
        if launchValue.contains("loaded-first") {
            return .loadedFirstRun
        }
        if launchValue.contains("superset-second") {
            return .supersetSecond
        }
        if launchValue.contains("myo-second") {
            return .myoSecond
        }
        if launchValue.contains("changed-weight") {
            return .changedWeight
        }
        if launchValue.contains("long-content") {
            return .longContent
        }
        if launchValue.contains("first-run") {
            return .firstRun
        }
        if launchValue.contains("beating") {
            return .beating
        }
        if launchValue.contains("superset") {
            return .superset
        }
        if launchValue.contains("myo") {
            return .myo
        }
        return .comparable
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
        _setScenario = State(initialValue: SetScenario.scenario(for: value))
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
                onClose: { isPresentingPrototype = false },
                onAdvanceFromSet: {
                    withAnimation(stageAnimation) {
                        restScenario = setScenario == .myo || setScenario == .myoSecond ? .myo : .plain
                        mode = .rest
                    }
                },
                onAdvanceFromRest: {
                    withAnimation(stageAnimation) {
                        setScenario = restScenario == .myo ? .myoSecond : .comparable
                        mode = .set
                    }
                }
            )
            .id(treatment.rawValue)
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

    private var stageAnimation: Animation {
        if reduceMotion {
            return .linear(duration: 0.12)
        }
        switch treatment {
        case .atmospheric: return .easeInOut(duration: 0.44)
        case .precise: return .easeOut(duration: 0.22)
        case .tactile: return .spring(duration: 0.36, bounce: 0.14)
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
        .onAppear {
            PrototypeHaptics.shared.prewarm()
        }
    }
}

private struct PrototypeStage: View {
    let treatment: DawnTreatment
    let mode: PrototypeMode
    let setScenario: SetScenario
    let restScenario: RestScenario
    let progress: Double
    let onClose: () -> Void
    let onAdvanceFromSet: () -> Void
    let onAdvanceFromRest: () -> Void
    @Namespace private var workObjectNamespace
    @State private var thresholdCrossed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            DawnBackdrop(
                treatment: treatment,
                mode: mode,
                progress: progress,
                thresholdCrossed: mode == .set && thresholdCrossed
            )

            switch mode {
            case .set:
                SetPrototypeView(
                    treatment: treatment,
                    scenario: setScenario,
                    progress: progress,
                    namespace: workObjectNamespace,
                    onClose: onClose,
                    onAdvance: onAdvanceFromSet,
                    onThresholdChange: { thresholdCrossed = $0 }
                )
                .transition(stageTransition)
            case .rest:
                RestPrototypeView(
                    treatment: treatment,
                    scenario: restScenario,
                    progress: progress,
                    namespace: workObjectNamespace,
                    onClose: onClose,
                    onAdvance: onAdvanceFromRest
                )
                .transition(stageTransition)
            }
        }
        .dynamicTypeSize(.large)
        .preferredColorScheme(.dark)
        .onAppear {
            PrototypeHaptics.shared.prewarm()
            thresholdCrossed = setScenario == .beating
        }
        .onChange(of: setScenario) { _, scenario in
            thresholdCrossed = scenario == .beating
        }
    }

    private var stageTransition: AnyTransition {
        guard !reduceMotion else { return .opacity }
        switch treatment {
        case .atmospheric:
            return .opacity
        case .precise:
            return .asymmetric(
                insertion: .offset(x: 12).combined(with: .opacity),
                removal: .offset(x: -12).combined(with: .opacity)
            )
        case .tactile:
            return .scale(scale: 0.98).combined(with: .opacity)
        }
    }
}

private struct SetPrototypeView: View {
    let treatment: DawnTreatment
    let scenario: SetScenario
    let progress: Double
    let namespace: Namespace.ID
    let onClose: () -> Void
    let onAdvance: () -> Void
    let onThresholdChange: (Bool) -> Void

    @State private var reps: Int
    @State private var direction = 1
    @State private var loggedPulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let fixture: SetFixture

    init(
        treatment: DawnTreatment,
        scenario: SetScenario,
        progress: Double,
        namespace: Namespace.ID,
        onClose: @escaping () -> Void,
        onAdvance: @escaping () -> Void,
        onThresholdChange: @escaping (Bool) -> Void
    ) {
        self.treatment = treatment
        self.scenario = scenario
        self.progress = progress
        self.namespace = namespace
        self.onClose = onClose
        self.onAdvance = onAdvance
        self.onThresholdChange = onThresholdChange
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
                        .foregroundStyle(.white.opacity(0.78))
                }

                Text(fixture.meta)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.72))

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
                Text("Target · \(fixture.target)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.74))

                RepObject(
                    treatment: treatment,
                    reps: reps,
                    direction: direction,
                    previous: isComparable ? fixture.previous : nil,
                    isBeating: isBeating,
                    accent: palette.accent,
                    namespace: namespace,
                    onStep: step
                )

                comparisonCopy
                    .font(.subheadline)
                    .frame(minHeight: 22)
            }

            Spacer(minLength: 8)

            DawnPrimaryButton(
                title: "Done",
                treatment: treatment,
                accent: palette.accent
            ) {
                PrototypeHaptics.shared.confirm(treatment: treatment)
                withAnimation(reduceMotion ? .linear(duration: 0.01) : .spring(duration: 0.32, bounce: 0.24)) {
                    loggedPulse.toggle()
                }
                onAdvance()
            }
            .scaleEffect(loggedPulse && !reduceMotion ? 0.985 : 1)

            Text("6 sets to go")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.white.opacity(0.68))
                .padding(.top, 8)
        }
        .padding(.horizontal, 22)
        .safeAreaPadding(.top, 4)
        .safeAreaPadding(.bottom, 6)
        .task {
            guard (ProcessInfo.processInfo.arguments.last ?? "").contains("autoplay") else { return }
            try? await Task.sleep(for: .milliseconds(1200))
            guard !Task.isCancelled else { return }
            onAdvance()
        }
    }

    @ViewBuilder
    private var comparisonCopy: some View {
        if let previous = fixture.previous, let previousKg = fixture.previousKg {
            Text("Last time: \(previous) at \(previousKg.formatted()) kg — different weight now")
                .foregroundStyle(.white.opacity(0.72))
        } else if let previous = fixture.previous {
            if isBeating {
                Text("Beating last time's \(previous)")
                    .foregroundStyle(Color.morningSuccess)
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
        let newValue = max(0, reps + delta)
        direction = delta
        withAnimation(stepAnimation) {
            reps = newValue
        }
        onThresholdChange(isComparable && newValue > (fixture.previous ?? .max))

        if let previous = fixture.previous,
           fixture.previousKg == nil,
           oldValue <= previous,
           newValue > previous
        {
            PrototypeHaptics.shared.threshold(treatment: treatment)
        } else {
            PrototypeHaptics.shared.rep(treatment: treatment)
        }
    }

    private var stepAnimation: Animation {
        if reduceMotion {
            return .linear(duration: 0.08)
        }
        switch treatment {
        case .atmospheric: return .easeOut(duration: 0.18)
        case .precise: return .linear(duration: 0.12)
        case .tactile: return .spring(duration: 0.28, bounce: 0.22)
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
                                : Color.white.opacity(0.76)
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
    let namespace: Namespace.ID
    let onStep: (Int) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GlassEffectContainer(spacing: 14) {
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
                    .workObjectContinuity(
                        id: "work-object-\(treatment.rawValue)",
                        in: namespace
                    )

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
    }

    @ViewBuilder
    private var readout: some View {
        switch treatment {
        case .atmospheric:
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 0) {
                    Text(reps, format: .number)
                        .font(.system(size: 92, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(reduceMotion ? .opacity : .numericText(countsDown: direction < 0))
                        .foregroundStyle(isBeating ? Color.morningSuccess : .white)
                        .shadow(
                            color: isBeating ? Color.morningSuccess.opacity(0.38) : .clear,
                            radius: 8
                        )
                    Text("Reps")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.72))
                }

                if let previous {
                    Text("Last \(previous)")
                        .font(.caption2.weight(.bold).monospacedDigit())
                        .foregroundStyle(isBeating ? Color.black.opacity(0.72) : .white.opacity(0.76))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            isBeating ? Color.morningSuccess : Color.white.opacity(0.1),
                            in: Capsule()
                        )
                        .offset(x: 11, y: 5)
                }
            }
        case .precise:
            let previousValue = previous ?? reps
            let delta = min(2, max(-2, reps - previousValue))

            VStack(spacing: 10) {
                Text(reps, format: .number)
                    .font(.system(size: 88, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(reduceMotion ? .opacity : .numericText(countsDown: direction < 0))
                    .foregroundStyle(isBeating ? Color.morningSuccess : .white)

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(.white.opacity(0.16))
                            .frame(height: 1)

                        if previous != nil {
                            Rectangle()
                                .fill(isBeating ? Color.morningSuccess : .white.opacity(0.56))
                                .frame(width: 2, height: 13)
                                .offset(x: proxy.size.width * 0.5)
                        }

                        Circle()
                            .fill(isBeating ? Color.morningSuccess : .white)
                            .frame(width: 8, height: 8)
                            .offset(x: proxy.size.width * (0.5 + Double(delta) * 0.17) - 4)
                    }
                }
                .frame(height: 13)

                Text(previous.map { "Last \($0)" } ?? "First set")
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.72))
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
                                isBeating ? Color.morningSuccess : Color.white.opacity(0.18),
                                lineWidth: isBeating ? 4 : 1
                            )
                    }
                    .shadow(color: .black.opacity(0.36), radius: 16, y: 10)
                    .shadow(color: isBeating ? Color.morningSuccess.opacity(0.18) : .clear, radius: 7)

                VStack(spacing: 2) {
                    if let previous {
                        Text("LAST \(previous)")
                            .font(.caption2.weight(.bold).monospacedDigit())
                            .tracking(1)
                            .foregroundStyle(isBeating ? Color.morningSuccess : .white.opacity(0.66))
                    }

                    Text(reps, format: .number)
                        .font(.system(size: 76, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(reduceMotion ? .opacity : .numericText(countsDown: direction < 0))
                    Text("Reps")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.72))
                }

                Capsule()
                    .fill(isBeating ? Color.morningSuccess : .white.opacity(0.34))
                    .frame(width: isBeating ? 32 : 20, height: 4)
                    .offset(y: -70)
            }
            .frame(width: 164, height: 164)
            .scaleEffect(isBeating ? 1.035 : 1)
            .rotation3DEffect(
                .degrees(reduceMotion ? 0 : Double(direction) * (isBeating ? 0.8 : 1.4)),
                axis: (x: 1, y: 0, z: 0)
            )
            .animation(.spring(duration: 0.28, bounce: 0.22), value: reps)
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
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        Group {
            if treatment == .tactile {
                if reduceTransparency {
                    label
                        .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 24))
                        .overlay {
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(.white.opacity(0.26), lineWidth: 1)
                        }
                } else {
                    label
                        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24))
                }
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
        .accessibilityAction(named: Text(accessibilityLabel), action)
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
            try? await Task.sleep(for: .milliseconds(initialRepeatDelay))
            var delay = repeatDelay
            while !Task.isCancelled {
                action()
                try? await Task.sleep(for: .milliseconds(delay))
                delay = max(60, Int(Double(delay) * repeatAcceleration))
            }
        }
    }

    private func stopRepeating() {
        repeatTask?.cancel()
        repeatTask = nil
    }

    private var initialRepeatDelay: Int {
        switch treatment {
        case .atmospheric: 410
        case .precise: 340
        case .tactile: 380
        }
    }

    private var repeatDelay: Int {
        switch treatment {
        case .atmospheric: 230
        case .precise: 170
        case .tactile: 210
        }
    }

    private var repeatAcceleration: Double {
        switch treatment {
        case .atmospheric: 0.8
        case .precise: 0.72
        case .tactile: 0.78
        }
    }
}

private struct RestPrototypeView: View {
    let treatment: DawnTreatment
    let scenario: RestScenario
    let progress: Double
    let namespace: Namespace.ID
    let onClose: () -> Void
    let onAdvance: () -> Void

    @State private var endDate = Date()
    @State private var answerRevealed = false
    @State private var hasFinished = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let fixture: RestFixture
    private let frozenRemaining: TimeInterval?

    init(
        treatment: DawnTreatment,
        scenario: RestScenario,
        progress: Double,
        namespace: Namespace.ID,
        onClose: @escaping () -> Void,
        onAdvance: @escaping () -> Void
    ) {
        self.treatment = treatment
        self.scenario = scenario
        self.progress = progress
        self.namespace = namespace
        self.onClose = onClose
        self.onAdvance = onAdvance
        fixture = RestFixture.fixture(for: scenario)
        let prototypeArgument = ProcessInfo.processInfo.arguments.last ?? ""
        frozenRemaining = prototypeArgument.contains("snapshot")
            ? TimeInterval(scenario == .myo ? 5 : 45)
            : nil
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

            Spacer(minLength: 24)

            TimelineView(.animation) { context in
                let remaining = frozenRemaining ?? max(0, endDate.timeIntervalSince(context.date))
                RestTimerObject(
                    treatment: treatment,
                    remaining: remaining,
                    total: Double(fixture.seconds),
                    compact: fixture.question != nil && answerRevealed,
                    accent: palette.accent,
                    namespace: namespace
                )
            }

            if scenario == .myo {
                Text("The 20-second rest IS the mechanism — don't stretch it")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(red: 1, green: 0.76, blue: 0.34))
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
                Text("Next")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.72))

                HStack(spacing: 5) {
                    Text(fixture.nextExercise)
                        .font(.headline)
                    if let sub = fixture.nextSub {
                        Text("· \(sub)")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.72))
                    }
                }
                .lineLimit(1)
                .minimumScaleFactor(0.8)

                Text(fixture.nextMeta)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.72))
            }

            GlassEffectContainer(spacing: 10) {
                HStack(spacing: 10) {
                    DawnSecondaryButton(
                        title: "+15s",
                        treatment: treatment,
                        accent: palette.accent,
                        quiet: scenario == .myo
                    ) {
                        endDate = max(endDate, Date()).addingTimeInterval(15)
                        hasFinished = false
                        PrototypeHaptics.shared.rep(treatment: treatment)
                    }

                    DawnSecondaryButton(
                        title: "Skip →",
                        treatment: treatment,
                        accent: palette.accent
                    ) {
                        PrototypeHaptics.shared.confirm(treatment: treatment)
                        finishRest(signalsZero: false)
                    }
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
        .task(id: endDate) {
            guard frozenRemaining == nil else { return }
            let milliseconds = max(0, Int(endDate.timeIntervalSinceNow * 1000))
            try? await Task.sleep(for: .milliseconds(milliseconds))
            guard !Task.isCancelled else { return }
            finishRest()
        }
    }

    private func resetTimer() {
        endDate = Date().addingTimeInterval(Double(fixture.seconds))
        answerRevealed = false
        hasFinished = false
    }

    private func revealAnswer() {
        guard !answerRevealed else { return }
        PrototypeHaptics.shared.reveal(treatment: treatment)
        let animation: Animation = reduceMotion
            ? .easeOut(duration: 0.18)
            : .spring(duration: 0.5, bounce: 0.12)
        withAnimation(animation) {
            answerRevealed = true
        }
    }

    private func finishRest(signalsZero: Bool = true) {
        guard !hasFinished else { return }
        hasFinished = true
        if signalsZero {
            PrototypeHaptics.shared.zero(treatment: treatment)
        }
        onAdvance()
    }
}

private struct RestTimerObject: View {
    let treatment: DawnTreatment
    let remaining: TimeInterval
    let total: Double
    let compact: Bool
    let accent: Color
    let namespace: Namespace.ID

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var fraction: Double {
        total > 0 ? min(1, max(0, remaining / total)) : 0
    }

    private var size: Double {
        compact ? 136 : (treatment == .tactile ? 216 : 204)
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
                    .shadow(color: accent.opacity(0.3), radius: 6)
            } else if treatment == .precise {
                PreciseTimerTicks(
                    segments: max(1, Int(total)),
                    fraction: fraction,
                    accent: accent
                )
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
                    .shadow(color: accent.opacity(0.14), radius: 8)
            }

            VStack(spacing: -2) {
                Text(Int(ceil(remaining)), format: .number)
                    .font(.system(size: compact ? 64 : 82, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(reduceMotion ? .opacity : .numericText(countsDown: true))
                Text("SEC")
                    .font(.caption.weight(.semibold))
                    .tracking(1.2)
                    .foregroundStyle(.white.opacity(0.72))
            }
        }
        .frame(width: size, height: size)
        .workObjectContinuity(
            id: "work-object-\(treatment.rawValue)",
            in: namespace
        )
        .animation(
            reduceMotion
                ? .easeOut(duration: 0.18)
                : .spring(duration: 0.55, bounce: 0.1),
            value: compact
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Int(ceil(remaining))) seconds remaining")
    }
}

private struct PreciseTimerTicks: View {
    let segments: Int
    let fraction: Double
    let accent: Color

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let outerRadius = min(size.width, size.height) / 2
            let activeSegments = Int(ceil(Double(segments) * fraction))

            for index in 0 ..< segments {
                let angle = Double(index) / Double(segments) * .pi * 2 - .pi / 2
                let innerRadius = outerRadius - (index.isMultiple(of: 5) ? 11 : 7)
                let start = CGPoint(
                    x: center.x + cos(angle) * innerRadius,
                    y: center.y + sin(angle) * innerRadius
                )
                let finish = CGPoint(
                    x: center.x + cos(angle) * outerRadius,
                    y: center.y + sin(angle) * outerRadius
                )
                var path = Path()
                path.move(to: start)
                path.addLine(to: finish)
                context.stroke(
                    path,
                    with: .color(index < activeSegments ? accent : .white.opacity(0.14)),
                    lineWidth: index.isMultiple(of: 5) ? 2 : 1
                )
            }
        }
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
                        .foregroundStyle(.white.opacity(0.78))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity)
                } else {
                    Text("Tap if you have it")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
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
