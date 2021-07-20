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
  internal enum Asset {
    internal static let email = ImageAsset(name: "Asset/email")
    internal static let friends = ImageAsset(name: "Asset/friends")
    internal static let mastodonTextLogo = ImageAsset(name: "Asset/mastodon.text.logo")
  }
  internal enum Circles {
    internal static let plusCircleFill = ImageAsset(name: "Circles/plus.circle.fill")
    internal static let plusCircle = ImageAsset(name: "Circles/plus.circle")
  }
  internal enum Colors {
    internal enum Border {
      internal static let composePoll = ColorAsset(name: "Colors/Border/compose.poll")
      internal static let notificationStatus = ColorAsset(name: "Colors/Border/notification.status")
      internal static let searchCard = ColorAsset(name: "Colors/Border/searchCard")
      internal static let status = ColorAsset(name: "Colors/Border/status")
    }
    internal enum Button {
      internal static let actionToolbar = ColorAsset(name: "Colors/Button/action.toolbar")
      internal static let disabled = ColorAsset(name: "Colors/Button/disabled")
      internal static let inactive = ColorAsset(name: "Colors/Button/inactive")
    }
    internal enum Icon {
      internal static let plus = ColorAsset(name: "Colors/Icon/plus")
    }
    internal enum Label {
      internal static let primary = ColorAsset(name: "Colors/Label/primary")
      internal static let secondary = ColorAsset(name: "Colors/Label/secondary")
      internal static let tertiary = ColorAsset(name: "Colors/Label/tertiary")
    }
    internal enum Notification {
      internal static let favourite = ColorAsset(name: "Colors/Notification/favourite")
      internal static let mention = ColorAsset(name: "Colors/Notification/mention")
      internal static let reblog = ColorAsset(name: "Colors/Notification/reblog")
    }
    internal enum Poll {
      internal static let disabled = ColorAsset(name: "Colors/Poll/disabled")
    }
    internal enum Shadow {
      internal static let searchCard = ColorAsset(name: "Colors/Shadow/SearchCard")
    }
    internal enum Slider {
      internal static let track = ColorAsset(name: "Colors/Slider/track")
    }
    internal enum TabBar {
      internal static let itemInactive = ColorAsset(name: "Colors/TabBar/item.inactive")
    }
    internal enum TextField {
      internal static let background = ColorAsset(name: "Colors/TextField/background")
      internal static let invalid = ColorAsset(name: "Colors/TextField/invalid")
      internal static let valid = ColorAsset(name: "Colors/TextField/valid")
    }
    internal static let alertYellow = ColorAsset(name: "Colors/alert.yellow")
    internal static let battleshipGrey = ColorAsset(name: "Colors/battleshipGrey")
    internal static let brandBlue = ColorAsset(name: "Colors/brand.blue")
    internal static let brandBlueDarken20 = ColorAsset(name: "Colors/brand.blue.darken.20")
    internal static let dangerBorder = ColorAsset(name: "Colors/danger.border")
    internal static let danger = ColorAsset(name: "Colors/danger")
    internal static let disabled = ColorAsset(name: "Colors/disabled")
    internal static let inactive = ColorAsset(name: "Colors/inactive")
    internal static let mediaTypeIndicotor = ColorAsset(name: "Colors/media.type.indicotor")
    internal static let successGreen = ColorAsset(name: "Colors/success.green")
    internal static let systemOrange = ColorAsset(name: "Colors/system.orange")
  }
  internal enum Connectivity {
    internal static let photoFillSplit = ImageAsset(name: "Connectivity/photo.fill.split")
  }
  internal enum Human {
    internal static let faceSmilingAdaptive = ImageAsset(name: "Human/face.smiling.adaptive")
  }
  internal enum Scene {
    internal enum Profile {
      internal enum Banner {
        internal static let bioEditBackgroundGray = ColorAsset(name: "Scene/Profile/Banner/bio.edit.background.gray")
        internal static let nameEditBackgroundGray = ColorAsset(name: "Scene/Profile/Banner/name.edit.background.gray")
        internal static let usernameGray = ColorAsset(name: "Scene/Profile/Banner/username.gray")
      }
    }
    internal enum Welcome {
      internal enum Illustration {
        internal static let backgroundCyan = ColorAsset(name: "Scene/Welcome/illustration/background.cyan")
        internal static let cloudBase = ImageAsset(name: "Scene/Welcome/illustration/cloud.base")
        internal static let elephantOnAirplaneWithContrail = ImageAsset(name: "Scene/Welcome/illustration/elephant.on.airplane.with.contrail")
        internal static let elephantThreeOnGrass = ImageAsset(name: "Scene/Welcome/illustration/elephant.three.on.grass")
        internal static let elephantThreeOnGrassWithTreeThree = ImageAsset(name: "Scene/Welcome/illustration/elephant.three.on.grass.with.tree.three")
        internal static let elephantThreeOnGrassWithTreeTwo = ImageAsset(name: "Scene/Welcome/illustration/elephant.three.on.grass.with.tree.two")
      }
      internal static let mastodonLogoBlack = ImageAsset(name: "Scene/Welcome/mastodon.logo.black")
      internal static let mastodonLogoBlackLarge = ImageAsset(name: "Scene/Welcome/mastodon.logo.black.large")
      internal static let mastodonLogo = ImageAsset(name: "Scene/Welcome/mastodon.logo")
      internal static let mastodonLogoLarge = ImageAsset(name: "Scene/Welcome/mastodon.logo.large")
    }
  }
  internal enum Settings {
    internal static let appearanceAutomatic = ImageAsset(name: "Settings/appearance.automatic")
    internal static let appearanceDark = ImageAsset(name: "Settings/appearance.dark")
    internal static let appearanceLight = ImageAsset(name: "Settings/appearance.light")
  }
  internal enum Theme {
    internal enum Mastodon {
      internal static let composeToolbarBackground = ColorAsset(name: "Theme/Mastodon/compose.toolbar.background")
      internal static let contentWarningOverlayBackground = ColorAsset(name: "Theme/Mastodon/content.warning.overlay.background")
      internal static let navigationBarBackground = ColorAsset(name: "Theme/Mastodon/navigation.bar.background")
      internal static let profileFieldCollectionViewBackground = ColorAsset(name: "Theme/Mastodon/profile.field.collection.view.background")
      internal static let secondaryGroupedSystemBackground = ColorAsset(name: "Theme/Mastodon/secondary.grouped.system.background")
      internal static let secondarySystemBackground = ColorAsset(name: "Theme/Mastodon/secondary.system.background")
      internal static let systemBackground = ColorAsset(name: "Theme/Mastodon/system.background")
      internal static let systemElevatedBackground = ColorAsset(name: "Theme/Mastodon/system.elevated.background")
      internal static let systemGroupedBackground = ColorAsset(name: "Theme/Mastodon/system.grouped.background")
      internal static let tabBarBackground = ColorAsset(name: "Theme/Mastodon/tab.bar.background")
      internal static let tableViewCellBackground = ColorAsset(name: "Theme/Mastodon/table.view.cell.background")
      internal static let tableViewCellSelectionBackground = ColorAsset(name: "Theme/Mastodon/table.view.cell.selection.background")
      internal static let tertiarySystemBackground = ColorAsset(name: "Theme/Mastodon/tertiary.system.background")
      internal static let tertiarySystemGroupedBackground = ColorAsset(name: "Theme/Mastodon/tertiary.system.grouped.background")
      internal static let separator = ColorAsset(name: "Theme/Mastodon/separator")
      internal static let tabBarItemInactiveIconColor = ColorAsset(name: "Theme/Mastodon/tab.bar.item.inactive.icon.color")
    }
    internal enum System {
      internal static let composeToolbarBackground = ColorAsset(name: "Theme/system/compose.toolbar.background")
      internal static let contentWarningOverlayBackground = ColorAsset(name: "Theme/system/content.warning.overlay.background")
      internal static let navigationBarBackground = ColorAsset(name: "Theme/system/navigation.bar.background")
      internal static let profileFieldCollectionViewBackground = ColorAsset(name: "Theme/system/profile.field.collection.view.background")
      internal static let secondaryGroupedSystemBackground = ColorAsset(name: "Theme/system/secondary.grouped.system.background")
      internal static let secondarySystemBackground = ColorAsset(name: "Theme/system/secondary.system.background")
      internal static let systemBackground = ColorAsset(name: "Theme/system/system.background")
      internal static let systemElevatedBackground = ColorAsset(name: "Theme/system/system.elevated.background")
      internal static let systemGroupedBackground = ColorAsset(name: "Theme/system/system.grouped.background")
      internal static let tabBarBackground = ColorAsset(name: "Theme/system/tab.bar.background")
      internal static let tableViewCellBackground = ColorAsset(name: "Theme/system/table.view.cell.background")
      internal static let tableViewCellSelectionBackground = ColorAsset(name: "Theme/system/table.view.cell.selection.background")
      internal static let tertiarySystemBackground = ColorAsset(name: "Theme/system/tertiary.system.background")
      internal static let tertiarySystemGroupedBackground = ColorAsset(name: "Theme/system/tertiary.system.grouped.background")
      internal static let separator = ColorAsset(name: "Theme/system/separator")
      internal static let tabBarItemInactiveIconColor = ColorAsset(name: "Theme/system/tab.bar.item.inactive.icon.color")
    }
  }
  internal enum Deprecated {
    internal enum Background {
      internal static let danger = ColorAsset(name: "_Deprecated/Background/danger")
      internal static let onboardingBackground = ColorAsset(name: "_Deprecated/Background/onboarding.background")
      internal static let secondaryGroupedSystemBackground = ColorAsset(name: "_Deprecated/Background/secondary.grouped.system.background")
      internal static let secondarySystemBackground = ColorAsset(name: "_Deprecated/Background/secondary.system.background")
      internal static let systemBackground = ColorAsset(name: "_Deprecated/Background/system.background")
      internal static let systemElevatedBackground = ColorAsset(name: "_Deprecated/Background/system.elevated.background")
      internal static let systemGroupedBackground = ColorAsset(name: "_Deprecated/Background/system.grouped.background")
      internal static let tertiarySystemBackground = ColorAsset(name: "_Deprecated/Background/tertiary.system.background")
      internal static let tertiarySystemGroupedBackground = ColorAsset(name: "_Deprecated/Background/tertiary.system.grouped.background")
    }
    internal enum Compose {
      internal static let background = ColorAsset(name: "_Deprecated/Compose/background")
      internal static let toolbarBackground = ColorAsset(name: "_Deprecated/Compose/toolbar.background")
    }
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
