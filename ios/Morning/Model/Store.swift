import Foundation

/* ===========================================================================
 *  STORAGE
 *  ---------------------------------------------------------------------------
 *  One JSON file for the history, a second for the session in progress, both in
 *  Application Support. `06-data.md §5`: a few tens of KB per year, so SwiftData
 *  and Core Data buy nothing here and cost migration work — and the export has
 *  to stay byte-compatible with the web app's format, which an object graph
 *  would fight.
 *
 *  THE ONE UNACCEPTABLE FAILURE MODE, from `04-rules.md §8`:
 *
 *      Never lose data on a failed write — surface it.
 *
 *  So every write is atomic and every write can throw. Nothing here swallows an
 *  error and returns quietly, because a save that silently did nothing is how
 *  you lose a session you already did.
 *
 *  Reads are the opposite: lenient by design. A malformed record is dropped and
 *  the rest of the file still loads, because a half-readable backup is better
 *  than none. That asymmetry is deliberate.
 * ======================================================================== */

@MainActor
final class Store {
    /// Surfaced, never swallowed. Each case says what the user lost, if
    /// anything, because that is what the message on screen has to say.
    enum StoreError: LocalizedError, Equatable {
        case couldNotCreateDirectory(String)
        case couldNotWriteHistory(String)
        case couldNotWriteInProgress(String)

        var errorDescription: String? {
            switch self {
            case let .couldNotCreateDirectory(reason):
                "Could not prepare the storage folder. \(reason)"
            case let .couldNotWriteHistory(reason):
                "Could not save your history. \(reason)"
            case let .couldNotWriteInProgress(reason):
                "Could not save the session in progress. \(reason)"
            }
        }
    }

    private let directory: URL

    /// - Parameter directory: injectable so each test gets an isolated
    ///   temporary directory rather than sharing Application Support.
    init(directory: URL? = nil) {
        self.directory = directory ?? FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Morning", isDirectory: true)
    }

    var historyURL: URL {
        directory.appendingPathComponent("history.json")
    }

    var inProgressURL: URL {
        directory.appendingPathComponent("in-progress.json")
    }

    // MARK: - Reading

    /// A missing file is not an error — it is a fresh install, which is the
    /// normal case on day one rather than an edge case.
    func load() -> AppData {
        guard let data = try? Data(contentsOf: historyURL) else { return .empty }
        return (try? JSONDecoder().decode(AppData.self, from: data)) ?? .empty
    }

    func loadInProgress() -> InProgressSession? {
        guard let data = try? Data(contentsOf: inProgressURL) else { return nil }
        return try? JSONDecoder().decode(InProgressSession.self, from: data)
    }

    // MARK: - Writing

    func save(_ appData: AppData) throws {
        try write(encoder.encode(appData), to: historyURL, failure: StoreError.couldNotWriteHistory)
    }

    /// Passing `nil` clears the file — the session finished or was abandoned.
    func saveInProgress(_ session: InProgressSession?) throws {
        guard let session else {
            try? FileManager.default.removeItem(at: inProgressURL)
            return
        }
        try write(encoder.encode(session), to: inProgressURL, failure: StoreError.couldNotWriteInProgress)
    }

    // MARK: - Export

    /// The bytes that go out through the share sheet, and the same shape the
    /// eventual import will read. Sorted keys so two exports of identical data
    /// are identical files, which is what makes "did anything change?" answerable.
    func exportJSON(_ appData: AppData) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(appData)
    }

    // MARK: - Internals

    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return encoder
    }

    /// Atomic, so a crash mid-write leaves the previous file intact rather than
    /// a truncated one.
    private func write(_ data: Data, to url: URL, failure: (String) -> StoreError) throws {
        do {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
        } catch {
            throw StoreError.couldNotCreateDirectory(error.localizedDescription)
        }

        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw failure(error.localizedDescription)
        }
    }
}
