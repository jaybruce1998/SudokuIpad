//
//  Cell.swift
//  Sudoku
//
//  Created by Ji Won Lee on 11/2/25.
//


    struct Cell {
        let r: Int, c: Int
        static func allCells() -> [Cell] {
            var list = [Cell]()
            for r in 0..<9 {
                for c in 0..<9 { list.append(Cell(r: r, c: c)) }
            }
            return list
        }
    }
