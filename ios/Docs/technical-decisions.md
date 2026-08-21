# Technical decisions

Current after W1 research. Revisit only when a running prototype provides
evidence, not because a package is fashionable.

## Baseline

- iOS 26 deployment target, iPhone only, portrait only.
- Xcode 27 beta while Eden's physical phone runs iOS 27 beta.
- Swift 6 with approachable concurrency and MainActor default isolation in the
  app target.
- SwiftUI for application structure and screens.
- Zero third-party runtime dependencies for the baseline.

## State

- Use Observation (`@Observable`) for the small mutable application/session
  model.
- Own app state with `@State`, distribute it through `@Environment`, and use
  `@Bindable` only where a view genuinely needs a binding.
- Keep program, steps, records, and persistence snapshots as plain value types.
- Timer state is an absolute `endsAt`; displayed remaining time is derived.
- Inject storage, clock, audio, and haptic services through small app-owned
  protocols/initializers. Do not add TCA or a dependency framework.

## Persistence

- Preserve the exact v1 `Codable` JSON schema.
- One atomic history file in Application Support.
- One separate atomic in-progress-session file.
- Surface write failures; never silently drop a session.
- No SwiftData or Core Data: the dataset is tiny, loaded whole, and must export
  byte-compatible JSON.
- `UserDefaults` is for genuine preferences only, never history.

## Rendering

- `MeshGradient` for authored dawn atmosphere.
- `Canvas` for the timer, year grid, and effects where one draw pass is cheaper
  than many view nodes.
- SwiftUI `colorEffect` first; `layerEffect` only when neighbouring-pixel
  sampling earns its cost.
- Shader use is limited to measured improvements such as gradient dithering,
  subtle grain, or restrained atmospheric scattering.
- Precompile visible shaders before first use.
- Liquid Glass is an interactive control/navigation layer, not a content
  background. Group custom glass in one `GlassEffectContainer`.
- Use SF Pro optical sizes, width/weight variants, `.monospacedDigit()`, and
  numeric content transitions before considering custom type.

## Motion

- `matchedGeometryEffect` for identity that carries between Set and Rest.
- `PhaseAnimator` / `KeyframeAnimator` for authored sequences.
- `TimelineView(.animation)` reads absolute time; it must not mutate observable
  state every frame.
- The system controls cadence. Profile on the iPhone 16 Pro before considering a
  `CADisplayLink`.
- Every transition remains interruptible and has a calmer semantic Reduce
  Motion form.
- Animate transforms and opacity before blur radius, complex masks, or live
  refraction.

## Haptics

- One app-owned `CHHapticEngine`.
- AHAP resources are appropriate for shaped patterns that need tuning.
- `UIFeedbackGenerator` or SwiftUI sensory feedback is limited to simple
  transients.
- Handle capability checks, interruption stops, reset recovery, engine restart,
  and player/resource recreation.
- Device acceptance distinguishes ordinary rep, passing last time, countdown,
  zero, and completion with the phone face down.

## Audio

Eden chose countdown reliability and music ducking over respecting the silent
switch.

- `AVAudioSession` category `.playback` with `.duckOthers`.
- Activate once at T−5, keep one duck through zero, then deactivate with
  `.notifyOthersOnDeactivation`.
- Do not keep the session active for the workout.
- Card reveal remains silent.
- `.ambient + .duckOthers` is not a valid Apple audio-session combination.

## Testing

- Keep the 53 existing acceptance assertions in XCTest and unskip them in their
  owning workstreams.
- XCTest remains for UI and performance tests.
- New pure logic may use Swift Testing where parameterization materially helps;
  both frameworks can coexist.
- Each persistence test gets an isolated temporary directory.
- Consider `swift-snapshot-testing` only as a test-target dependency after a
  smoke test on the exact Xcode/iOS renderer. Freeze time, locale, appearance,
  motion, and shaders.
- Prefer extracted-model tests, accessibility-visible behavior, and XCUI flows
  over ViewInspector hierarchy coupling.

## Conditional experiments

### Rive

Trial only for a real authored exercise figure whose state machine or
interactivity is visibly better than native paths. Hide it behind one adapter.
Reject it if the result is merely a looping illustration.

### Lottie

No baseline use. Consider only if a supplied After Effects asset cannot
reasonably be authored with native animation while preserving live colour,
state, and Reduce Motion.

## Rejected baseline dependencies

- TCA / `swift-dependencies`: disproportionate for one linear workout machine.
- Pow: overlaps native motion and risks generic delight.
- Shimmer packages: there is no network loading state.
- ViewInspector: couples tests to SwiftUI internals.
- Sentry and remote analytics: network, privacy, binary, and governance costs
  with no value for one personal offline user.

## Dependency gate

Add a package only when all are true:

1. Native APIs cannot reach the required quality without substantial custom
   infrastructure.
2. A running device prototype demonstrates a meaningful core-flow improvement.
3. It remains fully offline and adds no undeclared telemetry.
4. Frame time, launch, memory, thread, and binary costs are measured.
5. It builds cleanly under the exact Swift 6/Xcode configuration.
6. It is maintained, licensed appropriately, and has manageable dependencies.
7. It is hidden behind a small app-owned adapter.
8. Removing it never requires persisted-data migration or architecture rewrite.
