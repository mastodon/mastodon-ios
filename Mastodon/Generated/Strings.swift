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
      internal enum Common {
        /// Please try again.
        internal static let pleaseTryAgain = L10n.tr("Localizable", "Common.Alerts.Common.PleaseTryAgain")
        /// Please try again later.
        internal static let pleaseTryAgainLater = L10n.tr("Localizable", "Common.Alerts.Common.PleaseTryAgainLater")
      }
      internal enum DiscardPostContent {
        /// Confirm discard composed post content.
        internal static let message = L10n.tr("Localizable", "Common.Alerts.DiscardPostContent.Message")
        /// Discard Publish
        internal static let title = L10n.tr("Localizable", "Common.Alerts.DiscardPostContent.Title")
      }
      internal enum PublishPostFailure {
        /// Failed to publish the post.\nPlease check your internet connection.
        internal static let message = L10n.tr("Localizable", "Common.Alerts.PublishPostFailure.Message")
        /// Publish Failure
        internal static let title = L10n.tr("Localizable", "Common.Alerts.PublishPostFailure.Title")
      }
      internal enum ServerError {
        /// Server Error
        internal static let title = L10n.tr("Localizable", "Common.Alerts.ServerError.Title")
      }
      internal enum SignUpFailure {
        /// Sign Up Failure
        internal static let title = L10n.tr("Localizable", "Common.Alerts.SignUpFailure.Title")
      }
      internal enum VoteFailure {
        /// The poll has expired
        internal static let pollExpired = L10n.tr("Localizable", "Common.Alerts.VoteFailure.PollExpired")
        /// Vote Failure
        internal static let title = L10n.tr("Localizable", "Common.Alerts.VoteFailure.Title")
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
        /// Discard
        internal static let discard = L10n.tr("Localizable", "Common.Controls.Actions.Discard")
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
        /// Try Again
        internal static let tryAgain = L10n.tr("Localizable", "Common.Controls.Actions.TryAgain")
      }
      internal enum Status {
        /// Tap to reveal that may be sensitive
        internal static let mediaContentWarning = L10n.tr("Localizable", "Common.Controls.Status.MediaContentWarning")
        /// Show Post
        internal static let showPost = L10n.tr("Localizable", "Common.Controls.Status.ShowPost")
        /// content warning
        internal static let statusContentWarning = L10n.tr("Localizable", "Common.Controls.Status.StatusContentWarning")
        /// %@ reblogged
        internal static func userReblogged(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Status.UserReblogged", String(describing: p1))
        }
        /// Replied to %@
        internal static func userRepliedTo(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Status.UserRepliedTo", String(describing: p1))
        }
        internal enum Poll {
          /// Closed
          internal static let closed = L10n.tr("Localizable", "Common.Controls.Status.Poll.Closed")
          /// %@ left
          internal static func timeLeft(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Status.Poll.TimeLeft", String(describing: p1))
          }
          /// Vote
          internal static let vote = L10n.tr("Localizable", "Common.Controls.Status.Poll.Vote")
          internal enum VoteCount {
            /// %d votes
            internal static func multiple(_ p1: Int) -> String {
              return L10n.tr("Localizable", "Common.Controls.Status.Poll.VoteCount.Multiple", p1)
            }
            /// %d vote
            internal static func single(_ p1: Int) -> String {
              return L10n.tr("Localizable", "Common.Controls.Status.Poll.VoteCount.Single", p1)
            }
          }
          internal enum VoterCount {
            /// %d voters
            internal static func multiple(_ p1: Int) -> String {
              return L10n.tr("Localizable", "Common.Controls.Status.Poll.VoterCount.Multiple", p1)
            }
            /// %d voter
            internal static func single(_ p1: Int) -> String {
              return L10n.tr("Localizable", "Common.Controls.Status.Poll.VoterCount.Single", p1)
            }
          }
        }
      }
      internal enum Timeline {
        internal enum Loader {
          /// Loading missing posts...
          internal static let loadingMissingPosts = L10n.tr("Localizable", "Common.Controls.Timeline.Loader.LoadingMissingPosts")
          /// Load missing posts
          internal static let loadMissingPosts = L10n.tr("Localizable", "Common.Controls.Timeline.Loader.LoadMissingPosts")
        }
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
    internal enum Compose {
      /// Publish
      internal static let composeAction = L10n.tr("Localizable", "Scene.Compose.ComposeAction")
      /// Type or paste what's on your mind
      internal static let contentInputPlaceholder = L10n.tr("Localizable", "Scene.Compose.ContentInputPlaceholder")
      internal enum Attachment {
        /// This %@ is broken and can't be\nuploaded to Mastodon.
        internal static func attachmentBroken(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Scene.Compose.Attachment.AttachmentBroken", String(describing: p1))
        }
        /// Describe photo for low vision people...
        internal static let descriptionPhoto = L10n.tr("Localizable", "Scene.Compose.Attachment.DescriptionPhoto")
        /// Describe what’s happening for low vision people...
        internal static let descriptionVideo = L10n.tr("Localizable", "Scene.Compose.Attachment.DescriptionVideo")
        /// photo
        internal static let photo = L10n.tr("Localizable", "Scene.Compose.Attachment.Photo")
        /// video
        internal static let video = L10n.tr("Localizable", "Scene.Compose.Attachment.Video")
      }
      internal enum ContentWarning {
        /// Write an accurate warning here...
        internal static let placeholder = L10n.tr("Localizable", "Scene.Compose.ContentWarning.Placeholder")
      }
      internal enum MediaSelection {
        /// Browse
        internal static let browse = L10n.tr("Localizable", "Scene.Compose.MediaSelection.Browse")
        /// Take Photo
        internal static let camera = L10n.tr("Localizable", "Scene.Compose.MediaSelection.Camera")
        /// Photo Library
        internal static let photoLibrary = L10n.tr("Localizable", "Scene.Compose.MediaSelection.PhotoLibrary")
      }
      internal enum Poll {
        /// Duration: %@
        internal static func durationTime(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Scene.Compose.Poll.DurationTime", String(describing: p1))
        }
        /// 1 Day
        internal static let oneDay = L10n.tr("Localizable", "Scene.Compose.Poll.OneDay")
        /// 1 Hour
        internal static let oneHour = L10n.tr("Localizable", "Scene.Compose.Poll.OneHour")
        /// 7 Days
        internal static let sevenDays = L10n.tr("Localizable", "Scene.Compose.Poll.SevenDays")
        /// 6 Hours
        internal static let sixHours = L10n.tr("Localizable", "Scene.Compose.Poll.SixHours")
        /// 30 minutes
        internal static let thirtyMinutes = L10n.tr("Localizable", "Scene.Compose.Poll.ThirtyMinutes")
        /// 3 Days
        internal static let threeDays = L10n.tr("Localizable", "Scene.Compose.Poll.ThreeDays")
      }
      internal enum Title {
        /// New Post
        internal static let newPost = L10n.tr("Localizable", "Scene.Compose.Title.NewPost")
        /// New Reply
        internal static let newReply = L10n.tr("Localizable", "Scene.Compose.Title.NewReply")
      }
      internal enum Visibility {
        /// Only people I mention
        internal static let direct = L10n.tr("Localizable", "Scene.Compose.Visibility.Direct")
        /// Followers only
        internal static let `private` = L10n.tr("Localizable", "Scene.Compose.Visibility.Private")
        /// Public
        internal static let `public` = L10n.tr("Localizable", "Scene.Compose.Visibility.Public")
        /// Unlisted
        internal static let unlisted = L10n.tr("Localizable", "Scene.Compose.Visibility.Unlisted")
      }
    }
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
      internal enum NavigationBarState {
        /// See new posts
        internal static let newPosts = L10n.tr("Localizable", "Scene.HomeTimeline.NavigationBarState.NewPosts")
        /// Offline
        internal static let offline = L10n.tr("Localizable", "Scene.HomeTimeline.NavigationBarState.Offline")
        /// Published!
        internal static let published = L10n.tr("Localizable", "Scene.HomeTimeline.NavigationBarState.Published")
        /// Publishing post...
        internal static let publishing = L10n.tr("Localizable", "Scene.HomeTimeline.NavigationBarState.Publishing")
      }
    }
    internal enum PublicTimeline {
      /// Public
      internal static let title = L10n.tr("Localizable", "Scene.PublicTimeline.Title")
    }
    internal enum Register {
      /// Tell us about you.
      internal static let title = L10n.tr("Localizable", "Scene.Register.Title")
      internal enum Error {
        internal enum Item {
          /// Agreement
          internal static let agreement = L10n.tr("Localizable", "Scene.Register.Error.Item.Agreement")
          /// Email
          internal static let email = L10n.tr("Localizable", "Scene.Register.Error.Item.Email")
          /// Locale
          internal static let locale = L10n.tr("Localizable", "Scene.Register.Error.Item.Locale")
          /// Password
          internal static let password = L10n.tr("Localizable", "Scene.Register.Error.Item.Password")
          /// Reason
          internal static let reason = L10n.tr("Localizable", "Scene.Register.Error.Item.Reason")
          /// Username
          internal static let username = L10n.tr("Localizable", "Scene.Register.Error.Item.Username")
        }
        internal enum Reason {
          /// %@ must be accepted
          internal static func accepted(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Register.Error.Reason.Accepted", String(describing: p1))
          }
          /// %@ is required
          internal static func blank(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Register.Error.Reason.Blank", String(describing: p1))
          }
          /// %@ contains a disallowed e-mail provider
          internal static func blocked(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Register.Error.Reason.Blocked", String(describing: p1))
          }
          /// %@ is not a supported value
          internal static func inclusion(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Register.Error.Reason.Inclusion", String(describing: p1))
          }
          /// %@ is invalid
          internal static func invalid(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Register.Error.Reason.Invalid", String(describing: p1))
          }
          /// %@ is a reserved keyword
          internal static func reserved(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Register.Error.Reason.Reserved", String(describing: p1))
          }
          /// %@ is already in use
          internal static func taken(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Register.Error.Reason.Taken", String(describing: p1))
          }
          /// %@ is too long
          internal static func tooLong(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Register.Error.Reason.TooLong", String(describing: p1))
          }
          /// %@ is too short
          internal static func tooShort(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Register.Error.Reason.TooShort", String(describing: p1))
          }
          /// %@ does not seem to exist
          internal static func unreachable(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Register.Error.Reason.Unreachable", String(describing: p1))
          }
        }
        internal enum Special {
          /// This is not a valid e-mail address
          internal static let emailInvalid = L10n.tr("Localizable", "Scene.Register.Error.Special.EmailInvalid")
          /// Password is too short (must be at least 8 characters)
          internal static let passwordTooShort = L10n.tr("Localizable", "Scene.Register.Error.Special.PasswordTooShort")
          /// Username must only contain alphanumeric characters and underscores
          internal static let usernameInvalid = L10n.tr("Localizable", "Scene.Register.Error.Special.UsernameInvalid")
          /// Username is too long (can't be longer than 30 characters)
          internal static let usernameTooLong = L10n.tr("Localizable", "Scene.Register.Error.Special.UsernameTooLong")
        }
      }
      internal enum Input {
        internal enum Avatar {
          /// delete
          internal static let delete = L10n.tr("Localizable", "Scene.Register.Input.Avatar.Delete")
        }
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
          /// Your password needs at least eight characters
          internal static let hint = L10n.tr("Localizable", "Scene.Register.Input.Password.Hint")
          /// password
          internal static let placeholder = L10n.tr("Localizable", "Scene.Register.Input.Password.Placeholder")
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
        internal static let seeLess = L10n.tr("Localizable", "Scene.ServerPicker.Button.SeeLess")
        /// See More
        internal static let seeMore = L10n.tr("Localizable", "Scene.ServerPicker.Button.SeeMore")
        internal enum Category {
          /// All
          internal static let all = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.All")
        }
      }
      internal enum EmptyState {
        /// Something went wrong while loading data. Check your internet connection.
        internal static let badNetwork = L10n.tr("Localizable", "Scene.ServerPicker.EmptyState.BadNetwork")
        /// Finding available servers...
        internal static let findingServers = L10n.tr("Localizable", "Scene.ServerPicker.EmptyState.FindingServers")
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
