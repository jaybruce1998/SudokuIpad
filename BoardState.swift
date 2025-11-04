import Foundation

class BoardState {
    // MARK: - Properties

    /// Fixed givens (from Sudoku)
    var given: [[Bool]] = Array(repeating: Array(repeating: false, count: 9), count: 9)
    
    /// Current cell values (0 if empty)
    var values: [[Int]] = Array(repeating: Array(repeating: 0, count: 9), count: 9)
    
    /// Candidates presence (true if candidate exists)
    var cand: [[[Bool]]] = Array(
        repeating: Array(repeating: Array(repeating: false, count: 9), count: 9),
        count: 9
    )
    
    /// Candidate colors: 0 = none, 1..6 = palette
    var candColor: [[[UInt8]]] = Array(
        repeating: Array(repeating: Array(repeating: 0, count: 9), count: 9),
        count: 9
    )
    
    // MARK: - Initialization

    init() {
        // Default empty board
    }

    /// Create a deep copy
    func deepCopy() -> BoardState {
        let copy = BoardState()
        for r in 0..<9 {
            for c in 0..<9 {
                copy.given[r][c] = given[r][c]
                copy.values[r][c] = values[r][c]
                for k in 0..<9 {
                    copy.cand[r][c][k] = cand[r][c][k]
                    copy.candColor[r][c][k] = candColor[r][c][k]
                }
            }
        }
        return copy
    }

    /// Initialize from a Sudoku object
    static func fromSudoku(_ sudoku: Sudoku) -> BoardState {
        let state = BoardState()
        for r in 0..<9 {
            for c in 0..<9 {
                let v = sudoku.values[r][c]
                state.values[r][c] = v
                state.given[r][c] = (v != 0)
                // Candidates remain empty initially
            }
        }
        return state
    }
}
