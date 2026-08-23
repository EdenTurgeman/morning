#!/usr/bin/env python3
"""Reads a screen's vertical rhythm off a rendered frame.

W14 is a UI review and `ios/Agents/workstreams.md` says to measure a screen
before judging it. This is the measuring part: it finds the horizontal bands
that actually carry ink, and the gaps between them.

That one scan answers three of the things the review is looking for:

  * **undersized text** — a band's height is the cap-to-baseline extent of
    whatever is in it, so a 14pt line and a 34pt line are told apart without
    reading the source
  * **empty space** — a gap taller than the content around it
  * **cramped space** — two bands closer than the type in them is tall

Reported in points as well as pixels, because points are what the design system
is written in and a 3x screenshot flatters everything by a factor of three.

    python3 measure-layout.py <frame.png> [--scale 3] [--min-ink 0.12]
"""

import sys
from PIL import Image


def bands(path, scale=3.0, min_ink=0.12, ink_floor=95):  # ink_floor: std-dev threshold
    """Contiguous rows carrying ink, and the gaps between them.

    `ink_floor` is deliberately low. The app is a dark sky with pale type, so
    "ink" is anything meaningfully brighter than the backdrop — but the backdrop
    itself brightens toward the horizon, so the threshold is taken relative to
    each row's own darkest quartile rather than as an absolute.
    """
    image = Image.open(path).convert("L")
    width, height = image.size
    pixels = image.load()

    # Horizontal VARIANCE, not brightness. The first version thresholded on
    # "brighter than the row's floor" and missed two things badly: a full-width
    # bright button (its own fill raises the floor) and the black label on top
    # of it (darker, not lighter). The sky is a smooth vertical gradient, so any
    # row of plain sky is nearly uniform across its width and anything placed on
    # it — pale type, a bright fill, a dark label — is not.
    rows = []
    for y in range(height):
        row = [pixels[x, y] for x in range(0, width, 4)]
        mean = sum(row) / len(row)
        variance = sum((v - mean) ** 2 for v in row) / len(row)
        rows.append(variance ** 0.5)

    inked = [r >= ink_floor / 8 for r in rows]

    runs = []
    start = None
    for y, on in enumerate(inked):
        if on and start is None:
            start = y
        elif not on and start is not None:
            runs.append((start, y))
            start = None
    if start is not None:
        runs.append((start, height))

    # Rows of a paragraph are separate runs; a band is what reads as one block,
    # so runs closer than 8pt are merged.
    merged = []
    for run in runs:
        if merged and run[0] - merged[-1][1] < 8 * scale:
            merged[-1] = (merged[-1][0], run[1])
        else:
            merged.append(list(run))
            merged[-1] = tuple(merged[-1])
            continue
        merged[-1] = (merged[-1][0], run[1])
    return merged, height


def luminance(value):
    """WCAG relative luminance for one 8-bit channel-equal grey."""
    c = value / 255
    return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4


def contrast_of(path, start, end):
    """Ink-against-its-own-background ratio for one band.

    `measure-contrast.py` needs a hand-maintained zone table per screen, which
    means anything newly added to a screen is invisible to it until someone
    remembers to add a row. This takes the band the layout scan already found
    and measures it directly, so a new control is checked the first time it is
    rendered rather than the first time somebody updates a table.

    The glyph cores are the brightest few percent of the band and the backdrop
    is its median — taking the darkest pixels instead would measure against the
    corner of the sky rather than against what the text actually sits on.
    """
    image = Image.open(path).convert("L")
    width, _ = image.size
    pixels = image.load()
    values = sorted(
        pixels[x, y] for y in range(start, end) for x in range(0, width, 2)
    )
    if len(values) < 40:
        return None
    ink = values[int(len(values) * 0.985)]
    back = values[len(values) // 2]
    high, low = luminance(max(ink, back)), luminance(min(ink, back))
    return (high + 0.05) / (low + 0.05)


def main():
    args = sys.argv[1:]
    if not args:
        print(__doc__)
        return 2
    path = args[0]
    scale = float(args[args.index("--scale") + 1]) if "--scale" in args else 3.0

    found, height = bands(path, scale=scale)
    print(f"  {path}   {height}px tall  ({height / scale:.0f}pt)")
    print(f"  {'band (pt)':>16}  {'height':>8}  {'gap above':>10}")
    previous_end = 0
    for start, end in found:
        gap = (start - previous_end) / scale
        flag = ""
        band_pt = (end - start) / scale
        if band_pt < 13:
            flag += "  ← small type"
        if gap > 90:
            flag += "  ← large gap"
        elif 0 < gap < 6 and previous_end:
            flag += "  ← tight"
        if "--contrast" in args:
            ratio = contrast_of(path, start, end)
            shown = f"{ratio:5.2f}:1" if ratio else "    —  "
            if ratio and ratio < 6.6:
                shown += "  ← under the 6.6:1 floor"
            print(f"  {start / scale:6.0f}–{end / scale:<7.0f}  {band_pt:7.1f}  {shown}")
        else:
            print(
                f"  {start / scale:6.0f}–{end / scale:<7.0f}  {band_pt:7.1f}  {gap:9.1f}{flag}"
            )
        previous_end = end
    trailing = (height - previous_end) / scale
    print(f"  {'':>16}  {'':>8}  {trailing:9.1f}  ← below the last band")
    return 0


if __name__ == "__main__":
    sys.exit(main())
