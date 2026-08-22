import Foundation

/* ===========================================================================
 *  PLATE MATHS
 *  ---------------------------------------------------------------------------
 *  The loadout strings used to be literals ("4×1.25 + 2×2.5"), correct only for
 *  the weight the session happened to be written for. Once the weight became
 *  adjustable the breakdown had to be derived, or the card tells you to load
 *  plates you are not using.
 *
 *  It is bounded by what you actually own. An unbounded greedy fit returns
 *  "3×2.5" for 7.5 kg, which is wrong with only two 2.5s per handle — the real
 *  answer is 2×2.5 + 2×1.25. Respecting the inventory also makes the derived
 *  strings match the program's original hand-written ones exactly, which is how
 *  you know the derivation is right.
 *
 *  Reference: `src/lib/plates.ts`.
 * ======================================================================== */

enum Plates {
    /// Smallest change you can make to one handle, given the lightest plate.
    static var step: Double {
        plateInventory.map(\.kg).min() ?? 1.25
    }

    /// Heaviest you can load one handle with the plates you own.
    static var maximum: Double {
        plateInventory.reduce(0) { $0 + $1.kg * Double($1.count) }
    }

    /// "2×2.5 + 2×1.25" for one handle, or `nil` if the plates cannot make it.
    ///
    /// Heaviest first, but never more of a plate than exist. Exact because
    /// every denomination is a multiple of the next one down.
    static func breakdown(for kg: Double) -> String? {
        if kg <= 0 {
            return "bare handle"
        }

        var parts: [String] = []
        var remaining = kg

        for plate in plateInventory.sorted(by: { $0.kg > $1.kg }) {
            let count = min(plate.count, Int((remaining / plate.kg) + 1e-9))
            if count > 0 {
                parts.append("\(count)×\(format(plate.kg))")
                remaining -= Double(count) * plate.kg
            }
        }

        return remaining > 1e-9 ? nil : parts.joined(separator: " + ")
    }

    /// Whole numbers lose their decimal; everything else keeps at most two.
    static func format(_ kg: Double) -> String {
        kg == kg.rounded() ? String(Int(kg)) : String(format: "%g", (kg * 100).rounded() / 100)
    }
}
