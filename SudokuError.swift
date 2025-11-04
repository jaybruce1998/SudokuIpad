//
//  SudokuError.swift
//  Sudoku
//
//  Created by Ji Won Lee on 11/3/25.
//


enum SudokuError: Error {
    case invalidClue(row: Int, column: Int, value: Int)
}
