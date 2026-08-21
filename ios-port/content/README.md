# content/

Machine-readable exports of everything in the app that is **content, not code**.
Generated from the live source so nothing is retyped or paraphrased.

| File | What it is |
|---|---|
| `program.json` | The two sessions, the plate inventory, the weekly target and the week start day. Weights are **plates per handle**. |
| `cards.json` | The 26-card study deck, wine and tea. |
| `guide.json` | The nine Guide entries. |
| `compiled-steps.json` | What each session must compile to, step by step. The golden fixture for the step-compiler tests. |

## How to use these

**Transcribe `program.json` into Swift literals** — do not load it as a resource.
`03-program.md` explains why: the user edits the program himself in a text
editor every few months, and it has to be one readable object in one file.

`cards.json` and `guide.json` may go either way. The deck will grow over time
and adding a card must stay a one-line append, so whichever form you choose,
keep that property.

`compiled-steps.json` is a test fixture. Decode it in the test target and assert
the compiler's output against it.

## Do not edit content here

If a number or a string needs to change, it changes in the app's own program
object, and this folder gets regenerated. These files are a snapshot of the web
build at the moment the port began — the copy has been through several rounds of
revision and is part of the product.
