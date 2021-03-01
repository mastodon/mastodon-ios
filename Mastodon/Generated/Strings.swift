// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {

  internal enum Common {
    internal enum Alerts {
      internal enum ServerError {
        /// Server Error
        internal static let title = L10n.tr("Localizable", "Common.Alerts.ServerError.Title")
      }
      internal enum SignUpFailure {
        /// Sign Up Failure
        internal static let title = L10n.tr("Localizable", "Common.Alerts.SignUpFailure.Title")
      }
    }
    internal enum Controls {
      internal enum Actions {
        /// Add
        internal static let add = L10n.tr("Localizable", "Common.Controls.Actions.Add")
        /// Back
        internal static let back = L10n.tr("Localizable", "Common.Controls.Actions.Back")
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
        /// Sign In
        internal static let signIn = L10n.tr("Localizable", "Common.Controls.Actions.SignIn")
        /// Sign Up
        internal static let signUp = L10n.tr("Localizable", "Common.Controls.Actions.SignUp")
        /// Take photo
        internal static let takePhoto = L10n.tr("Localizable", "Common.Controls.Actions.TakePhoto")
      }
      internal enum Status {
        /// Tap to reveal that may be sensitive
        internal static let mediaContentWarning = L10n.tr("Localizable", "Common.Controls.Status.MediaContentWarning")
        /// Show Post
        internal static let showPost = L10n.tr("Localizable", "Common.Controls.Status.ShowPost")
        /// content warning
        internal static let statusContentWarning = L10n.tr("Localizable", "Common.Controls.Status.StatusContentWarning")
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
    internal enum Errors {
      /// must be accepted
      internal static let errAccepted = L10n.tr("Localizable", "Common.Errors.ErrAccepted")
      /// is required
      internal static let errBlank = L10n.tr("Localizable", "Common.Errors.ErrBlank")
      /// contains a disallowed e-mail provider
      internal static let errBlocked = L10n.tr("Localizable", "Common.Errors.ErrBlocked")
      /// is not a supported value
      internal static let errInclusion = L10n.tr("Localizable", "Common.Errors.ErrInclusion")
      /// is invalid
      internal static let errInvalid = L10n.tr("Localizable", "Common.Errors.ErrInvalid")
      /// is a reserved keyword or username
      internal static let errReserved = L10n.tr("Localizable", "Common.Errors.ErrReserved")
      /// is already in use
      internal static let errTaken = L10n.tr("Localizable", "Common.Errors.ErrTaken")
      /// is too long ( can't be longer than 30 characters)
      internal static let errTooLong = L10n.tr("Localizable", "Common.Errors.ErrTooLong")
      /// is too short (must be at least 8 characters)
      internal static let errTooShort = L10n.tr("Localizable", "Common.Errors.ErrTooShort")
      /// does not seem to exist
      internal static let errUnreachable = L10n.tr("Localizable", "Common.Errors.ErrUnreachable")
      internal enum Item {
        /// agreement
        internal static let agreement = L10n.tr("Localizable", "Common.Errors.Item.Agreement")
        /// email
        internal static let email = L10n.tr("Localizable", "Common.Errors.Item.Email")
        /// locale
        internal static let locale = L10n.tr("Localizable", "Common.Errors.Item.Locale")
        /// password
        internal static let password = L10n.tr("Localizable", "Common.Errors.Item.Password")
        /// reason
        internal static let reason = L10n.tr("Localizable", "Common.Errors.Item.Reason")
        /// username
        internal static let username = L10n.tr("Localizable", "Common.Errors.Item.Username")
      }
      internal enum Itemdetail {
        /// It's not a valid e-mail address
        internal static let emailinvalid = L10n.tr("Localizable", "Common.Errors.Itemdetail.Emailinvalid")
        /// username only contains alphanumeric characters and underscores
        internal static let usernameinvalid = L10n.tr("Localizable", "Common.Errors.Itemdetail.Usernameinvalid")
      }
    }
  }

  internal enum Scene {
    internal enum ConfirmEmail {
      /// We just sent an email to %@,\ntap the link to confirm your account.
      internal static func subtitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.ConfirmEmail.Subtitle", String(describing: p1))
      }
      /// One last thing.
      internal static let title = L10n.tr("Localizable", "Scene.ConfirmEmail.Title")
      internal enum Button {
        /// I never got an email
        internal static let dontReceiveEmail = L10n.tr("Localizable", "Scene.ConfirmEmail.Button.DontReceiveEmail")
        /// Open Email App
        internal static let openEmailApp = L10n.tr("Localizable", "Scene.ConfirmEmail.Button.OpenEmailApp")
      }
      internal enum DontReceiveEmail {
        /// Check if your email address is correct as well as your junk folder if you haven’t.
        internal static let description = L10n.tr("Localizable", "Scene.ConfirmEmail.DontReceiveEmail.Description")
        /// Resend Email
        internal static let resendEmail = L10n.tr("Localizable", "Scene.ConfirmEmail.DontReceiveEmail.ResendEmail")
        /// Check your email
        internal static let title = L10n.tr("Localizable", "Scene.ConfirmEmail.DontReceiveEmail.Title")
      }
      internal enum OpenEmailApp {
        /// We just sent you an email. Check your junk folder if you haven’t.
        internal static let description = L10n.tr("Localizable", "Scene.ConfirmEmail.OpenEmailApp.Description")
        /// Mail
        internal static let mail = L10n.tr("Localizable", "Scene.ConfirmEmail.OpenEmailApp.Mail")
        /// Open Email Client
        internal static let openEmailClient = L10n.tr("Localizable", "Scene.ConfirmEmail.OpenEmailApp.OpenEmailClient")
        /// Check your inbox.
        internal static let title = L10n.tr("Localizable", "Scene.ConfirmEmail.OpenEmailApp.Title")
      }
    }
    internal enum HomeTimeline {
      /// Home
      internal static let title = L10n.tr("Localizable", "Scene.HomeTimeline.Title")
    }
    internal enum PublicTimeline {
      /// Public
      internal static let title = L10n.tr("Localizable", "Scene.PublicTimeline.Title")
    }
    internal enum Register {
      /// Regsiter request sent. Please check your email.
      internal static let checkEmail = L10n.tr("Localizable", "Scene.Register.CheckEmail")
      /// Success
      internal static let success = L10n.tr("Localizable", "Scene.Register.Success")
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
        internal enum Invite {
          /// Why do you want to join?
          internal static let registrationUserInviteRequest = L10n.tr("Localizable", "Scene.Register.Input.Invite.RegistrationUserInviteRequest")
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
        /// See Less
        internal static let seeless = L10n.tr("Localizable", "Scene.ServerPicker.Button.Seeless")
        /// See More
        internal static let seemore = L10n.tr("Localizable", "Scene.ServerPicker.Button.Seemore")
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
