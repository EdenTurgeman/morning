#!/usr/bin/env python3
"""Measure text and control contrast on rendered simulator frames.

    ios/Tools/measure-contrast.py ios/build/iter/set-equal.png set
    ios/Tools/measure-contrast.py ios/build/rest-p1.00.png rest

Why this exists
---------------
`02-design-brief.md §6` sets a contrast bar of 18:1 / 10:1 / 6.6:1 for the three
text levels. Two cheaper ways of checking it were tried first and both lied:

  * **Reading the declared alpha.** It ignores what the glyph is actually
    composited over. The sky's luminance changes with session progress, so the
    same `white 0.72` label measured 7.61:1 at twilight and 6.36:1 at gold.
  * **Looking at it.** Every defect this tool has found looked fine.

Everything it found was invisible to both: the accent ramp being too dark to
carry glyphs (4.59:1), the rep control having no boundary at all (1.18:1), the
legibility scrim being ramped backwards, and `SEC` failing only at the gold end
of the session.

The trap this tool exists to avoid
----------------------------------
A hand-placed sampling band is not trustworthy. It has silently measured:

  * a gradient, when the band drifted off the text (reported 1.32:1 for a zone
    that actually holds 6.76:1);
  * the timer's ring arc, when the band sat below the label (4.87:1 for a zone
    holding 7.71:1);
  * a control's border, after that border was deliberately strengthened
    (4.13:1 for a zone holding 8.11:1);
  * the inside of a glyph, when the x-window was narrower than the digits.

So this SNAPS to the rows that actually carry ink before sampling, prints the
rows it chose, and takes the background from immediately above and below the
snapped run rather than from the window as a whole.

**Read the printed row range.** If it does not sit where you expect the element
to be, the window is wrong and the number is meaningless. That check is the
whole point.

Text vs controls
----------------
`--controls` measures a UI component's BOUNDARY against what is behind it, which
is a different requirement: WCAG 2.1 SC 1.4.11 asks for 3:1. Text measurement
does not cover this. The rep control passed every text check for its entire life
while its boundary sat at 1.18:1 — the glyph was doing all the work and the
button had no visible shape.
"""
import sys
from pathlib import Path

try:
    import numpy as np
    from PIL import Image
except ImportError:
    sys.exit("needs numpy and pillow:  python3 -m pip install numpy pillow")

# iPhone 16 Pro, 1206 x 2622.
#
# One bar, deliberately. `§6` quotes the web palette's three levels as
# 18:1 / 10:1 / 6.6:1, but that palette sits on a flat near-black background.
# This one sits on a sky that is lit at the bottom by design, so pure white
# reads 19:1 at the top of the screen and about 12:1 over the counter. Scoring
# each element against a per-level bar just invites moving elements between
# levels until they pass.
#
# So: 6.6:1 is the floor everything must clear, the `level` column is
# informational, and the honest summary is the range each level actually spans.
BAR = 6.6
BAR_COMPONENT = 3.0

ZONES = {
    "set": [
        ("title   exercise name", 380, 620, 30, 1180, "primary"),
        ("sub     sub-label", 590, 700, 30, 1180, "secondary"),
        ("meta    load / set position", 655, 770, 30, 1180, "secondary"),
        ("counter rep number", -900, -580, 180, 1030, "primary"),
        ("label   Reps", -620, -490, 400, 810, "tertiary"),
        ("button  primary label", -340, -230, 120, 1090, "tertiary"),
        ("footer  sets to go", -175, -70, 30, 1180, "tertiary"),
    ],
    # Windows stop short of the controls: their border out-inks the text.
    "rest": [
        # Re-anchored during W14. The old window (940–1180) sat on the ring's
        # upper arc and the sky above the digits, catching the very top of them
        # at best, and reported white-on-night type as 3.71:1 — a failing grade
        # for the largest, brightest thing on the screen. A window that misses
        # its element does not produce a small error, it produces a confident
        # wrong answer, and the tool's own footer says to check exactly this.
        ("timer   seconds", 1150, 1400, 300, 910, "primary"),
        ("label   SEC", 1420, 1470, 430, 780, "tertiary"),
        ("label   Next", 2150, 2200, 30, 1180, "tertiary"),
        ("next    exercise", 2175, 2230, 30, 1180, "secondary"),
        ("next    meta line", 2240, 2292, 30, 1180, "tertiary"),
    ],
    # Home is not inside a workout, so its start controls are bottom-pinned but
    # everything above them is short and top-anchored.
    # Home is not inside a workout, so its start controls are bottom-pinned but
    # everything above them is short and top-anchored. Windows are taken from a
    # row profile of the rendered screen rather than guessed — and they stop
    # short of the week pips, which are filled accent furniture, not glyphs.
    "home": [
        ("title   Morning", 275, 345, 30, 1180, "primary"),
        ("subtitle", 358, 412, 30, 1180, "secondary"),
        ("label   Set up", 496, 542, 30, 1180, "tertiary"),
        ("loadout kg", 568, 690, 30, 1180, "primary"),
        ("plates", 700, 748, 30, 1180, "secondary"),
        ("label   This week", 838, 884, 30, 1180, "tertiary"),
        ("nudge", 952, 1008, 30, 1180, "secondary"),
        ("run line", 1028, 1074, 30, 1180, "tertiary"),
        ("button  start label", -580, -360, 120, 1090, "tertiary"),
        ("other   session", -262, -206, 30, 1180, "tertiary"),
    ],
    "card": [
        ("timer   compact", 840, 1120, 300, 910, "primary"),
        ("topic", 1170, 1230, 30, 1180, "tertiary"),
        ("question", 1240, 1380, 30, 1180, "secondary"),
        ("answer  first line", 1420, 1490, 30, 1180, "secondary"),
        ("answer  last line", 1730, 1790, 30, 1180, "secondary"),
    ],
}

CONTROLS = {
    "set": [("rep control", 1788, 1800, 120, 270, 1820, 1890, 340, 430)],
    "rest": [("+15s / Skip", 2360, 2372, 100, 500, 2380, 2450, 20, 52)],
}


def relative_luminance(rgb):
    c = rgb / 255.0
    c = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    return 0.2126 * c[..., 0] + 0.7152 * c[..., 1] + 0.0722 * c[..., 2]


def ratio(a, b):
    hi, lo = max(a, b), min(a, b)
    return (hi + 0.05) / (lo + 0.05)


def snap(lum, y0, y1, x0, x1, min_rows=6):
    """Find the rows in the window that actually carry ink."""
    window = lum[y0:y1, x0:x1]
    row_background = np.median(window, axis=1, keepdims=True)
    ink = np.abs(window - row_background) > 0.06
    counts = ink.sum(axis=1)
    live = counts > max(3, 0.004 * (x1 - x0))

    runs, start = [], None
    for index, alive in enumerate(live):
        if alive and start is None:
            start = index
        if not alive and start is not None:
            if index - start >= min_rows:
                runs.append((start, index))
            start = None
    if start is not None and len(live) - start >= min_rows:
        runs.append((start, len(live)))
    if not runs:
        return None
    best = max(runs, key=lambda r: (r[1] - r[0]) * counts[r[0] : r[1]].max())
    return y0 + best[0], y0 + best[1]


def resolve(bound, height):
    """Negative bounds count back from the bottom of the frame.

    The primary action and the footer are pinned to the safe area, so their
    position does not move when the cue list gets a line longer — but every
    element above them does. Anchoring them from the bottom is what stops a
    three-cue layout and a four-cue layout needing two sets of numbers.
    """
    return height + bound if bound < 0 else bound


def locate_glyphs(rgb, y_from, y_to, x0, x1, min_height=60):
    """Find the tallest band of near-white ink in a region.

    The rest timer is the one element on any screen whose vertical position is
    not fixed: it centres in whatever space is left between the chrome and the
    study card, so a 20-second myo rest and a 45-second rest with a card put it
    in two different places, and re-centring it moved both. Three separate
    hardcoded windows have now measured the sky beside those digits and reported
    it as a contrast failure for the largest text in the app.

    So this one is found rather than assumed. Returns None if there is no such
    band, which is a real answer too.
    """
    band = rgb[y_from:y_to, x0:x1].mean(axis=2)
    rows = np.where((band > 200).sum(axis=1) > 24)[0]
    if len(rows) == 0:
        return None
    runs, start, prev = [], rows[0], rows[0]
    for y in rows[1:]:
        if y - prev > 12:
            runs.append((start, prev))
            start = y
        prev = y
    runs.append((start, prev))
    tallest = max(runs, key=lambda r: r[1] - r[0])
    if tallest[1] - tallest[0] < min_height:
        return None
    return y_from + tallest[0], y_from + tallest[1]


def widen(lum, y0, y1, x0, x1, limit=200):
    """Grow a window until the ink inside it stops touching the edges.

    THE INSTRUMENT HAS BEEN WRONG THREE TIMES NOW, always the same way: a
    hardcoded window drifts off its element after a layout change and reports a
    confident number for whatever it landed on instead. It said 3.71:1 for
    white-on-night in W14, and 5.45:1 for the same digits again after the rest
    ring was re-centred — both times for the largest, brightest thing on screen.

    A window that misses its element does not produce a small error. So the
    window is a hint about where to start looking, and this follows the ink.
    """
    height = lum.shape[0]
    for _ in range(limit // 10):
        snapped = snap(lum, y0, y1, x0, x1)
        if snapped is None:
            # Nothing at all here — search outwards before giving up.
            if y1 - y0 > 600:
                return y0, y1
            y0, y1 = max(0, y0 - 40), min(height, y1 + 40)
            continue
        top, bottom = snapped
        if top > y0 and bottom < y1:
            return y0, y1
        if top <= y0:
            y0 = max(0, y0 - 10)
        if bottom >= y1:
            y1 = min(height, y1 + 10)
    return y0, y1


def measure_text(lum, y0, y1, x0, x1):
    y0, y1 = widen(lum, y0, y1, x0, x1)
    snapped = snap(lum, y0, y1, x0, x1)
    if snapped is None:
        return None
    top, bottom = snapped
    # Touching the window edge is the signature of having grabbed a neighbour
    # rather than the element — it is how a footer window once measured the
    # primary button's lower edge and reported 4.96:1 for text that holds 8:1.
    suspect = top <= y0 or bottom >= y1
    band = lum[top:bottom, x0:x1]
    pad = max(6, (bottom - top) // 2)
    around = np.concatenate([
        lum[max(0, top - pad) : top, x0:x1].ravel(),
        lum[bottom : min(lum.shape[0], bottom + pad), x0:x1].ravel(),
    ])
    background = float(np.median(around))
    deviation = band.ravel() - background
    up, down = deviation[deviation > 0], deviation[deviation < 0]
    if (up**2).sum() >= (down**2).sum():
        core = float(np.percentile(band, 99.5))
    else:
        core = float(np.percentile(band, 0.5))
    return ratio(core, background), core, background, (top, bottom), suspect


def main():
    if len(sys.argv) < 3 or sys.argv[2] not in ZONES:
        sys.exit(f"usage: {Path(sys.argv[0]).name} <frame.png> <{'|'.join(ZONES)}> [--controls]")

    path, screen = sys.argv[1], sys.argv[2]
    image = np.asarray(Image.open(path).convert("RGB")).astype(np.float64)
    lum = relative_luminance(image)

    print(f"\n{path}  ({screen})")
    print(f"{'element':30s} {'contrast':>9s}  {'rows':>13s}  level      status")
    worst = (1e9, "")

    levels = {}
    height = lum.shape[0]
    found = locate_glyphs(image, int(height * 0.20), int(height * 0.62), 300, 910) if screen == "rest" else None

    for name, y0, y1, x0, x1, level in ZONES[screen]:
        if found is not None and name.startswith("timer"):
            y0, y1 = found[0] - 12, found[1] + 12
        elif found is not None and name == "label   SEC":
            # Directly under the digits, wherever those turned out to be.
            y0, y1 = found[1] + 6, found[1] + 70
        result = measure_text(lum, resolve(y0, height), resolve(y1, height), x0, x1)
        if result is None:
            print(f"{name:30s}   no ink found — the window is wrong")
            continue
        value, _, _, (top, bottom), suspect = result
        status = "OK" if value >= BAR else "UNDER BAR"
        if suspect:
            status += "  <- ink touches the window edge; widen it and re-check"
        print(f"{name:30s} {value:8.2f}:1  {top:5d}-{bottom:<7d} {level:9s}  {status}")
        levels.setdefault(level, []).append(value)
        if value < worst[0]:
            worst = (value, name)

    print()
    for level in ("primary", "secondary", "tertiary"):
        if level in levels:
            print(f"  {level:9s} spans {min(levels[level]):5.2f}:1 – {max(levels[level]):5.2f}:1")

    if "--controls" in sys.argv and screen in CONTROLS:
        print()
        for name, by0, by1, bx0, bx1, sy0, sy1, sx0, sx1 in CONTROLS[screen]:
            border = float(np.percentile(lum[by0:by1, bx0:bx1], 95))
            behind = float(np.median(lum[sy0:sy1, sx0:sx1]))
            value = ratio(border, behind)
            status = "OK" if value >= BAR_COMPONENT else "UNDER BAR"
            print(f"{name + ' boundary':30s} {value:8.2f}:1  {'':13s} {'>=3:1':9s}  {status}")

    print(f"\nweakest text zone: {worst[1].strip()} @ {worst[0]:.2f}:1   (floor {BAR}:1)")
    print("Check the row ranges above. If one does not sit on its element, the number is meaningless.")


if __name__ == "__main__":
    main()
