import UIKit

class BoardView: UIView {
    
    // MARK: - State
    var boardState: BoardState
    var sudoku: Sudoku
    
    var inputMode: InputMode = .value
    var selectedColor: CandColor = .red
    var autoUpdate: Bool = true
    var showMistakes: Bool = true
    var singleColorCells: Bool = true
    var mistakesCurrent: Int32 = 0
    
    private var undoStack: [BoardState] = []
    var onBoardChanged: (() -> Void)? = nil
    
    // MARK: - Init
    init(frame: CGRect, sudoku: Sudoku, boardState: BoardState) {
        self.sudoku = sudoku
        self.boardState = boardState
        super.init(frame: frame)
        backgroundColor = .white
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Helpers
    private var cellSize: CGFloat {
        min(bounds.width, bounds.height) / 9.0
    }
    
    private var gridSize: CGFloat {
        cellSize * 9.0
    }
    
    // MARK: - Undo / Candidate Management
    func undo() {
        guard let previous = undoStack.popLast() else { return }
        self.boardState = previous
        setNeedsDisplay()
        onBoardChanged?()
    }
    
    func resetCandidates() {
        pushUndo()
        for r in 0..<9 {
            for c in 0..<9 {
                if boardState.values[r][c] != 0 { continue }
                for k in 0..<9 {
                    boardState.cand[r][c][k] = false
                    boardState.candColor[r][c][k] = 0
                }
                if !autoUpdate {
                    for k in 0..<9 { boardState.cand[r][c][k] = true }
                } else {
                    for k in 0..<9 {
                        let v = k + 1
                        if !conflicts(row: r, col: c, value: v) {
                            boardState.cand[r][c][k] = true
                        }
                    }
                }
            }
        }
        setNeedsDisplay()
        onBoardChanged?()
    }
    
    func resetCandidateColors() {
        pushUndo()
        for r in 0..<9 {
            for c in 0..<9 {
                for k in 0..<9 { boardState.candColor[r][c][k] = 0 }
            }
        }
        setNeedsDisplay()
        onBoardChanged?()
    }
    
    private func pushUndo() {
        undoStack.append(boardState.deepCopy())
    }
    
    // MARK: - Input Handling
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        guard location.x >= 0, location.y >= 0,
              location.x <= gridSize, location.y <= gridSize else { return }
        
        let col = Int(location.x / cellSize)
        let row = Int(location.y / cellSize)
        guard row < 9, col < 9 else { return }
        
        if boardState.given[row][col] { return }
        
        if boardState.values[row][col] != 0 {
            // clear user-filled value
            pushUndo()
            boardState.values[row][col] = 0
            for k in 0..<9 { boardState.cand[row][col][k] = false; boardState.candColor[row][col][k] = 0 }
            setNeedsDisplay()
            onBoardChanged?()
            return
        }
        
        // Determine candidate index in 3x3 subcell
        let localX = location.x - CGFloat(col) * cellSize
        let localY = location.y - CGFloat(row) * cellSize
        let subCellW = cellSize / 3
        let subCellH = cellSize / 3
        let sc = min(Int(localX / subCellW), 2)
        let sr = min(Int(localY / subCellH), 2)
        let d = sr * 3 + sc
        
        let hasCandidate = boardState.cand[row][col][d]
        
        switch inputMode {
        case .value:
            if hasCandidate {
                setValue(row: row, col: col, value: d + 1)
            } else {
                toggleCandidate(row: row, col: col, index: d)
            }
        case .toggle:
            toggleCandidate(row: row, col: col, index: d)
        case .color:
            setCandidateColored(row: row, col: col, index: d)
        }
    }
    
    func isComplete() -> Bool {
        for r in 0..<9 {
            for c in 0..<9 {
                if !boardState.given[r][c] && boardState.values[r][c] != sudoku.complete[r][c] {
                    return false
                }
            }
        }
        return true
    }
    
    private func setValue(row: Int, col: Int, value: Int) {
        guard !boardState.given[row][col] else { return }
        pushUndo()
        boardState.values[row][col] = value
        if value != sudoku.complete[row][col] {
            mistakesCurrent += 1
        }
        for k in 0..<9 { boardState.cand[row][col][k] = false; boardState.candColor[row][col][k] = 0 }
        if autoUpdate && value != 0 { removePeersCandidates(row: row, col: col, value: value) }
        setNeedsDisplay()
        onBoardChanged?()
    }
    
    private func toggleCandidate(row: Int, col: Int, index: Int) {
        guard boardState.values[row][col] == 0 else { return }
        pushUndo()
        boardState.cand[row][col][index].toggle()
        if !boardState.cand[row][col][index] { boardState.candColor[row][col][index] = 0 }
        setNeedsDisplay()
        onBoardChanged?()
    }
    
    private func setCandidateColored(row: Int, col: Int, index: Int) {
        guard boardState.values[row][col] == 0 else { return }
        pushUndo()
        boardState.cand[row][col][index] = true
        
        let current = boardState.candColor[row][col][index]
        let wanted = UInt8(selectedColor.rawValue)
        
        if current == wanted && current != 0 {
            boardState.candColor[row][col][index] = 0
        } else {
            if singleColorCells {
                for k in 0..<9 {
                    if boardState.candColor[row][col][k] != wanted {
                        boardState.candColor[row][col][k] = 0
                    }
                }
            }
            boardState.candColor[row][col][index] = wanted
        }
        setNeedsDisplay()
        onBoardChanged?()
    }
    
    private func removePeersCandidates(row: Int, col: Int, value: Int) {
        let d = value - 1
        for cc in 0..<9 where cc != col { boardState.cand[row][cc][d] = false; boardState.candColor[row][cc][d] = 0 }
        for rr in 0..<9 where rr != row { boardState.cand[rr][col][d] = false; boardState.candColor[rr][col][d] = 0 }
        let br = (row/3)*3, bc = (col/3)*3
        for rr in br..<br+3 {
            for cc in bc..<bc+3 {
                if rr == row && cc == col { continue }
                boardState.cand[rr][cc][d] = false
                boardState.candColor[rr][cc][d] = 0
            }
        }
    }
    
    private func conflicts(row: Int, col: Int, value: Int) -> Bool {
        for cc in 0..<9 { if boardState.values[row][cc] == value { return true } }
        for rr in 0..<9 { if boardState.values[rr][col] == value { return true } }
        let br = (row/3)*3, bc = (col/3)*3
        for rr in br..<br+3 {
            for cc in bc..<bc+3 {
                if boardState.values[rr][cc] == value { return true }
            }
        }
        return false
    }
    
    // MARK: - Drawing
    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.fill(rect)
        
        let valueFont = UIFont.boldSystemFont(ofSize: cellSize * 0.6)
        let candFont = UIFont.systemFont(ofSize: cellSize * 0.22)
        
        for r in 0..<9 {
            for c in 0..<9 {
                let x0 = CGFloat(c) * cellSize
                let y0 = CGFloat(r) * cellSize
                
                if boardState.values[r][c] == 0 {
                    for k in 0..<9 where boardState.cand[r][c][k] {
                        if let color = CandColor(rawValue: Int(boardState.candColor[r][c][k]))?.uiColor {
                            let sr = k / 3, sc = k % 3
                            let rect = CGRect(x: x0 + CGFloat(sc) * (cellSize/3) + 2,
                                              y: y0 + CGFloat(sr) * (cellSize/3) + 2,
                                              width: cellSize/3 - 4,
                                              height: cellSize/3 - 4)
                            ctx.setFillColor(color.cgColor)
                            ctx.fill(rect)
                        }
                    }
                }
                
                if boardState.values[r][c] != 0 {
                    let v = boardState.values[r][c]
                    let text: NSString = "\(v)" as NSString
                    var color: UIColor
                    if boardState.given[r][c] {
                        color = .black
                    } else if showMistakes && v != sudoku.complete[r][c] {
                        color = UIColor(red: 200/255, green: 0, blue: 0, alpha: 1)
                    } else {
                        color = UIColor(red: 0, green: 70/255, blue: 200/255, alpha: 1)
                    }
                    let attrs: [NSAttributedString.Key: Any] = [.font: valueFont, .foregroundColor: color]
                    let size = text.size(withAttributes: attrs)
                    let tx = x0 + (cellSize - size.width)/2
                    let ty = y0 + (cellSize - size.height)/2
                    text.draw(at: CGPoint(x: tx, y: ty), withAttributes: attrs)
                } else {
                    for k in 0..<9 where boardState.cand[r][c][k] {
                        let sr = k / 3, sc = k % 3
                        let text: NSString = "\(k+1)" as NSString
                        let attrs: [NSAttributedString.Key: Any] = [.font: candFont, .foregroundColor: UIColor.darkGray]
                        let size = text.size(withAttributes: attrs)
                        let cx = x0 + CGFloat(sc) * (cellSize/3) + (cellSize/3 - size.width)/2
                        let cy = y0 + CGFloat(sr) * (cellSize/3) + (cellSize/3 - size.height)/2
                        text.draw(at: CGPoint(x: cx, y: cy), withAttributes: attrs)
                    }
                }
            }
        }
        
        for i in 0...9 {
            ctx.setStrokeColor((i % 3 == 0 ? UIColor.black : UIColor.lightGray).cgColor)
            ctx.setLineWidth(i % 3 == 0 ? 3 : 1)
            
            ctx.move(to: CGPoint(x: CGFloat(i)*cellSize, y: 0))
            ctx.addLine(to: CGPoint(x: CGFloat(i)*cellSize, y: gridSize))
            ctx.strokePath()
            
            ctx.move(to: CGPoint(x: 0, y: CGFloat(i)*cellSize))
            ctx.addLine(to: CGPoint(x: gridSize, y: CGFloat(i)*cellSize))
            ctx.strokePath()
        }
        
        ctx.setStrokeColor(UIColor.black.cgColor)
        ctx.setLineWidth(1)
        ctx.stroke(CGRect(x: 0, y: 0, width: gridSize, height: gridSize))
    }
    
    // MARK: - Public Methods
    func setAutoUpdate(_ enabled: Bool) { autoUpdate = enabled }
    func setShowMistakes(_ enabled: Bool) { showMistakes = enabled; setNeedsDisplay() }
    func setSingleColorCells(_ enabled: Bool) { singleColorCells = enabled; setNeedsDisplay() }
    func setSelectedColor(_ color: CandColor) { selectedColor = color; setNeedsDisplay() }
    func setMode(_ mode: InputMode) { inputMode = mode }
}
