# Handing this port between agents

One clone, one agent at a time, sequential. No worktrees, no parallel branches.
That is a deliberate choice: this is a design-led port where almost every
workstream depends on the direction agreed in the one before it, so parallelism
would mostly buy merge conflicts and divergent visual decisions.

Three files carry the whole protocol:

| File | Role |
|---|---|
| `../../CLAUDE.md` | What the project is and the rules that bind. Read every session. |
| `workstreams.md` | The work, in order, with a paste-ready kickoff prompt for each. |
| `00-handoff-log.md` | Append-only. What actually happened, and what the next agent must know. |

## Starting an agent

1. Open `workstreams.md`, find the first workstream that is not `done`.
2. Check its **gate**. If the gate is not met, that workstream is not startable —
   go back one. The gates exist because `ios-port/README.md` puts research and
   agreement *before* building, and an agent will skip that on instinct.
3. Copy that workstream's **kickoff prompt** verbatim into the new agent.
4. When it finishes, it appends to `00-handoff-log.md` and flips the status in
   `workstreams.md`. Nothing else needs updating.

Every kickoff prompt starts with the same two lines, so no agent can begin
without loading the rules:

> Read `CLAUDE.md`, then `ios/Agents/00-handoff-log.md`, then the `ios-port/`
> documents it points you at. Then confirm the gate for this workstream is met
> before writing anything.

## The rules of the road

**Run `./scripts/bootstrap.sh` first, every session.** It is idempotent — it
checks Xcode and the simulator, installs SwiftLint and SwiftFormat if missing,
runs `npm install`, and wires the git hooks.

**Commit on a branch per workstream**, named `ios-port/w<N>-<slug>` — e.g.
`ios-port/w3-foundations`. Merge to `main` when the workstream is done and CI is
green. Sequential agents, but still one reviewable unit of work per branch.

**Persist every stable milestone.** Update the handoff notes, commit, and push
when a workstream reaches a green reviewable checkpoint so progress remains
traceable from the repository rather than only from an agent conversation.

**`ios/Morning.xcodeproj` is committed.** Changes to it are reviewable like any
other file, so keep them small and intentional — do not let Xcode drag unrelated
churn into a commit.

**Progress is measured in un-skipped assertions.** There are 53 in
`ios/MorningTests/Acceptance/`, every one of them a bug that already happened
once. `grep -rc 'throw XCTSkip' ios/MorningTests/Acceptance/` is the honest
progress bar, and CI prints it on every run.

**Do not paraphrase content.** Exercise names, cues, targets, celebration copy,
card text, Guide text: verbatim from `ios-port/content/*.json` or from the web
source. The copy has been through many rounds and it is part of the product.

**When you are unsure whether something is a design decision or a product
decision, it is a product decision — ask Eden.** Anything touching the training
program, and the four items `05-platform.md` says to propose rather than build
(notifications, Apple Health, Live Activities, widgets), always.

## Writing a handoff entry

Short, specific, and honest about what is *not* done. The template is at the
bottom of `00-handoff-log.md`. The two fields that matter most:

- **Decisions taken** — anything the next agent would otherwise re-litigate,
  with the reason. "Chose X over Y because Z."
- **Landmines** — what you found and did not fix, what you half-fixed, what you
  are suspicious of. This is worth more than the summary of what you built.
