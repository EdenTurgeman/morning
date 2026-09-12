import SwiftUI

/* ===========================================================================
 *  THE STUDY PAGE
 *  ---------------------------------------------------------------------------
 *  `plans/010`. The first view of the deck that is not one line on the Summary.
 *
 *  `plans/004` refused this surface, and was right to: the deck was 26 cards
 *  and a screen for 26 cards is a screen for a rest filler. It is 356 now,
 *  across 111 topics, written by fifteen groups and a curriculum review. What
 *  changed is the ratio, not the principle.
 *
 *  ── the question it answers ──────────────────────────────────────────────
 *  **What do I know, what am I getting wrong, and what have I not met yet?**
 *  Three sections, in that order, and nothing else. Not "how am I doing" —
 *  that is a score, and `009` settled that this app states knowledge instead.
 *
 *  ── why it is an INDEX ───────────────────────────────────────────────────
 *  The plan considered a grid of topics and rejected it: 111 cells, most
 *  holding one or two cards, is a map of the deck's shape rather than of his
 *  knowledge. An index is the printed object that already solves this — it is
 *  *supposed* to be long, it is read by looking things up rather than
 *  scanning, and leader dots carry the eye across a gap that a grid would have
 *  to fill with a cell.
 *
 *  It is also the one shape that does not rank him. Alphabetical is how you
 *  find things; ordered-by-worst is a list of your failures with a nicer name.
 *
 *  ── what it must never become ────────────────────────────────────────────
 *  No percentage. No chart of settled-over-time. No card browser — the whole
 *  design of the deck is that cards find HIM. See `plans/010` §"What this plan
 *  does NOT propose".
 * ======================================================================== */

struct StudyScreen: View {
    let report: StudyReport
    let onClose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if report.standing.met == 0 {
                empty
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: Space.section) {
                        headline
                        if !report.troubles.isEmpty {
                            troubles
                        }
                        index
                    }
                    .padding(.horizontal, Space.gutter)
                    .padding(.top, Space.step)
                    .padding(.bottom, Space.section)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .paperGround()
    }

    private var header: some View {
        HStack {
            Button("Close", action: onClose)
                .font(TypeScale.label)
                .foregroundStyle(Paper.press)
                .frame(minWidth: Hit.minimum, minHeight: Hit.minimum, alignment: .leading)
                // THE WHOLE TARGET IS TAPPABLE, NOT JUST THE GLYPHS.
                // A `.frame(min…: Hit.…)` on a Button reserves the layout space and does
                // NOT extend its hit region — SwiftUI still hit-tests the rendered label.
                // With `alignment: .leading` the text is then pinned to one edge of a 68pt
                // box, so most of the target was dead paper.
                //
                // Eden, on the phone: *"seems like the clickable area is the text of the
                // button not the button itself, this feels bad to click."* At 6:10am with a
                // knuckle this is the difference between a control and a dare.
                .contentShape(Rectangle())
            Spacer()
            Text("Study")
                .font(TypeScale.label)
                .foregroundStyle(Paper.press)
            Spacer()
            Color.clear.frame(width: Hit.minimum, height: Hit.minimum)
        }
        .padding(.horizontal, Space.gutter)
    }

    // MARK: - What you know

    /// ONE NUMBER, and it is the one that only goes up by studying.
    ///
    /// The Ledger's shape — a staggering true number with its provenance under
    /// it — because this screen is the Ledger's equivalent for the deck, and
    /// `02-design-brief.md §8`'s line about it applies word for word: it exists
    /// to make the last six months feel like they happened.
    ///
    /// **Cards met, not questions settled.** Settled is the smaller, prouder
    /// number and it is the wrong headline: it moves twice a week at best, and
    /// against 268 questions it reads as a fraction of a thing he has barely
    /// started. Met moves every morning.
    private var headline: some View {
        VStack(alignment: .leading, spacing: Space.tight) {
            Text("\(report.standing.met)")
                .font(TypeScale.counter(76))
                .monospacedDigit()
                .foregroundStyle(Paper.press)

            Text("of \(report.standing.cards) cards met")
                .font(TypeScale.body)
                .foregroundStyle(Paper.press)

            if let solid = solidLine {
                Text(solid)
                    .font(TypeScale.body)
                    .foregroundStyle(Paper.press)
                    .padding(.top, Space.snug)
            }
        }
        .padding(.top, Space.step)
    }

    /// The second fact, and only when there is one. A deck he has met but never
    /// answered a question in has nothing to say here, and "0 solid" is a zero
    /// dressed as a fact — the rule `Deck.Standing.line` already follows.
    private var solidLine: String? {
        let standing = report.standing
        guard standing.answered > 0, standing.settled > 0 || standing.shaky > 0 else { return nil }
        let noun = standing.settled == 1 ? "question" : "questions"
        guard standing.shaky > 0 else { return "\(standing.settled) \(noun) solid." }
        guard standing.settled > 0 else {
            return "\(standing.shaky) \(standing.shaky == 1 ? "question" : "questions") you keep missing."
        }
        return "\(standing.settled) \(noun) solid, \(standing.shaky) you keep missing."
    }

    // MARK: - What you keep getting wrong

    /// THE CONFUSION PAIR, GIVEN THE ROOM IT NEVER GETS ON A REST CARD.
    ///
    /// On the card it is one truncated line at the bottom of a sheet that is
    /// already full. Here it is the whole point of the section: the question,
    /// and under it the answer he keeps reaching for, struck through in the
    /// pen's red — the same mark, the same ink, the same gesture as a wrong
    /// pick, because this world crosses things out one way.
    private var troubles: some View {
        VStack(alignment: .leading, spacing: Space.step) {
            sectionLabel("WHAT YOU KEEP MISSING")

            VStack(alignment: .leading, spacing: Space.gutter) {
                ForEach(Array(report.troubles.prefix(StudyReport.troubleLimit).enumerated()), id: \.element.id) {
                    index, trouble in
                    if index > 0 {
                        // A ruled line between entries, not a gap. Five
                        // questions and five struck answers with only space
                        // between them read as one long paragraph of things he
                        // is bad at; a rule makes each its own item.
                        Rectangle()
                            .fill(Paper.rule)
                            .frame(height: 1)
                    }
                    troubleEntry(trouble)
                }

                if report.troubles.count > StudyReport.troubleLimit {
                    Text("And \(report.troubles.count - StudyReport.troubleLimit) more.")
                        .font(TypeScale.label)
                        .foregroundStyle(Paper.press.opacity(0.55))
                }
            }
            .padding(Space.gutter)
            .frame(maxWidth: .infinity, alignment: .leading)
            .sheeted(seed: 31)
        }
    }

    private func troubleEntry(_ trouble: StudyReport.Trouble) -> some View {
        VStack(alignment: .leading, spacing: Space.snug) {
            Text(trouble.question)
                .font(TypeScale.body)
                .foregroundStyle(Paper.press)
                .fixedSize(horizontal: false, vertical: true)

            if let confusion = trouble.confusion {
                // "YOU SAY" rather than nothing: without it the struck line is
                // just a second sentence with a stroke through it, and which of
                // the two is HIS is the whole point of the pair.
                //
                // ABOVE the answer rather than beside it. Inline, the label ate
                // enough width to push every struck answer to three lines —
                // measured on the seeded page, all five of them — and three
                // lines of red is the section shouting. Above, the answer runs
                // full width and lands in two.
                Text("YOU SAY")
                    .font(TypeScale.microLabel)
                    .tracking(1.6)
                    .foregroundStyle(Paper.press.opacity(0.45))

                Text(confusion)
                    .font(TypeScale.body)
                    .foregroundStyle(Paper.press.opacity(0.5))
                    .textRenderer(StudyStrike(ink: Paper.danger))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - The index

    private var index: some View {
        VStack(alignment: .leading, spacing: Space.step) {
            sectionLabel("THE DECK")

            VStack(alignment: .leading, spacing: Space.gutter) {
                ForEach(subjects, id: \.self) { subject in
                    VStack(alignment: .leading, spacing: Space.snug) {
                        Text(subject.uppercased())
                            .font(TypeScale.microLabel)
                            .tracking(1.8)
                            .foregroundStyle(Paper.press.opacity(0.5))

                        ForEach(report.topics.filter { $0.subject == subject }) { topic in
                            IndexRow(topic: topic)
                        }
                    }
                }
            }
            .padding(Space.gutter)
            .frame(maxWidth: .infinity, alignment: .leading)
            .sheeted(seed: 47)

            if !report.unmet.isEmpty {
                // WHAT HE HAS NOT MET, as a sentence rather than a list.
                //
                // A list of every topic he has never opened is a list of
                // everything he has not done, which is the shape this screen
                // spends its whole design avoiding. A count and three examples
                // says the same true thing and reads as an invitation.
                Text(unmetLine)
                    .font(TypeScale.body)
                    .foregroundStyle(Paper.press.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Space.snug)
            }
        }
    }

    private var subjects: [String] {
        var seen: [String] = []
        for topic in report.topics where !seen.contains(topic.subject) {
            seen.append(topic.subject)
        }
        return seen
    }

    /// The line that makes the page add up.
    ///
    /// It used to count TOPICS only — "37 topics you have not met yet" — while
    /// the index above it counts cards and the headline counts the whole deck.
    /// Three numbers, no arithmetic between them. Eden: *"the deck shows me
    /// quite a few subjects but they don't sum up to the 350 questions we
    /// built."*
    ///
    /// Cards first, because cards are the unit both of the other two figures are
    /// in: the index's right-hand column plus this number is the headline's
    /// total, exactly.
    private var unmetLine: String {
        let examples = report.unmet.prefix(3).joined(separator: ", ")
        let topics = report.unmet.count
        let cards = report.unmetCards
        let noun = cards == 1 ? "card" : "cards"
        if topics <= 3 {
            return "\(cards) more \(noun) waiting, in \(examples)."
        }
        return "\(cards) more \(noun) waiting, across \(topics) topics "
            + "you have not opened yet, including \(examples)."
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(TypeScale.microLabel)
            .tracking(1.8)
            .foregroundStyle(Paper.press)
    }

    // MARK: - Empty

    /// EMPTY IS THE NORMAL CASE, and on this screen it is the hardest one.
    ///
    /// `LedgerScreen`'s ruling applies word for word: *"'0 tonnes' is a bad
    /// answer: it is a number pretending to be an achievement."* So is "0 of
    /// 356". What is true before the first card is that the deck is written and
    /// waiting, and that it comes to him rather than the other way round.
    private var empty: some View {
        VStack(alignment: .leading, spacing: Space.step) {
            Text("Nothing studied yet")
                .font(TypeScale.title)
                .foregroundStyle(Paper.press)

            Text(
                "\(report.standing.cards) cards are waiting, on wine and tea. "
                    + "Two come to you during a session, and one after it. "
                    + "This page fills in as you meet them."
            )
            .font(TypeScale.body)
            .foregroundStyle(Paper.press)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Space.gutter)
        .padding(.top, Space.section)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension View {
    /// A PASTED PLY, like every other surface in this world you actually READ.
    ///
    /// The first version of this screen set its text straight on the stock, and
    /// it was the same mistake `RestScreen` records against the study card:
    /// *"bare text sitting straight on the stock while the head, the counter and
    /// the horizon were all sheets with torn edges. It read as a gap in the
    /// world rather than as a quiet element."*
    ///
    /// It pays the same dividend twice over here, because this is a screen of
    /// nothing but reading: press black measures 11.35:1 on the ply against
    /// 7.74:1 on the stock.
    ///
    /// Two sheets rather than one, with the headline on the bare page above
    /// them — a desk with the index and the errata laid on it, which is also
    /// the reading order.
    func sheeted(seed: UInt64) -> some View {
        let sheet = TornEdge(tornTop: true, tornBottom: true, seed: seed)
        return clipShape(sheet)
            .background {
                sheet
                    .fill(Paper.ply)
                    // THE SHADOW IS CAST BY THE SHEET, NOT BY THE FIBRE ON IT.
                    // See `Ply` in `PaperTokens.swift` for the whole reason. Order is the
                    // entire fix: shadow the fill, then print the fibre on top.
                    .shadow(color: Paper.press.opacity(0.22), radius: 3, x: 0, y: 2)
                    .overlay { Fibre().clipShape(sheet) }
            }
    }
}

/// One line of the index: topic, leader dots, and where he stands in it.
///
/// **Leader dots, drawn rather than typed.** A row of "." characters wraps,
/// hyphenates and never lands on the same baseline twice; a dotted rule is one
/// shape that always fits the gap it is given. It is also the actual printed
/// object this page is imitating.
/// The rule between an index entry and its tally.
private struct LeaderDots: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

private struct IndexRow: View {
    let topic: StudyReport.Topic

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Space.snug) {
            Text(topic.name)
                .font(TypeScale.body)
                .foregroundStyle(Paper.press)
                .lineLimit(1)
                .layoutPriority(1)

            // ONE STROKE, NOT TWO HUNDRED VIEWS.
            //
            // The dots were an `HStack` of 200 `Rectangle`s used as a mask, on
            // EVERY row of the index. At a few dozen met topics that is several
            // thousand views in one scroll view, all to draw a dotted line.
            //
            // A butt-capped dash is the same picture: square ends, so the dashes
            // are printed squares rather than the round ones a default cap would
            // give — which was the whole reason the mask existed.
            LeaderDots()
                .stroke(
                    Paper.press.opacity(0.28),
                    style: StrokeStyle(lineWidth: 1, lineCap: .butt, dash: [1, 3])
                )
                .frame(height: 1)
                .frame(maxWidth: .infinity)
                .offset(y: -3)

            Text(tally)
                .font(TypeScale.body)
                .monospacedDigit()
                .foregroundStyle(Paper.press)
                .layoutPriority(1)
        }
        .frame(minHeight: 26)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(topic.name), \(tally)")
    }

    /// "3 / 6" — met over held. Not a percentage, and not a bar: a fraction of
    /// two small whole numbers is read as two counts, which is what it is.
    /// A percentage of six cards is a score invented out of a rounding error.
    private var tally: String {
        "\(topic.met) / \(topic.cards)"
    }
}

/// The pen, for the index page.
///
/// A second copy of `RestScreen`'s `PenStrike` with the sweep taken out — that
/// one animates because it is drawn as a verdict lands, and here the mark is
/// already true when the page opens. Sharing it would mean exporting an
/// animation parameter that this caller must always pass as 1.
private struct StudyStrike: TextRenderer {
    var ink: Color

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        for line in layout {
            context.draw(line)
        }
        for line in layout {
            let box = line.typographicBounds.rect
            context.fill(
                Path(CGRect(x: box.minX, y: box.midY - 1, width: box.width, height: 2)),
                with: .color(ink)
            )
        }
    }
}
