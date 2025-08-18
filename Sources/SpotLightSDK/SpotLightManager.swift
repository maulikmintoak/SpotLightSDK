import UIKit

public protocol SpotLightListener: AnyObject {
    func onCoachmarkClosed()
    func onCoachmarkNextClicked(index: Int, isLastIndex: Bool)
    func onCoachmarkBackClicked(index: Int)
}

@MainActor
public final class SpotLightManager {
    private weak var activity: UIViewController?
    private weak var listener: SpotLightListener?

    private var window: UIWindow?
    private var overlayView: CoachmarkOverlayView?
    private var popupView: CoachmarkPopupView?

    private var currentIndex = 0
    private var targets: [CoachmarkTarget] = []
    private var isCoachmarkVisible = false
    
    private var isLastStep: Bool {
        return currentIndex == targets.count - 1
    }

    public init(activity: UIViewController, listener: SpotLightListener? = nil) {
        self.activity = activity
        self.listener = listener
    }

    public func showCoachmarks(targetList: [CoachmarkTarget]) {
        guard !targetList.isEmpty else { return }
        self.targets = targetList
        self.currentIndex = 0
        showCurrentTarget()
    }

    private func showCurrentTarget() {
        guard let activity = activity else { return }
        let currentTarget = targets[currentIndex]

        guard let scene = activity.view.window?.windowScene ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first(where: { $0.activationState == .foregroundActive }) else {
            return
        }
        
        let overlayWindow = UIWindow(windowScene: scene)
        overlayWindow.frame = scene.screen.bounds
        overlayWindow.windowLevel = .alert + 1
        overlayWindow.backgroundColor = .clear
        self.window = overlayWindow
        
        guard let window = self.window else { return }
        let containerView = UIView(frame: window.bounds)
        containerView.backgroundColor = .clear
        activity.view.layoutIfNeeded()

        // Overlay
        let overlay = CoachmarkOverlayView(target: currentTarget)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(overlay)
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: containerView.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            overlay.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
        self.overlayView = overlay

        // Popup
        let popup = CoachmarkPopupView()
        popup.translatesAutoresizingMaskIntoConstraints = true
        containerView.addSubview(popup)
        self.popupView = popup

        // Set content
        popup.showBottomButtonStack = currentTarget.showBottomButtonStack ?? true
        popup.titleLabel.text = currentTarget.title.text
        popup.hideTitleStack = currentTarget.title.text == ""
        popup.descriptionLabel.text = currentTarget.description.text
        popup.statusLabel.text = "\(currentIndex + 1) of \(targets.count)"
//        popup.previousButton.isHidden = isFirstTarget()
//        popup.nextButton.isHidden = isLastTarget()
        popup.previousButton.addTarget(self, action: #selector(previousTapped), for: .touchUpInside)
        popup.nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        popup.skipButton.addTarget(self, action: #selector(closeWindow), for: .touchUpInside)
        
        popup.titleLabel.configureLabel(color: currentTarget.title.color, font: currentTarget.title.font)
        popup.descriptionLabel.configureLabel(color: currentTarget.description.color, font: currentTarget.description.font)
        
        
        self.updateButtonStates(popup: popup)

        // Window setup
        window.addSubview(containerView)
        window.makeKeyAndVisible()
        isCoachmarkVisible = true

        DispatchQueue.main.async {
            self.adjustPopupPosition()
        }
    }

    private func adjustPopupPosition() {
        guard let popup = popupView, let parent = popup.superview else { return }

        let targetView = targets[currentIndex].targetView
        let rect = targetView.convert(targetView.bounds, to: parent)

        popup.sizeToFit()
        popup.layoutIfNeeded()

        let popupWidth = UIScreen.main.bounds.width - 40
        let maxHeight = UIScreen.main.bounds.height * 0.5
        let estimatedHeight = popup.systemLayoutSizeFitting(
            CGSize(width: popupWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        popup.frame = CGRect(
            x: 20,
            y: 0,
            width: popupWidth,
            height: min(maxHeight, estimatedHeight)
        )

        let target = targets[currentIndex]
        let spacing: CGFloat = target.popupDistance ?? 16
        let out = effectiveHighlightOutset(for: target)
        let expandedMinY = rect.minY - out
        let expandedMaxY = rect.maxY + out
        let spaceAbove = expandedMinY - spacing
        let spaceBelow = UIScreen.main.bounds.height - expandedMaxY - spacing

        if spaceBelow >= popup.frame.height {
            // Show below
            popup.frame.origin.y = expandedMaxY + spacing
        } else if spaceAbove >= popup.frame.height {
            // Show above
            popup.frame.origin.y = expandedMinY - popup.frame.height - spacing
        } else {
            // Center if space insufficient
            popup.frame.origin.y = (UIScreen.main.bounds.height - popup.frame.height) / 2
        }
    }

    private func isFirstTarget() -> Bool {
        return currentIndex == 0
    }

    private func isLastTarget() -> Bool {
        return currentIndex == targets.count - 1
    }

    @objc private func nextTapped() {
        if isLastStep {
            listener?.onCoachmarkNextClicked(index: self.currentIndex, isLastIndex: true)
            self.closeWindow()
        } else {
            currentIndex += 1
            listener?.onCoachmarkNextClicked(index: self.currentIndex, isLastIndex: false)
            guard currentIndex < targets.count else { return }
            overlayView?.updateTarget(targets[currentIndex])
            updateUI()
        }
    }

    @objc private func previousTapped() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        listener?.onCoachmarkBackClicked(index: self.currentIndex)
        overlayView?.updateTarget(targets[currentIndex])
        updateUI()
    }

    private func updateUI() {
        guard let popup = popupView else { return }

        let currentTarget = targets[currentIndex]
        popup.showBottomButtonStack = currentTarget.showBottomButtonStack ?? true
        popup.titleLabel.text = currentTarget.title.text
        popup.hideTitleStack = currentTarget.title.text == ""
        popup.descriptionLabel.text = currentTarget.description.text
        popup.statusLabel.text = "\(currentIndex + 1) of \(targets.count)"
        popup.titleLabel.configureLabel(color: currentTarget.title.color, font: currentTarget.title.font)
        popup.titleLabel.textAlignment = currentTarget.titleAlignment ?? .left
        
        popup.descriptionLabel.configureLabel(color: currentTarget.description.color, font: currentTarget.description.font)
        popup.descriptionLabel.textAlignment = currentTarget.descriptionAlignment ?? .left
        
        self.updateButtonStates(popup: popup)
        
        adjustPopupPosition()
    }
    
    private func effectiveHighlightOutset(for t: CoachmarkTarget) -> CGFloat {
        let basePadding = CGFloat(t.paddingDp)

        let extra = (t.needPadding ?? false) ? max(0, t.extraPadding ?? 0) : 0
        let paddingBorderWidth = (t.needPadding ?? false) ? (t.paddingBorder?.width ?? 0) : 0

        let multiBorders = (t.needBorder ?? false) ? (t.borders?.reduce(0) { $0 + $1.width } ?? 0) : 0

        let strokeWidth: CGFloat = 4.0 // keep in sync with overlay's strokeLayer.lineWidth

        return basePadding + extra + paddingBorderWidth + multiBorders + strokeWidth / 2
    }
    
    private func updateButtonStates(popup: CoachmarkPopupView) {
        let target = targets[currentIndex]

        let prevMode = target.previousButtonMode ?? .image()
        switch prevMode {
        case .image(let tint): popup.previousButton.applyImage(named: "previous_icon", tint: tint)
        case .text(let t):     popup.previousButton.applyText(t)
        }

        let defaultNext: CMButtonMode = isLastTarget()
            ? .text(CMText(text: "Done", color: .white, font: .systemFont(ofSize: 12, weight: .semibold)))
            : .image()
        let nextMode = target.nextButtonMode ?? defaultNext
        switch nextMode {
        case .image(let tint):
            popup.nextButton.applyImage(named: "next_icon", tint: tint)
        case .text(let t):
            popup.nextButton.applyText(t)
            if isLastTarget() {
                popup.nextButton.backgroundColor = .systemBlue
                popup.nextButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
                popup.nextButton.layer.cornerRadius = 4.0
                popup.nextButton.layer.borderWidth = 0
            }
        }

        let skipMode = target.skipButtonMode ?? .image()
        switch skipMode {
        case .image(let tint): popup.skipButton.applyImage(named: "close_icon", tint: .black)
        case .text(let t):     popup.skipButton.applyText(t)
        }

        popup.previousButton.isEnabled = currentIndex > 0
        popup.previousButton.alpha = popup.previousButton.isEnabled ? 1.0 : 0.5
    }

    @objc private func closeWindow() {
        if !isCoachmarkVisible { return }
        window?.isHidden = true
        window = nil
        overlayView = nil
        popupView = nil
        isCoachmarkVisible = false
        listener?.onCoachmarkClosed()
    }
}
