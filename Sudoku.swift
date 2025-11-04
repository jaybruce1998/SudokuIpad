import Foundation

final class Sudoku {
    // MARK: - Core properties
    var values: [[Int]]           // current puzzle (may have blanks)
    var complete: [[Int]]         // solution
    var candidates: [[[Bool]]]
    var remaining: [[Int]]
    var rRemaining: [[Int]]
    var cRemaining: [[Int]]
    var bRemaining: [[Int]]
    var ind: [Int] = []   // unused permutation indices
    var solvable: Bool
    
    static let PERMS: [GridBits] = GridBits.buildPerms()

    // MARK: - Private constructors
    /// Only used internally by other initializers
    private init() {
        values = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        complete = Array(repeating: Array(repeating: 0, count: 9), count: 9)

        candidates = Array(
            repeating: Array(repeating: Array(repeating: true, count: 9), count: 9),
            count: 9
        )
        remaining = Array(repeating: Array(repeating: 9, count: 9), count: 9)
        rRemaining = Array(repeating: Array(repeating: 9, count: 9), count: 9)
        cRemaining = Array(repeating: Array(repeating: 9, count: 9), count: 9)
        bRemaining = Array(repeating: Array(repeating: 9, count: 9), count: 9)
        solvable = true
    }

    /// Only used internally by randomPuzzle()
    convenience init(ind: [Int]) {
        self.init()
        self.ind = ind
        setComplete()
    }

    // MARK: - Public constructors
    /// Difficulty: 0 = easy, 1 = medium, 2 = hard, 3 = extreme
    convenience init(difficulty d: Int) {
        self.init(ind: [])
        var filled = Array(repeating: Array(repeating: false, count: 9), count: 9)

        if d == 0 {
            // Easy: remove cells randomly but keep solvable
            var cells = Cell.allCells()
            while !cells.isEmpty {
                let c = cells.remove(at: Int.random(in: 0..<cells.count))
                filled[c.r][c.c] = false
                reset()
                for r in 0..<9 { for c in 0..<9 { values[r][c] = 0 } }
                resetGrid(filled: filled)
                filled[c.r][c.c] = !easy()
            }
        } else {
            // Medium / Hard / Extreme
            var dif = 4
            while d != dif {
                randomize(filled: &filled)
                if easy() { dif = 0 }
                else if medium() { dif = 1 }
                else if hard() { dif = 2 }
                else { dif = 3 }
            }
        }
        fillGrid(filled: filled)
    }

    /// Import from string
    convenience init(fromString p: String) {
        self.init()
        var str = p
        if str.count < 81 { str += String(repeating: "0", count: 81 - str.count) }
        reset()
        var i = 0
        for r in 0..<9 {
            for c in 0..<9 {
                if let val = Int(String(str[str.index(str.startIndex, offsetBy: i)])) {
                    if val >= 1 && val <= 9 { set(r: r, c: c, v: val - 1) }
                }
                i += 1
            }
        }
    }

    convenience init(fromGrid g: [[Int]]) {
        self.init()
        reset()
        var mutableGrid = g             // copy to a mutable variable
        SudokuSymmetry.applyRandomSymmetry(&mutableGrid)
        for r in 0..<9 {
            for c in 0..<9 {
                if mutableGrid[r][c] != 0 {
                    set(r: r, c: c, v: mutableGrid[r][c] - 1)
                }
            }
        }
        if let solution = SudokuDLX.solution(values) {
            complete = solution
        }
    }
    
    convenience init(copy s: Sudoku, testRow r: Int, testCol c: Int, testValue v: Int) {
        self.init() // call default initializer to allocate arrays

        // Copy all 9×9 arrays
        for i in 0..<9 {
            for j in 0..<9 {
                for k in 0..<9 {
                    candidates[i][j][k] = s.candidates[i][j][k]
                }
                values[i][j] = s.values[i][j]
                remaining[i][j] = s.remaining[i][j]
                rRemaining[i][j] = s.rRemaining[i][j]
                cRemaining[i][j] = s.cRemaining[i][j]
                bRemaining[i][j] = s.bRemaining[i][j]
            }
        }

        // Attempt the test placement
        solvable = set(r: r, c: c, v: v)
    }

}
