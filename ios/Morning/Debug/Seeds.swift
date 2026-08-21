//
//  Seeds.swift
//
//  The debug seeder ios-port/06-data.md §2 asks for.
//
//  "You cannot design the Ledger, the year grid or the history list against
//   nothing, and you should not design them against three sessions either —
//   they need to look right after six months."
//
//  Every screen gets reviewed at EMPTY, ONE WEEK and SIX MONTHS before it is
//  called done. Empty is not an edge case: on day one it is what the app is.
//
//  Usage, once persistence exists:
//
//    Xcode scheme -> Run -> Arguments -> "-seed six-months"
//    or call Seed.sixMonths.load() from a debug menu.
//
//  The files ship in the bundle in every configuration — ~150KB, and the code
//  that reads them is behind #if DEBUG. Excluding them from Release needed an
//  off-label build setting for a saving that does not matter on a personal app.
//
//  Regenerate or re-anchor them to a different "today" with:
//    node ios/Tools/gen-seeds.mjs 2027-01-15
//

#if DEBUG

import Foundation

enum Seed: String, CaseIterable {
    /// A fresh install. The state the app actually ships in.
    case empty
    /// The `first` celebration tier has fired. One cell in the year grid.
    case oneSession = "one-session"
    /// The week meter completing for the first time.
    case oneWeek = "one-week"
    /// A plateau, a personal best, a missed week, and a working-weight change
    /// partway through — so every celebration tier and every "not comparable"
    /// path is reachable.
    case sixMonths = "six-months"
    /// The year grid full, and a lifetime milestone about to cross.
    case oneYear = "one-year"

    /// Reads the seed out of the bundle. Returns nil rather than trapping, so
    /// a missing fixture degrades to "no data" instead of killing the app.
    func load() -> AppData? {
        guard let url = Bundle.main.url(forResource: "\(rawValue).seed", withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else {
            assertionFailure("seed \(rawValue) missing from the bundle")
            return nil
        }
        return try? JSONDecoder().decode(AppData.self, from: data)
    }

    /// The seed named by a `-seed <name>` launch argument, if any.
    static var fromLaunchArguments: Seed? {
        let args = ProcessInfo.processInfo.arguments
        guard let flag = args.firstIndex(of: "-seed"), args.indices.contains(flag + 1) else {
            return nil
        }
        return Seed(rawValue: args[flag + 1])
    }
}

#endif
