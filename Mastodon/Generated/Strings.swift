// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {

  internal enum Common {
    internal enum Controls {
      internal enum Actions {
        /// Add
        internal static let add = L10n.tr("Localizable", "Common.Controls.Actions.Add")
        /// Cancel
        internal static let cancel = L10n.tr("Localizable", "Common.Controls.Actions.Cancel")
        /// Confirm
        internal static let confirm = L10n.tr("Localizable", "Common.Controls.Actions.Confirm")
        /// Continue
        internal static let `continue` = L10n.tr("Localizable", "Common.Controls.Actions.Continue")
        /// Edit
        internal static let edit = L10n.tr("Localizable", "Common.Controls.Actions.Edit")
        /// OK
        internal static let ok = L10n.tr("Localizable", "Common.Controls.Actions.Ok")
        /// Open in Safari
        internal static let openInSafari = L10n.tr("Localizable", "Common.Controls.Actions.OpenInSafari")
        /// Preview
        internal static let preview = L10n.tr("Localizable", "Common.Controls.Actions.Preview")
        /// Remove
        internal static let remove = L10n.tr("Localizable", "Common.Controls.Actions.Remove")
        /// Save
        internal static let save = L10n.tr("Localizable", "Common.Controls.Actions.Save")
        /// Save photo
        internal static let savePhoto = L10n.tr("Localizable", "Common.Controls.Actions.SavePhoto")
        /// See More
        internal static let seeMore = L10n.tr("Localizable", "Common.Controls.Actions.SeeMore")
        /// Sign in
        internal static let signIn = L10n.tr("Localizable", "Common.Controls.Actions.SignIn")
        /// Sign up
        internal static let signUp = L10n.tr("Localizable", "Common.Controls.Actions.SignUp")
        /// Take photo
        internal static let takePhoto = L10n.tr("Localizable", "Common.Controls.Actions.TakePhoto")
      }
      internal enum Status {
        /// content warning
        internal static let contentWarning = L10n.tr("Localizable", "Common.Controls.Status.ContentWarning")
        /// Show Post
        internal static let showPost = L10n.tr("Localizable", "Common.Controls.Status.ShowPost")
        /// %@ boosted
        internal static func userBoosted(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Status.UserBoosted", String(describing: p1))
        }
      }
      internal enum Timeline {
        /// Load More
        internal static let loadMore = L10n.tr("Localizable", "Common.Controls.Timeline.LoadMore")
      }
    }
    internal enum Countable {
      internal enum Photo {
        /// photos
        internal static let multiple = L10n.tr("Localizable", "Common.Countable.Photo.Multiple")
        /// photo
        internal static let single = L10n.tr("Localizable", "Common.Countable.Photo.Single")
      }
    }
  }

  internal enum Scene {
    internal enum HomeTimeline {
      /// Home
      internal static let title = L10n.tr("Localizable", "Scene.HomeTimeline.Title")
    }
    internal enum PublicTimeline {
      /// Public
      internal static let title = L10n.tr("Localizable", "Scene.PublicTimeline.Title")
    }
    internal enum Register {
      /// Tell us about you.
      internal static let title = L10n.tr("Localizable", "Scene.Register.Title")
      internal enum Input {
        internal enum DisplayName {
          /// display name
          internal static let placeholder = L10n.tr("Localizable", "Scene.Register.Input.DisplayName.Placeholder")
        }
        internal enum Email {
          /// email
          internal static let placeholder = L10n.tr("Localizable", "Scene.Register.Input.Email.Placeholder")
        }
        internal enum Password {
          /// password
          internal static let placeholder = L10n.tr("Localizable", "Scene.Register.Input.Password.Placeholder")
          /// Your password needs at least:
          internal static let prompt = L10n.tr("Localizable", "Scene.Register.Input.Password.Prompt")
          /// Eight characters
          internal static let promptEightCharacters = L10n.tr("Localizable", "Scene.Register.Input.Password.PromptEightCharacters")
        }
        internal enum Username {
          /// This username is taken.
          internal static let duplicatePrompt = L10n.tr("Localizable", "Scene.Register.Input.Username.DuplicatePrompt")
          /// username
          internal static let placeholder = L10n.tr("Localizable", "Scene.Register.Input.Username.Placeholder")
        }
      }
    }
    internal enum ServerPicker {
      /// Pick a Server,\nany server.
      internal static let title = L10n.tr("Localizable", "Scene.ServerPicker.Title")
      internal enum Button {
        /// See less
        internal static let seeLess = L10n.tr("Localizable", "Scene.ServerPicker.Button.SeeLess")
        /// See More
        internal static let seeMore = L10n.tr("Localizable", "Scene.ServerPicker.Button.SeeMore")
        internal enum Category {
          /// All
          internal static let all = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.All")
        }
      }
      internal enum Input {
        /// Find a server or join your own...
        internal static let placeholder = L10n.tr("Localizable", "Scene.ServerPicker.Input.Placeholder")
      }
      internal enum Label {
        /// CATEGORY
        internal static let category = L10n.tr("Localizable", "Scene.ServerPicker.Label.Category")
        /// LANGUAGE
        internal static let language = L10n.tr("Localizable", "Scene.ServerPicker.Label.Language")
        /// USERS
        internal static let users = L10n.tr("Localizable", "Scene.ServerPicker.Label.Users")
      }
    }
    internal enum ServerRules {
      /// By continuing, you're subject to the terms of service and privacy policy for %@.
      internal static func prompt(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.ServerRules.Prompt", String(describing: p1))
      }
      /// These rules are set by the admins of %@.
      internal static func subtitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.ServerRules.Subtitle", String(describing: p1))
      }
      /// Some ground rules.
      internal static let title = L10n.tr("Localizable", "Scene.ServerRules.Title")
      internal enum Button {
        /// I Agree
        internal static let confirm = L10n.tr("Localizable", "Scene.ServerRules.Button.Confirm")
      }
    }
    internal enum Welcome {
      /// Social networking\nback in your hands.
      internal static let slogan = L10n.tr("Localizable", "Scene.Welcome.Slogan")
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: nil, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
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
