# SpotLightSDK
SpotLightSDK
A lightweight, customizable iOS coachmark/onboarding overlay for highlighting UI elements and guiding users step-by-step.

## Features

- Highlight any `UIView` (rect or circle) with a dimmed background
- Optional breathing **animation** around the highlight
- Per-step **stroke/fill** colors
- **Layered borders** (multiple rings with width/color/priority)
- Extra **padding** gap + a **padding border** (with corner radius)
- Configurable **popup distance** from the highlight
- Popup top-right **Skip**, with optional bottom button row
- Mandatory **fonts & colors** for title/description (strong typing)
- Per-step button modes: **text** (font/color) or **image** (with tint)
- Title/description **alignment** (default `.left`)
- Safe overlay window handling, iOS 13+

---

## Requirements

- iOS 13+
- Swift 5.9+
- Xcode 15+ recommended

---

## Installation (Swift Package Manager)

1. Xcode → **File → Add Packages…**
2. Enter your repo URL, e.g.  
   `https://github.com/maulikmintoak/SpotLightSDK`
3. Choose a version (e.g. **Up to Next Major** from `0.1.0`)
4. Add the product **SpotLightSDK** to your app target.

> **Assets:** The package includes `next_icon`, `previous_icon`, and `close_icon` in `Sources/SpotLightSDK/Resources/Images.xcassets`.
> If you change asset names, update your loading code accordingly.

---

## Quick Start

```swift
import UIKit
import SpotLightSDK

final class MyViewController: UIViewController, SpotLightListener {
    private var coach: SpotLightManager?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startCoachmarks()
    }

    func startCoachmarks() {
        // Step 1
        let step1 = CoachmarkTarget(
            targetView: primaryButton,
            title: CMText(text: "Start here",
                          color: .label,
                          font: .preferredFont(forTextStyle: .headline)),
            description: CMText(text: "Tap this to perform the main action.",
                                color: .secondaryLabel,
                                font: .systemFont(ofSize: 12, weight: .semibold)),
            shape: .rect,
            paddingDp: 10,
            highlightStrokeColor: .systemPink,
            showAnimation: true,            // default true; explicit here for clarity
            popupDistance: 16,              // default 16 if nil
            nextButtonMode: .image(tint: .systemPink),
            previousButtonMode: .image(tint: .tertiaryLabel),
            skipButtonMode: .image(tint: .tertiaryLabel),
            showBottomButtonStack: true     // default true
        )

        // Step 2 with extra padding + borders
        let step2 = CoachmarkTarget(
            targetView: secondaryView,
            title: CMText(text: "Do this next",
                          color: .label,
                          font: .preferredFont(forTextStyle: .headline)),
            description: CMText(text: "Follow this step to continue.",
                                color: .secondaryLabel,
                                font: .preferredFont(forTextStyle: .body)),
            shape: .circle,
            paddingDp: 8,
            highlightStrokeColor: .systemPink,
            showAnimation: false,           // disable breathing
            popupDistance: 20,
            titleAlignment: .left,
            descriptionAlignment: .left,
            needPadding: true,
            extraPadding: 6,
            paddingBorder: CMPaddingBorder(width: 3, color: .systemYellow, cornerRadius: 14),
            needBorder: true,
            borders: [
                CMBorder(width: 2, color: .white,      priority: 0),
                CMBorder(width: 3, color: .black,      priority: 1),
                CMBorder(width: 4, color: .systemPink, priority: 2)
            ],
            showBottomButtonStack: false
        )

        coach = SpotLightManager(activity: self, listener: self)
        coach?.showCoachmarks(targetList: [step1, step2])
    }

    // MARK: - SpotLightListener
    func onCoachmarkClosed() { }
    func onCoachmarkNextClicked(index: Int, isLastIndex: Bool) { }
    func onCoachmarkBackClicked(index: Int) { }
}
```

---

## API

### SpotLightManager
```swift
public final class SpotLightManager {
    public init(activity: UIViewController, listener: SpotLightListener? = nil)
    public func showCoachmarks(targetList: [CoachmarkTarget])
}
```

### SpotLightListener
```swift
public protocol SpotLightListener: AnyObject {
    func onCoachmarkClosed()
    func onCoachmarkNextClicked(index: Int, isLastIndex: Bool)
    func onCoachmarkBackClicked(index: Int)
}
```

### CoachmarkTarget (per step)
```swift
public struct CoachmarkTarget {
    public let targetView: UIView
    public let title: CMText                      // required: text + color + font
    public let description: CMText                // required: text + color + font
    public let shape: CoachmarkShape              // .rect or .circle
    public let paddingDp: Int                     // base padding around target

    // Overlay
    public let highlightStrokeColor: UIColor?     // breathing stroke color
    public let highlightFillColor: UIColor?

    // Animation
    public let showAnimation: Bool?               // default true

    // Borders (outer rings)
    public let needBorder: Bool?
    public let borders: [CMBorder]?               // width/color/priority (asc = inner→outer)

    // Extra padding + padding border
    public let needPadding: Bool?
    public let extraPadding: CGFloat?             // extra gap beyond paddingDp
    public let paddingBorder: CMPaddingBorder?    // one ring after extraPadding

    // Popup placement & text alignment
    public let popupDistance: CGFloat?            // gap to popup (default 16)
    public let titleAlignment: NSTextAlignment?   // default .left
    public let descriptionAlignment: NSTextAlignment? // default .left

    // Popup controls
    public let nextButtonMode: CMButtonMode?      // .image(tint) or .text(CMText)
    public let previousButtonMode: CMButtonMode?
    public let skipButtonMode: CMButtonMode?
    public let showBottomButtonStack: Bool?       // default true
}
```

### Supporting Types
```swift
public struct CMText {
    public let text: String
    public let color: UIColor
    public let font: UIFont
}

public enum CMButtonMode {
    case image(tint: UIColor? = nil)              // uses packaged assets: next/prev/close
    case text(CMText)                              // custom title + font + color
}

public enum CoachmarkShape { case rect, circle }

public struct CMBorder {                           // for multi-layer borders
    public let width: CGFloat
    public let color: UIColor
    public let priority: Int                      // lower = drawn first (inner)
}

public struct CMPaddingBorder {                    // border after extra padding
    public let width: CGFloat
    public let color: UIColor
    public let cornerRadius: CGFloat              // for .rect only
}
```

> **Last step default:** If `nextButtonMode` is not provided, the last step’s Next becomes a “Done” text button (blue background). Override with your own `.text(CMText)` to customize.

---

## Layout Notes

- Popup header is a horizontal row: **[ Text (title+description) | Skip(24pt) ]**.
  The Skip sits in a fixed **24pt** column and pins to the top-right; title/description never wrap beneath it.
  If the title is empty, top/trailing popup margins tighten so Skip stays visually ~16×16 from the card edges.
- The bottom button row is a vertical stack item that can be **hidden** per step via `showBottomButtonStack`.
  Buttons are sized to **32pt** height (via constraints or container views) to ensure a consistent tap target.
- `popupDistance` (default **16pt**) controls the fixed gap between the highlight and the popup. The manager accounts for all visual outsets (padding, `extraPadding`, `paddingBorder`, multi-borders, and stroke width) to **avoid overlap**.

---

## Asset Loading (SPM)

If you customize icons, load from the package bundle:

```swift
let image = UIImage(named: "next_icon", in: .module, compatibleWith: nil)
```

The package ships `next_icon`, `previous_icon`, `close_icon`—keep those names or update your code.

---

## Troubleshooting

- **Popup overlaps the highlight**  
  Set/raise `popupDistance` (e.g. `24`) and ensure you’re using the latest version (placement accounts for borders/padding/stroke).
- **Icons not showing**  
  Verify asset names and that they live under  
  `Sources/SpotLightSDK/Resources/Images.xcassets`. Load via `.module`.
- **Buttons look too small**  
  Confirm the 32pt height setup (either via button constraints with `buttonRow.alignment = .fill` or container wrappers).

---

## License

MIT © Your Name

---

## Contributing

PRs and issues are welcome. Please include:
- iOS version & device
- Repro steps
- Screenshots/screen recording for layout issues
