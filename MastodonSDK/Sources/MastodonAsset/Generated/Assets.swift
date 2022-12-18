// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

#if os(macOS)
  import AppKit
#elseif os(iOS)
  import UIKit
#elseif os(tvOS) || os(watchOS)
  import UIKit
#endif
#if canImport(SwiftUI)
  import SwiftUI
#endif

// Deprecated typealiases
@available(*, deprecated, renamed: "ColorAsset.Color", message: "This typealias will be removed in SwiftGen 7.0")
public typealias AssetColorTypeAlias = ColorAsset.Color
@available(*, deprecated, renamed: "ImageAsset.Image", message: "This typealias will be removed in SwiftGen 7.0")
public typealias AssetImageTypeAlias = ImageAsset.Image

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Asset Catalogs

// swiftlint:disable identifier_name line_length nesting type_body_length type_name
public enum Asset {
  public enum Arrow {
    public static let `repeat` = ImageAsset(name: "Arrow/repeat")
    public static let repeatSmall = ImageAsset(name: "Arrow/repeat.small")
    public static let squareAndArrowUp = ImageAsset(name: "Arrow/square.and.arrow.up")
  }
  public enum Asset {
    public static let email = ImageAsset(name: "Asset/email")
    public static let friends = ImageAsset(name: "Asset/friends")
    public static let mastodonTextLogo = ImageAsset(name: "Asset/mastodon.text.logo")
  }
  public enum Circles {
    public static let forbidden20 = ImageAsset(name: "Circles/forbidden.20")
    public static let plusCircleFill = ImageAsset(name: "Circles/plus.circle.fill")
    public static let plusCircle = ImageAsset(name: "Circles/plus.circle")
  }
  public enum Colors {
    public enum Border {
      public static let composePoll = ColorAsset(name: "Colors/Border/compose.poll")
      public static let searchCard = ColorAsset(name: "Colors/Border/searchCard")
      public static let status = ColorAsset(name: "Colors/Border/status")
    }
    public enum Button {
      public static let actionToolbar = ColorAsset(name: "Colors/Button/action.toolbar")
      public static let disabled = ColorAsset(name: "Colors/Button/disabled")
      public static let inactive = ColorAsset(name: "Colors/Button/inactive")
      public static let tagFollow = ColorAsset(name: "Colors/Button/tagFollow")
      public static let tagUnfollow = ColorAsset(name: "Colors/Button/tagUnfollow")
    }
    public enum Icon {
      public static let plus = ColorAsset(name: "Colors/Icon/plus")
    }
    public enum Label {
      public static let primary = ColorAsset(name: "Colors/Label/primary")
      public static let primaryReverse = ColorAsset(name: "Colors/Label/primary.reverse")
      public static let secondary = ColorAsset(name: "Colors/Label/secondary")
      public static let tertiary = ColorAsset(name: "Colors/Label/tertiary")
    }
    public enum Notification {
      public static let favourite = ColorAsset(name: "Colors/Notification/favourite")
      public static let mention = ColorAsset(name: "Colors/Notification/mention")
      public static let reblog = ColorAsset(name: "Colors/Notification/reblog")
    }
    public enum Poll {
      public static let disabled = ColorAsset(name: "Colors/Poll/disabled")
    }
    public enum Primary {
      public static let _300 = ColorAsset(name: "Colors/Primary/300")
      public static let _700 = ColorAsset(name: "Colors/Primary/700")
    }
    public enum Shadow {
      public static let searchCard = ColorAsset(name: "Colors/Shadow/SearchCard")
    }
    public enum Slider {
      public static let track = ColorAsset(name: "Colors/Slider/track")
    }
    public enum TextField {
      public static let background = ColorAsset(name: "Colors/TextField/background")
      public static let invalid = ColorAsset(name: "Colors/TextField/invalid")
      public static let valid = ColorAsset(name: "Colors/TextField/valid")
    }
    public static let alertYellow = ColorAsset(name: "Colors/alert.yellow")
    public static let badgeBackground = ColorAsset(name: "Colors/badge.background")
    public static let battleshipGrey = ColorAsset(name: "Colors/battleshipGrey")
    public static let brand = ColorAsset(name: "Colors/brand")
    public static let dangerBorder = ColorAsset(name: "Colors/danger.border")
    public static let danger = ColorAsset(name: "Colors/danger")
    public enum Deprecated {
      public static let brandBlue = ColorAsset(name: "Colors/deprecated/brand.blue")
      public static let brandBlueDarken20 = ColorAsset(name: "Colors/deprecated/brand.blue.darken.20")
    }
    public static let disabled = ColorAsset(name: "Colors/disabled")
    public static let inactive = ColorAsset(name: "Colors/inactive")
    public static let mediaTypeIndicotor = ColorAsset(name: "Colors/media.type.indicotor")
    public static let successGreen = ColorAsset(name: "Colors/success.green")
    public static let systemOrange = ColorAsset(name: "Colors/system.orange")
  }
  public enum Communication {
    public static let bubbleLeftAndBubbleRight = ImageAsset(name: "Communication/bubble.left.and.bubble.right")
    public static let share = ImageAsset(name: "Communication/share")
  }
  public enum Connectivity {
    public static let photoFillSplit = ImageAsset(name: "Connectivity/photo.fill.split")
  }
  public enum Editing {
    public static let checkmark20 = ImageAsset(name: "Editing/checkmark.20")
    public static let checkmark = ImageAsset(name: "Editing/checkmark")
    public static let xmark = ImageAsset(name: "Editing/xmark")
  }
  public enum Human {
    public static let eyeCircleFill = ImageAsset(name: "Human/eye.circle.fill")
    public static let eyeSlashCircleFill = ImageAsset(name: "Human/eye.slash.circle.fill")
    public static let faceSmilingAdaptive = ImageAsset(name: "Human/face.smiling.adaptive")
  }
  public enum ObjectsAndTools {
    public static let bellBadgeFill = ImageAsset(name: "ObjectsAndTools/bell.badge.fill")
    public static let bellBadge = ImageAsset(name: "ObjectsAndTools/bell.badge")
    public static let bellFill = ImageAsset(name: "ObjectsAndTools/bell.fill")
    public static let bell = ImageAsset(name: "ObjectsAndTools/bell")
    public static let bookmarkFill = ImageAsset(name: "ObjectsAndTools/bookmark.fill")
    public static let bookmark = ImageAsset(name: "ObjectsAndTools/bookmark")
    public static let gear = ImageAsset(name: "ObjectsAndTools/gear")
    public static let houseFill = ImageAsset(name: "ObjectsAndTools/house.fill")
    public static let house = ImageAsset(name: "ObjectsAndTools/house")
    public static let magnifyingglassFill = ImageAsset(name: "ObjectsAndTools/magnifyingglass.fill")
    public static let magnifyingglass = ImageAsset(name: "ObjectsAndTools/magnifyingglass")
    public static let squareAndPencil = ImageAsset(name: "ObjectsAndTools/square.and.pencil")
    public static let starFill = ImageAsset(name: "ObjectsAndTools/star.fill")
    public static let star = ImageAsset(name: "ObjectsAndTools/star")
  }
  public enum Scene {
    public enum Compose {
      public enum Attachment {
        public static let indicatorButtonBackground = ColorAsset(name: "Scene/Compose/Attachment/indicator.button.background")
        public static let retry = ImageAsset(name: "Scene/Compose/Attachment/retry")
        public static let stop = ImageAsset(name: "Scene/Compose/Attachment/stop")
      }
      public static let earth = ImageAsset(name: "Scene/Compose/Earth")
      public static let mention = ImageAsset(name: "Scene/Compose/Mention")
      public static let more = ImageAsset(name: "Scene/Compose/More")
      public static let people = ImageAsset(name: "Scene/Compose/People")
      public static let buttonTint = ColorAsset(name: "Scene/Compose/button.tint")
      public static let chatWarningFill = ImageAsset(name: "Scene/Compose/chat.warning.fill")
      public static let chatWarning = ImageAsset(name: "Scene/Compose/chat.warning")
      public static let emojiFill = ImageAsset(name: "Scene/Compose/emoji.fill")
      public static let emoji = ImageAsset(name: "Scene/Compose/emoji")
      public static let media = ImageAsset(name: "Scene/Compose/media")
      public static let peopleAdd = ImageAsset(name: "Scene/Compose/people.add")
      public static let pollFill = ImageAsset(name: "Scene/Compose/poll.fill")
      public static let poll = ImageAsset(name: "Scene/Compose/poll")
      public static let reorderDot = ImageAsset(name: "Scene/Compose/reorder.dot")
    }
    public enum Discovery {
      public static let profileCardBackground = ColorAsset(name: "Scene/Discovery/profile.card.background")
    }
    public enum Notification {
      public static let confirmFollowRequestButtonBackground = ColorAsset(name: "Scene/Notification/confirm.follow.request.button.background")
      public static let deleteFollowRequestButtonBackground = ColorAsset(name: "Scene/Notification/delete.follow.request.button.background")
    }
    public enum Onboarding {
      public static let avatarPlaceholder = ImageAsset(name: "Scene/Onboarding/avatar.placeholder")
      public static let background = ColorAsset(name: "Scene/Onboarding/background")
      public static let navigationBackButtonBackground = ColorAsset(name: "Scene/Onboarding/navigation.back.button.background")
      public static let navigationBackButtonBackgroundHighlighted = ColorAsset(name: "Scene/Onboarding/navigation.back.button.background.highlighted")
      public static let navigationNextButtonBackground = ColorAsset(name: "Scene/Onboarding/navigation.next.button.background")
      public static let navigationNextButtonBackgroundHighlighted = ColorAsset(name: "Scene/Onboarding/navigation.next.button.background.highlighted")
      public static let searchBarBackground = ColorAsset(name: "Scene/Onboarding/search.bar.background")
      public static let textFieldBackground = ColorAsset(name: "Scene/Onboarding/textField.background")
    }
    public enum Profile {
      public enum About {
        public static let bioAboutFieldVerifiedBackground = ColorAsset(name: "Scene/Profile/About/bio.about.field.verified.background")
        public static let bioAboutFieldVerifiedText = ColorAsset(name: "Scene/Profile/About/bio.about.field.verified.text")
      }
      public enum Banner {
        public static let bioEditBackgroundGray = ColorAsset(name: "Scene/Profile/Banner/bio.edit.background.gray")
        public static let nameEditBackgroundGray = ColorAsset(name: "Scene/Profile/Banner/name.edit.background.gray")
        public static let usernameGray = ColorAsset(name: "Scene/Profile/Banner/username.gray")
      }
      public enum RelationshipButton {
        public static let backgroundDark = ColorAsset(name: "Scene/Profile/RelationshipButton/background.dark")
        public static let backgroundHighlightedDark = ColorAsset(name: "Scene/Profile/RelationshipButton/background.highlighted.dark")
        public static let backgroundHighlightedLight = ColorAsset(name: "Scene/Profile/RelationshipButton/background.highlighted.light")
        public static let backgroundLight = ColorAsset(name: "Scene/Profile/RelationshipButton/background.light")
      }
    }
    public enum Report {
      public static let background = ColorAsset(name: "Scene/Report/background")
      public static let reportBanner = ColorAsset(name: "Scene/Report/report.banner")
    }
    public enum Setting {
      public static let background = ColorAsset(name: "Scene/Setting/background")
    }
    public enum Sidebar {
      public static let logo = ImageAsset(name: "Scene/Sidebar/logo")
    }
    public enum Welcome {
      public enum Illustration {
        public static let backgroundCyan = ColorAsset(name: "Scene/Welcome/illustration/background.cyan")
        public static let cloudBaseExtend = ImageAsset(name: "Scene/Welcome/illustration/cloud.base.extend")
        public static let cloudBase = ImageAsset(name: "Scene/Welcome/illustration/cloud.base")
        public static let elephantOnAirplaneWithContrail = ImageAsset(name: "Scene/Welcome/illustration/elephant.on.airplane.with.contrail")
        public static let elephantThreeOnGrassExtend = ImageAsset(name: "Scene/Welcome/illustration/elephant.three.on.grass.extend")
        public static let elephantThreeOnGrass = ImageAsset(name: "Scene/Welcome/illustration/elephant.three.on.grass")
        public static let elephantThreeOnGrassWithTreeThree = ImageAsset(name: "Scene/Welcome/illustration/elephant.three.on.grass.with.tree.three")
        public static let elephantThreeOnGrassWithTreeTwo = ImageAsset(name: "Scene/Welcome/illustration/elephant.three.on.grass.with.tree.two")
      }
      public static let mastodonLogo = ImageAsset(name: "Scene/Welcome/mastodon.logo")
      public static let signInButtonBackground = ColorAsset(name: "Scene/Welcome/sign.in.button.background")
    }
  }
  public enum Settings {
    public static let automatic = ImageAsset(name: "Settings/automatic")
    public static let dark = ImageAsset(name: "Settings/dark")
    public static let light = ImageAsset(name: "Settings/light")
  }
  public enum Theme {
    public enum Mastodon {
      public static let composePollRowBackground = ColorAsset(name: "Theme/Mastodon/compose.poll.row.background")
      public static let composeToolbarBackground = ColorAsset(name: "Theme/Mastodon/compose.toolbar.background")
      public static let contentWarningOverlayBackground = ColorAsset(name: "Theme/Mastodon/content.warning.overlay.background")
      public static let navigationBarBackground = ColorAsset(name: "Theme/Mastodon/navigation.bar.background")
      public static let profileFieldCollectionViewBackground = ColorAsset(name: "Theme/Mastodon/profile.field.collection.view.background")
      public static let secondaryGroupedSystemBackground = ColorAsset(name: "Theme/Mastodon/secondary.grouped.system.background")
      public static let secondarySystemBackground = ColorAsset(name: "Theme/Mastodon/secondary.system.background")
      public static let sidebarBackground = ColorAsset(name: "Theme/Mastodon/sidebar.background")
      public static let systemBackground = ColorAsset(name: "Theme/Mastodon/system.background")
      public static let systemElevatedBackground = ColorAsset(name: "Theme/Mastodon/system.elevated.background")
      public static let systemGroupedBackground = ColorAsset(name: "Theme/Mastodon/system.grouped.background")
      public static let tabBarBackground = ColorAsset(name: "Theme/Mastodon/tab.bar.background")
      public static let tableViewCellBackground = ColorAsset(name: "Theme/Mastodon/table.view.cell.background")
      public static let tableViewCellSelectionBackground = ColorAsset(name: "Theme/Mastodon/table.view.cell.selection.background")
      public static let tertiarySystemBackground = ColorAsset(name: "Theme/Mastodon/tertiary.system.background")
      public static let tertiarySystemGroupedBackground = ColorAsset(name: "Theme/Mastodon/tertiary.system.grouped.background")
      public static let notificationStatusBorderColor = ColorAsset(name: "Theme/Mastodon/notification.status.border.color")
      public static let separator = ColorAsset(name: "Theme/Mastodon/separator")
      public static let tabBarItemInactiveIconColor = ColorAsset(name: "Theme/Mastodon/tab.bar.item.inactive.icon.color")
    }
    public enum System {
      public static let composePollRowBackground = ColorAsset(name: "Theme/system/compose.poll.row.background")
      public static let composeToolbarBackground = ColorAsset(name: "Theme/system/compose.toolbar.background")
      public static let contentWarningOverlayBackground = ColorAsset(name: "Theme/system/content.warning.overlay.background")
      public static let navigationBarBackground = ColorAsset(name: "Theme/system/navigation.bar.background")
      public static let profileFieldCollectionViewBackground = ColorAsset(name: "Theme/system/profile.field.collection.view.background")
      public static let secondaryGroupedSystemBackground = ColorAsset(name: "Theme/system/secondary.grouped.system.background")
      public static let secondarySystemBackground = ColorAsset(name: "Theme/system/secondary.system.background")
      public static let sidebarBackground = ColorAsset(name: "Theme/system/sidebar.background")
      public static let systemBackground = ColorAsset(name: "Theme/system/system.background")
      public static let systemElevatedBackground = ColorAsset(name: "Theme/system/system.elevated.background")
      public static let systemGroupedBackground = ColorAsset(name: "Theme/system/system.grouped.background")
      public static let tabBarBackground = ColorAsset(name: "Theme/system/tab.bar.background")
      public static let tableViewCellBackground = ColorAsset(name: "Theme/system/table.view.cell.background")
      public static let tableViewCellSelectionBackground = ColorAsset(name: "Theme/system/table.view.cell.selection.background")
      public static let tertiarySystemBackground = ColorAsset(name: "Theme/system/tertiary.system.background")
      public static let tertiarySystemGroupedBackground = ColorAsset(name: "Theme/system/tertiary.system.grouped.background")
      public static let notificationStatusBorderColor = ColorAsset(name: "Theme/system/notification.status.border.color")
      public static let separator = ColorAsset(name: "Theme/system/separator")
      public static let tabBarItemInactiveIconColor = ColorAsset(name: "Theme/system/tab.bar.item.inactive.icon.color")
    }
  }
}
// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details

public final class ColorAsset {
  public fileprivate(set) var name: String

  #if os(macOS)
  public typealias Color = NSColor
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  public typealias Color = UIColor
  #endif

  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  public private(set) lazy var color: Color = {
    guard let color = Color(asset: self) else {
      fatalError("Unable to load color asset named \(name).")
    }
    return color
  }()

  #if os(iOS) || os(tvOS)
  @available(iOS 11.0, tvOS 11.0, *)
  public func color(compatibleWith traitCollection: UITraitCollection) -> Color {
    let bundle = Bundle.module
    guard let color = Color(named: name, in: bundle, compatibleWith: traitCollection) else {
      fatalError("Unable to load color asset named \(name).")
    }
    return color
  }
  #endif

  #if canImport(SwiftUI)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  public private(set) lazy var swiftUIColor: SwiftUI.Color = {
    SwiftUI.Color(asset: self)
  }()
  #endif

  fileprivate init(name: String) {
    self.name = name
  }
}

public extension ColorAsset.Color {
  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  convenience init?(asset: ColorAsset) {
    let bundle = Bundle.module
    #if os(iOS) || os(tvOS)
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSColor.Name(asset.name), bundle: bundle)
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
public extension SwiftUI.Color {
  init(asset: ColorAsset) {
    let bundle = Bundle.module
    self.init(asset.name, bundle: bundle)
  }
}
#endif

public struct ImageAsset {
  public fileprivate(set) var name: String

  #if os(macOS)
  public typealias Image = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  public typealias Image = UIImage
  #endif

  @available(iOS 8.0, tvOS 9.0, watchOS 2.0, macOS 10.7, *)
  public var image: Image {
    let bundle = Bundle.module
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

  #if os(iOS) || os(tvOS)
  @available(iOS 8.0, tvOS 9.0, *)
  public func image(compatibleWith traitCollection: UITraitCollection) -> Image {
    let bundle = Bundle.module
    guard let result = Image(named: name, in: bundle, compatibleWith: traitCollection) else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }
  #endif

  #if canImport(SwiftUI)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  public var swiftUIImage: SwiftUI.Image {
    SwiftUI.Image(asset: self)
  }
  #endif
}

public extension ImageAsset.Image {
  @available(iOS 8.0, tvOS 9.0, watchOS 2.0, *)
  @available(macOS, deprecated,
    message: "This initializer is unsafe on macOS, please use the ImageAsset.image property")
  convenience init?(asset: ImageAsset) {
    #if os(iOS) || os(tvOS)
    let bundle = Bundle.module
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSImage.Name(asset.name))
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
public extension SwiftUI.Image {
  init(asset: ImageAsset) {
    let bundle = Bundle.module
    self.init(asset.name, bundle: bundle)
  }

  init(asset: ImageAsset, label: Text) {
    let bundle = Bundle.module
    self.init(asset.name, bundle: bundle, label: label)
  }

  init(decorative asset: ImageAsset) {
    let bundle = Bundle.module
    self.init(decorative: asset.name, bundle: bundle)
  }
}
#endif
