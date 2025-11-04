import Foundation

/// Represents a compact encoding of a 9×9 Sudoku permutation’s row/column legality
struct GridBits {
    private var first: UInt64 = 0
    private var last: UInt64 = 0

    mutating func set(_ bit: Int) {
        if bit < 64 { first |= (1 << UInt64(bit)) }
        else { last |= (1 << UInt64(bit - 64)) }
    }

    func get(_ bit: Int) -> Bool {
        if bit < 64 { return ((first >> UInt64(bit)) & 1) != 0 }
        else { return ((last >> UInt64(bit - 64)) & 1) != 0 }
    }

    func legal(_ g: GridBits) -> Bool {
        return ((first & g.first) | (last & g.last)) == 0
    }

    /// Builds all ~46,656 legal permutations for Sudoku
    static func buildPerms() -> [GridBits] {
        var packed: [GridBits] = []
        packed.reserveCapacity(46656)

        let S3: [[Int]] = [
            [0, 1, 2], [0, 2, 1], [1, 0, 2],
            [1, 2, 0], [2, 0, 1], [2, 1, 0]
        ]

        var TRIPLES = Array(repeating: Array(repeating: Array(repeating: 0, count: 3), count: 3), count: 216)
        var ROW_MAP = Array(repeating: Array(repeating: 0, count: 9), count: 216)
        var COL_MAP = Array(repeating: Array(repeating: 0, count: 9), count: 216)

        var idx = 0
        for a in 0..<6 {
            for b in 0..<6 {
                for c in 0..<6 {
                    TRIPLES[idx][0] = S3[a]
                    TRIPLES[idx][1] = S3[b]
                    TRIPLES[idx][2] = S3[c]

                    for band in 0..<3 {
                        for i in 0..<3 {
                            let src = 3 * band + i
                            let dst = 3 * band + TRIPLES[idx][band][i]
                            ROW_MAP[idx][dst] = (src % 3) * 3 + (src / 3)
                            COL_MAP[idx][src] = dst
                        }
                    }
                    idx += 1
                }
            }
        }

        for rb in 0..<216 {
            for cb in 0..<216 {
                var gb = GridBits()
                for r in 0..<9 {
                    let cBase = ROW_MAP[rb][r]
                    let cFinal = COL_MAP[cb][cBase]
                    let bit = r * 9 + cFinal
                    gb.set(bit)
                }
                packed.append(gb)
            }
        }

        print("✅ Built PERMS: \(packed.count) entries")
        return packed
    }
}
