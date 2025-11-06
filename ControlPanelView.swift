import UIKit

class ControlPanelView: UIView {
    
    private let autoSwitch = UISwitch()
    private let mistakesSwitch = UISwitch()
    private let singleColorSwitch = UISwitch()
    
    private let undoButton = UIButton(type: .system)
    private let resetCandidatesButton = UIButton(type: .system)
    private let resetColorsButton = UIButton(type: .system)
    private let exportButton = UIButton(type: .system)
    
    private let inputModeSegmented = UISegmentedControl(items: ["Value", "Toggle", "Color"])
    
    private var colorButtons: [UIButton] = []
    private var numberButtons: [UIButton] = []
    private var selectedNumber: Int? = nil

    
    // MARK: - Board Handling
    private weak var board: BoardView?
    
    // MARK: - Callbacks
    var onUndo: (() -> Void)?
    var onSetMode: ((InputMode) -> Void)?
    var onSetAuto: ((Bool) -> Void)?
    var onSetShowMistakes: ((Bool) -> Void)?
    var onSetSingleColorCells: ((Bool) -> Void)?
    var onSetColor: ((CandColor) -> Void)?
    var onSetNumber: ((Int) -> Void)?
    var onResetCandidates: (() -> Void)?
    var onResetColors: (() -> Void)?
    var onExport: (() -> Void)?
    
    // MARK: - Init
    init(board: BoardView) {
        self.board = board
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.spacing = 8
        mainStack.alignment = .leading
        mainStack.distribution = .fill
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            mainStack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -8)
        ])
        
        // --- Number row (1–9) ---
        let numberRow = UIStackView()
        numberRow.axis = .horizontal
        numberRow.spacing = 4
        numberRow.distribution = .fillEqually
        mainStack.addArrangedSubview(numberRow)
        
        for n in 1...9 {
            let btn = UIButton(type: .system)
            btn.setTitle("\(n)", for: .normal)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
            btn.layer.cornerRadius = 6
            btn.layer.borderColor = UIColor.systemGray3.cgColor
            btn.layer.borderWidth = 1
            btn.heightAnchor.constraint(equalToConstant: 36).isActive = true
            btn.tag = n
            btn.addTarget(self, action: #selector(numberTapped(_:)), for: .touchUpInside)
            numberRow.addArrangedSubview(btn)
            numberButtons.append(btn)
        }
        
        // --- Switches row 1: Auto + Mistakes ---
        let switchesRow1 = UIStackView()
        switchesRow1.axis = .horizontal
        switchesRow1.spacing = 16
        switchesRow1.alignment = .center
        mainStack.addArrangedSubview(switchesRow1)
        
        func makeSwitchItem(labelText: String, toggle: UISwitch) -> UIStackView {
            let stack = UIStackView()
            stack.axis = .horizontal
            stack.spacing = 4
            stack.alignment = .center
            let label = UILabel(text: labelText)
            stack.addArrangedSubview(label)
            stack.addArrangedSubview(toggle)
            return stack
        }
        
        switchesRow1.addArrangedSubview(makeSwitchItem(labelText: "Auto-update", toggle: autoSwitch))
        switchesRow1.addArrangedSubview(makeSwitchItem(labelText: "Show mistakes", toggle: mistakesSwitch))
        
        // --- Switch row 2: Single color ---
        let switchesRow2 = UIStackView()
        switchesRow2.axis = .horizontal
        switchesRow2.spacing = 16
        switchesRow2.alignment = .center
        switchesRow2.addArrangedSubview(makeSwitchItem(labelText: "Single color", toggle: singleColorSwitch))
        mainStack.addArrangedSubview(switchesRow2)
        
        // Switch initial setup
        autoSwitch.isOn = true
        autoSwitch.addTarget(self, action: #selector(autoChanged(_:)), for: .valueChanged)
        mistakesSwitch.isOn = true
        mistakesSwitch.addTarget(self, action: #selector(showMistakesChanged(_:)), for: .valueChanged)
        singleColorSwitch.isOn = true
        singleColorSwitch.addTarget(self, action: #selector(singleColorChanged(_:)), for: .valueChanged)
        
        // --- Input mode ---
        mainStack.addArrangedSubview(UILabel(text: "Input Mode:"))
        inputModeSegmented.selectedSegmentIndex = 0
        inputModeSegmented.addTarget(self, action: #selector(inputModeChanged(_:)), for: .valueChanged)
        mainStack.addArrangedSubview(inputModeSegmented)
        
        // --- Candidate colors ---
        let colorsGrid = UIStackView()
        colorsGrid.axis = .horizontal
        colorsGrid.spacing = 4
        colorsGrid.distribution = .fillEqually
        mainStack.addArrangedSubview(colorsGrid)
        
        let colors: [(UIColor, CandColor)] = [
            (.red, .red), (.orange, .orange), (.yellow, .yellow),
            (.green, .green), (.blue, .blue), (.purple, .violet)
        ]
        
        for (uiColor, candColor) in colors {
            let btn = UIButton(type: .system)
            btn.backgroundColor = uiColor
            btn.layer.cornerRadius = 4
            btn.heightAnchor.constraint(equalToConstant: 32).isActive = true
            btn.addTarget(self, action: #selector(colorTapped(_:)), for: .touchUpInside)
            btn.tag = candColor.rawValue
            colorButtons.append(btn)
            colorsGrid.addArrangedSubview(btn)
        }
        
        // --- Buttons row: Undo + Reset Candidates ---
        undoButton.setTitle("Undo", for: .normal)
        undoButton.addTarget(self, action: #selector(undoTapped), for: .touchUpInside)
        
        resetCandidatesButton.setTitle("Reset candidates", for: .normal)
        resetCandidatesButton.addTarget(self, action: #selector(resetCandidatesTapped), for: .touchUpInside)
        
        let buttonRow = UIStackView(arrangedSubviews: [undoButton, resetCandidatesButton])
        buttonRow.axis = .horizontal
        buttonRow.distribution = .fillEqually
        buttonRow.alignment = .fill
        buttonRow.spacing = 8
        mainStack.addArrangedSubview(buttonRow)
        
        // --- Export + Reset Colors row ---
        exportButton.setTitle("Export", for: .normal)
        exportButton.addTarget(self, action: #selector(exportTapped), for: .touchUpInside)
        
        resetColorsButton.setTitle("Reset colors", for: .normal)
        resetColorsButton.addTarget(self, action: #selector(resetColorsTapped), for: .touchUpInside)
        
        let exportRow = UIStackView(arrangedSubviews: [exportButton, resetColorsButton])
        exportRow.axis = .horizontal
        exportRow.distribution = .fillEqually
        exportRow.spacing = 8
        mainStack.addArrangedSubview(exportRow)
    }
    
    private func updateNumberButtonHighlight() {
        for btn in numberButtons {
            if btn.tag == selectedNumber {
                btn.backgroundColor = .systemBlue
                btn.setTitleColor(.white, for: .normal)
            } else {
                btn.backgroundColor = .clear
                btn.setTitleColor(.label, for: .normal)
            }
        }
    }

    // MARK: - Actions
    @objc private func numberTapped(_ sender: UIButton) {
        let number = sender.tag
        selectedNumber = number
        updateNumberButtonHighlight()
        onSetNumber?(number)
    }

    @objc private func autoChanged(_ sender: UISwitch) { onSetAuto?(sender.isOn) }
    @objc private func showMistakesChanged(_ sender: UISwitch) { onSetShowMistakes?(sender.isOn) }
    @objc private func singleColorChanged(_ sender: UISwitch) { onSetSingleColorCells?(sender.isOn) }
    
    @objc private func inputModeChanged(_ sender: UISegmentedControl) {
        let mode: InputMode = {
            switch sender.selectedSegmentIndex {
            case 0: return .value
            case 1: return .toggle
            case 2: return .color
            default: return .value
            }
        }()
        onSetMode?(mode)
    }
    
    @objc private func colorTapped(_ sender: UIButton) {
        guard let color = CandColor(rawValue: sender.tag) else { return }
        onSetColor?(color)
        onSetMode?(.color)
        let attrs: [NSAttributedString.Key: Any] = [.foregroundColor: color.uiColor ?? UIColor.black]
        inputModeSegmented.setTitleTextAttributes(attrs, for: .normal)
        inputModeSegmented.selectedSegmentIndex = 2
    }
    
    @objc private func undoTapped() { onUndo?() }
    @objc private func resetCandidatesTapped() { onResetCandidates?() }
    @objc private func resetColorsTapped() { onResetColors?() }
    @objc private func exportTapped() { onExport?() }

}

// MARK: - UILabel convenience
private extension UILabel {
    convenience init(text: String) {
        self.init()
        self.text = text
    }
}
