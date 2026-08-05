import UIKit

public struct CoachmarkTarget {
    public let targetView: UIView
    public let title: CMText
    public let description: CMText
    public let shape: CoachmarkShape
    public let paddingDp: Int
    public let highlightStrokeColor: UIColor?
    public let highlightFillColor: UIColor?
    public let leftBarFillColor: UIColor?
    public let nextButtonMode: CMButtonMode?
    public let previousButtonMode: CMButtonMode?
    public let skipButtonMode: CMButtonMode?
    public let showAnimation: Bool?
    public let needBorder: Bool?
    public let leftBarShow: Bool?
    public let borders: [CMBorder]?
    public let needPadding: Bool?
    public let extraPadding: CGFloat?
    public let paddingBorder: CMPaddingBorder?
    public let popupDistance: CGFloat?
    public let titleAlignment: NSTextAlignment?
    public let descriptionAlignment: NSTextAlignment?
    public let showBottomButtonStack: Bool?
    public let iconRenderingMode: UIImage.RenderingMode?
    public let statusTextStyle: CMText?
    public let nextImage: UIImage?
    public let previousImage: UIImage?
    /// Optional fully-designed image for the previous button in its DISABLED (first step) state — e.g.
    /// Axis's grey "btn-prev" (fill + border + grey arrow baked in). When nil (default), the SDK keeps
    /// its original behaviour (fade the normal previous icon), so other hosts are unaffected.
    public let previousDisabledImage: UIImage?
    public let closeImage: UIImage?

    public init(targetView: UIView,
                title: CMText,
                description: CMText,
                shape: CoachmarkShape,
                paddingDp: Int,
                highlightStrokeColor: UIColor? = nil,
                highlightFillColor: UIColor? = nil,
                leftBarFillColor: UIColor? = nil,
                nextButtonMode: CMButtonMode? = nil,
                previousButtonMode: CMButtonMode? = nil,
                skipButtonMode: CMButtonMode? = nil,
                showAnimation: Bool? = nil,
                needBorder: Bool? = nil,
                leftBarShow: Bool? = nil,
                borders: [CMBorder]? = nil,
                needPadding: Bool? = nil,
                extraPadding: CGFloat? = nil,
                paddingBorder: CMPaddingBorder? = nil,
                popupDistance: CGFloat? = nil,
                titleAlignment: NSTextAlignment? = nil,
                descriptionAlignment: NSTextAlignment? = nil,
                showBottomButtonStack: Bool? = nil,
                iconRenderingMode: UIImage.RenderingMode? = nil,
                statusTextStyle: CMText? = nil,
                nextImage: UIImage? = nil,
                previousImage: UIImage? = nil,
                previousDisabledImage: UIImage? = nil,
                closeImage: UIImage? = nil) {
        self.targetView = targetView
        self.title = title
        self.description = description
        self.shape = shape
        self.paddingDp = paddingDp
        self.highlightStrokeColor = highlightStrokeColor
        self.highlightFillColor = highlightFillColor
        self.leftBarFillColor = leftBarFillColor
        self.nextButtonMode = nextButtonMode
        self.previousButtonMode = previousButtonMode
        self.skipButtonMode = skipButtonMode
        self.showAnimation = showAnimation
        self.needBorder = needBorder
        self.leftBarShow = leftBarShow
        self.borders = borders
        self.needPadding = needPadding
        self.extraPadding = extraPadding
        self.paddingBorder = paddingBorder
        self.popupDistance = popupDistance
        self.titleAlignment = titleAlignment
        self.descriptionAlignment = descriptionAlignment
        self.showBottomButtonStack = showBottomButtonStack
        self.iconRenderingMode = iconRenderingMode
        self.statusTextStyle = statusTextStyle
        self.nextImage = nextImage
        self.previousImage = previousImage
        self.previousDisabledImage = previousDisabledImage
        self.closeImage = closeImage
    }
}

public struct CMPaddingBorder {
    public let width: CGFloat
    public let color: UIColor
    public let cornerRadius: CGFloat
    public init(width: CGFloat, color: UIColor, cornerRadius: CGFloat) {
        self.width = width
        self.color = color
        self.cornerRadius = cornerRadius
    }
}

public struct CMBorder {
    public let width: CGFloat
    public let color: UIColor
    public let priority: Int
    public init(width: CGFloat, color: UIColor, priority: Int) {
        self.width = width
        self.color = color
        self.priority = priority
    }
}

enum CMAssets {
    static func image(_ name: String) -> UIImage? {
        #if SWIFT_PACKAGE
        return UIImage(named: name, in: .module, compatibleWith: nil)
        #else
        return UIImage(named: name)
        #endif
    }
}

public enum CMButtonMode {
    case image(tint: UIColor? = nil)
    case text(CMText)
}

public enum CoachmarkShape {
    case rect
    case circle
}

public struct CMText {
    public let text: String
    public let color: UIColor
    public let bgColor: UIColor
    public let font: UIFont

    public init(text: String, color: UIColor, bgColor: UIColor, font: UIFont) {
        self.text = text
        self.color = color
        self.bgColor = bgColor
        self.font = font
    }
}

extension UILabel {
    func configureLabel(color: UIColor, font: UIFont) {
        self.textColor = color
        self.font = font
        self.adjustsFontForContentSizeCategory = true
    }
}

extension UIButton {
    func applyText(_ cm: CMText) {
        setImage(nil, for: .normal)
        setTitle(cm.text, for: .normal)
        setTitleColor(cm.color, for: .normal)
        titleLabel?.font = cm.font
    }
    
    func applyImage(_ image: UIImage? = nil, named name: String, tint: UIColor?, renderingMode: UIImage.RenderingMode = .alwaysTemplate) {
        let base = image ?? CMAssets.image(name) ?? UIImage(named: name)
        let img = base?.withRenderingMode(renderingMode)
        setTitle("", for: .normal)
        setImage(img, for: .normal)
        if renderingMode == .alwaysTemplate, let tint = tint { self.tintColor = tint }
        backgroundColor = .clear
        contentEdgeInsets = .zero
        layer.cornerRadius = 0
        layer.borderWidth = 0
    }
}
