import Foundation

extension Sudoku {
    
    private func setRandom(_ g: inout [GridBits], _ i: Int) -> Int {
        // Pick a random index from ind
        let rIndex = Int.random(in: 0..<ind.count)
        let r = ind[rIndex]

        // Set the permutation at g[i]
        g[i] = Sudoku.PERMS[r]

        // Keep only the indices that are legal with g[i]
        ind = ind.filter { g[i].legal(Sudoku.PERMS[$0]) }

        return r
    }

    func setComplete() {
        var g = Array(repeating: GridBits(), count: 8)
        complete = Array(repeating: Array(repeating: 0, count: 9), count: 9)

        ind = Array(0..<Sudoku.PERMS.count)

        for i in 0..<5 { _ = setRandom(&g, i) }

        var s = ind
        var b = true
        while b {
            let i = setRandom(&g, 5)
            if !ind.isEmpty { _ = setRandom(&g, 6) }
            if ind.isEmpty {
                if s.count > 35 {
                    s.removeAll { $0 == i }
                    ind = s
                } else {
                    setComplete()  // retry if permutation fails
                    return
                }
            } else { b = false }
        }

        _ = setRandom(&g, 7)

        for n in 0..<8 {
            var idx = 0
            for r in 0..<9 {
                for c in 0..<9 {
                    if g[n].get(idx) { complete[r][c] = n + 1 }
                    idx += 1
                }
            }
        }

        for r in 0..<9 {
            for c in 0..<9 {
                if complete[r][c] == 0 { complete[r][c] = 9 }
            }
        }
    }

    
    func randomize(filled: inout [[Bool]]) {
        // 1️⃣ Create the list of all cells
        var l: [Cell] = Cell.allCells()

        // 2️⃣ Copy complete -> values
        for i in 0..<9 {
            for j in 0..<9 {
                values[i][j] = complete[i][j]
            }
        }

        // 3️⃣ Randomly remove cells
        while !l.isEmpty {
            let index = Int.random(in: 0..<l.count)
            let c = l.remove(at: index)
            values[c.r][c.c] = 0
            if !SudokuDLX.legal(values) {
                values[c.r][c.c] = complete[c.r][c.c]
            }
        }

        // 4️⃣ Reset tracking arrays
        reset()

        // 5️⃣ Set filled flags and clear values for givens
        for i in 0..<9 {
            for j in 0..<9 {
                filled[i][j] = values[i][j] > 0
                if filled[i][j] {
                    values[i][j] = 0
                }
            }
        }

        // 6️⃣ Reset candidates/grid with the filled array
        resetGrid(filled: filled)
    }

    static func randomPuzzle() -> Sudoku {
        let s = Sudoku(ind: [])
        var filled = Array(repeating: Array(repeating: false, count: 9), count: 9)
        s.randomize(filled: &filled)
        return s
    }

}
