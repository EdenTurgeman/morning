# Motion performance on a real iPhone

Everything here was measured on Eden's iPhone 16 Pro at 120Hz, on this app, and
every rule is written because breaking it shipped a visible stutter. None of it
is general SwiftUI advice copied from somewhere — where a rule contradicts the
common wisdom, the contradiction is the point and the reason is given.

Read this before touching anything that moves.

---

## 0. The one-line version

**A frame's cost is set by what CHANGES each frame, not by what is on screen.**

The app is not heavy. It draws a few dozen shapes. Every stutter found so far has
been the same defect wearing different clothes: something expensive was made to
depend on a value that changes 120 times a second, when it did not have to.

---

## 1. Animate transforms. Never animate layout.

`scaleEffect`, `offset`, `rotationEffect` and `opacity` are handled by the
compositor. `frame(width:)`, `frame(height:)`, `padding` and `spacing` are
handled by the layout engine, which re-runs layout for the subtree **and
re-derives every `Shape` path in it**, on every frame.

This one defect has now been found and fixed **five times** in this codebase:

| Where | What it animated | Now |
|---|---|---|
| `LedgerScreen` first rule | `frame(width:)` | `scaleEffect(x:anchor:.leading)` |
| `EndSessionConfirm` hold bar | `frame(width:)` | `scaleEffect(x:anchor:.leading)` |
| `RepControl` crossing wipe | `frame(width:)` inside a mask | `scaleEffect(x:anchor:.leading)` |
| `RestScreen` study progress rule | `frame(width:)` on a clock | `scaleEffect(x:anchor:.leading)` |
| `PaperSunrise` rays | `frame(height:)` on 41 shapes | `scaleEffect(anchor:.bottom)` |

The last one was the worst thing in the app: forty-one procedurally torn ray
shapes each resizing their own frame every frame, so SwiftUI re-ran layout for
the whole fan and re-tessellated forty-one paths, 120 times a second, on the
main thread. Eden: *"the elements appear and do their thing but with some
dropped frames."*

**Before reaching for a transform, check the algebra.** A uniform scale about
the right anchor is often not an approximation of the layout change, it is the
same picture. A ray is a wedge struck in ANGLES from a pivot, so scaling it
uniformly about that pivot preserves every angle and changes only the reach,
which is exactly what the animating height was doing. When that equivalence
holds, say so in a comment, because the next person will assume you approximated.

**If you cannot avoid animating a frame,** make sure nothing expensive hangs off
it: no offscreen passes, no canvases, no custom renderers.

---

## 2. `drawingGroup()` pays at a fixed size and costs at a changing one

`drawingGroup()` rasterises a subtree into an offscreen buffer.

- **Fixed size, composited repeatedly** → pays. `Halftone` is the whole screen,
  never resizes, and is blended on every frame of every transition. It keeps its
  `drawingGroup`.
- **Size changes per frame** → the buffer is reallocated and repainted every
  frame. You have replaced a cheap redraw with an expensive one.

Adding `drawingGroup` to `Fibre`, which lives inside a ply that resizes, was my
own regression: an 83ms hitch, ten dropped frames, found with Instruments.

`compositingGroup()` is the same trap with a friendlier name. It also forces an
offscreen pass. It was added to the study card's sheet for a real reason (see §3)
and made that card slower on every frame it grew.

**The test is not "is this expensive to draw". It is "can the buffer be reused".**

---

## 3. `.shadow` applies to every leaf beneath it

This one cost the whole app quietly for months.

```swift
sheet.fill(Paper.ply)
    .overlay { Fibre().clipShape(sheet) }   // 420 hairline strokes
    .shadow(radius: 3)                      // ← blurs all 421 things
```

Without a compositing group, `.shadow` is applied to each drawn leaf separately.
That asked for a 3pt blur around **420 individual fibre strokes** as well as
around the sheet, on every pasted ply in the app. Nobody ever saw it, because 420
shadows at 22% under strokes at 7% are invisible. It was pure cost.

The obvious fix is `.compositingGroup()` before the shadow — and that is what the
study card did, which is how it ended up allocating an offscreen texture at a new
size every frame while it grew.

**Order is the real fix, and it is free:**

```swift
sheet.fill(Paper.ply)
    .shadow(radius: 3)                      // one closed path casts one shadow
    .overlay { Fibre().clipShape(sheet) }   // printed on top, casts nothing
```

One shape, one shadow — which Core Animation can satisfy with a shadow path
rather than a render pass — and no group. Pixel-identical to the intent.

**Rule: shadow the fill, then print the texture on top. Never group just to tidy
up a shadow.**

---

## 4. A `TimelineView(.animation)` subtree runs at the display rate

Everything inside the closure is re-evaluated every frame. Put **only what reads
the clock** inside it, and keep these out entirely:

- `Canvas`, and anything that builds a `Path` from a value that changes
- custom `TextRenderer`s (§5)
- `.blur`, `compositingGroup`, `drawingGroup`
- anything whose `frame` depends on the clock — scale it instead (§1)

`.animation` with no `minimumInterval` means the display rate, which is 120Hz on
this phone. If the value cannot be read that fast — a boil, a drifting texture, a
second counter — cap it. A rate cap is not a compromise, it is a statement about
what the value means.

---

## 5. Keep custom `TextRenderer`s out of animating subtrees

A custom `TextRenderer` opts text out of SwiftUI's cached glyph path. It forces
`Text.Layout` to resolve and a bespoke draw to run every frame, whether or not it
is drawing anything.

`RestScreen` attached `PenStrike` to **all four option rows at all times**,
including while the card was still opening and no row was struck — four custom
renderers animating in, for a stroke none of them were drawing. Eden: *"still
some choppiness when opening the question card at the end of the animation."*
The end of that animation is exactly when the four rows arrive.

**Attach the renderer to the one element that actually uses it,** and gate it on
a state that flips *before* the animation starts, so the sweep still has
somewhere to sweep from.

---

## 6. A leaf whose inputs change every frame can never be elided

`Canvas`'s closure takes `size`. While `Fibre` filled its parent, every frame of
the study card's growth handed it a size it had never seen, so there was nothing
to reuse — batching its 420 strokes into one path made each redraw cheap but did
not stop the redraws.

Fixing the canvas at a constant size makes its inputs constant, and an unchanged
leaf is work SwiftUI can skip.

It was also the more truthful model: fibre density is a property of the PAPER,
not of the piece you tore off it. 420 strokes per ply meant a small ply was made
of finer stock than a large one.

---

## 7. Count the views, not just the pixels

The study index drew its leader dots as an `HStack` of **200 `Rectangle`s used as
a mask, per row**. At a few dozen met topics that is several thousand views in
one scroll view, to draw a dotted line.

A butt-capped dash is the same picture — square ends, which was the entire reason
the mask existed — in one stroked path.

---

## 8. Instrumentation is not free

A `print()` on every tap is main-thread file I/O in the middle of a gesture. A
`Perf` harness added to find a stutter became part of it. Measure with
Instruments, which is out of process, and delete the probes afterwards.

---

## 9. How to actually measure

The simulator will not show any of this. It does not run at 120Hz and its timing
is not representative — `device-checklist.md` has said so all along, and the
halftone's 14,175-fill-calls-per-redraw defect survived months of simulator
screenshots.

```bash
xcrun xctrace record --template 'Animation Hitches' \
  --device-name 'iPhone' --attach Morning --output /tmp/hitches.trace
```

Send **SIGINT**, not SIGTERM, to stop it, or the trace is unwritable.

Two rules learned the hard way:

- **Measure ink coverage, not mean luma.** Mean luma cannot see a blank screen
  on a light ground — a 220ms blank frame during a transition sat undetected
  because the average brightness barely moved.
- **Measure contrast on rendered frames, never from tokens.** `PaperGround` lays
  a halftone over every surface, so the rendered ply is darker than `Paper.ply`
  and every ratio calculated from the token is optimistic. The crossing rule
  computes to 3.12:1 and measures 2.48:1.

And the discipline that found all of the above: **change one thing, re-measure.**
Three separate "obvious" fixes to the study scheduler each moved the median by
exactly zero, because the thing was throughput-bound and none of them touched
throughput. A hypothesis that is not measured is a decoration.

---

## 10. Things that were suspected and were NOT the problem

Kept because a ruled-out cause is worth as much as a found one, and each of these
cost a round of work:

- **State-update latency.** Measured on device: `advance` 2.4–8.6ms, `persist`
  1.1–6.0ms, `Deck.draw` 7.7ms. About one frame at 120Hz. The taps were never
  slow; the frames after them were.
- **The halftone being drawn twice.** Removing `SetScreen`'s own ground was
  measured at 192.0 → 191.0 mean, so it *replaced* a ground rather than doubling
  one.
- **Screen transitions repainting whole screens.** They do, and that is correct
  and cheap. What made it look expensive was the shadow defect in §3, which every
  ply on both screens was paying on every frame of the cross-dissolve.
