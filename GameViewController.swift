import UIKit

class GameViewController: UIViewController {

    let sudoku: Sudoku
    let difficulty: String
    let boardState: BoardState
    let boardView: BoardView
    let controlPanel: ControlPanelView

    // Timer
    private var timer: Timer?
    private var secondsElapsed = 0

    // Labels for time and mistakes
    private let timerLabel = UILabel()
    private let mistakesLabel = UILabel()

    init(sudoku: Sudoku, difficulty: String) {
        self.sudoku = sudoku
        self.difficulty = difficulty
        self.boardState = BoardState.fromSudoku(sudoku)
        self.boardView = BoardView(frame: .zero, sudoku: sudoku, boardState: self.boardState)
        self.controlPanel = ControlPanelView(board: boardView)
        super.init(nibName: nil, bundle: nil)
        
        setupCallbacks()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setupLabels()
        setupLayout()
        startTimer()
    }

    private func setupLabels() {
        timerLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .medium)
        timerLabel.textAlignment = .left
        timerLabel.text = "00:00"
        
        mistakesLabel.font = UIFont.systemFont(ofSize: 18)
        mistakesLabel.textAlignment = .right
        mistakesLabel.text = "Mistakes: 0"
    }

    private func setupLayout() {
        boardView.translatesAutoresizingMaskIntoConstraints = false
        controlPanel.translatesAutoresizingMaskIntoConstraints = false
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        mistakesLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(boardView)
        view.addSubview(controlPanel)
        view.addSubview(timerLabel)
        view.addSubview(mistakesLabel)
        
        NSLayoutConstraint.activate([
            // Timer & mistakes at top
            timerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            timerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            mistakesLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            mistakesLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // BoardView: below labels, square, fills width
            boardView.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 8),
            boardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            boardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            boardView.heightAnchor.constraint(equalTo: boardView.widthAnchor), // ensures square cells

            // ControlPanel: directly below board
            controlPanel.topAnchor.constraint(equalTo: boardView.bottomAnchor, constant: 8),
            controlPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            controlPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            controlPanel.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            //controlPanel.heightAnchor.constraint(equalToConstant: 100) // fixed height
        ])
    }


    private func setupCallbacks() {
        controlPanel.onUndo = { [weak self] in
            self?.boardView.undo()
            self?.updateMistakes()
        }
        controlPanel.onResetCandidates = { [weak self] in
            self?.boardView.resetCandidates()
        }
        
        controlPanel.onResetColors = { [weak self] in
            self?.boardView.resetCandidateColors()
        }
        
        controlPanel.onExport = { [weak self] in
            self?.handleExport()
        }

        controlPanel.onSetMode = { [weak self] mode in self?.boardView.setMode(mode) }
        controlPanel.onSetAuto = { [weak self] auto in self?.boardView.setAutoUpdate(auto) }
        controlPanel.onSetShowMistakes = { [weak self] show in
            self?.boardView.setShowMistakes(show)
            self?.updateMistakes()
        }
        controlPanel.onSetSingleColorCells = { [weak self] single in
            self?.boardView.setSingleColorCells(single)
        }
        controlPanel.onSetColor = { [weak self] color in self?.boardView.setSelectedColor(color) }
        
        // Ensure mistakes update whenever the board changes
        boardView.onBoardChanged = { [weak self] in
            guard let self = self else { return }
            self.updateMistakes()
            
            // Check if the board is full and valid
            if self.boardView.isComplete() {  // You’ll need to implement isComplete()
                self.endGame()
            }
        }
    }
    
    private func endGame() {
        // Stop the timer
        timer?.invalidate()
        
        // Build the completion message
        let elapsedTime = formattedTime()
        let mistakes = boardView.mistakesCurrent
        let msg = "Completed in \(elapsedTime) with \(mistakes) mistakes."

        // Show UIAlertController
        let alert = UIAlertController(title: difficulty, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            // Return to previous screen (difficulty selection)
            self.navigationController?.popViewController(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.secondsElapsed += 1
            self.timerLabel.text = self.formattedTime()
        }
    }
    
    private func formattedTime() -> String {
        let m = secondsElapsed / 60
        let s = secondsElapsed % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func updateMistakes() {
        if boardView.showMistakes {
            mistakesLabel.text = "Mistakes: \(boardView.mistakesCurrent)"
        } else {
            mistakesLabel.text = ""
        }
    }

    @objc private func handleExport() {
        // Flatten the Sudoku grid into a single 81-character string
        let exportString = sudoku.values
            .flatMap { $0 }        // flatten 2D array
            .map(String.init)      // convert each Int to String
            .joined()              // concatenate all 81 digits
        
        // Create the system share sheet
        let activityVC = UIActivityViewController(activityItems: [exportString], applicationActivities: nil)
        
        // For iPads, set the popover anchor (important!)
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.maxY - 100, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        // Present the share sheet
        present(activityVC, animated: true)
    }

}
