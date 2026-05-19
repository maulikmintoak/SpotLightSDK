import UIKit

@MainActor
final class CoachmarkOverlayView: UIView {

    private var target: CoachmarkTarget
    private let dimColor = UIColor.black.withAlphaComponent(0.7)
    private let strokeLayer = CAShapeLayer()
    private var padding: CGFloat { CGFloat(target.paddingDp) }
    private var shape: CoachmarkShape { target.shape }

    init(target: CoachmarkTarget) {
        self.target = target
//        self.padding = CGFloat(target.paddingDp)
//        self.shape = target.shape
        super.init(frame: UIScreen.main.bounds)
        backgroundColor = .clear
        isUserInteractionEnabled = true
        setupStrokeLayer()
        if target.showAnimation ?? true {
            startBreathingAnimation()
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func updateTarget(_ newTarget: CoachmarkTarget) {
        self.target = newTarget
        self.setNeedsDisplay()
        setupStrokeLayer()
        strokeLayer.removeAllAnimations()
        if newTarget.showAnimation ?? true {
            startBreathingAnimation()
        }
    }

    private func setupStrokeLayer() {
        strokeLayer.removeFromSuperlayer()
        self.layer.sublayers?.removeAll()

        let dimLayer = CALayer()
        dimLayer.frame = bounds
        dimLayer.backgroundColor = dimColor.cgColor

        let maskLayer = CAShapeLayer()
        maskLayer.frame = bounds
        let path = UIBezierPath(rect: bounds)

        if let holePath = getHolePath() {
            path.append(holePath)
        }

        maskLayer.path = path.cgPath
        maskLayer.fillRule = .evenOdd
        dimLayer.mask = maskLayer
        self.layer.addSublayer(dimLayer)
        
        addBorderLayers()

        strokeLayer.fillColor = (target.highlightFillColor ?? UIColor.clear).cgColor
        strokeLayer.strokeColor = (target.highlightStrokeColor ?? UIColor.darkGray).cgColor
        strokeLayer.lineWidth = 2.0
        strokeLayer.path = getHolePath()?.cgPath
        strokeLayer.opacity = 1.0
        self.layer.addSublayer(strokeLayer)
    }
    
    private func borderPath(outwardOffset: CGFloat, cornerRadiusOverride: CGFloat? = nil) -> UIBezierPath? {
        guard target.targetView.superview != nil else { return nil }
        let targetFrame = target.targetView.convert(target.targetView.bounds, to: self)
        let padded = targetFrame.insetBy(dx: -padding, dy: -padding)
        switch target.shape {
        case .rect:
            let expanded = padded.insetBy(dx: -outwardOffset, dy: -outwardOffset)
            let r = cornerRadiusOverride ?? 10
            return UIBezierPath(roundedRect: expanded, cornerRadius: r)
        case .circle:
            let center = CGPoint(x: padded.midX, y: padded.midY)
            let baseRadius = max(padded.width, padded.height) / 2
            let radius = baseRadius + outwardOffset
            return UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        }
    }
    
    private func addPaddingBorderIfNeeded() -> CGFloat {
        guard target.needPadding ?? false,
              let border = target.paddingBorder else { return 0 }

        let extra = max(0, target.extraPadding ?? 0)         // additional gap beyond paddingDp
        let offset = extra + border.width / 2                 // align ring’s inner edge after gap

        let cornerOverride: CGFloat? = (target.shape == .rect) ? border.cornerRadius : nil
        guard let p = borderPath(outwardOffset: offset, cornerRadiusOverride: cornerOverride) else { return 0 }

        let ring = CAShapeLayer()
        ring.fillColor = UIColor.clear.cgColor
        ring.strokeColor = border.color.cgColor
        ring.lineWidth = border.width
        ring.path = p.cgPath
        ring.opacity = 1.0
        self.layer.addSublayer(ring)

        return extra + border.width
    }
    
    private func addBorderLayers() {
        guard target.needBorder ?? false,
              let specs = target.borders,
              !specs.isEmpty else { return }
        let ordered = specs.sorted { $0.priority < $1.priority }
        // Start after optional padding border (Req 3)
        var accumulated: CGFloat = addPaddingBorderIfNeeded()
        for spec in ordered {
            let innerAlignedOffset = accumulated + spec.width / 2
            guard let p = borderPath(outwardOffset: innerAlignedOffset) else { continue }
            let ring = CAShapeLayer()
            ring.fillColor = UIColor.clear.cgColor
            ring.strokeColor = spec.color.cgColor
            ring.lineWidth = spec.width
            ring.path = p.cgPath
            ring.opacity = 1.0
            self.layer.addSublayer(ring)
            accumulated += spec.width
        }
    }

    private func getHolePath() -> UIBezierPath? {
        guard target.targetView.superview != nil else { return nil }
        let targetFrame = target.targetView.convert(target.targetView.bounds, to: self)
        let paddedFrame = targetFrame.insetBy(dx: -padding, dy: -padding)

        switch target.shape {
        case .rect:
            return UIBezierPath(roundedRect: paddedFrame, cornerRadius: 10)
        case .circle:
            let center = CGPoint(x: paddedFrame.midX, y: paddedFrame.midY)
            let radius = max(paddedFrame.width, paddedFrame.height) / 2
            return UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        }
    }

    private func startBreathingAnimation1() {
        let breathAnim = CABasicAnimation(keyPath: "transform.scale")
        breathAnim.fromValue = 1.0
        breathAnim.toValue = 1.1
        breathAnim.duration = 1.0
        breathAnim.repeatCount = .infinity
        breathAnim.autoreverses = true
        breathAnim.timingFunction = CAMediaTimingFunction(name: .linear)
        strokeLayer.add(breathAnim, forKey: "breath")
    }
    private func startBreathingAnimation() {
        // Opacity animation
        let opacityAnim = CABasicAnimation(keyPath: "opacity")
        opacityAnim.fromValue = 0.4
        opacityAnim.toValue = 1.0
        opacityAnim.duration = 0.6
        opacityAnim.autoreverses = true
        opacityAnim.repeatCount = .infinity
        opacityAnim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        strokeLayer.add(opacityAnim, forKey: "breathOpacity")

        // Optional: Line width pulse (comment out if not needed)
        let widthAnim = CABasicAnimation(keyPath: "lineWidth")
        widthAnim.fromValue = 2.0
        widthAnim.toValue = 4.0
        widthAnim.duration = 0.6
        widthAnim.autoreverses = true
        widthAnim.repeatCount = .infinity
        widthAnim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        strokeLayer.add(widthAnim, forKey: "breathWidth")
    }


    override func removeFromSuperview() {
        super.removeFromSuperview()
        strokeLayer.removeAllAnimations()
    }

    func isPointInHole(_ point: CGPoint) -> Bool {
        return getHolePath()?.contains(point) ?? false
    }
}

