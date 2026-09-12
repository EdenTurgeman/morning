import SwiftUI
import UniformTypeIdentifiers

/* ===========================================================================
 *  GUIDE, AND BACKUP
 *  ---------------------------------------------------------------------------
 *  The two screens that are read rather than used. `02-design-brief.md §8`.
 *
 *  The Guide is nine short entries, verbatim from `content/guide.json`. It is a
 *  static reference read maybe monthly, which is exactly the case `§6` names as
 *  needing DYNAMIC TYPE THROUGH THE ACCESSIBILITY SIZES — unlike the workout
 *  screens, which clamp because they are already at the top of the scale and
 *  must never scroll. This one scrolls by design.
 *
 *  Backup is the other half. `04-rules.md §8`:
 *
 *  · Export produces JSON, and restoring it reproduces the history exactly.
 *  · Restore validates, confirms the session-count swap, then replaces.
 *  · Erase is destructive, confirmed, and VISUALLY DE-EMPHASISED.
 *  · Never lose data on a failed write — surface it.
 *
 *  The export format is already proven: `scripts/verify-export.ts` runs a real
 *  export through the web app's own `parseData` on every CI run, so "opens in
 *  the web app's Restore box" is checked continuously rather than once.
 * ======================================================================== */

struct GuideEntry: Codable, Equatable {
    let heading: String
    let body: String
}

enum Guide {
    static let entries: [GuideEntry] = load()

    private struct File: Decodable {
        let entries: [GuideEntry]
    }

    private static func load() -> [GuideEntry] {
        for bundle in [Bundle.main, Bundle(for: BundleToken.self)] {
            guard let url = bundle.url(forResource: "guide", withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let file = try? JSONDecoder().decode(File.self, from: data)
            else {
                continue
            }
            return file.entries
        }
        assertionFailure("guide.json is in neither the app nor the test bundle")
        return []
    }

    private final class BundleToken {}
}

struct GuideScreen: View {
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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
                Text("Guide")
                    .font(TypeScale.label)
                    .foregroundStyle(Paper.press)
                Spacer()
                Color.clear.frame(width: Hit.minimum, height: Hit.minimum)
            }
            .padding(.horizontal, Space.gutter)

            ScrollView {
                VStack(alignment: .leading, spacing: Space.section) {
                    ForEach(Array(Guide.entries.enumerated()), id: \.offset) { _, entry in
                        VStack(alignment: .leading, spacing: Space.snug) {
                            Text(entry.heading)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(Paper.press)

                            Text(entry.body)
                                .font(.body)
                                .foregroundStyle(Paper.press)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.horizontal, Space.gutter)
                .padding(.vertical, Space.section)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .paperGround()
        // Read monthly, not at 6:10am. This one takes the accessibility sizes;
        // the workout screens deliberately do not.
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }
}

// MARK: - Backup

struct BackupScreen: View {
    let data: AppData
    let onRestore: (AppData) -> Void
    let onErase: () -> Void
    let onClose: () -> Void
    /// Stamps `AppData.lastBackup`. The field existed in the schema, in every
    /// seed and in the web build's own writer, and this port never wrote it and
    /// never showed it — so the one screen whose whole job is "do you have a
    /// copy" could not answer the question.
    let onExported: () -> Void

    @State private var exporting = false
    @State private var importing = false
    @State private var pendingRestore: AppData?
    @State private var confirmingErase = false
    @State private var problem: String?

    /// Whole days since the last export, or nil if there has never been one.
    /// `src/lib/storage.ts`'s `daysSince`.
    private var daysSinceBackup: Int? {
        guard let stamp = data.lastBackup,
              let then = ISO8601DateFormatter().date(from: stamp)
        else {
            return nil
        }
        return Int(Date().timeIntervalSince(then) / 86400)
    }

    private var statusText: String {
        guard let days = daysSinceBackup else { return "Never backed up." }
        if days == 0 {
            return "Backed up today."
        }
        return "Last backup \(days) \(days == 1 ? "day" : "days") ago."
    }

    /// Three states, on the paper world's own inks. A rule rather than a
    /// filled badge: this is status, not a control.
    ///
    /// The middle state was a leftover `DawnPalette(progress: 0.3).accent` —
    /// the ramp's violet-rose, which belongs to a world that no longer exists.
    /// And "current" was the OVERPRINT, which everywhere else in this app means
    /// attention: a healthy backup was being flagged in the app's alarm ink.
    ///
    /// Now it follows the ink law. `danger` — you have no copy of this. The
    /// overprint — attention, it is going stale. Blue — already true, current.
    private var statusTone: Color {
        guard let days = daysSinceBackup else { return Paper.danger }
        return days > 14 ? Paper.overprint : Paper.blue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.section) {
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
                Text("Backup")
                    .font(TypeScale.label)
                    .foregroundStyle(Paper.press)
                Spacer()
                Color.clear.frame(width: Hit.minimum, height: Hit.minimum)
            }

            // The status leads, because it is the answer to the question you
            // opened this screen with. Copy verbatim from `src/screens/Backup.tsx`.
            HStack(spacing: Space.snug) {
                Rectangle()
                    .fill(statusTone)
                    .frame(width: 2)
                // One line. The web carries a second — "125 sessions stored on
                // this phone" — because it has no headline number; this port has
                // one 40pt below. My first attempt swapped that duplication for
                // a worse one, repeating "the export is the only copy that…"
                // from the paragraph underneath. The status is complete on its
                // own.
                Text(statusText)
                    .font(TypeScale.body)
                    .foregroundStyle(Paper.press)
                Spacer(minLength: 0)
            }
            .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: Space.snug) {
                Text("\(data.history.count) sessions")
                    .font(TypeScale.counter(38))
                    .foregroundStyle(Paper.press)
                Text("This is everything the app knows about you. The export is the "
                    + "only copy that survives a lost phone.")
                    .font(TypeScale.body)
                    .foregroundStyle(Paper.press)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: Space.step) {
                PaperPrimaryButton(title: "Export") {
                    exporting = true
                    onExported()
                }

                Button("Restore from a file") { importing = true }
                    .font(TypeScale.body)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(Paper.press)
                    .frame(minHeight: Hit.minimum)
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
            }

            Spacer()

            // Destructive, confirmed, and visually de-emphasised — it sits at
            // the bottom, in body weight, in no accent at all.
            //
            // The distance from Export is the safety mechanism and it stays.
            // What changed is the rule above it: measured, this control sat
            // alone at the foot of a 369pt void and read as orphaned rather
            // than as de-emphasised. A hairline makes it the last SECTION
            // instead of a stranded button, which is the ordinary iOS pattern
            // for a destructive action and costs none of the distance.
            VStack(spacing: Space.snug) {
                Rectangle()
                    .fill(Paper.press.opacity(0.22))
                    .frame(height: 1)

                Button("Erase everything") { confirmingErase = true }
                    .font(TypeScale.body)
                    // Full strength, not 0.75. Measured on the rendered frame,
                    // the dimmed version came out at **3.07:1** — below this
                    // app's own 6.6:1 text floor and below WCAG AA's 4.5:1 for
                    // ordinary text. De-emphasis is right for this control and
                    // it already has three other forms of it: it is last, it is
                    // body weight, and it sits alone under a rule at the far end
                    // of the screen from Export. Making the label hard to read
                    // is not a fourth — you have to be able to read the thing
                    // you are about to tap.
                    .foregroundStyle(Paper.danger)
                    .frame(maxWidth: .infinity, minHeight: Hit.minimum)
            }
        }
        .padding(.horizontal, Space.gutter)
        .modifier(FillOrScroll())
        .safeAreaPadding(.vertical, Space.step)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .paperGround()
        .fileExporter(
            isPresented: $exporting,
            document: BackupDocument(bytes: exportBytes),
            contentType: .json,
            defaultFilename: "morning-\(today).json"
        ) { result in
            if case let .failure(error) = result {
                problem = error.localizedDescription
            }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            handleImport(result)
        }
        // Restore CONFIRMS THE SWAP by naming both counts, because replacing
        // 120 sessions with 3 is the mistake this dialog exists to prevent.
        // `alert`, not `confirmationDialog`, and the same reason as the End
        // dialog in `WorkoutHost`: measured on iOS 26, the sheet renders as a
        // translucent card with **no visible cancel**. On a control that
        // replaces every session you have, "how do I say no" must be on screen.
        .alert(
            "Replace your history?",
            isPresented: .constant(pendingRestore != nil)
        ) {
            Button("Replace", role: .destructive) {
                if let pendingRestore {
                    onRestore(pendingRestore)
                }
                pendingRestore = nil
            }
            Button("Cancel", role: .cancel) { pendingRestore = nil }
        } message: {
            if let pendingRestore {
                Text("This file has \(pendingRestore.history.count) sessions. "
                    + "You currently have \(data.history.count). This cannot be undone.")
            }
        }
        .alert("Erase everything?", isPresented: $confirmingErase) {
            Button("Erase", role: .destructive, action: onErase)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All \(data.history.count) sessions, permanently. Export first if you haven't.")
        }
        .alert("Could not read that file", isPresented: .constant(problem != nil)) {
            Button("OK") { problem = nil }
        } message: {
            Text(problem ?? "")
        }
    }

    /// Validates before offering the swap. A file that is not a Morning backup
    /// must say so rather than quietly restoring nothing.
    private func handleImport(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let scoped = url.startAccessingSecurityScopedResource()
            defer {
                if scoped {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let decoded = try JSONDecoder().decode(AppData.self, from: Data(contentsOf: url))
            guard !decoded.history.isEmpty else {
                problem = "That file has no sessions in it."
                return
            }
            pendingRestore = decoded
        } catch {
            problem = error.localizedDescription
        }
    }

    /// Sorted keys, so two exports of identical data are identical files —
    /// which is what makes "did anything change?" answerable.
    private var exportBytes: Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return (try? encoder.encode(data)) ?? Data()
    }

    private var today: String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}

/// The bytes that go out through the share sheet.
///
/// It carries pre-encoded `Data` rather than an `AppData`, because
/// `FileDocument`'s members are nonisolated while this module's `Codable`
/// conformances are main-actor by default. Encoding at the call site — where
/// the actor already is — is simpler than fighting that, and the document is
/// literally "the bytes" anyway.
struct BackupDocument: FileDocument {
    static let readableContentTypes = [UTType.json]

    let bytes: Data

    init(bytes: Data) {
        self.bytes = bytes
    }

    init(configuration: ReadConfiguration) throws {
        guard let contents = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        bytes = contents
    }

    func fileWrapper(configuration _: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: bytes)
    }
}
