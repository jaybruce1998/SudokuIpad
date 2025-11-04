import UIKit

class DifficultyViewController: UIViewController {

    // Lazy-loaded puzzle sets
    private var seventeenGrids: [[[Int]]]?
    private var nightmareGrids: [[[Int]]]?
    
    private let importField = UITextField()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Select Difficulty"
        setupUI()
    }

    // MARK: - UI Setup
    private func setupUI() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])

        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Select Difficulty"
        titleLabel.font = .boldSystemFont(ofSize: 28)
        stack.addArrangedSubview(titleLabel)

        // Difficulty buttons
        let difficultyButtons = ["Easy", "Medium", "Hard", "Extreme", "17", "Nightmare"]
        let buttonGrid = UIStackView()
        buttonGrid.axis = .vertical
        buttonGrid.spacing = 10
        buttonGrid.alignment = .fill
        buttonGrid.distribution = .fillEqually
        stack.addArrangedSubview(buttonGrid)
        
        for i in 0..<difficultyButtons.count/2 {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 12
            rowStack.distribution = .fillEqually
            rowStack.alignment = .fill
            buttonGrid.addArrangedSubview(rowStack)
            rowStack.heightAnchor.constraint(equalToConstant: 50).isActive = true
            
            for j in 0..<2 {
                let index = i*2 + j
                guard index < difficultyButtons.count else { continue }
                let btn = UIButton(type: .system)
                btn.setTitle(difficultyButtons[index], for: .normal)
                btn.titleLabel?.font = .boldSystemFont(ofSize: 18)
                btn.backgroundColor = .systemBlue
                btn.setTitleColor(.white, for: .normal)
                btn.layer.cornerRadius = 8
                btn.tag = index
                btn.addTarget(self, action: #selector(difficultyTapped(_:)), for: .touchUpInside)
                rowStack.addArrangedSubview(btn)
            }
        }

        // Random button
        let randomButton = UIButton(type: .system)
        randomButton.setTitle("Random", for: .normal)
        randomButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        randomButton.backgroundColor = .systemGreen
        randomButton.setTitleColor(.white, for: .normal)
        randomButton.layer.cornerRadius = 8
        randomButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        //randomButton.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        randomButton.addTarget(self, action: #selector(randomTapped), for: .touchUpInside)
        stack.addArrangedSubview(randomButton)

        // Import field + button
        let importRow = UIStackView()
        importRow.axis = .horizontal
        importRow.spacing = 12
        importRow.distribution = .fill
        importRow.alignment = .fill
        importRow.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(importRow)
        
        importField.placeholder = "Paste 81-character puzzle"
        importField.borderStyle = .roundedRect
        importRow.addArrangedSubview(importField)
        
        let importBtn = UIButton(type: .system)
        importBtn.setTitle("Import", for: .normal)
        importBtn.addTarget(self, action: #selector(importTapped(_:)), for: .touchUpInside)
        importRow.addArrangedSubview(importBtn)
        importBtn.widthAnchor.constraint(equalToConstant: 80).isActive = true
    }

    // MARK: - Button Actions
    @objc private func difficultyTapped(_ sender: UIButton) {
        let title = sender.currentTitle ?? ""
        switch title {
        case "Easy", "Medium", "Hard", "Extreme":
            startSudoku(difficulty: title, preset: nil)
        case "17":
            if let grid = loadSeventeenRandom() {
                startSudoku(difficulty: "17", preset: grid)
            }
        case "Nightmare":
            if let grid = loadNightmareRandom() {
                startSudoku(difficulty: "Nightmare", preset: grid)
            }
        default:
            break
        }
    }

    @objc private func randomTapped() {
        let sudoku = Sudoku.randomPuzzle()
        let gameVC = GameViewController(sudoku: sudoku, difficulty: sudoku.difficulty())
        navigationController?.pushViewController(gameVC, animated: true)
    }

    @objc private func importTapped(_ sender: UIButton) {
        guard let text = importField.text, !text.isEmpty else {
            showAlert(title: "Import", message: "Please paste an 81-character puzzle string.")
            return
        }
        
        let sudoku = Sudoku(fromString: text)
        if sudoku.isValid() {
            let gameVC = GameViewController(sudoku: sudoku, difficulty: sudoku.difficulty())
            navigationController?.pushViewController(gameVC, animated: true)
        } else {
            showAlert(title: "Import", message: "Invalid puzzle string.")
        }
    }

    // MARK: - Helper
    private func startSudoku(difficulty: String, preset: [[Int]]?) {
        let diffInt: Int
                switch difficulty {
                    case "Easy": diffInt = 0
                    case "Medium": diffInt = 1
                    case "Hard": diffInt = 2
                    default: diffInt = 3
                }
        let sudoku = preset != nil ? Sudoku(fromGrid: preset!) : Sudoku(difficulty: diffInt)
        let gameVC = GameViewController(sudoku: sudoku, difficulty: difficulty)
        navigationController?.pushViewController(gameVC, animated: true)
    }

    // MARK: - Lazy-loading 17-clue set
    private func loadSeventeenRandom() -> [[Int]]? {
        if seventeenGrids == nil {
            do {
                let text = try String(contentsOfFile: Bundle.main.path(forResource: "17", ofType: "txt")!, encoding: .utf8)
                let lines = text.components(separatedBy: .newlines).filter { !$0.isEmpty }
                seventeenGrids = lines.map { line -> [[Int]] in
                    var grid = Array(repeating: Array(repeating: 0, count: 9), count: 9)
                    for r in 0..<9 {
                        for c in 0..<9 {
                            let index = line.index(line.startIndex, offsetBy: r*9+c)
                            let digit = Int(String(line[index])) ?? 0
                            grid[r][c] = digit
                        }
                    }
                    return grid
                }
            } catch {
                showAlert(title: "Error", message: "Failed to load 17.txt: \(error.localizedDescription)")
                return nil
            }
        }
        return seventeenGrids?.randomElement()
    }

    // MARK: - Lazy-loading Nightmare set
    private func loadNightmareRandom() -> [[Int]]? {
        if nightmareGrids == nil {
            do {
                let text = try String(contentsOfFile: Bundle.main.path(forResource: "nightmare", ofType: "txt")!, encoding: .utf8)
                let lines = text.components(separatedBy: .newlines).filter { !$0.isEmpty }
                nightmareGrids = lines.map { line -> [[Int]] in
                    var grid = Array(repeating: Array(repeating: 0, count: 9), count: 9)
                    for r in 0..<9 {
                        for c in 0..<9 {
                            let index = line.index(line.startIndex, offsetBy: r*9+c)
                            let digit = Int(String(line[index])) ?? 0
                            grid[r][c] = digit
                        }
                    }
                    return grid
                }
            } catch {
                showAlert(title: "Error", message: "Failed to load nightmare.txt: \(error.localizedDescription)")
                return nil
            }
        }
        return nightmareGrids?.randomElement()
    }

    // MARK: - Helper alert function
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

}
