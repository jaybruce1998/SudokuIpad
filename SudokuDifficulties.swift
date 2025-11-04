import Foundation

extension Sudoku {
    
    func easy() -> Bool {
        var b = true
        var r = true
        
        while b {
            b = false
            r = true
            for i in 0..<9 {
                for j in 0..<9 {
                    if remaining[i][j] == 1 {
                        for v in 0..<9 {
                            if candidates[i][j][v] {
                                if !set(r: i, c: j, v: v) {
                                    solvable = false
                                    return true
                                }
                                b = true
                                break
                            }
                        }
                    } else {
                        r = r && values[i][j] > 0
                    }
                }
            }
        }
        return r
    }
    
    func medium() -> Bool {
        var b = true
        while b {
            if easy() { return true }
            b = false
            for i in 0..<9 {
                for v in 0..<9 {
                    if rRemaining[i][v] == 0 || cRemaining[i][v] == 0 || bRemaining[i][v] == 0 {
                        solvable = false
                        return true
                    } else if rRemaining[i][v] == 1 {
                        for c in 0..<9 {
                            if candidates[i][c][v] {
                                if !set(r: i, c: c, v: v) {
                                    solvable = false
                                    return true
                                }
                                b = true
                                break
                            }
                        }
                    } else if cRemaining[i][v] == 1 {
                        for r in 0..<9 {
                            if candidates[r][i][v] {
                                if !set(r: r, c: i, v: v) {
                                    solvable = false
                                    return true
                                }
                                b = true
                                break
                            }
                        }
                    } else if bRemaining[i][v] == 1 {
                        let br = i / 3 * 3
                        let bc = i % 3 * 3
                        for r in br..<br+3 {
                            for c in bc..<bc+3 {
                                if candidates[r][c][v] {
                                    if !set(r: r, c: c, v: v) {
                                        solvable = false
                                        return true
                                    }
                                    b = true
                                    break
                                }
                            }
                        }
                    }
                }
            }
        }
        
        for i in 0..<9 {
            for j in 0..<9 {
                if values[i][j] == 0 { return false }
            }
        }
        return true
    }
    
    func hard() -> Bool {
        var b = true
        while b {
            if medium() { return true }
            b = false

            var r = 0
            while r < 9 {
                var c = 0
                while c < 9 {
                    if values[r][c] == 0 {
                        for v in 0..<9 {
                            if candidates[r][c][v] {
                                let s = Sudoku(copy: self, testRow: r, testCol: c, testValue: v)
                                if s.easy() {
                                    if s.solvable {
                                        setValues(s.values)
                                        return true
                                    } else {
                                        candidates[r][c][v] = false
                                        rRemaining[r][v] -= 1
                                        cRemaining[c][v] -= 1
                                        bRemaining[r / 3 * 3 + c / 3][v] -= 1
                                        b = true
                                        r = 9 // force exit outer loops
                                        c = 9
                                        break
                                    }
                                }
                            }
                        }
                    }
                    c += 1
                }
                r += 1
            }
        }
        return false
    }

    func extreme() -> Bool {
        var b = true
        while b {
            if medium() { return true }
            b = false

            var r = 0
            while r < 9 {
                var c = 0
                while c < 9 {
                    if values[r][c] == 0 {
                        for v in 0..<9 {
                            if candidates[r][c][v] {
                                let s = Sudoku(copy: self, testRow: r, testCol: c, testValue: v)
                                if s.medium() {
                                    if s.solvable {
                                        setValues(s.values)
                                        return true
                                    } else {
                                        candidates[r][c][v] = false
                                        rRemaining[r][v] -= 1
                                        cRemaining[c][v] -= 1
                                        bRemaining[r / 3 * 3 + c / 3][v] -= 1
                                        b = true
                                        r = 9
                                        c = 9
                                        break
                                    }
                                }
                            }
                        }
                    }
                    c += 1
                }
                r += 1
            }
        }
        return false
    }
    
    func difficulty() -> String {
        var filled = Array(repeating: Array(repeating: false, count: 9), count: 9)
        for i in 0..<9 {
            for j in 0..<9 {
                filled[i][j] = values[i][j] > 0
            }
        }

        let result: String
        if easy() { result = "Easy" }
        else if medium() { result = "Medium" }
        else if hard() { result = "Hard" }
        else if extreme() { result = "Extreme" }
        else { result = "Nightmare" }

        // Reset values for unfilled cells
        for i in 0..<9 {
            for j in 0..<9 {
                if !filled[i][j] { values[i][j] = 0 }
            }
        }

        return result
    }
}
