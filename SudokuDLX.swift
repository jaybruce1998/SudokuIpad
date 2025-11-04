import Foundation

final class SudokuDLX {

    // MARK: - Exact-cover column mapping
    private static func cellCol(_ r: Int, _ c: Int) -> Int { r * 9 + c }               // 0..80
    private static func rowDigCol(_ r: Int, _ d: Int) -> Int { 81 + r * 9 + d }        // 81..161
    private static func colDigCol(_ c: Int, _ d: Int) -> Int { 162 + c * 9 + d }       // 162..242
    private static func boxIndex(_ r: Int, _ c: Int) -> Int { (r / 3) * 3 + (c / 3) }  // 0..8
    private static func boxDigCol(_ b: Int, _ d: Int) -> Int { 243 + b * 9 + d }       // 243..323
    private static func rowId(_ r: Int, _ c: Int, _ d: Int) -> Int { (r * 9 + c) * 9 + d } // 0..728

    // MARK: - DLX Structures
    class Node {
        var L: Node!
        var R: Node!
        var U: Node!
        var D: Node!
        var C: Column!
        var rid: Int = 0
        init() {
            self.L = self
            self.R = self
            self.U = self
            self.D = self
        }
    }

    final class Column: Node {
        var size: Int = 0
        var name: Int
        init(_ name: Int) {
            self.name = name
            super.init()
        }
    }

    final class DLX {
        let header: Column
        let cols: [Column]
        var solutionsFound = 0
        var limit = 0
        var solution: [[Int]]? = nil
        var choiceStack: [Node] = []

        init(_ ncols: Int) {
            header = Column(-1)
            var cols = [Column]()
            var last: Column = header
            for i in 0..<ncols {
                let c = Column(i)
                cols.append(c)
                // Insert to the right of 'last'
                c.R = last.R
                c.L = last
                last.R.L = c
                last.R = c
                last = c
            }
            self.cols = cols
        }

        func appendRow(_ rid: Int, _ colIds: [Int]) {
            var first: Node? = nil
            var prev: Node? = nil
            for cid in colIds {
                let col = cols[cid]
                let node = Node()
                node.C = col
                node.rid = rid

                // insert node at bottom of column
                node.D = col
                node.U = col.U
                col.U.D = node
                col.U = node
                col.size += 1

                // horizontal links
                if first == nil {
                    first = node
                    node.L = node
                    node.R = node
                } else {
                    node.L = prev
                    node.R = prev!.R
                    prev!.R.L = node
                    prev!.R = node
                }
                prev = node
            }
        }

        // MARK: - Knuth Cover/Uncover
        func cover(_ c: Column) {
            c.R.L = c.L
            c.L.R = c.R
            var i = c.D!
            while i !== c {
                var j = i.R!
                while j !== i {
                    j.D.U = j.U
                    j.U.D = j.D
                    j.C.size -= 1
                    j = j.R!
                }
                i = i.D!
            }
        }

        func uncover(_ c: Column) {
            var i = c.U!
            while i !== c {
                var j = i.L!
                while j !== i {
                    j.C.size += 1
                    j.D.U = j
                    j.U.D = j
                    j = j.L!
                }
                i = i.U!
            }
            c.R.L = c
            c.L.R = c
        }

        func chooseColumn() -> Column {
            var best: Column? = nil
            var bestSize = Int.max
            var c = header.R as! Column
            while c !== header {
                if c.size < bestSize {
                    bestSize = c.size
                    best = c
                    if bestSize <= 1 { break }
                }
                c = c.R as! Column
            }
            return best!
        }

        func search() {
            if solutionsFound >= limit { return }
            if header.R === header {
                solutionsFound += 1
                if solutionsFound == 1 {
                    var sol = Array(repeating: Array(repeating: 0, count: 9), count: 9)
                    for n in choiceStack {
                        let rid = n.rid
                        let rc = rid / 9
                        let r = rc / 9
                        let c = rc % 9
                        let d = rid % 9
                        sol[r][c] = d + 1
                    }
                    solution = sol
                }
                return
            }
            let c = chooseColumn()
            if c.size == 0 { return }
            cover(c)
            var r = c.D!
            while r !== c {
                choiceStack.append(r)
                var j = r.R!
                while j !== r {
                    cover(j.C)
                    j = j.R!
                }

                search()

                j = r.L!
                while j !== r {
                    uncover(j.C)
                    j = j.L!
                }
                _ = choiceStack.popLast()
                if solutionsFound >= limit {
                    uncover(c)
                    return
                }
                r = r.D!
            }
            uncover(c)
        }
    }

    // MARK: - Sudoku DLX Builder
    private static func buildSudokuDLX() -> DLX {
        let dlx = DLX(324)
        for r in 0..<9 {
            for c in 0..<9 {
                for d in 0..<9 {
                    let cols = [
                        cellCol(r, c),
                        rowDigCol(r, d),
                        colDigCol(c, d),
                        boxDigCol(boxIndex(r, c), d)
                    ]
                    dlx.appendRow(rowId(r, c, d), cols)
                }
            }
        }
        return dlx
    }

    // MARK: - Apply Given
    private static func applyGiven(_ dlx: DLX, _ r: Int, _ c: Int, _ d: Int) -> Bool {
        let cellColumn = dlx.cols[cellCol(r, c)]
        var n = cellColumn.D!
        var target: Node? = nil

        while n !== cellColumn {
            var ok = false
            var j = n
            repeat {
                let name = j.C.name
                if name >= 81 && name < 162 {
                    let rd = name - 81
                    let rr = rd / 9
                    let dd = rd % 9
                    if rr == r && dd == d {
                        ok = true
                        break
                    }
                }
                j = j.R!
            } while j !== n
            if ok {
                target = n
                break
            }
            n = n.D!
        }

        guard let row = target else {
            return false
        }

        dlx.cover(row.C)
        var j = row.R!
        while j !== row {
            dlx.cover(j.C)
            j = j.R!
        }
        return true
    }

    // MARK: - Public API
    static func solution(_ g: [[Int]]) -> [[Int]]? {
        let dlx = buildSudokuDLX()
        for r in 0..<9 {
            for c in 0..<9 {
                let val = g[r][c]
                if val != 0 {
                    if !applyGiven(dlx, r, c, val - 1) {
                        return nil
                    }
                }
            }
        }
        dlx.limit = 2
        dlx.solutionsFound = 0
        dlx.search()
        return dlx.solutionsFound == 1 ? dlx.solution : nil
    }

    static func legal(_ g: [[Int]]) -> Bool {
        return solution(g) != nil
    }
}
