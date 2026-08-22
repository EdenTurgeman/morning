# Research notes

Deliverable 1 of `02-design-brief.md §11`.

Research completed 2026-08-21 before native visual work. Eden's direction after
reviewing the evidence is explicit: **keep Morning's sunrise identity, but do
not copy the web composition. Carry the spirit and make it smoother, more
physical, more legible, and unmistakably native.**

## Method

The available screen-library MCPs required paid plans. Eden chose public,
inspectable evidence instead:

- official product and help documentation
- App Store listing creatives, used only for visible composition
- public demos and walkthroughs, used for interaction claims
- Apple design profiles, HIG, and platform documentation
- a complete local traversal of Morning sessions A and B

Marketing screenshots were never treated as proof of interaction. Observed
behaviour and our adaptation are separated below.

## Morning itself — complete A and B sessions

Both web sessions were completed from Home through Summary while reading
`04-rules.md`.

- A: 21 steps, 13 sets, two carded rests.
- B: 25 steps, 14 sets, two carded rests, three 20-second myo rests.
- Bodyweight sets correctly default to 10 reps; loaded sets default to 12.
- Back preserves the value entered in the current session.
- Superset partners transition directly; rest begins only after the pair.
- Timers advance automatically from an absolute end time.
- The final myo rest is an intentional inter-block gap before Floor fly.
- Daybreak is a separate overlay above an already-mounted Summary.

What survives:

- progress expressed as a dawn rather than a step counter
- one set, one action, one-tap common case
- the previous comparable set at the moment of action
- automatic Rest and automatic card reveal
- the sun finally clearing the horizon as completion

What does not survive:

- fixed-header / scrolling-middle / pinned-footer workout layout
- any internal scrolling during Set or Rest
- small close-range type and web-safe control sizing
- Summary animation and card timing beginning invisibly under Daybreak
- DOM/CSS safe-area, viewport, audio-unlock, and storage workarounds

## References studied

### SmartGym — inline logging

Sources:

- <https://apps.apple.com/us/app/smartgym-gym-home-workouts/id922744883>
- <https://help.smartgymapp.com/article/138-configure-iphones-action-button>
- <https://9to5mac.com/2026/07/23/smartgym-update-makes-it-easier-to-manually-adjust-and-log-exercises-on-the-go/>

**Mechanic.** One active set keeps planned and actual values together; one
contextual action logs the set and begins Rest.

**Left out.** The useful focused mode avoids showing the whole workout at once.

**Hard case.** Resumed workouts, supersets, final sets, and active timers alter
the action without losing the current values.

**Take.** One set and one unmistakable primary action.

**Reject.** Its generic gym-dashboard identity, editable-program clutter,
prediction, tables, and impersonal messaging. Morning already knows exactly
what the action is and why it matters.

### Ladder — Rest as preparation

Sources:

- <https://www.joinladder.com/app/workout/23163dac-6651-45a4-98b5-46fe93a76675?hideEmailCapture=1>
- <https://www.youtube.com/watch?v=VE1Q0YppQeo>

**Mechanic.** Rest previews the next movement and warns before transition.

**Left out.** The active player reduces navigation and setup decisions.

**Hard case.** Preparation time can be added and sections can be replayed.

**Take.** Rest should answer both “how long?” and “what is next?” from a
distance.

**Reject.** Video-first hierarchy and swipe-only navigation.

### Seconds — distance-legible countdown

Sources:

- <https://apps.apple.com/us/app/seconds-pro-interval-timer/id363978811>
- <https://play.google.com/store/apps/details?id=com.runloop.seconds&hl=en_GB>

**Mechanic.** A full-screen countdown, current interval, next interval, and
spoken warnings are designed to work without holding the phone.

**Left out.** No logging or workout dashboard competes with time.

**Hard case.** It remains useful with the screen off through audio.

**Take.** The countdown is the visual fact; the ring is supporting evidence.

**Reject.** Colour as the only Set/Rest distinction.

### Hevy and Strong — automatic Rest

Sources:

- <https://www.hevyapp.com/features/workout-rest-timer/>
- <https://www.hevyapp.com/features/track-exercises/>
- <https://help.strongapp.io/article/231-rest-timer>

**Mechanic.** Logging a set starts Rest automatically; previous values are
available during the live workout; Rest has explicit adjustment and Skip.

**Left out.** Deep exercise history can remain outside the active action.

**Hard case.** New sets have no invented history, and timers remain visible
through Live Activities.

**Take.** Prefill known values and expose only the relevant comparator.

**Reject.** Spreadsheet set tables and compact timers that require a tap to
become readable.

### Endel — environment as state

Sources:

- <https://endel.io/>
- <https://endel.io/technology>
- <https://60fps.design/shots/endel-adjust-sound-pad-slider-interaction>

**Mechanic.** One state value continuously changes sound and generative visuals;
finite scenarios have authored beginnings, middles, and endings.

**Left out.** Persistent dashboards and explanatory chrome disappear during the
active experience.

**Hard case.** Endless soundscapes and finite sessions use different timing
models.

**Take.** Let one semantic workout-progress value drive sky, light, accent,
timer, and completion.

**Reject.** Incidental sensor-driven colour. Morning progress must remain
predictable and repeatable.

### Portal and Calm — authored atmosphere

Sources:

- <https://portal.app/>
- <https://portal.app/faq/what-is-the-difference-between-the-focus-sleep-escape-modes>
- <https://support.calm.com/hc/en-us/articles/360053428413-Calm-App-in-Dark-Mode-iOS-13>

**Mechanic.** Atmosphere can fill the screen while controls recede; Calm authors
real day/night variants rather than filtering every scene.

**Left out.** Controls do not stay visible merely to advertise capability.

**Hard case.** OLED use, hardware limitations, and unsupported scenes are stated
honestly.

**Take.** Author the key dawn phases by eye, then interpolate.

**Reject.** Photorealistic scenery and uncontrolled gradients behind text.

### Halide — precision without a cockpit

Sources:

- <https://developer.apple.com/news/?id=x6bv1a36>
- <https://www.lux.camera/introducing-halide/>
- <https://medium.com/halide/introducing-halide-mkii-30f9f2bceac3>

**Mechanic.** Precision tools appear only when relevant; controls retain stable
thumb positions; numeric state is explicit rather than colour-only.

**Left out.** It does not show every camera control simultaneously.

**Hard case.** Left/right reach, ambiguous active modes, and changing phone
sizes were tested directly.

**Take.** Stable controls, tabular numerals, explicit comparison validity, and
short mechanical motion.

**Reject.** Tiny engraved labels and a cold camera-instrument brand.

### Things 3 and Bear — restrained native material

Sources:

- <https://culturedcode.com/things/features/>
- <https://culturedcode.com/things/blog/2025/09/things-for-os-26/>
- <https://blog.bear.app/2025/09/bear-is-now-com-paw-tible-with-new-oses-with-adapted-glassy-look/>

**Mechanic.** Things preserves one object's identity across contexts; Bear adds
only “a drop” of platform glass while typography and content remain primary.

**Left out.** Glass is not applied to every surface.

**Hard case.** One object changes role without changing its identity.

**Take.** The rep counter can become the Rest timer through continuity, pressure,
detents, and light.

**Reject.** Required dragging, fake reflections, and glass on noninteractive
content.

### Flighty — state reduction

Sources:

- <https://developer.apple.com/news/?id=970ncww4>
- <https://flighty.com/help/live-activities-widgets>

**Mechanic.** The same trip representation changes hierarchy as the event moves
from departure to flight; it remains useful offline.

**Left out.** Information that has stopped being actionable disappears.

**Hard case.** Compact and disconnected states retain the durable fact.

**Take.** Set → Rest → next Set should preserve exercise identity while reducing
the screen to what matters now.

**Reject.** Dense status-board aesthetics.

### Gentler Streak, Oura, and Athlytic — honest comparison

Sources:

- <https://docs.gentler.app/understanding-your-activity-path/interpret-the-activity-path>
- <https://support.ouraring.com/hc/en-us/articles/360058599753-How-to-Use-the-Oura-App>
- <https://athlyticapp.helpscoutdocs.com/article/20-understanding-recovery>

**Mechanic.** Continuity can survive legitimate rest; comparisons exist only
after a valid personal baseline; like is compared with like.

**Left out.** Absence of evidence is not silently filled with a score.

**Hard case.** Calibration and invalid measurement contexts are named directly.

**Take.** A prior set is a target only for the same session, exact slot, and
same working weight.

**Reject.** Composite readiness scores, coercive streaks, and coloured judgment.

### Compound and Strava Year in Sport — data as identity

Sources:

- <https://apps.apple.com/tm/app/compound-yearly-habit-tracker/id6756857450>
- <https://support.strava.com/en-us/articles/15401959-your-year-in-sport>

**Mechanic.** A whole year can become one artifact; a personal retrospective can
lead with one monumental true number.

**Left out.** Compound explicitly avoids dashboards, notifications, resets, and
gamification; Strava selects rather than showing every metric equally.

**Hard case.** Sparse data still has a visible chronology.

**Take.** Ledger gets one dominant lifetime fact; History gets a whole-year
portrait.

**Reject.** Share-first stories, social comparison, and binary success colour.

### Anki and Brainscape — reveal without losing context

Sources:

- <https://docs.ankimobile.net/study-screen.html>
- <https://docs.ankiweb.net/deck-options>
- <https://www.brainscape.com/academy/brainscape-in-app-gestures/>

**Mechanic.** The card itself is an obvious reveal target; timed reveal can
advance without requiring action.

**Left out.** Reveal does not need sound.

**Hard case.** Long answers need stable reading geometry; generic study apps
often solve this with scrolling, which Morning cannot.

**Take.** Stable question → rule → answer geometry, silent automatic reveal, and
a soft haptic.

**Reject.** 3D card flips, ratings, mastery, swiping, and internal scrolling.

### Apple platform guidance — glass, motion, and Live Activities

Sources:

- <https://developer.apple.com/design/human-interface-guidelines/materials>
- <https://developer.apple.com/videos/play/wwdc2025/219/>
- <https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass>
- <https://developer.apple.com/design/human-interface-guidelines/live-activities>

**Mechanic.** Liquid Glass forms a control/navigation layer above content;
compact Live Activity regions preserve the changing fact; motion communicates
causality and remains interruptible.

**Left out.** Apple does not prescribe one timer layout or recommend glass as a
general content background.

**Hard case.** Reduce Motion, Reduce Transparency, compact width, and changing
background luminance are first-class states.

**Take.** Sparse interactive glass, one `GlassEffectContainer`, system countdown
text outside the app, and semantic reduced-motion variants.

**Reject.** Glass timer faces, glass cue cards, and motion carrying information
that disappears when reduced.

## Answers to the brief's questions

### Countdowns you read from two metres

The number must dominate. A ring or depletion field reinforces direction but
cannot be the only clock. Next exercise and controls occupy one stable lower
zone. Morning should improve on the web by enlarging the number, not by adding
timer decoration.

### Atmosphere at 6am

Use a controlled content layer: authored dawn phases, slow local drift, stable
dark luminance behind text, and one light source. Atmosphere changes with
session progress, not with random sensors. Controls float above it sparingly.

### Consistency without gamification

Show provisional weekly completion and dated evidence. A current week is
unfinished, never “broken.” Blank days are absence, not failure. Longest run
remains after a missed week.

### A personal number that feels like an achievement

Give a true lifetime total the field, then explain its provenance quietly.
Milestones stay rare. Empty states present the beginning of a record rather than
zero as an achievement.

### Question → answer as something turning over

Do not literally flip a long card. The timer yields space, the thinking line
becomes the answer rule, and the answer resolves in the same reading plane.

### What premium means now

Stable hierarchy, authored transitions, excellent typography, object continuity,
matched haptics, and restraint. Glass and shaders are materials, not identity.

### Live Activities and the Dynamic Island

The strongest later proposal is one workout activity whose hierarchy changes:
quiet session progress during Set, countdown plus next exercise during Rest.
This remains proposal-only.

### Single-purpose, onboarding-free entry

Resume the active workout; otherwise show the derived next session, setup, and
one Start action. No account, quiz, permission gauntlet, or feature carousel.

## Where this leaves the directions

The research originally framed Dawn, Instrument, and Physical as separate
identities. Eden's feedback narrows the right experiment:

> The sunrise is Morning's identity. Compare native executions of that idea,
> not three unrelated fitness apps.

W1 therefore prototypes three treatments of the same load-bearing dawn:

### 1. Atmospheric Dawn

The room gets lighter. A controlled MeshGradient sky, authored horizon phases,
and localized light make progress environmental. Controls remain visually quiet.

Risk: atmosphere becomes mush and competes with text.

### 2. Precise Dawn

The dawn remains, but progress and comparison use calibrated rails, explicit
labels, tabular numerals, and short mechanical motion. Warmth comes from the sky
and haptics, not dashboard clutter.

Risk: precision becomes cold or generic.

### 3. Tactile Dawn

One lit counter object becomes the Rest timer. Pressure, detents, edge light, and
restrained interactive glass make it feel held while the same sky continues
behind it.

Risk: physicality becomes fussy or skeuomorphic.

These are running Set and Rest prototypes, not static mockups. They share the
same content and state harness so the vote is about execution:

- first run: bodyweight 10 and loaded 12
- same-weight previous value: below, equal, crossing, and back below
- changed-weight history, explicitly non-comparable
- superset partner one and partner two
- myo set one and set two
- plain 60-second Rest
- card question and longest revealed answer
- 20-second myo Rest at 5 seconds
- longest exercise name and cue set
- Reduce Motion and Reduce Transparency

## Rule

Extract mechanics; never ship another app's brand. Morning should remain
recognizable to its one user while looking and feeling impossible to mistake for
the web build.
