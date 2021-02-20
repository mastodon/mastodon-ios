// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

#if os(macOS)
  import AppKit
#elseif os(iOS)
  import UIKit
#elseif os(tvOS) || os(watchOS)
  import UIKit
#endif

// Deprecated typealiases
@available(*, deprecated, renamed: "ColorAsset.Color", message: "This typealias will be removed in SwiftGen 7.0")
internal typealias AssetColorTypeAlias = ColorAsset.Color
@available(*, deprecated, renamed: "ImageAsset.Image", message: "This typealias will be removed in SwiftGen 7.0")
internal typealias AssetImageTypeAlias = ImageAsset.Image

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Asset Catalogs

// swiftlint:disable identifier_name line_length nesting type_body_length type_name
internal enum Asset {
  internal static let accentColor = ColorAsset(name: "AccentColor")
  internal enum Arrows {
    internal static let arrowTriangle2Circlepath = ImageAsset(name: "Arrows/arrow.triangle.2.circlepath")
  }
  internal enum Colors {
    internal enum Background {
      internal static let secondarySystemBackground = ColorAsset(name: "Colors/Background/secondary.system.background")
      internal static let signUpSystemBackground = ColorAsset(name: "Colors/Background/signUp.system.background")
      internal static let systemBackground = ColorAsset(name: "Colors/Background/system.background")
      internal static let tertiarySystemBackground = ColorAsset(name: "Colors/Background/tertiary.system.background")
    }
    internal enum Button {
      internal static let highlight = ColorAsset(name: "Colors/Button/highlight")
    }
    internal enum Icon {
      internal static let photo = ColorAsset(name: "Colors/Icon/photo")
      internal static let plus = ColorAsset(name: "Colors/Icon/plus")
    }
    internal enum Label {
      internal static let black = ColorAsset(name: "Colors/Label/black")
      internal static let primary = ColorAsset(name: "Colors/Label/primary")
      internal static let secondary = ColorAsset(name: "Colors/Label/secondary")
    }
    internal enum TextField {
      internal static let successGreen = ColorAsset(name: "Colors/TextField/successGreen")
    }
    internal static let lightAlertYellow = ColorAsset(name: "Colors/lightAlertYellow")
    internal static let lightBackground = ColorAsset(name: "Colors/lightBackground")
    internal static let lightBrandBlue = ColorAsset(name: "Colors/lightBrandBlue")
    internal static let lightDangerRed = ColorAsset(name: "Colors/lightDangerRed")
    internal static let lightDarkGray = ColorAsset(name: "Colors/lightDarkGray")
    internal static let lightDisabled = ColorAsset(name: "Colors/lightDisabled")
    internal static let lightInactive = ColorAsset(name: "Colors/lightInactive")
    internal static let lightSecondaryText = ColorAsset(name: "Colors/lightSecondaryText")
    internal static let lightSuccessGreen = ColorAsset(name: "Colors/lightSuccessGreen")
    internal static let lightWhite = ColorAsset(name: "Colors/lightWhite")
    internal static let systemOrange = ColorAsset(name: "Colors/system.orange")
  }
  internal enum ToolBar {
    internal static let bookmark = ImageAsset(name: "ToolBar/bookmark")
    internal static let lock = ImageAsset(name: "ToolBar/lock")
    internal static let more = ImageAsset(name: "ToolBar/more")
    internal static let reply = ImageAsset(name: "ToolBar/reply")
    internal static let retoot = ImageAsset(name: "ToolBar/retoot")
    internal static let star = ImageAsset(name: "ToolBar/star")
  }
  internal enum TootTimeline {
    internal static let global = ImageAsset(name: "TootTimeline/Global")
    internal static let textlock = ImageAsset(name: "TootTimeline/Textlock")
    internal static let email = ImageAsset(name: "TootTimeline/email")
    internal static let lock = ImageAsset(name: "TootTimeline/lock")
    internal static let unlock = ImageAsset(name: "TootTimeline/unlock")
  }
}
// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details

internal final class ColorAsset {
  internal fileprivate(set) var name: String

  #if os(macOS)
  internal typealias Color = NSColor
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  internal typealias Color = UIColor
  #endif

  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  internal private(set) lazy var color: Color = {
    guard let color = Color(asset: self) else {
      fatalError("Unable to load color asset named \(name).")
    }
    return color
  }()

  fileprivate init(name: String) {
    self.name = name
  }
}

internal extension ColorAsset.Color {
  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  convenience init?(asset: ColorAsset) {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSColor.Name(asset.name), bundle: bundle)
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

internal struct ImageAsset {
  internal fileprivate(set) var name: String

  #if os(macOS)
  internal typealias Image = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  internal typealias Image = UIImage
  #endif

  internal var image: Image {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    let image = Image(named: name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    let name = NSImage.Name(self.name)
    let image = (bundle == .main) ? NSImage(named: name) : bundle.image(forResource: name)
    #elseif os(watchOS)
    let image = Image(named: name)
    #endif
    guard let result = image else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }
}

internal extension ImageAsset.Image {
  @available(macOS, deprecated,
    message: "This initializer is unsafe on macOS, please use the ImageAsset.image property")
  convenience init?(asset: ImageAsset) {
    #if os(iOS) || os(tvOS)
    let bundle = BundleToken.bundle
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSImage.Name(asset.name))
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
