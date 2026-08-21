# Morning — native iOS port

You are rebuilding a working app, not designing one from nothing. Everything it
*does* is settled and tested. Everything it *looks like* is deliberately open,
and making it look genuinely excellent is the point of this rewrite.

## What the app is

A single-user, offline morning workout app. It runs one specific 20-minute
session step by step, records the reps, and makes six months of "I did 14
instead of 13" visible as something that compounds. One user, one iPhone, no
accounts, no server, no other people in it.

There is a live web version at <https://edenturgeman.github.io/morning/> and its
source is the repository this folder sits in. **The web app is the behaviour
specification. It is not the design ceiling.** It was built inside constraints
that no longer apply — see `05-platform.md` — and you should expect to beat it
visually by a wide margin.

## Read in this order

| File | What it settles |
|---|---|
| `01-product.md` | Who it's for, how it's used, what must never be lost |
| `02-design-brief.md` | **The main document.** Visual direction, the research method, the quality bar |
| `03-program.md` | The training program and how it stays editable |
| `04-rules.md` | Every behavioural rule that must survive the port |
| `05-platform.md` | What native unlocks, and which old constraints are dead |
| `06-data.md` | The storage contract and importing the existing history |
| `07-acceptance.md` | What "done" is checked against |
| `content/*.json` | The program, the study deck and the guide text, machine-readable |

`content/` exists so you never retype content. Decode it, or transcribe it into
Swift literals — but do not paraphrase it. The copy in this app is part of the
product and it has been through many rounds.

## Working agreement

**1. Design before you build.** Do not start by porting screens one by one.
Read `02-design-brief.md`, do the research pass it describes, and come back with
two or three visual directions to choose between. Getting agreement on the look
is the first deliverable, not the last.

**2. Port the reasoning, not the code.** The web source is full of workarounds
for problems iOS does not have — viewport-height hacks, safe-area arithmetic,
scroll-lock, StrictMode guards. `04-rules.md` separates the intent from the scar
tissue. When the source and this folder disagree about *why*, this folder wins.

**3. Ship starting at zero, but keep the door open.** The existing history stays
in the web app for now — porting it is a follow-up, not a launch requirement.
What that costs you is the thing to watch: on day one every screen has no data,
so **empty and near-empty states are the normal case, not an edge case**. Design
them properly, and develop against seeded fixtures so you can also see the Ledger
and the year grid full. Store data in the schema the web app already uses
(`06-data.md`) so the later import is a file copy rather than a translation.

**4. Ask rather than assume on training content.** Exercise names, cues, targets,
rest seconds and the card deck are not yours to improve. Layout, hierarchy,
motion, colour and typography entirely are.

## Environment

- **Target: iOS 18+, iPhone only, portrait only.** One device — an iPhone 16 Pro.
  There is no back-compatibility burden and no iPad or Mac target. Do not add
  one "to be safe"; the newer APIs are a large part of what makes this worth
  doing.
- SwiftUI. SPM dependencies are fine and encouraged where they raise the ceiling.
- Signed with a paid Apple Developer account for personal device install.
- Xcode Previews and the simulator are the iteration loop. Use them constantly —
  this is a project about how things look and feel.

## First session checklist

1. Read this folder end to end.
2. Run the web app (`npm i && npm run dev`) and do a full session of A and a
   full session of B on a simulator or phone. Read `04-rules.md` while you do.
   You cannot design the replacement for something you have not used.
3. Do the research pass in `02-design-brief.md`.
4. Come back with directions to choose from. Then build.
