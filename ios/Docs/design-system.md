# Design system

> **Empty on purpose.** This is deliverable 4 of
> `ios-port/02-design-brief.md §11` and it is written **after** a direction is
> agreed, not before. Filling it in speculatively would be making the design
> decision that W1 exists to put in front of Eden.
>
> Workstream **W2** fills this in. The headings below are the required contents.

The web app's equivalent is documented inline in `src/index.css` — read it for
the level of "written down" this is asking for.

---

## Direction

<!-- Which of A · Dawn / B · Instrument / C · Physical (or what else), and the
     reasoning. Link the research notes and the prototype that won. -->

## Colour

<!-- The ramp, and what drives it. If the sunrise idea survives: the OKLCH
     stops, why each one, and how progress samples it. The web version's five
     hand-picked stops are in src/lib/sunrise.ts — hand-picked, not generated,
     "a formula gave an even ramp; it did not give a sunrise."

     Non-negotiable, from §6:
     · Dark by default. Light mode optional and low priority.
     · One accent for progress and primary action.
     · Semantic success/destruction colours kept OFF the accent ramp so they
       never collide with it.
     · Text contrast ≥ 4.5:1 at every level, tertiary labels included. The web
       palette holds 18:1 / 10:1 / 6.6:1 — match or beat it. -->

## Type

<!-- Scale, weights, optical sizes, width variants. SF Pro properly — the web
     build shipped Inter only because SF is not available to web apps.
     · Tabular numerals (.monospacedDigit()) on anything that changes in place.
     · .contentTransition(.numericText()) for counters that roll rather than swap.
     · Dynamic Type through the accessibility sizes on reading screens (Guide,
       cards, History). Workout screens may use fixed large type — they are
       already at the top of the scale. -->

## Spacing and layout

<!-- The grid. And the two hard minimums: primary targets ≥ 64pt, rep controls
     78pt because they are hit with a knuckle. Nothing important in the top 15%
     of the screen during a set — the phone is on the floor. -->

## Material and depth

<!-- Blur materials, translucency, specularity, Metal shaders (.colorEffect /
     .layerEffect) for atmosphere and for grain that stops gradients banding on
     OLED. What earns its place and what was tried and cut. -->

## Motion

<!-- Curves, springs, durations, and the doctrine from §9:
     · Fast where it's in the way, slow where it's the point. Step transitions
       instant; the completion moment can take four seconds.
     · Nothing blocks input. A transition must never gate the next tap on an
       animation finishing — the web version had exactly this bug and it made
       the app feel broken.
     · Motion carries meaning. When something gets smaller it is giving its
       space to something else.
     · Every animation has a reduced-motion form. Calmer, not disabled. -->

## Haptics

<!-- A TABLE, written down beside the animation timings — §9: choreographed,
     never sprinkled. The web app has NO haptics at all, so this is the single
     largest available upgrade in felt quality.

     Minimum vocabulary from 05-platform.md §3:

     | Event                          | Pattern | Why |
     |--------------------------------|---------|-----|
     | Rep increment / decrement      |         | a detent, not a buzz |
     | Passing last time's number     |         | distinctly different and more satisfying; must be tellable with the phone face down |
     | Set logged                     |         | confirming, with a little weight |
     | Countdown, last five seconds   |         | a pulse per second, intensifying |
     | Zero                           |         | unmistakable: transient + short continuous decay |
     | Session complete               |         | designed CHHapticEngine pattern against the Daybreak animation, not a canned success |
     | Card reveal                    |         | soft. The one place sound is banned and a haptic is welcome |

     CoreHaptics for anything with shape; UIFeedbackGenerator only for simple
     transients. Handle engine reset and the audio-session interaction. -->

## Sound

<!-- The six cues from 05-platform.md §3, and the rule that separates them from
     haptics: sound is for events you might not be looking at (time is up);
     haptics confirm something you just did. The count-in ascends on purpose. -->
