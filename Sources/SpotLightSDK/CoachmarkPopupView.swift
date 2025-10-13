// MARK: - CoachmarkPopupView.swift

import UIKit

@MainActor
final class CoachmarkPopupView: UIView {

    let titleLabel = UILabel()
    let leftBar = UIView()
    let descriptionLabel = UILabel()
    let statusLabel = UILabel()
    let nextButton = UIButton(type: .custom)
    let previousButton = UIButton(type: .custom)
    let skipButton = UIButton(type: .custom)
    var showBottomButtonStack: Bool = true {
        didSet {
            buttonRow.isHidden = !showBottomButtonStack
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
    
    var hideTitleStack: Bool = true {
        didSet {
            titleLabel.isHidden = hideTitleStack
            titleMinHeightC.isActive = !hideTitleStack
            contentTopConstraint.constant = 16
            contentTrailingConstraint.constant = -10
            
            // ensure the header row aligns skip with the current top label
            headerRow.alignment = .fill
            
            // collapse any hidden arranged view gaps
            textStack.setNeedsLayout()
            
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
    

    private var buttonRow: UIStackView!
    private var contentStack: UIStackView!
    private var headerRow: UIStackView!
    private var textStack: UIStackView!
    private var skipWrapper: UIView!
    private var contentTopConstraint: NSLayoutConstraint!
    private var contentTrailingConstraint: NSLayoutConstraint!
    private var titleMinHeightC: NSLayoutConstraint!
    private var descMinHeightC: NSLayoutConstraint!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = .white
        layer.cornerRadius = 10

        leftBar.layer.cornerRadius = 6
        leftBar.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner] // top-right & bottom-right
        leftBar.clipsToBounds = true
        leftBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(leftBar)

        NSLayoutConstraint.activate([
            leftBar.widthAnchor.constraint(equalToConstant: 6),
            leftBar.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            leftBar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            leftBar.leadingAnchor.constraint(equalTo: leadingAnchor)
        ])
        
        // Labels
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .left

        descriptionLabel.font = .systemFont(ofSize: 15)
        descriptionLabel.textColor = .darkGray
        descriptionLabel.numberOfLines = 5
        descriptionLabel.textAlignment = .left
        descriptionLabel.lineBreakMode = .byTruncatingTail

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false

        // Minimum heights: 24pt
        titleMinHeightC = titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 24)
        descMinHeightC  = descriptionLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 24)
        titleMinHeightC.isActive = true
        descMinHeightC.isActive  = true

        // Optional: make labels expand and avoid truncation weirdness
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        descriptionLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        descriptionLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        
        statusLabel.font = .systemFont(ofSize: 13)
        statusLabel.textColor = .gray
        statusLabel.textAlignment = .center

        // Default icons (keep your existing loading; adjust if using SPM bundle)
        nextButton.setImage(UIImage(named: "next_icon"), for: .normal)
        previousButton.setImage(UIImage(named: "previous_icon"), for: .normal)
        skipButton.setImage(UIImage(named: "close_icon"), for: .normal)
        nextButton.titleLabel?.font = UIFont.systemFont(ofSize: 12.0)

        nextButton.translatesAutoresizingMaskIntoConstraints = false
        previousButton.translatesAutoresizingMaskIntoConstraints = false
        
        // --- Bottom row ---
        buttonRow = UIStackView(arrangedSubviews: [previousButton, statusLabel, nextButton])
        buttonRow.axis = .horizontal
        buttonRow.spacing = 20
        buttonRow.alignment = .center
        buttonRow.distribution = .equalSpacing
        buttonRow.translatesAutoresizingMaskIntoConstraints = false
        buttonRow.isHidden = !showBottomButtonStack

        // --- Text stack (title + description) ---
        textStack = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        textStack.axis = .vertical
        textStack.spacing = 0
        textStack.alignment = .fill
        textStack.distribution = .fill
        textStack.translatesAutoresizingMaskIntoConstraints = false

        // --- Skip wrapper column (fixed 24pt) with skip button pinned top-trailing ---
        skipWrapper = UIView()
        skipWrapper.translatesAutoresizingMaskIntoConstraints = false
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        skipWrapper.addSubview(skipButton)
        skipWrapper.backgroundColor = .clear
        
        NSLayoutConstraint.activate([
            skipWrapper.widthAnchor.constraint(equalToConstant: 24),
            skipWrapper.heightAnchor.constraint(greaterThanOrEqualTo: skipButton.heightAnchor),
            skipButton.widthAnchor.constraint(equalToConstant: 24),
            skipButton.heightAnchor.constraint(equalToConstant: 24),
            skipButton.topAnchor.constraint(equalTo: skipWrapper.topAnchor),
            skipButton.trailingAnchor.constraint(equalTo: skipWrapper.trailingAnchor)
        ])
        // Keep the skip column tight
        skipWrapper.setContentHuggingPriority(.required, for: .horizontal)
        skipWrapper.setContentCompressionResistancePriority(.required, for: .horizontal)
        skipWrapper.setContentHuggingPriority(.required, for: .vertical)
        skipWrapper.setContentCompressionResistancePriority(.required, for: .vertical)

        // --- Header row: [ TextStack | SkipWrapper(24) ] ---
        headerRow = UIStackView(arrangedSubviews: [textStack, skipWrapper])
        headerRow.axis = .horizontal
        headerRow.alignment = .fill
        headerRow.distribution = .fill
        headerRow.spacing = 12
        headerRow.translatesAutoresizingMaskIntoConstraints = false

        // --- Root (vertical) stack: headerRow then buttonRow ---
        contentStack = UIStackView(arrangedSubviews: [headerRow, buttonRow])
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.distribution = .fill
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(contentStack)
        
        contentTopConstraint = contentStack.topAnchor.constraint(equalTo: topAnchor, constant: 16)
        contentTrailingConstraint = contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10)

        NSLayoutConstraint.activate([
            nextButton.heightAnchor.constraint(equalToConstant: 32),
            previousButton.heightAnchor.constraint(equalToConstant: 32),
            contentTopConstraint,
            contentStack.leadingAnchor.constraint(equalTo: leftBar.trailingAnchor, constant: 16),
            contentTrailingConstraint,
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }
    
}
