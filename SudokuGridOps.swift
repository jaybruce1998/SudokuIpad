//
//  SudokuGridOps.swift
//

import Foundation

extension Sudoku {
    
    // MARK: - Reset helpers
    
    func reset() {
        for r in 0..<9 {
            for c in 0..<9 {
                for v in 0..<9 {
                    candidates[r][c][v] = true
                }
                remaining[r][c] = 9
                rRemaining[r][c] = 9
                cRemaining[r][c] = 9
                bRemaining[r][c] = 9
            }
        }
    }

    func resetGrid(filled: [[Bool]]) {
        for r in 0..<9 {
            for c in 0..<9 {
                if filled[r][c] {
                    _ = set(r: r, c: c, v: complete[r][c] - 1)
                }
            }
        }
    }

    func fillGrid(filled: [[Bool]]) {
        for r in 0..<9 {
            for c in 0..<9 {
                values[r][c] = filled[r][c] ? complete[r][c] : 0
            }
        }
    }

    func setValues(_ v: [[Int]]) {
        for r in 0..<9 {
            for c in 0..<9 {
                values[r][c] = v[r][c]
            }
        }
    }

    // MARK: - Candidate tracking

    private func badRemove(r: Int, c: Int, v: Int) -> Bool {
        if candidates[r][c][v] {
            if remaining[r][c] == 1 {
                return true
            }
            candidates[r][c][v] = false
            remaining[r][c] -= 1
            rRemaining[r][v] -= 1
            cRemaining[c][v] -= 1
            bRemaining[r/3*3 + c/3][v] -= 1
        }
        return false
    }

    @discardableResult
    func set(r: Int, c: Int, v: Int) -> Bool {
        let br = r / 3 * 3
        var bc = c / 3
        let b = br + bc
        remaining[r][c] = 0

        for i in 0..<9 {
            if candidates[r][c][i] {
                candidates[r][c][i] = false
                rRemaining[r][i] -= 1
                cRemaining[c][i] -= 1
                bRemaining[b][i] -= 1
            }
            if badRemove(r: i, c: c, v: v) || badRemove(r: r, c: i, v: v) {
                return false
            }
        }

        bc *= 3
        for i in br..<(br + 3) {
            for j in bc..<(bc + 3) {
                if badRemove(r: i, c: j, v: v) {
                    return false
                }
            }
        }

        values[r][c] = v + 1
        rRemaining[r][v] = 9
        cRemaining[c][v] = 9
        bRemaining[b][v] = 9

        return true
    }
    
    func isValid() -> Bool {
        guard let solution = SudokuDLX.solution(values) else {
            return false
        }
        complete = solution
        return true
    }
}
