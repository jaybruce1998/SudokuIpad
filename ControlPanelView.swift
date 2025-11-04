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

    // MARK: - Board Handling
    private weak var board: BoardView?

    // MARK: - Callbacks
    var onUndo: (() -> Void)?
    var onSetMode: ((InputMode) -> Void)?
    var onSetAuto: ((Bool) -> Void)?
    var onSetShowMistakes: ((Bool) -> Void)?
    var onSetSingleColorCells: ((Bool) -> Void)?
    var onSetColor: ((CandColor) -> Void)?
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
        
        // --- Switches row ---
        let switchesStack = UIStackView()
        switchesStack.axis = .horizontal
        switchesStack.spacing = 16
        switchesStack.alignment = .center
        switchesStack.distribution = .fill
        mainStack.addArrangedSubview(switchesStack)
        
        // Function to create switch+label, hugging tightly
        func makeSwitchItem(labelText: String, toggle: UISwitch) -> UIStackView {
            let stack = UIStackView()
            stack.axis = .horizontal
            stack.spacing = 4
            stack.alignment = .center
            stack.distribution = .fill
            let label = UILabel(text: labelText)
            label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            toggle.setContentHuggingPriority(.required, for: .horizontal)
            stack.addArrangedSubview(label)
            stack.addArrangedSubview(toggle)
            return stack
        }

        switchesStack.addArrangedSubview(makeSwitchItem(labelText: "Auto-update", toggle: autoSwitch))
        switchesStack.addArrangedSubview(makeSwitchItem(labelText: "Show mistakes", toggle: mistakesSwitch))
        switchesStack.addArrangedSubview(makeSwitchItem(labelText: "Single color", toggle: singleColorSwitch))
        
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
        
        // Candidate colors
        let colorsGrid = UIStackView()
        colorsGrid.axis = .horizontal
        colorsGrid.spacing = 4
        colorsGrid.distribution = .fillEqually
        mainStack.addArrangedSubview(colorsGrid)
        
        let colors: [(UIColor, CandColor)] = [
            (.red, .red),
            (.orange, .orange),
            (.yellow, .yellow),
            (.green, .green),
            (.blue, .blue),
            (.purple, .violet)
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
        
        undoButton.setTitle("Undo", for: .normal)
        undoButton.addTarget(self, action: #selector(undoTapped), for: .touchUpInside)

        resetCandidatesButton.setTitle("Reset candidates", for: .normal)
        resetCandidatesButton.addTarget(self, action: #selector(resetCandidatesTapped), for: .touchUpInside)

        resetColorsButton.setTitle("Reset colors", for: .normal)
        resetColorsButton.addTarget(self, action: #selector(resetColorsTapped), for: .touchUpInside)

        // Put all three in a horizontal stack
        let buttonRow = UIStackView(arrangedSubviews: [undoButton, resetCandidatesButton, resetColorsButton])
        buttonRow.axis = .horizontal
        buttonRow.distribution = .fillEqually
        buttonRow.alignment = .fill
        buttonRow.spacing = 8

        // Add that row to the main stack
        mainStack.addArrangedSubview(buttonRow)

        // Make the row stretch full width
        buttonRow.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            buttonRow.leadingAnchor.constraint(equalTo: mainStack.leadingAnchor),
            buttonRow.trailingAnchor.constraint(equalTo: mainStack.trailingAnchor)
        ])
        // --- Export button ---
        exportButton.setTitle("Export", for: .normal)
        exportButton.addTarget(self, action: #selector(exportTapped), for: .touchUpInside)
        mainStack.addArrangedSubview(exportButton)


    }
    
    // MARK: - Actions
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
        // Immediately update input mode for real, not just UI
        onSetMode?(.color)
        // Update segmented control color text to match selected color
        let attrs: [NSAttributedString.Key: Any] = [.foregroundColor: color.uiColor ?? UIColor.black]
        inputModeSegmented.setTitleTextAttributes(attrs, for: .normal)
        inputModeSegmented.selectedSegmentIndex = 2
    }
    
    @objc private func undoTapped() { onUndo?() }
    @objc private func resetCandidatesTapped() { onResetCandidates?() }
    @objc private func resetColorsTapped() { onResetColors?() }
    @objc private func exportTapped() { onExport?() }

}

// MARK: - Convenience UILabel initializer
private extension UILabel {
    convenience init(text: String) {
        self.init()
        self.text = text
    }
}
