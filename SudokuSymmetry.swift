import Foundation

final class SudokuSymmetry {
    
    // MARK: - Random utilities
    private static func rand(_ m: Int) -> Int {
        Int.random(in: 0..<m)
    }
    
    // MARK: - Public API
    static func applyRandomSymmetry(_ values: inout [[Int]]) {
        var ops: [Int] = []
        ops.append(0)             // transpose
        ops.append(contentsOf: [1, 1]) // bands
        ops.append(contentsOf: [2, 2]) // stacks
        for _ in 0..<6 { ops.append(3) } // rows in bands
        for _ in 0..<6 { ops.append(4) } // cols in stacks
        
        for _ in stride(from: rand(17), through: 1, by: -1) {
            if ops.isEmpty { break }
            let opIndex = rand(ops.count)
            let op = ops.remove(at: opIndex)
            switch op {
            case 0: transpose(&values)
            case 1: randomBandOp(&values)
            case 2: randomStackOp(&values)
            case 3: randomRowsInBandOp(&values)
            case 4: randomColsInStackOp(&values)
            default: break
            }
        }
        
        // Digit symmetry — randomly swap digits 1–9
        for _ in stride(from: rand(9), through: 1, by: -1) {
            let a = rand(9) + 1
            var b = rand(9) + 1
            while a == b {
                b = rand(9) + 1
            }
            swapDigits(&values, a, b)
        }
    }
    
    // MARK: - Basic transforms
    private static func transpose(_ a: inout [[Int]]) {
        for r in 0..<9 {
            for c in (r + 1)..<9 {
                let t = a[r][c]
                a[r][c] = a[c][r]
                a[c][r] = t
            }
        }
    }
    
    private static func swapRows(_ a: inout [[Int]], _ r1: Int, _ r2: Int) {
        if r1 == r2 { return }
        a.swapAt(r1, r2)
    }
    
    private static func swapCols(_ a: inout [[Int]], _ c1: Int, _ c2: Int) {
        if c1 == c2 { return }
        for r in 0..<9 {
            let t = a[r][c1]
            a[r][c1] = a[r][c2]
            a[r][c2] = t
        }
    }
    
    private static func swapBands(_ a: inout [[Int]], _ b1: Int, _ b2: Int) {
        if b1 == b2 { return }
        for i in 0..<3 {
            swapRows(&a, b1 * 3 + i, b2 * 3 + i)
        }
    }
    
    private static func swapStacks(_ a: inout [[Int]], _ s1: Int, _ s2: Int) {
        if s1 == s2 { return }
        for r in 0..<9 {
            for i in 0..<3 {
                let c1 = s1 * 3 + i
                let c2 = s2 * 3 + i
                let t = a[r][c1]
                a[r][c1] = a[r][c2]
                a[r][c2] = t
            }
        }
    }
    
    private static func cycleRowsInBand(_ a: inout [[Int]], _ band: Int, _ forward: Bool) {
        let r0 = band * 3
        let r1 = r0 + 1
        let r2 = r0 + 2
        if forward {
            // [r0, r1, r2] -> [r2, r0, r1]
            let t = a[r2]
            a[r2] = a[r1]
            a[r1] = a[r0]
            a[r0] = t
        } else {
            // [r0, r1, r2] -> [r1, r2, r0]
            let t = a[r0]
            a[r0] = a[r1]
            a[r1] = a[r2]
            a[r2] = t
        }
    }
    
    private static func cycleColsInStack(_ a: inout [[Int]], _ stack: Int, _ forward: Bool) {
        let c0 = stack * 3
        let c1 = c0 + 1
        let c2 = c0 + 2
        for r in 0..<9 {
            if forward {
                // [c0, c1, c2] -> [c2, c0, c1]
                let t = a[r][c2]
                a[r][c2] = a[r][c1]
                a[r][c1] = a[r][c0]
                a[r][c0] = t
            } else {
                // [c0, c1, c2] -> [c1, c2, c0]
                let t = a[r][c0]
                a[r][c0] = a[r][c1]
                a[r][c1] = a[r][c2]
                a[r][c2] = t
            }
        }
    }
    
    // MARK: - Random S3 operations
    private static func randomBandOp(_ a: inout [[Int]]) {
        if Double.random(in: 0..<1) < 0.5 {
            let b1 = rand(3)
            var b2 = rand(3)
            while b1 == b2 { b2 = rand(3) }
            swapBands(&a, b1, b2)
        } else {
            if Double.random(in: 0..<1) < 0.5 {
                swapBands(&a, 0, 2)
                swapBands(&a, 0, 1)
            } else {
                swapBands(&a, 0, 1)
                swapBands(&a, 0, 2)
            }
        }
    }
    
    private static func randomStackOp(_ a: inout [[Int]]) {
        if Double.random(in: 0..<1) < 0.5 {
            let s1 = rand(3)
            var s2 = rand(3)
            while s1 == s2 { s2 = rand(3) }
            swapStacks(&a, s1, s2)
        } else {
            if Double.random(in: 0..<1) < 0.5 {
                swapStacks(&a, 0, 2)
                swapStacks(&a, 0, 1)
            } else {
                swapStacks(&a, 0, 1)
                swapStacks(&a, 0, 2)
            }
        }
    }
    
    private static func randomRowsInBandOp(_ a: inout [[Int]]) {
        let band = rand(3)
        if Double.random(in: 0..<1) < 0.5 {
            let rA = rand(3)
            var rB = rand(3)
            while rA == rB { rB = rand(3) }
            swapRows(&a, band * 3 + rA, band * 3 + rB)
        } else {
            cycleRowsInBand(&a, band, Double.random(in: 0..<1) < 0.5)
        }
    }
    
    private static func randomColsInStackOp(_ a: inout [[Int]]) {
        let stack = rand(3)
        if Double.random(in: 0..<1) < 0.5 {
            let cA = rand(3)
            var cB = rand(3)
            while cA == cB { cB = rand(3) }
            swapCols(&a, stack * 3 + cA, stack * 3 + cB)
        } else {
            cycleColsInStack(&a, stack, Double.random(in: 0..<1) < 0.5)
        }
    }
    
    private static func swapDigits(_ a: inout [[Int]], _ d1: Int, _ d2: Int) {
        for r in 0..<9 {
            for c in 0..<9 {
                let v = a[r][c]
                if v == d1 { a[r][c] = d2 }
                else if v == d2 { a[r][c] = d1 }
            }
        }
    }
}
