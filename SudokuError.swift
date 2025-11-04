enum SudokuError: Error {
    case invalidClue(row: Int, column: Int, value: Int)
}
