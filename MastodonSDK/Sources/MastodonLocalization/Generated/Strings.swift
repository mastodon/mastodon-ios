// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum L10n {
  public enum Common {
    public enum Alerts {
      public enum BlockDomain {
        /// Block Domain
          public static let blockEntireDomain = String(localized: "Common.Alerts.BlockDomain.BlockEntireDomain", bundle: MastodonLocalization.bundle)
        public static func title(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Common.Alerts.BlockDomain.Title.\(placeholder: .object)"), args: [String(describing: p1)]) //"Are you really, really sure you want to block the entire %@? In most cases a few targeted blocks or mutes are sufficient and preferable. You will not see content from that domain and any of your followers from that domain will be removed."
        }
      }
      public enum BoostAPost {
        /// Boost
        public static let boost = String(localized: "Common.Alerts.BoostAPost.Boost",  defaultValue: "Boost", bundle: MastodonLocalization.bundle)
        /// Cancel
        public static let cancel = String(localized: "Common.Alerts.BoostAPost.Cancel",  defaultValue: "Cancel", bundle: MastodonLocalization.bundle)
        /// Boost Post?
        public static let titleBoost = String(localized: "Common.Alerts.BoostAPost.TitleBoost",  defaultValue: "Boost Post?", bundle: MastodonLocalization.bundle)
        /// Unboost Post?
        public static let titleUnboost = String(localized: "Common.Alerts.BoostAPost.TitleUnboost",  defaultValue: "Unboost Post?", bundle: MastodonLocalization.bundle)
        /// Unboost
        public static let unboost = String(localized: "Common.Alerts.BoostAPost.Unboost",  defaultValue: "Unboost", bundle: MastodonLocalization.bundle)
      }
      public enum CleanCache {
        /// Successfully cleaned %@ cache.
        public static func message(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Common.Alerts.CleanCache.Message.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// Clean Cache
        public static let title = String(localized: "Common.Alerts.CleanCache.Title",  defaultValue: "Clean Cache", bundle: MastodonLocalization.bundle)
      }
      public enum Common {
        /// Please try again.
        public static let pleaseTryAgain = String(localized: "Common.Alerts.Common.PleaseTryAgain",  defaultValue: "Please try again.", bundle: MastodonLocalization.bundle)
        /// Please try again later.
        public static let pleaseTryAgainLater = String(localized: "Common.Alerts.Common.PleaseTryAgainLater",  defaultValue: "Please try again later.", bundle: MastodonLocalization.bundle)
      }
      public enum DeletePost {
        /// Are you sure you want to delete this post?
        public static let message = String(localized: "Common.Alerts.DeletePost.Message",  defaultValue: "Are you sure you want to delete this post?", bundle: MastodonLocalization.bundle)
        /// Delete Post
        public static let title = String(localized: "Common.Alerts.DeletePost.Title",  defaultValue: "Delete Post", bundle: MastodonLocalization.bundle)
      }
      public enum EditProfileFailure {
        /// Cannot edit profile. Please try again.
        public static let message = String(localized: "Common.Alerts.EditProfileFailure.Message",  defaultValue: "Cannot edit profile. Please try again.", bundle: MastodonLocalization.bundle)
        /// Edit Profile Error
        public static let title = String(localized: "Common.Alerts.EditProfileFailure.Title",  defaultValue: "Edit Profile Error", bundle: MastodonLocalization.bundle)
      }
      public enum MediaMissingAltText {
        /// Cancel
        public static let cancel = String(localized: "Common.Alerts.MediaMissingAltText.Cancel",  defaultValue: "Cancel", bundle: MastodonLocalization.bundle)
        /// %d of your images are missing alt text.
        /// Post Anyway?
        public static func message(_ p1: Int) -> String {
            return L10n.tr(String.LocalizationValue("Common.Alerts.MediaMissingAltText.Message.\(placeholder: .int)"), args: [p1])
        }
        /// Post
        public static let post = String(localized: "Common.Alerts.MediaMissingAltText.Post",  defaultValue: "Post", bundle: MastodonLocalization.bundle)
        /// Media Missing Alt Text
        public static let title = String(localized: "Common.Alerts.MediaMissingAltText.Title",  defaultValue: "Media Missing Alt Text", bundle: MastodonLocalization.bundle)
      }
      public enum PublishPostFailure {
        /// Failed to publish the post.
        /// Please check your internet connection.
        public static let message = String(localized: "Common.Alerts.PublishPostFailure.Message",  defaultValue: "Failed to publish the post.\nPlease check your internet connection.", bundle: MastodonLocalization.bundle)
        /// Publish Failure
        public static let title = String(localized: "Common.Alerts.PublishPostFailure.Title",  defaultValue: "Publish Failure", bundle: MastodonLocalization.bundle)
        public enum AttachmentsMessage {
          /// Cannot attach more than one video.
          public static let moreThanOneVideo = String(localized: "Common.Alerts.PublishPostFailure.AttachmentsMessage.MoreThanOneVideo",  defaultValue: "Cannot attach more than one video.", bundle: MastodonLocalization.bundle)
          /// Cannot attach a video to a post that already contains images.
          public static let videoAttachWithPhoto = String(localized: "Common.Alerts.PublishPostFailure.AttachmentsMessage.VideoAttachWithPhoto",  defaultValue: "Cannot attach a video to a post that already contains images.", bundle: MastodonLocalization.bundle)
        }
      }
      public enum SavePhotoFailure {
        /// Please enable the photo library access permission to save the photo.
        public static let message = String(localized: "Common.Alerts.SavePhotoFailure.Message",  defaultValue: "Please enable the photo library access permission to save the photo.", bundle: MastodonLocalization.bundle)
        /// Save Photo Failure
        public static let title = String(localized: "Common.Alerts.SavePhotoFailure.Title",  defaultValue: "Save Photo Failure", bundle: MastodonLocalization.bundle)
      }
      public enum ServerError {
        /// Server Error
        public static let title = String(localized: "Common.Alerts.ServerError.Title",  defaultValue: "Server Error", bundle: MastodonLocalization.bundle)
      }
      public enum SignOut {
        /// Sign Out
        public static let confirm = String(localized: "Common.Alerts.SignOut.Confirm",  defaultValue: "Sign Out", bundle: MastodonLocalization.bundle)
        /// Are you sure you want to sign out?
        public static let message = String(localized: "Common.Alerts.SignOut.Message",  defaultValue: "Are you sure you want to sign out?", bundle: MastodonLocalization.bundle)
        /// Sign Out
        public static let title = String(localized: "Common.Alerts.SignOut.Title",  defaultValue: "Sign Out", bundle: MastodonLocalization.bundle)
      }
      public enum SignUpFailure {
        /// Sign Up Failure
        public static let title = String(localized: "Common.Alerts.SignUpFailure.Title",  defaultValue: "Sign Up Failure", bundle: MastodonLocalization.bundle)
      }
      public enum TranslationFailed {
        /// OK
        public static let button = String(localized: "Common.Alerts.TranslationFailed.Button",  defaultValue: "OK", bundle: MastodonLocalization.bundle)
        /// Translation failed. Maybe the administrator has not enabled translations on this server or this server is running an older version of Mastodon where translations are not yet supported.
        public static let message = String(localized: "Common.Alerts.TranslationFailed.Message",  defaultValue: "Translation failed. Maybe the administrator has not enabled translations on this server or this server is running an older version of Mastodon where translations are not yet supported.", bundle: MastodonLocalization.bundle)
        /// Note
        public static let title = String(localized: "Common.Alerts.TranslationFailed.Title",  defaultValue: "Note", bundle: MastodonLocalization.bundle)
      }
      public enum UnfollowUser {
        /// Cancel
        public static let cancel = String(localized: "Common.Alerts.UnfollowUser.Cancel",  defaultValue: "Cancel", bundle: MastodonLocalization.bundle)
        /// Unfollow %@?
        public static func title(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Common.Alerts.UnfollowUser.Title.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// Unfollow
        public static let unfollow = String(localized: "Common.Alerts.UnfollowUser.Unfollow",  defaultValue: "Unfollow", bundle: MastodonLocalization.bundle)
      }
      public enum VoteFailure {
        /// The poll has ended
        public static let pollEnded = String(localized: "Common.Alerts.VoteFailure.PollEnded",  defaultValue: "The poll has ended", bundle: MastodonLocalization.bundle)
        /// Vote Failure
        public static let title = String(localized: "Common.Alerts.VoteFailure.Title",  defaultValue: "Vote Failure", bundle: MastodonLocalization.bundle)
      }
    }
    public enum Controls {
      public enum Actions {
        /// Add
        public static let add = String(localized: "Common.Controls.Actions.Add",  defaultValue: "Add", bundle: MastodonLocalization.bundle)
        /// Back
        public static let back = String(localized: "Common.Controls.Actions.Back",  defaultValue: "Back", bundle: MastodonLocalization.bundle)
        /// Block %@
        public static func blockDomain(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Common.Controls.Actions.BlockDomain.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// Bookmark
        public static let bookmark = String(localized: "Common.Controls.Actions.Bookmark",  defaultValue: "Bookmark", bundle: MastodonLocalization.bundle)
        /// Cancel
        public static let cancel = String(localized: "Common.Controls.Actions.Cancel",  defaultValue: "Cancel", bundle: MastodonLocalization.bundle)
        /// Compose
        public static let compose = String(localized: "Common.Controls.Actions.Compose",  defaultValue: "Compose", bundle: MastodonLocalization.bundle)
        /// Confirm
        public static let confirm = String(localized: "Common.Controls.Actions.Confirm",  defaultValue: "Confirm", bundle: MastodonLocalization.bundle)
        /// Continue
        public static let `continue` = String(localized: "Common.Controls.Actions.Continue",  defaultValue: "Continue", bundle: MastodonLocalization.bundle)
        /// Copy
        public static let copy = String(localized: "Common.Controls.Actions.Copy",  defaultValue: "Copy", bundle: MastodonLocalization.bundle)
        /// Copy Photo
        public static let copyPhoto = String(localized: "Common.Controls.Actions.CopyPhoto",  defaultValue: "Copy Photo", bundle: MastodonLocalization.bundle)
        /// Delete
        public static let delete = String(localized: "Common.Controls.Actions.Delete",  defaultValue: "Delete", bundle: MastodonLocalization.bundle)
        /// Discard
        public static let discard = String(localized: "Common.Controls.Actions.Discard",  defaultValue: "Discard", bundle: MastodonLocalization.bundle)
        /// Done
        public static let done = String(localized: "Common.Controls.Actions.Done",  defaultValue: "Done", bundle: MastodonLocalization.bundle)
        /// Edit
        public static let edit = String(localized: "Common.Controls.Actions.Edit",  defaultValue: "Edit", bundle: MastodonLocalization.bundle)
        /// Edit
        public static let editPost = String(localized: "Common.Controls.Actions.EditPost",  defaultValue: "Edit", bundle: MastodonLocalization.bundle)
        /// Find people to follow
        public static let findPeople = String(localized: "Common.Controls.Actions.FindPeople",  defaultValue: "Find people to follow", bundle: MastodonLocalization.bundle)
        /// Follow %@
        public static func follow(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Common.Controls.Actions.Follow.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// Manually search instead
        public static let manuallySearch = String(localized: "Common.Controls.Actions.ManuallySearch",  defaultValue: "Manually search instead", bundle: MastodonLocalization.bundle)
        /// Next
        public static let next = String(localized: "Common.Controls.Actions.Next",  defaultValue: "Next", bundle: MastodonLocalization.bundle)
        /// OK
        public static let ok = String(localized: "Common.Controls.Actions.Ok",  defaultValue: "OK", bundle: MastodonLocalization.bundle)
        /// Open
        public static let `open` = String(localized: "Common.Controls.Actions.Open",  defaultValue: "Open", bundle: MastodonLocalization.bundle)
        /// Open in Browser
        public static let openInBrowser = String(localized: "Common.Controls.Actions.OpenInBrowser",  defaultValue: "Open in Browser", bundle: MastodonLocalization.bundle)
        /// Open in Safari
        public static let openInSafari = String(localized: "Common.Controls.Actions.OpenInSafari",  defaultValue: "Open in Safari", bundle: MastodonLocalization.bundle)
        /// Preview
        public static let preview = String(localized: "Common.Controls.Actions.Preview",  defaultValue: "Preview", bundle: MastodonLocalization.bundle)
        /// Previous
        public static let previous = String(localized: "Common.Controls.Actions.Previous",  defaultValue: "Previous", bundle: MastodonLocalization.bundle)
        /// Remove
        public static let remove = String(localized: "Common.Controls.Actions.Remove",  defaultValue: "Remove", bundle: MastodonLocalization.bundle)
        /// Remove Bookmark
        public static let removeBookmark = String(localized: "Common.Controls.Actions.RemoveBookmark",  defaultValue: "Remove Bookmark", bundle: MastodonLocalization.bundle)
        /// Reply
        public static let reply = String(localized: "Common.Controls.Actions.Reply",  defaultValue: "Reply", bundle: MastodonLocalization.bundle)
        /// Report %@
        public static func reportUser(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Common.Controls.Actions.ReportUser.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// Save
        public static let save = String(localized: "Common.Controls.Actions.Save",  defaultValue: "Save", bundle: MastodonLocalization.bundle)
        /// Save Photo
        public static let savePhoto = String(localized: "Common.Controls.Actions.SavePhoto",  defaultValue: "Save Photo", bundle: MastodonLocalization.bundle)
        /// See More
        public static let seeMore = String(localized: "Common.Controls.Actions.SeeMore",  defaultValue: "See More", bundle: MastodonLocalization.bundle)
        /// Settings
        public static let settings = String(localized: "Common.Controls.Actions.Settings",  defaultValue: "Settings", bundle: MastodonLocalization.bundle)
        /// Share
        public static let share = String(localized: "Common.Controls.Actions.Share",  defaultValue: "Share", bundle: MastodonLocalization.bundle)
        /// Share Post
        public static let sharePost = String(localized: "Common.Controls.Actions.SharePost",  defaultValue: "Share Post", bundle: MastodonLocalization.bundle)
        /// Share %@
        public static func shareUser(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Common.Controls.Actions.ShareUser.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// Log in
        public static let signIn = String(localized: "Common.Controls.Actions.SignIn",  defaultValue: "Log in", bundle: MastodonLocalization.bundle)
        /// Skip
        public static let skip = String(localized: "Common.Controls.Actions.Skip",  defaultValue: "Skip", bundle: MastodonLocalization.bundle)
        /// Take Photo
        public static let takePhoto = String(localized: "Common.Controls.Actions.TakePhoto",  defaultValue: "Take Photo", bundle: MastodonLocalization.bundle)
        /// Try Again
        public static let tryAgain = String(localized: "Common.Controls.Actions.TryAgain",  defaultValue: "Try Again", bundle: MastodonLocalization.bundle)
        /// Unblock %@
        public static func unblockDomain(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Common.Controls.Actions.UnblockDomain.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// Unfollow %@
        public static func unfollow(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Common.Controls.Actions.Unfollow.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        public enum TranslatePost {
          /// Translate from %@
          public static func title(_ p1: Any) -> String {
              return L10n.tr(String.LocalizationValue("Common.Controls.Actions.TranslatePost.Title.\(placeholder: .object)"), args: [String(describing: p1)])
          }
          /// Unknown
          public static let unknownLanguage = String(localized: "Common.Controls.Actions.TranslatePost.UnknownLanguage",  defaultValue: "Unknown", bundle: MastodonLocalization.bundle)
        }
      }
      public enum Friendship {
        /// Block
        public static let block = String(localized: "Common.Controls.Friendship.Block",  defaultValue: "Block", bundle: MastodonLocalization.bundle)
        /// Block domain %@
        public static func blockDomain(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Common.Controls.Friendship.BlockDomain.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// Blocked
        public static let blocked = String(localized: "Common.Controls.Friendship.Blocked",  defaultValue: "Blocked", bundle: MastodonLocalization.bundle)
        /// Block %@
        public static func blockUser(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Common.Controls.Friendship.BlockUser.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// Domain Blocked
        public static let domainBlocked = String(localized: "Common.Controls.Friendship.DomainBlocked",  defaultValue: "Domain Blocked", bundle: MastodonLocalization.bundle)
        /// Edit Info
        public static let editInfo = String(localized: "Common.Controls.Friendship.EditInfo",  defaultValue: "Edit Info", bundle: MastodonLocalization.bundle)
        /// Follow
        public static let follow = String(localized: "Common.Controls.Friendship.Follow",  defaultValue: "Follow", bundle: MastodonLocalization.bundle)
        /// Follow back
        public static let followBack = String(localized: "Common.Controls.Friendship.FollowBack",  defaultValue: "Follow back", bundle: MastodonLocalization.bundle)
        /// Following
        public static let following = String(localized: "Common.Controls.Friendship.Following",  defaultValue: "Following", bundle: MastodonLocalization.bundle)
        /// Hide Boosts
        public static let hideReblogs = String(localized: "Common.Controls.Friendship.HideReblogs",  defaultValue: "Hide Boosts", bundle: MastodonLocalization.bundle)
        /// Mute
        public static let mute = String(localized: "Common.Controls.Friendship.Mute",  defaultValue: "Mute", bundle: MastodonLocalization.bundle)
        /// Muted
        public static let muted = String(localized: "Common.Controls.Friendship.Muted",  defaultValue: "Muted", bundle: MastodonLocalization.bundle)
        /// Mute %@
        public static func muteUser(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Common.Controls.Friendship.MuteUser.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// Mutual
        public static let mutual = String(localized: "Common.Controls.Friendship.Mutual",  defaultValue: "Mutual", bundle: MastodonLocalization.bundle)
        /// Pending
        public static let pending = String(localized: "Common.Controls.Friendship.Pending",  defaultValue: "Pending", bundle: MastodonLocalization.bundle)
        /// Request
        public static let request = String(localized: "Common.Controls.Friendship.Request",  defaultValue: "Request", bundle: MastodonLocalization.bundle)
        /// Show Boosts
        public static let showReblogs = String(localized: "Common.Controls.Friendship.ShowReblogs",  defaultValue: "Show Boosts", bundle: MastodonLocalization.bundle)
        /// Unblock
        public static let unblock = String(localized: "Common.Controls.Friendship.Unblock",  defaultValue: "Unblock", bundle: MastodonLocalization.bundle)
        /// Unblock %@
        public static func unblockUser(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Common.Controls.Friendship.UnblockUser.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// Unmute
        public static let unmute = String(localized: "Common.Controls.Friendship.Unmute",  defaultValue: "Unmute", bundle: MastodonLocalization.bundle)
        /// Unmute %@
        public static func unmuteUser(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Common.Controls.Friendship.UnmuteUser.\(placeholder: .object)"), args: [String(describing: p1)])
        }
      }
      public enum Keyboard {
        public enum Common {
          /// Compose New Post
          public static let composeNewPost = String(localized: "Common.Controls.Keyboard.Common.ComposeNewPost",  defaultValue: "Compose New Post", bundle: MastodonLocalization.bundle)
          /// Open Settings
          public static let openSettings = String(localized: "Common.Controls.Keyboard.Common.OpenSettings",  defaultValue: "Open Settings", bundle: MastodonLocalization.bundle)
          /// Show Favorites
          public static let showFavorites = String(localized: "Common.Controls.Keyboard.Common.ShowFavorites",  defaultValue: "Show Favorites", bundle: MastodonLocalization.bundle)
          /// Switch to %@
          public static func switchToTab(_ p1: Any) -> String {
              return L10n.tr(String.LocalizationValue("Common.Controls.Keyboard.Common.SwitchToTab.\(placeholder: .object)"), args: [String(describing: p1)])
          }
        }
        public enum SegmentedControl {
          /// Next Section
          public static let nextSection = String(localized: "Common.Controls.Keyboard.SegmentedControl.NextSection",  defaultValue: "Next Section", bundle: MastodonLocalization.bundle)
          /// Previous Section
          public static let previousSection = String(localized: "Common.Controls.Keyboard.SegmentedControl.PreviousSection",  defaultValue: "Previous Section", bundle: MastodonLocalization.bundle)
        }
        public enum Timeline {
          /// Next Post
          public static let nextStatus = String(localized: "Common.Controls.Keyboard.Timeline.NextStatus",  defaultValue: "Next Post", bundle: MastodonLocalization.bundle)
          /// Open Author's Profile
          public static let openAuthorProfile = String(localized: "Common.Controls.Keyboard.Timeline.OpenAuthorProfile",  defaultValue: "Open Author's Profile", bundle: MastodonLocalization.bundle)
          /// Open Booster's Profile
          public static let openRebloggerProfile = String(localized: "Common.Controls.Keyboard.Timeline.OpenRebloggerProfile",  defaultValue: "Open Booster's Profile", bundle: MastodonLocalization.bundle)
          /// Open Post
          public static let openStatus = String(localized: "Common.Controls.Keyboard.Timeline.OpenStatus",  defaultValue: "Open Post", bundle: MastodonLocalization.bundle)
          /// Preview Image
          public static let previewImage = String(localized: "Common.Controls.Keyboard.Timeline.PreviewImage",  defaultValue: "Preview Image", bundle: MastodonLocalization.bundle)
          /// Previous Post
          public static let previousStatus = String(localized: "Common.Controls.Keyboard.Timeline.PreviousStatus",  defaultValue: "Previous Post", bundle: MastodonLocalization.bundle)
          /// Reply to Post
          public static let replyStatus = String(localized: "Common.Controls.Keyboard.Timeline.ReplyStatus",  defaultValue: "Reply to Post", bundle: MastodonLocalization.bundle)
          /// Toggle Content Warning
          public static let toggleContentWarning = String(localized: "Common.Controls.Keyboard.Timeline.ToggleContentWarning",  defaultValue: "Toggle Content Warning", bundle: MastodonLocalization.bundle)
          /// Toggle Favorite on Post
          public static let toggleFavorite = String(localized: "Common.Controls.Keyboard.Timeline.ToggleFavorite",  defaultValue: "Toggle Favorite on Post", bundle: MastodonLocalization.bundle)
          /// Toggle Boost on Post
          public static let toggleReblog = String(localized: "Common.Controls.Keyboard.Timeline.ToggleReblog",  defaultValue: "Toggle Boost on Post", bundle: MastodonLocalization.bundle)
        }
      }
      public enum Status {
        /// Content Warning
        public static let contentWarning = String(localized: "Common.Controls.Status.ContentWarning",  defaultValue: "Content Warning", bundle: MastodonLocalization.bundle)
        /// Edited %@
        public static func editedAtTimestampPrefix(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Common.Controls.Status.EditedAtTimestampPrefix.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// %@ via %@
        public static func linkViaUser(_ p1: Any, _ p2: Any) -> String {
            return L10n.tr(String.LocalizationValue("Common.Controls.Status.LinkViaUser.\(placeholder: .object).\(placeholder: .object)"), args: [String(describing: p1), String(describing: p2)])
        }
        /// Load Embed
        public static let loadEmbed = String(localized: "Common.Controls.Status.LoadEmbed",  defaultValue: "Load Embed", bundle: MastodonLocalization.bundle)
        /// Matches filter: "%@"
        public static func matchesFilter(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Common.Controls.Status.MatchesFilter.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// Tap anywhere to reveal
        public static let mediaContentWarning = String(localized: "Common.Controls.Status.MediaContentWarning",  defaultValue: "Tap anywhere to reveal", bundle: MastodonLocalization.bundle)
        /// Mention
        public static let mention = String(localized: "Common.Controls.Status.Mention",  defaultValue: "Mention", bundle: MastodonLocalization.bundle)
        /// %@ via %@
        public static func postedViaApplication(_ p1: Any, _ p2: Any) -> String {
            return L10n.tr(String.LocalizationValue("Common.Controls.Status.PostedViaApplication.\(placeholder: .object).\(placeholder: .object)"), args: [String(describing: p1), String(describing: p2)])
        }
        /// Private mention
        public static let privateMention = String(localized: "Common.Controls.Status.PrivateMention",  defaultValue: "Private mention", bundle: MastodonLocalization.bundle)
        /// Private reply
        public static let privateReply = String(localized: "Common.Controls.Status.PrivateReply",  defaultValue: "Private reply", bundle: MastodonLocalization.bundle)
        /// Reply
        public static let reply = String(localized: "Common.Controls.Status.Reply",  defaultValue: "Reply", bundle: MastodonLocalization.bundle)
        /// Sensitive Content
        public static let sensitiveContent = String(localized: "Common.Controls.Status.SensitiveContent",  defaultValue: "Sensitive Content", bundle: MastodonLocalization.bundle)
        /// Show anyway
        public static let showAnyway = String(localized: "Common.Controls.Status.ShowAnyway",  defaultValue: "Show anyway", bundle: MastodonLocalization.bundle)
        /// Show more
        public static let showMore = String(localized: "Common.Controls.Status.ShowMore",  defaultValue: "Show more", bundle: MastodonLocalization.bundle)
        /// Show Post
        public static let showPost = String(localized: "Common.Controls.Status.ShowPost",  defaultValue: "Show Post", bundle: MastodonLocalization.bundle)
        /// Show user profile
        public static let showUserProfile = String(localized: "Common.Controls.Status.ShowUserProfile",  defaultValue: "Show user profile", bundle: MastodonLocalization.bundle)
        /// Tap to reveal
        public static let tapToReveal = String(localized: "Common.Controls.Status.TapToReveal",  defaultValue: "Tap to reveal", bundle: MastodonLocalization.bundle)
        /// %@ boosted
        public static func userReblogged(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Common.Controls.Status.UserReblogged.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// Replied to %@
        public static func userRepliedTo(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Common.Controls.Status.UserRepliedTo.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        public enum Actions {
          /// Copy Link
          public static let copyLink = String(localized: "Common.Controls.Status.Actions.CopyLink",  defaultValue: "Copy Link", bundle: MastodonLocalization.bundle)
          /// Favorite
          public static let favorite = String(localized: "Common.Controls.Status.Actions.Favorite",  defaultValue: "Favorite", bundle: MastodonLocalization.bundle)
          /// Hide
          public static let hide = String(localized: "Common.Controls.Status.Actions.Hide",  defaultValue: "Hide", bundle: MastodonLocalization.bundle)
          /// Menu
          public static let menu = String(localized: "Common.Controls.Status.Actions.Menu",  defaultValue: "Menu", bundle: MastodonLocalization.bundle)
          /// Boost
          public static let reblog = String(localized: "Common.Controls.Status.Actions.Reblog",  defaultValue: "Boost", bundle: MastodonLocalization.bundle)
          /// Reply
          public static let reply = String(localized: "Common.Controls.Status.Actions.Reply",  defaultValue: "Reply", bundle: MastodonLocalization.bundle)
          /// Share Link in Post
          public static let shareLinkInPost = String(localized: "Common.Controls.Status.Actions.ShareLinkInPost",  defaultValue: "Share Link in Post", bundle: MastodonLocalization.bundle)
          /// Show
          public static let show = String(localized: "Common.Controls.Status.Actions.Show",  defaultValue: "Show", bundle: MastodonLocalization.bundle)
          /// Show GIF
          public static let showGif = String(localized: "Common.Controls.Status.Actions.ShowGif",  defaultValue: "Show GIF", bundle: MastodonLocalization.bundle)
          /// Show image
          public static let showImage = String(localized: "Common.Controls.Status.Actions.ShowImage",  defaultValue: "Show image", bundle: MastodonLocalization.bundle)
          /// Show video player
          public static let showVideoPlayer = String(localized: "Common.Controls.Status.Actions.ShowVideoPlayer",  defaultValue: "Show video player", bundle: MastodonLocalization.bundle)
          /// Tap then hold to show menu
          public static let tapThenHoldToShowMenu = String(localized: "Common.Controls.Status.Actions.TapThenHoldToShowMenu",  defaultValue: "Tap then hold to show menu", bundle: MastodonLocalization.bundle)
          /// Unfavorite
          public static let unfavorite = String(localized: "Common.Controls.Status.Actions.Unfavorite",  defaultValue: "Unfavorite", bundle: MastodonLocalization.bundle)
          /// Undo boost
          public static let unreblog = String(localized: "Common.Controls.Status.Actions.Unreblog",  defaultValue: "Undo boost", bundle: MastodonLocalization.bundle)
          public enum A11YLabels {
            /// Boost
            public static let reblog = String(localized: "Common.Controls.Status.Actions.A11YLabels.Reblog",  defaultValue: "Boost", bundle: MastodonLocalization.bundle)
            /// Undo boost
            public static let unreblog = String(localized: "Common.Controls.Status.Actions.A11YLabels.Unreblog",  defaultValue: "Undo boost", bundle: MastodonLocalization.bundle)
          }
        }
        public enum Buttons {
          /// Last edit %@
          public static func editHistoryDetail(_ p1: Any) -> String {
              return L10n.tr(String.LocalizationValue("Common.Controls.Status.Buttons.EditHistoryDetail.\(placeholder: .object)"), args: [String(describing: p1)])
          }
          /// Edit History
          public static let editHistoryTitle = String(localized: "Common.Controls.Status.Buttons.EditHistoryTitle",  defaultValue: "Edit History", bundle: MastodonLocalization.bundle)
          /// Favorites
          public static let favoritesTitle = String(localized: "Common.Controls.Status.Buttons.FavoritesTitle",  defaultValue: "Favorites", bundle: MastodonLocalization.bundle)
          /// Boosts
          public static let reblogsTitle = String(localized: "Common.Controls.Status.Buttons.ReblogsTitle",  defaultValue: "Boosts", bundle: MastodonLocalization.bundle)
        }
        public enum Card {
          /// By
          public static let by = String(localized: "Common.Controls.Status.Card.By",  defaultValue: "By", bundle: MastodonLocalization.bundle)
          /// By %@
          public static func byAuthor(_ p1: Any) -> String {
              return L10n.tr(String.LocalizationValue("Common.Controls.Status.Card.ByAuthor.\(placeholder: .object)"), args: [String(describing: p1)])
          }
        }
        public enum EditHistory {
          /// Original Post · %@
          public static func originalPost(_ p1: Any) -> String {
              return L10n.tr(String.LocalizationValue("Common.Controls.Status.EditHistory.OriginalPost.\(placeholder: .object)"), args: [String(describing: p1)])
          }
          /// Edit History
          public static let title = String(localized: "Common.Controls.Status.EditHistory.Title",  defaultValue: "Edit History", bundle: MastodonLocalization.bundle)
        }
        public enum Media {
          /// %@, attachment %d of %d
          public static func accessibilityLabel(_ p1: Any, _ p2: Int, _ p3: Int) -> String {
              return L10n.tr(String.LocalizationValue("Common.Controls.Status.Media.AccessibilityLabel.\(placeholder: .object).attachment\(placeholder: .int)of\(placeholder: .int)"), args: [String(describing: p1), p2, p3])
          }
          /// Expands the GIF. Double-tap and hold to show actions
          public static let expandGifHint = String(localized: "Common.Controls.Status.Media.ExpandGifHint",  defaultValue: "Expands the GIF. Double-tap and hold to show actions", bundle: MastodonLocalization.bundle)
          /// Expands the image. Double-tap and hold to show actions
          public static let expandImageHint = String(localized: "Common.Controls.Status.Media.ExpandImageHint",  defaultValue: "Expands the image. Double-tap and hold to show actions", bundle: MastodonLocalization.bundle)
          /// Shows the video player. Double-tap and hold to show actions
          public static let expandVideoHint = String(localized: "Common.Controls.Status.Media.ExpandVideoHint",  defaultValue: "Shows the video player. Double-tap and hold to show actions", bundle: MastodonLocalization.bundle)
        }
        public enum MetaEntity {
          /// Email address: %@
          public static func email(_ p1: Any) -> String {
              return L10n.tr(String.LocalizationValue("Common.Controls.Status.MetaEntity.Email.\(placeholder: .object)"), args: [String(describing: p1)])
          }
          /// Hashtag: %@
          public static func hashtag(_ p1: Any) -> String {
              return L10n.tr(String.LocalizationValue("Common.Controls.Status.MetaEntity.Hashtag.\(placeholder: .object)"), args: [String(describing: p1)])
          }
          /// Show Profile: %@
          public static func mention(_ p1: Any) -> String {
              return L10n.tr(String.LocalizationValue("Common.Controls.Status.MetaEntity.Mention.\(placeholder: .object)"), args: [String(describing: p1)])
          }
          /// Link: %@
          public static func url(_ p1: Any) -> String {
              return L10n.tr(String.LocalizationValue("Common.Controls.Status.MetaEntity.Url.\(placeholder: .object)"), args: [String(describing: p1)])
          }
        }
        public enum Poll {
          /// Choose one or more
          public static let chooseOneOrMore = String(localized: "Common.Controls.Status.Poll.ChooseOneOrMore",  defaultValue: "Choose one or more", bundle: MastodonLocalization.bundle)
          /// Closed
          public static let closed = String(localized: "Common.Controls.Status.Poll.Closed",  defaultValue: "Closed", bundle: MastodonLocalization.bundle)
          /// Hide Results
          public static let hideResults = String(localized: "Common.Controls.Status.Poll.HideResults",  defaultValue: "Hide Results", bundle: MastodonLocalization.bundle)
          /// See Results
          public static let seeResults = String(localized: "Common.Controls.Status.Poll.SeeResults",  defaultValue: "See Results", bundle: MastodonLocalization.bundle)
          /// Vote
          public static let vote = String(localized: "Common.Controls.Status.Poll.Vote",  defaultValue: "Vote", bundle: MastodonLocalization.bundle)
          /// Voted
          public static let voted = String(localized: "Common.Controls.Status.Poll.Voted",  defaultValue: "Voted", bundle: MastodonLocalization.bundle)
        }
        public enum Tag {
          /// Email
          public static let email = String(localized: "Common.Controls.Status.Tag.Email",  defaultValue: "Email", bundle: MastodonLocalization.bundle)
          /// Emoji
          public static let emoji = String(localized: "Common.Controls.Status.Tag.Emoji",  defaultValue: "Emoji", bundle: MastodonLocalization.bundle)
          /// Hashtag
          public static let hashtag = String(localized: "Common.Controls.Status.Tag.Hashtag",  defaultValue: "Hashtag", bundle: MastodonLocalization.bundle)
          /// Link
          public static let link = String(localized: "Common.Controls.Status.Tag.Link",  defaultValue: "Link", bundle: MastodonLocalization.bundle)
          /// Mention
          public static let mention = String(localized: "Common.Controls.Status.Tag.Mention",  defaultValue: "Mention", bundle: MastodonLocalization.bundle)
          /// URL
          public static let url = String(localized: "Common.Controls.Status.Tag.Url",  defaultValue: "URL", bundle: MastodonLocalization.bundle)
        }
        public enum Translation {
          /// Show Original
          public static let showOriginal = String(localized: "Common.Controls.Status.Translation.ShowOriginal",  defaultValue: "Show Original", bundle: MastodonLocalization.bundle)
          /// Translated from %@ using %@
          public static func translatedFrom(_ p1: Any, _ p2: Any) -> String {
              return L10n.tr(String.LocalizationValue("Common.Controls.Status.Translation.TranslatedFrom.\(placeholder: .object).\(placeholder: .object)"), args: [String(describing: p1), String(describing: p2)])
          }
          /// Unknown
          public static let unknownLanguage = String(localized: "Common.Controls.Status.Translation.UnknownLanguage",  defaultValue: "Unknown", bundle: MastodonLocalization.bundle)
          /// Unknown
          public static let unknownProvider = String(localized: "Common.Controls.Status.Translation.UnknownProvider",  defaultValue: "Unknown", bundle: MastodonLocalization.bundle)
        }
        public enum Visibility {
          /// Only mentioned user can see this post.
          public static let direct = String(localized: "Common.Controls.Status.Visibility.Direct",  defaultValue: "Only mentioned user can see this post.", bundle: MastodonLocalization.bundle)
          /// Only their followers can see this post.
          public static let `private` = String(localized: "Common.Controls.Status.Visibility.Private",  defaultValue: "Only their followers can see this post.", bundle: MastodonLocalization.bundle)
          /// Only my followers can see this post.
          public static let privateFromMe = String(localized: "Common.Controls.Status.Visibility.PrivateFromMe",  defaultValue: "Only my followers can see this post.", bundle: MastodonLocalization.bundle)
          /// Everyone can see this post but not display in the public timeline.
          public static let unlisted = String(localized: "Common.Controls.Status.Visibility.Unlisted",  defaultValue: "Everyone can see this post but not display in the public timeline.", bundle: MastodonLocalization.bundle)
        }
      }
      public enum Tabs {
        /// Home
        public static let home = String(localized: "Common.Controls.Tabs.Home",  defaultValue: "Home", bundle: MastodonLocalization.bundle)
        /// Notifications
        public static let notifications = String(localized: "Common.Controls.Tabs.Notifications",  defaultValue: "Notifications", bundle: MastodonLocalization.bundle)
        /// Profile
        public static let profile = String(localized: "Common.Controls.Tabs.Profile",  defaultValue: "Profile", bundle: MastodonLocalization.bundle)
        /// Search and Explore
        public static let searchAndExplore = String(localized: "Common.Controls.Tabs.SearchAndExplore",  defaultValue: "Search and Explore", bundle: MastodonLocalization.bundle)
        public enum A11Y {
          /// Explore
          public static let explore = String(localized: "Common.Controls.Tabs.A11Y.Explore",  defaultValue: "Explore", bundle: MastodonLocalization.bundle)
          /// Search
          public static let search = String(localized: "Common.Controls.Tabs.A11Y.Search",  defaultValue: "Search", bundle: MastodonLocalization.bundle)
        }
      }
      public enum Timeline {
        /// Filtered
        public static let filtered = String(localized: "Common.Controls.Timeline.Filtered",  defaultValue: "Filtered", bundle: MastodonLocalization.bundle)
        public enum Header {
          /// You can’t view this user’s profile
          /// until they unblock you.
          public static let blockedWarning = String(localized: "Common.Controls.Timeline.Header.BlockedWarning",  defaultValue: "You can’t view this user’s profile\nuntil they unblock you.", bundle: MastodonLocalization.bundle)
          /// You can’t view this user's profile
          /// until you unblock them.
          /// Your profile looks like this to them.
          public static let blockingWarning = String(localized: "Common.Controls.Timeline.Header.BlockingWarning",  defaultValue: "You can’t view this user's profile\nuntil you unblock them.\nYour profile looks like this to them.", bundle: MastodonLocalization.bundle)
          /// No Post Found
          public static let noStatusFound = String(localized: "Common.Controls.Timeline.Header.NoStatusFound",  defaultValue: "No Post Found", bundle: MastodonLocalization.bundle)
          /// This user has been suspended.
          public static let suspendedWarning = String(localized: "Common.Controls.Timeline.Header.SuspendedWarning",  defaultValue: "This user has been suspended.", bundle: MastodonLocalization.bundle)
          /// You can’t view %@’s profile
          /// until they unblock you.
          public static func userBlockedWarning(_ p1: Any) -> String {
              return L10n.tr(String.LocalizationValue("Common.Controls.Timeline.Header.UserBlockedWarning.\(placeholder: .object)"), args: [String(describing: p1)])
          }
          /// You can’t view %@’s profile
          /// until you unblock them.
          /// Your profile looks like this to them.
          public static func userBlockingWarning(_ p1: Any) -> String {
              return L10n.tr(String.LocalizationValue("Common.Controls.Timeline.Header.UserBlockingWarning.\(placeholder: .object)"), args: [String(describing: p1)])
          }
          /// %@’s account has been suspended.
          public static func userSuspendedWarning(_ p1: Any) -> String {
              return L10n.tr(String.LocalizationValue("Common.Controls.Timeline.Header.UserSuspendedWarning.\(placeholder: .object)"), args: [String(describing: p1)])
          }
        }
        public enum Loader {
          /// Loading missing posts...
          public static let loadingMissingPosts = String(localized: "Common.Controls.Timeline.Loader.LoadingMissingPosts",  defaultValue: "Loading missing posts...", bundle: MastodonLocalization.bundle)
          /// Load missing posts
          public static let loadMissingPosts = String(localized: "Common.Controls.Timeline.Loader.LoadMissingPosts",  defaultValue: "Load missing posts", bundle: MastodonLocalization.bundle)
          /// Show more replies
          public static let showMoreReplies = String(localized: "Common.Controls.Timeline.Loader.ShowMoreReplies",  defaultValue: "Show more replies", bundle: MastodonLocalization.bundle)
        }
        public enum Timestamp {
          /// Now
          public static let now = String(localized: "Common.Controls.Timeline.Timestamp.Now",  defaultValue: "Now", bundle: MastodonLocalization.bundle)
        }
      }
    }
    public enum UserList {
      /// %@ followers
      public static func followersCount(_ p1: String) -> String {
          return L10n.tr(String.LocalizationValue("Common.UserList.FollowersCount.\(placeholder: .object)"), args: [String(describing: p1)])
      }
      /// No verified link
      public static let noVerifiedLink = String(localized: "Common.UserList.NoVerifiedLink",  defaultValue: "No verified link", bundle: MastodonLocalization.bundle)
    }
  }
  public enum Extension {
    public enum OpenIn {
      /// This doesn't seem to be a valid Mastodon link.
      public static let invalidLinkError = String(localized: "Extension.OpenIn.InvalidLinkError",  defaultValue: "This doesn't seem to be a valid Mastodon link.", bundle: MastodonLocalization.bundle)
    }
  }
  public enum Scene {
    public enum AccountList {
      /// Add Account
      public static let addAccount = String(localized: "Scene.AccountList.AddAccount",  defaultValue: "Add Account", bundle: MastodonLocalization.bundle)
      /// Dismiss Account Switcher
      public static let dismissAccountSwitcher = String(localized: "Scene.AccountList.DismissAccountSwitcher",  defaultValue: "Dismiss Account Switcher", bundle: MastodonLocalization.bundle)
      /// Logout
      public static let logout = String(localized: "Scene.AccountList.Logout",  defaultValue: "Logout", bundle: MastodonLocalization.bundle)
      /// Log Out Of All Accounts
      public static let logoutAllAccounts = String(localized: "Scene.AccountList.LogoutAllAccounts",  defaultValue: "Log Out Of All Accounts", bundle: MastodonLocalization.bundle)
      /// Current selected profile: %@. Double tap then hold to show account switcher
      public static func tabBarHint(_ p1: Any) -> String {
          return L10n.tr(String.LocalizationValue("Scene.AccountList.TabBarHint.\(placeholder: .object)"), args: [String(describing: p1)])
      }
    }
    public enum Bookmark {
      /// Bookmarks
      public static let title = String(localized: "Scene.Bookmark.Title",  defaultValue: "Bookmarks", bundle: MastodonLocalization.bundle)
    }
    public enum Compose {
      /// Publish
      public static let composeAction = String(localized: "Scene.Compose.ComposeAction",  defaultValue: "Publish", bundle: MastodonLocalization.bundle)
      /// Type or paste what’s on your mind
      public static let contentInputPlaceholder = String(localized: "Scene.Compose.ContentInputPlaceholder",  defaultValue: "Type or paste what’s on your mind", bundle: MastodonLocalization.bundle)
      /// replying to %@
      public static func replyingToUser(_ p1: Any) -> String {
          return L10n.tr(String.LocalizationValue("Scene.Compose.ReplyingToUser.\(placeholder: .object)"), args: [String(describing: p1)])
      }
      public enum Accessibility {
        /// Add Attachment
        public static let appendAttachment = String(localized: "Scene.Compose.Accessibility.AppendAttachment",  defaultValue: "Add Attachment", bundle: MastodonLocalization.bundle)
        /// Add Poll
        public static let appendPoll = String(localized: "Scene.Compose.Accessibility.AppendPoll",  defaultValue: "Add Poll", bundle: MastodonLocalization.bundle)
        /// Custom Emoji Picker
        public static let customEmojiPicker = String(localized: "Scene.Compose.Accessibility.CustomEmojiPicker",  defaultValue: "Custom Emoji Picker", bundle: MastodonLocalization.bundle)
        /// Disable Content Warning
        public static let disableContentWarning = String(localized: "Scene.Compose.Accessibility.DisableContentWarning",  defaultValue: "Disable Content Warning", bundle: MastodonLocalization.bundle)
        /// Enable Content Warning
        public static let enableContentWarning = String(localized: "Scene.Compose.Accessibility.EnableContentWarning",  defaultValue: "Enable Content Warning", bundle: MastodonLocalization.bundle)
        /// Posting as %@
        public static func postingAs(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Scene.Compose.Accessibility.PostingAs.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// Post Options
        public static let postOptions = String(localized: "Scene.Compose.Accessibility.PostOptions",  defaultValue: "Post Options", bundle: MastodonLocalization.bundle)
        /// Post Visibility Menu
        public static let postVisibilityMenu = String(localized: "Scene.Compose.Accessibility.PostVisibilityMenu",  defaultValue: "Post Visibility Menu", bundle: MastodonLocalization.bundle)
        /// Remove Poll
        public static let removePoll = String(localized: "Scene.Compose.Accessibility.RemovePoll",  defaultValue: "Remove Poll", bundle: MastodonLocalization.bundle)
      }
      public enum Attachment {
        /// This %@ is broken and can’t be
        /// uploaded to Mastodon.
        public static func attachmentBroken(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Scene.Compose.Attachment.AttachmentBroken.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// Attachment too large
        public static let attachmentTooLarge = String(localized: "Scene.Compose.Attachment.AttachmentTooLarge",  defaultValue: "Attachment too large", bundle: MastodonLocalization.bundle)
        /// Can not recognize this media attachment
        public static let canNotRecognizeThisMediaAttachment = String(localized: "Scene.Compose.Attachment.CanNotRecognizeThisMediaAttachment",  defaultValue: "Can not recognize this media attachment", bundle: MastodonLocalization.bundle)
        /// Compressing...
        public static let compressingState = String(localized: "Scene.Compose.Attachment.CompressingState",  defaultValue: "Compressing...", bundle: MastodonLocalization.bundle)
        /// Describe the photo for the visually-impaired...
        public static let descriptionPhoto = String(localized: "Scene.Compose.Attachment.DescriptionPhoto",  defaultValue: "Describe the photo for the visually-impaired...", bundle: MastodonLocalization.bundle)
        /// Describe the video for the visually-impaired...
        public static let descriptionVideo = String(localized: "Scene.Compose.Attachment.DescriptionVideo",  defaultValue: "Describe the video for the visually-impaired...", bundle: MastodonLocalization.bundle)
        /// Load Failed
        public static let loadFailed = String(localized: "Scene.Compose.Attachment.LoadFailed",  defaultValue: "Load Failed", bundle: MastodonLocalization.bundle)
        /// photo
        public static let photo = String(localized: "Scene.Compose.Attachment.Photo",  defaultValue: "photo", bundle: MastodonLocalization.bundle)
        /// Server Processing...
        public static let serverProcessingState = String(localized: "Scene.Compose.Attachment.ServerProcessingState",  defaultValue: "Server Processing...", bundle: MastodonLocalization.bundle)
        /// Upload Failed
        public static let uploadFailed = String(localized: "Scene.Compose.Attachment.UploadFailed",  defaultValue: "Upload Failed", bundle: MastodonLocalization.bundle)
        /// video
        public static let video = String(localized: "Scene.Compose.Attachment.Video",  defaultValue: "video", bundle: MastodonLocalization.bundle)
      }
      public enum AutoComplete {
        /// Space to add
        public static let spaceToAdd = String(localized: "Scene.Compose.AutoComplete.SpaceToAdd",  defaultValue: "Space to add", bundle: MastodonLocalization.bundle)
      }
      public enum ContentWarning {
        /// Write an accurate warning here...
        public static let placeholder = String(localized: "Scene.Compose.ContentWarning.Placeholder",  defaultValue: "Write an accurate warning here...", bundle: MastodonLocalization.bundle)
      }
      public enum Keyboard {
        /// Add Attachment - %@
        public static func appendAttachmentEntry(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Scene.Compose.Keyboard.AppendAttachmentEntry.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// Discard Post
        public static let discardPost = String(localized: "Scene.Compose.Keyboard.DiscardPost",  defaultValue: "Discard Post", bundle: MastodonLocalization.bundle)
        /// Publish Post
        public static let publishPost = String(localized: "Scene.Compose.Keyboard.PublishPost",  defaultValue: "Publish Post", bundle: MastodonLocalization.bundle)
        /// Select Visibility - %@
        public static func selectVisibilityEntry(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Scene.Compose.Keyboard.SelectVisibilityEntry.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// Toggle Content Warning
        public static let toggleContentWarning = String(localized: "Scene.Compose.Keyboard.ToggleContentWarning",  defaultValue: "Toggle Content Warning", bundle: MastodonLocalization.bundle)
        /// Toggle Poll
        public static let togglePoll = String(localized: "Scene.Compose.Keyboard.TogglePoll",  defaultValue: "Toggle Poll", bundle: MastodonLocalization.bundle)
      }
      public enum Language {
        /// Other Language…
        public static let other = String(localized: "Scene.Compose.Language.Other",  defaultValue: "Other Language…", bundle: MastodonLocalization.bundle)
        /// Recent
        public static let recent = String(localized: "Scene.Compose.Language.Recent",  defaultValue: "Recent", bundle: MastodonLocalization.bundle)
        /// Suggested
        public static let suggested = String(localized: "Scene.Compose.Language.Suggested",  defaultValue: "Suggested", bundle: MastodonLocalization.bundle)
        /// Post Language
        public static let title = String(localized: "Scene.Compose.Language.Title",  defaultValue: "Post Language", bundle: MastodonLocalization.bundle)
      }
      public enum MediaSelection {
        /// Browse
        public static let browse = String(localized: "Scene.Compose.MediaSelection.Browse",  defaultValue: "Browse", bundle: MastodonLocalization.bundle)
        /// Take Photo
        public static let camera = String(localized: "Scene.Compose.MediaSelection.Camera",  defaultValue: "Take Photo", bundle: MastodonLocalization.bundle)
        /// Photo Library
        public static let photoLibrary = String(localized: "Scene.Compose.MediaSelection.PhotoLibrary",  defaultValue: "Photo Library", bundle: MastodonLocalization.bundle)
      }
      public enum Poll {
        /// Add Option
        public static let addOption = String(localized: "Scene.Compose.Poll.AddOption",  defaultValue: "Add Option", bundle: MastodonLocalization.bundle)
        /// Duration: %@
        public static func durationTime(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Scene.Compose.Poll.DurationTime.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// Move Down
        public static let moveDown = String(localized: "Scene.Compose.Poll.MoveDown",  defaultValue: "Move Down", bundle: MastodonLocalization.bundle)
        /// Move Up
        public static let moveUp = String(localized: "Scene.Compose.Poll.MoveUp",  defaultValue: "Move Up", bundle: MastodonLocalization.bundle)
        /// 1 Day
        public static let oneDay = String(localized: "Scene.Compose.Poll.OneDay",  defaultValue: "1 Day", bundle: MastodonLocalization.bundle)
        /// 1 Hour
        public static let oneHour = String(localized: "Scene.Compose.Poll.OneHour",  defaultValue: "1 Hour", bundle: MastodonLocalization.bundle)
        /// Option %ld
        public static func optionNumber(_ p1: Int) -> String {
            return L10n.tr(String.LocalizationValue("Scene.Compose.Poll.OptionNumber.\(placeholder: .int)"), args: [p1])
        }
        /// Remove Option
        public static let removeOption = String(localized: "Scene.Compose.Poll.RemoveOption",  defaultValue: "Remove Option", bundle: MastodonLocalization.bundle)
        /// 7 Days
        public static let sevenDays = String(localized: "Scene.Compose.Poll.SevenDays",  defaultValue: "7 Days", bundle: MastodonLocalization.bundle)
        /// 6 Hours
        public static let sixHours = String(localized: "Scene.Compose.Poll.SixHours",  defaultValue: "6 Hours", bundle: MastodonLocalization.bundle)
        /// The poll has empty option
        public static let thePollHasEmptyOption = String(localized: "Scene.Compose.Poll.ThePollHasEmptyOption",  defaultValue: "The poll has empty option", bundle: MastodonLocalization.bundle)
        /// The poll is invalid
        public static let thePollIsInvalid = String(localized: "Scene.Compose.Poll.ThePollIsInvalid",  defaultValue: "The poll is invalid", bundle: MastodonLocalization.bundle)
        /// 30 minutes
        public static let thirtyMinutes = String(localized: "Scene.Compose.Poll.ThirtyMinutes",  defaultValue: "30 minutes", bundle: MastodonLocalization.bundle)
        /// 3 Days
        public static let threeDays = String(localized: "Scene.Compose.Poll.ThreeDays",  defaultValue: "3 Days", bundle: MastodonLocalization.bundle)
        /// Poll
        public static let title = String(localized: "Scene.Compose.Poll.Title",  defaultValue: "Poll", bundle: MastodonLocalization.bundle)
      }
      public enum Title {
        /// Edit Post
        public static let editPost = String(localized: "Scene.Compose.Title.EditPost",  defaultValue: "Edit Post", bundle: MastodonLocalization.bundle)
        /// New Post
        public static let newPost = String(localized: "Scene.Compose.Title.NewPost",  defaultValue: "New Post", bundle: MastodonLocalization.bundle)
        /// New Reply
        public static let newReply = String(localized: "Scene.Compose.Title.NewReply",  defaultValue: "New Reply", bundle: MastodonLocalization.bundle)
      }
      public enum Visibility {
        /// Only people I mention
        public static let direct = String(localized: "Scene.Compose.Visibility.Direct",  defaultValue: "Only people I mention", bundle: MastodonLocalization.bundle)
        /// Followers only
        public static let `private` = String(localized: "Scene.Compose.Visibility.Private",  defaultValue: "Followers only", bundle: MastodonLocalization.bundle)
        /// Public
        public static let `public` = String(localized: "Scene.Compose.Visibility.Public",  defaultValue: "Public", bundle: MastodonLocalization.bundle)
        /// Unlisted
        public static let unlisted = String(localized: "Scene.Compose.Visibility.Unlisted",  defaultValue: "Unlisted", bundle: MastodonLocalization.bundle)
      }
    }
    public enum ConfirmEmail {
      /// Tap the link we sent you to verify %@. We’ll wait right here.
      public static func tapTheLinkWeEmailedToYouToVerifyYourAccount(_ p1: Any) -> String {
          return L10n.tr(String.LocalizationValue("Scene.ConfirmEmail.TapTheLinkWeEmailedToYouToVerifyYourAccount.\(placeholder: .object)"), args: [String(describing: p1)])
      }
      /// Check Your Inbox
      public static let title = String(localized: "Scene.ConfirmEmail.Title",  defaultValue: "Check Your Inbox", bundle: MastodonLocalization.bundle)
      public enum Button {
        /// Resend
        public static let resend = String(localized: "Scene.ConfirmEmail.Button.Resend",  defaultValue: "Resend", bundle: MastodonLocalization.bundle)
      }
      public enum DidntGetLink {
        /// Didn’t get a link?
        public static let `prefix` = String(localized: "Scene.ConfirmEmail.DidntGetLink.Prefix",  defaultValue: "Didn’t get a link?", bundle: MastodonLocalization.bundle)
        /// Resend (%@)
        public static func resendIn(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Scene.ConfirmEmail.DidntGetLink.ResendIn.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// Resend now.
        public static let resendNow = String(localized: "Scene.ConfirmEmail.DidntGetLink.ResendNow",  defaultValue: "Resend now.", bundle: MastodonLocalization.bundle)
      }
      public enum DontReceiveEmail {
        /// Check if your email address is correct as well as your junk folder if you haven’t.
        public static let description = String(localized: "Scene.ConfirmEmail.DontReceiveEmail.Description",  defaultValue: "Check if your email address is correct as well as your junk folder if you haven’t.", bundle: MastodonLocalization.bundle)
        /// Resend Email
        public static let resendEmail = String(localized: "Scene.ConfirmEmail.DontReceiveEmail.ResendEmail",  defaultValue: "Resend Email", bundle: MastodonLocalization.bundle)
        /// Check your Email
        public static let title = String(localized: "Scene.ConfirmEmail.DontReceiveEmail.Title",  defaultValue: "Check your Email", bundle: MastodonLocalization.bundle)
      }
      public enum OpenEmailApp {
        /// We just sent you an email. Check your junk folder if you haven’t.
        public static let description = String(localized: "Scene.ConfirmEmail.OpenEmailApp.Description",  defaultValue: "We just sent you an email. Check your junk folder if you haven’t.", bundle: MastodonLocalization.bundle)
        /// Mail
        public static let mail = String(localized: "Scene.ConfirmEmail.OpenEmailApp.Mail",  defaultValue: "Mail", bundle: MastodonLocalization.bundle)
        /// Open Email Client
        public static let openEmailClient = String(localized: "Scene.ConfirmEmail.OpenEmailApp.OpenEmailClient",  defaultValue: "Open Email Client", bundle: MastodonLocalization.bundle)
        /// Check your Inbox.
        public static let title = String(localized: "Scene.ConfirmEmail.OpenEmailApp.Title",  defaultValue: "Check your Inbox.", bundle: MastodonLocalization.bundle)
      }
    }
    public enum Discovery {
      /// These are the posts gaining traction in your corner of Mastodon.
      public static let intro = String(localized: "Scene.Discovery.Intro",  defaultValue: "These are the posts gaining traction in your corner of Mastodon.", bundle: MastodonLocalization.bundle)
      public enum Tabs {
        /// Community
        public static let community = String(localized: "Scene.Discovery.Tabs.Community",  defaultValue: "Community", bundle: MastodonLocalization.bundle)
        /// For You
        public static let forYou = String(localized: "Scene.Discovery.Tabs.ForYou",  defaultValue: "For You", bundle: MastodonLocalization.bundle)
        /// Hashtags
        public static let hashtags = String(localized: "Scene.Discovery.Tabs.Hashtags",  defaultValue: "Hashtags", bundle: MastodonLocalization.bundle)
        /// News
        public static let news = String(localized: "Scene.Discovery.Tabs.News",  defaultValue: "News", bundle: MastodonLocalization.bundle)
        /// Posts
        public static let posts = String(localized: "Scene.Discovery.Tabs.Posts",  defaultValue: "Posts", bundle: MastodonLocalization.bundle)
      }
    }
    public enum Donation {
      /// Currency
      public static let currency = String(localized: "Scene.Donation.Currency",  defaultValue: "Currency", bundle: MastodonLocalization.bundle)
      /// Donate
      public static let donatebuttontitle = String(localized: "Scene.Donation.Donatebuttontitle",  defaultValue: "Donate", bundle: MastodonLocalization.bundle)
      public enum Picker {
        /// Monthly
        public static let monthlyTitle = String(localized: "Scene.Donation.Picker.MonthlyTitle",  defaultValue: "Monthly", bundle: MastodonLocalization.bundle)
        /// Just once
        public static let onceTitle = String(localized: "Scene.Donation.Picker.OnceTitle",  defaultValue: "Just once", bundle: MastodonLocalization.bundle)
        /// Yearly
        public static let yearlyTitle = String(localized: "Scene.Donation.Picker.YearlyTitle",  defaultValue: "Yearly", bundle: MastodonLocalization.bundle)
      }
      public enum Success {
        /// We are sorry, an error occurred and we have not been able to process your donation.
        /// 
        /// Please retry in a few minutes.
        public static let serverErrorMessage = String(localized: "Scene.Donation.Success.ServerErrorMessage",  defaultValue: "We are sorry, an error occurred and we have not been able to process your donation.\n\nPlease retry in a few minutes.", bundle: MastodonLocalization.bundle)
        /// Payment failed
        public static let serverErrorTitle = String(localized: "Scene.Donation.Success.ServerErrorTitle",  defaultValue: "Payment failed", bundle: MastodonLocalization.bundle)
        /// Spread the word
        public static let shareButtonTitle = String(localized: "Scene.Donation.Success.ShareButtonTitle",  defaultValue: "Spread the word", bundle: MastodonLocalization.bundle)
        /// You should receive an email confirming your donation soon.
        public static let subtitle = String(localized: "Scene.Donation.Success.Subtitle",  defaultValue: "You should receive an email confirming your donation soon.", bundle: MastodonLocalization.bundle)
        /// Thank you for your contribution!
        public static let title = String(localized: "Scene.Donation.Success.Title",  defaultValue: "Thank you for your contribution!", bundle: MastodonLocalization.bundle)
      }
    }
    public enum Familiarfollowers {
      /// Followed by %@
      public static func followedByNames(_ p1: Any) -> String {
          return L10n.tr(String.LocalizationValue("Scene.Familiarfollowers.FollowedByNames.\(placeholder: .object)"), args: [String(describing: p1)])
      }
      /// Followers you familiar
      public static let title = String(localized: "Scene.Familiarfollowers.Title",  defaultValue: "Followers you familiar", bundle: MastodonLocalization.bundle)
    }
    public enum Favorite {
      /// Favorites
      public static let title = String(localized: "Scene.Favorite.Title",  defaultValue: "Favorites", bundle: MastodonLocalization.bundle)
    }
    public enum FavoritedBy {
      /// Favorited By
      public static let title = String(localized: "Scene.FavoritedBy.Title",  defaultValue: "Favorited By", bundle: MastodonLocalization.bundle)
    }
    public enum FollowedTags {
      /// Followed Tags
      public static let title = String(localized: "Scene.FollowedTags.Title",  defaultValue: "Followed Tags", bundle: MastodonLocalization.bundle)
      public enum Actions {
        /// Follow
        public static let follow = String(localized: "Scene.FollowedTags.Actions.Follow",  defaultValue: "Follow", bundle: MastodonLocalization.bundle)
        /// Unfollow
        public static let unfollow = String(localized: "Scene.FollowedTags.Actions.Unfollow",  defaultValue: "Unfollow", bundle: MastodonLocalization.bundle)
      }
      public enum Header {
        /// participants
        public static let participants = String(localized: "Scene.FollowedTags.Header.Participants",  defaultValue: "participants", bundle: MastodonLocalization.bundle)
        /// posts
        public static let posts = String(localized: "Scene.FollowedTags.Header.Posts",  defaultValue: "posts", bundle: MastodonLocalization.bundle)
        /// posts today
        public static let postsToday = String(localized: "Scene.FollowedTags.Header.PostsToday",  defaultValue: "posts today", bundle: MastodonLocalization.bundle)
      }
    }
    public enum Follower {
      /// Followers from other servers are not displayed.
      public static let footer = String(localized: "Scene.Follower.Footer",  defaultValue: "Followers from other servers are not displayed.", bundle: MastodonLocalization.bundle)
      /// follower
      public static let title = String(localized: "Scene.Follower.Title",  defaultValue: "follower", bundle: MastodonLocalization.bundle)
    }
    public enum Following {
      /// Follows from other servers are not displayed.
      public static let footer = String(localized: "Scene.Following.Footer",  defaultValue: "Follows from other servers are not displayed.", bundle: MastodonLocalization.bundle)
      /// following
      public static let title = String(localized: "Scene.Following.Title",  defaultValue: "following", bundle: MastodonLocalization.bundle)
    }
    public enum HomeTimeline {
      /// Home
      public static let title = String(localized: "Scene.HomeTimeline.Title",  defaultValue: "Home", bundle: MastodonLocalization.bundle)
      public enum EmptyState {
        /// This list is empty
        public static let listEmptyMessageTitle = String(localized: "Scene.HomeTimeline.EmptyState.ListEmptyMessageTitle",  defaultValue: "This list is empty", bundle: MastodonLocalization.bundle)
      }
      public enum TimelineMenu {
        /// Following
        public static let following = String(localized: "Scene.HomeTimeline.TimelineMenu.Following",  defaultValue: "Following", bundle: MastodonLocalization.bundle)
        /// Local
        public static let localCommunity = String(localized: "Scene.HomeTimeline.TimelineMenu.LocalCommunity",  defaultValue: "Local", bundle: MastodonLocalization.bundle)
        public enum Hashtags {
          /// You don't follow any Hashtags
          public static let emptyMessage = String(localized: "Scene.HomeTimeline.TimelineMenu.Hashtags.EmptyMessage",  defaultValue: "You don't follow any Hashtags", bundle: MastodonLocalization.bundle)
          /// Followed Hashtags
          public static let title = String(localized: "Scene.HomeTimeline.TimelineMenu.Hashtags.Title",  defaultValue: "Followed Hashtags", bundle: MastodonLocalization.bundle)
        }
        public enum Lists {
          /// You don't have any Lists
          public static let emptyMessage = String(localized: "Scene.HomeTimeline.TimelineMenu.Lists.EmptyMessage",  defaultValue: "You don't have any Lists", bundle: MastodonLocalization.bundle)
          /// Lists
          public static let title = String(localized: "Scene.HomeTimeline.TimelineMenu.Lists.Title",  defaultValue: "Lists", bundle: MastodonLocalization.bundle)
        }
      }
      public enum TimelinePill {
        /// New Posts
        public static let newPosts = String(localized: "Scene.HomeTimeline.TimelinePill.NewPosts",  defaultValue: "New Posts", bundle: MastodonLocalization.bundle)
        /// Offline
        public static let offline = String(localized: "Scene.HomeTimeline.TimelinePill.Offline",  defaultValue: "Offline", bundle: MastodonLocalization.bundle)
        /// Post Sent
        public static let postSent = String(localized: "Scene.HomeTimeline.TimelinePill.PostSent",  defaultValue: "Post Sent", bundle: MastodonLocalization.bundle)
      }
    }
    public enum Login {
      /// Log in with the server where you created your account. For example, if your handle is @you@example.social, enter 'example.social'.
      public static let subtitle = String(localized: "Scene.Login.Subtitle",  defaultValue: "Log in with the server where you created your account. For example, if your handle is @you@example.social, enter 'example.social'.", bundle: MastodonLocalization.bundle)
      /// Welcome Back
      public static let title = String(localized: "Scene.Login.Title",  defaultValue: "Welcome Back", bundle: MastodonLocalization.bundle)
      public enum ServerSearchField {
        /// Enter URL or search for your server
        public static let placeholder = String(localized: "Scene.Login.ServerSearchField.Placeholder",  defaultValue: "Enter URL or search for your server", bundle: MastodonLocalization.bundle)
      }
    }
    public enum Notification {
      /// Learn more about server blocks
      public static let learnMoreAboutServerBlocks = String(localized: "Scene.Notification.LearnMoreAboutServerBlocks",  defaultValue: "Learn more about server blocks", bundle: MastodonLocalization.bundle)
      /// View report
      public static let viewReport = String(localized: "Scene.Notification.ViewReport",  defaultValue: "View report", bundle: MastodonLocalization.bundle)
      public enum AdminFilter {
        /// Admin Notifications
        public static let title = String(localized: "Scene.Notification.AdminFilter.Title",  defaultValue: "Admin Notifications", bundle: MastodonLocalization.bundle)
        public enum Reports {
          /// Show reports of spam, rule violations, and other complaints
          public static let subtitle = String(localized: "Scene.Notification.AdminFilter.Reports.Subtitle",  defaultValue: "Show reports of spam, rule violations, and other complaints", bundle: MastodonLocalization.bundle)
          /// Admin reports
          public static let title = String(localized: "Scene.Notification.AdminFilter.Reports.Title",  defaultValue: "Admin reports", bundle: MastodonLocalization.bundle)
        }
        public enum Signups {
          /// Show notifications of new accounts created on this instance
          public static let subtitle = String(localized: "Scene.Notification.AdminFilter.Signups.Subtitle",  defaultValue: "Show notifications of new accounts created on this instance", bundle: MastodonLocalization.bundle)
          /// Account signups
          public static let title = String(localized: "Scene.Notification.AdminFilter.Signups.Title",  defaultValue: "Account signups", bundle: MastodonLocalization.bundle)
        }
      }
      public enum FilteredNotification {
        /// Accept
        public static let accept = String(localized: "Scene.Notification.FilteredNotification.Accept",  defaultValue: "Accept", bundle: MastodonLocalization.bundle)
        /// Dismiss
        public static let dismiss = String(localized: "Scene.Notification.FilteredNotification.Dismiss",  defaultValue: "Dismiss", bundle: MastodonLocalization.bundle)
        /// Filtered Notifications
        public static let title = String(localized: "Scene.Notification.FilteredNotification.Title",  defaultValue: "Filtered Notifications", bundle: MastodonLocalization.bundle)
      }
      public enum FollowRequest {
        /// Accept
        public static let accept = String(localized: "Scene.Notification.FollowRequest.Accept",  defaultValue: "Accept", bundle: MastodonLocalization.bundle)
        /// Accepted
        public static let accepted = String(localized: "Scene.Notification.FollowRequest.Accepted",  defaultValue: "Accepted", bundle: MastodonLocalization.bundle)
        /// reject
        public static let reject = String(localized: "Scene.Notification.FollowRequest.Reject",  defaultValue: "reject", bundle: MastodonLocalization.bundle)
        /// Rejected
        public static let rejected = String(localized: "Scene.Notification.FollowRequest.Rejected",  defaultValue: "Rejected", bundle: MastodonLocalization.bundle)
      }
      public enum GroupedNotificationDescription {
        /// %@ boosted:
        public static func multiplePeopleBoosted(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Scene.Notification.GroupedNotificationDescription.MultiplePeopleBoosted.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// %@ favorited:
        public static func multiplePeopleFavourited(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Scene.Notification.GroupedNotificationDescription.MultiplePeopleFavourited.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// %@ followed you
        public static func multiplePeopleFollowedYou(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Scene.Notification.GroupedNotificationDescription.MultiplePeopleFollowedYou.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// %@ boosted:
        public static func singleNameBoosted(_ p1: Any) -> String {
//            let localizable = String(lo)
            return L10n.tr(String.LocalizationValue("Scene.Notification.GroupedNotificationDescription.SingleNameBoosted.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// %@ edited a post you interacted with
        public static func singleNameEditedAPost(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Scene.Notification.GroupedNotificationDescription.SingleNameEditedAPost.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// %@ favorited:
        public static func singleNameFavourited(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Scene.Notification.GroupedNotificationDescription.SingleNameFavourited.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// %@ followed you
        public static func singleNameFollowedYou(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Scene.Notification.GroupedNotificationDescription.SingleNameFollowedYou.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// %@ mentioned you
        public static func singleNameMentionedYou(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Scene.Notification.GroupedNotificationDescription.SingleNameMentionedYou.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// %@ posted:
        public static func singleNamePosted(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Scene.Notification.GroupedNotificationDescription.SingleNamePosted.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// %@ ran %@
        public static func singleNameRanPoll(_ p1: Any, _ p2: Any) -> String {
            return L10n.tr(String.LocalizationValue("Scene.Notification.GroupedNotificationDescription.SingleNameRanPoll.\(placeholder: .object).\(placeholder: .object)"), args: [String(describing: p1), String(describing: p2)])
        }
        /// %@ requested to follow you
        public static func singleNameRequestedToFollowYou(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Scene.Notification.GroupedNotificationDescription.SingleNameRequestedToFollowYou.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// %@ signed up
        public static func singleNameSignedUp(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Scene.Notification.GroupedNotificationDescription.SingleNameSignedUp.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// Someone reported %@.
        public static func someoneReportedAccount(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Scene.Notification.GroupedNotificationDescription.SomeoneReportedAccount.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// Someone reported %@ for rule violation.
        public static func someoneReportedAccountForRuleViolation(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Scene.Notification.GroupedNotificationDescription.SomeoneReportedAccountForRuleViolation.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// Someone reported %@ for spam.
        public static func someoneReportedAccountForSpam(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Scene.Notification.GroupedNotificationDescription.SomeoneReportedAccountForSpam.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// Someone reported %ld posts from %@.
        public static func someoneReportedPostsFromAccount(_ p1: Int, _ p2: String) -> String {
            return L10n.tr(String.LocalizationValue("Scene.Notification.GroupedNotificationDescription.SomeoneReportedPostsFromAccount.\(placeholder: .int).\(placeholder: .object)"), args: [String(describing: p1), String(describing: p2)])
        }
        /// Someone reported %ld posts from %@ for rule violation.
        public static func someoneReportedPostsFromAccountForRuleViolation(_ p1: Int, _ p2: String) -> String {
            return L10n.tr(String.LocalizationValue("Scene.Notification.GroupedNotificationDescription.SomeoneReportedPostsFromAccountForRuleViolation.\(placeholder: .int).\(placeholder: .object)"), args: [String(describing: p1), String(describing: p2)])
        }
        /// Someone reported %ld from %@ for spam.
        public static func someoneReportedPostsFromAccountForSpam(_ p1: Int, _ p2: String) -> String {
            return L10n.tr(String.LocalizationValue("Scene.Notification.GroupedNotificationDescription.SomeoneReportedPostsFromAccountForSpam.\(placeholder: .int).\(placeholder: .object)"), args: [String(describing: p1), String(describing: p2)])
        }
        /// Your poll has ended
        public static let yourPollHasEnded = String(localized: "Scene.Notification.GroupedNotificationDescription.YourPollHasEnded",  defaultValue: "Your poll has ended", bundle: MastodonLocalization.bundle)
      }
      public enum Headers {
        /// Boost
        public static let boost = String(localized: "Scene.Notification.Headers.Boost",  defaultValue: "Boost", bundle: MastodonLocalization.bundle)
        /// Edit
        public static let edit = String(localized: "Scene.Notification.Headers.Edit",  defaultValue: "Edit", bundle: MastodonLocalization.bundle)
        /// Favorite
        public static let favourite = String(localized: "Scene.Notification.Headers.Favourite",  defaultValue: "Favorite", bundle: MastodonLocalization.bundle)
        /// Follow
        public static let follow = String(localized: "Scene.Notification.Headers.Follow",  defaultValue: "Follow", bundle: MastodonLocalization.bundle)
        /// Follow request
        public static let followRequest = String(localized: "Scene.Notification.Headers.FollowRequest",  defaultValue: "Follow request", bundle: MastodonLocalization.bundle)
        /// Warning
        public static let moderationWarning = String(localized: "Scene.Notification.Headers.ModerationWarning",  defaultValue: "Warning", bundle: MastodonLocalization.bundle)
        /// Poll
        public static let poll = String(localized: "Scene.Notification.Headers.Poll",  defaultValue: "Poll", bundle: MastodonLocalization.bundle)
        /// Report
        public static let report = String(localized: "Scene.Notification.Headers.Report",  defaultValue: "Report", bundle: MastodonLocalization.bundle)
        /// Domain block
        public static let severedRelationships = String(localized: "Scene.Notification.Headers.SeveredRelationships",  defaultValue: "Domain block", bundle: MastodonLocalization.bundle)
        /// Signup
        public static let signUp = String(localized: "Scene.Notification.Headers.SignUp",  defaultValue: "Signup", bundle: MastodonLocalization.bundle)
        /// Post
        public static let status = String(localized: "Scene.Notification.Headers.Status",  defaultValue: "Post", bundle: MastodonLocalization.bundle)
      }
      public enum Keyobard {
        /// Show Everything
        public static let showEverything = String(localized: "Scene.Notification.Keyobard.ShowEverything",  defaultValue: "Show Everything", bundle: MastodonLocalization.bundle)
        /// Show Mentions
        public static let showMentions = String(localized: "Scene.Notification.Keyobard.ShowMentions",  defaultValue: "Show Mentions", bundle: MastodonLocalization.bundle)
      }
      public enum NotificationDescription {
        /// favorited your post
        public static let favoritedYourPost = String(localized: "Scene.Notification.NotificationDescription.FavoritedYourPost",  defaultValue: "favorited your post", bundle: MastodonLocalization.bundle)
        /// followed you
        public static let followedYou = String(localized: "Scene.Notification.NotificationDescription.FollowedYou",  defaultValue: "followed you", bundle: MastodonLocalization.bundle)
        /// mentioned you
        public static let mentionedYou = String(localized: "Scene.Notification.NotificationDescription.MentionedYou",  defaultValue: "mentioned you", bundle: MastodonLocalization.bundle)
        /// poll has ended
        public static let pollHasEnded = String(localized: "Scene.Notification.NotificationDescription.PollHasEnded",  defaultValue: "poll has ended", bundle: MastodonLocalization.bundle)
        /// boosted your post
        public static let rebloggedYourPost = String(localized: "Scene.Notification.NotificationDescription.RebloggedYourPost",  defaultValue: "boosted your post", bundle: MastodonLocalization.bundle)
        /// An admin from %@ has blocked %@, including %@.
        public static func relationshipSeverance(_ p1: String, _ p2: String, _ p3: String) -> String {
            return L10n.tr(String.LocalizationValue("Scene.Notification.NotificationDescription.RelationshipSeverance.\(placeholder: .object).\(placeholder: .object).\(placeholder: .object)"), args: [String(describing: p1), String(describing: p2), String(describing: p3)])
        }
        /// request to follow you
        public static let requestToFollowYou = String(localized: "Scene.Notification.NotificationDescription.RequestToFollowYou",  defaultValue: "request to follow you", bundle: MastodonLocalization.bundle)
      }
      public enum Policy {
        /// Filter Notifications from…
        public static let title = String(localized: "Scene.Notification.Policy.Title",  defaultValue: "Filter Notifications from…", bundle: MastodonLocalization.bundle)
        public enum Action {
          public enum Accept {
            /// Show in notifications
            public static let subtitle = String(localized: "Scene.Notification.Policy.Action.Accept.Subtitle",  defaultValue: "Show in notifications", bundle: MastodonLocalization.bundle)
            /// Accept
            public static let title = String(localized: "Scene.Notification.Policy.Action.Accept.Title",  defaultValue: "Accept", bundle: MastodonLocalization.bundle)
          }
          public enum Drop {
            /// Send to the void, never to be seen again
            public static let subtitle = String(localized: "Scene.Notification.Policy.Action.Drop.Subtitle",  defaultValue: "Send to the void, never to be seen again", bundle: MastodonLocalization.bundle)
            /// Ignore
            public static let title = String(localized: "Scene.Notification.Policy.Action.Drop.Title",  defaultValue: "Ignore", bundle: MastodonLocalization.bundle)
          }
          public enum Filter {
            /// Send to filtered notifications inbox
            public static let subtitle = String(localized: "Scene.Notification.Policy.Action.Filter.Subtitle",  defaultValue: "Send to filtered notifications inbox", bundle: MastodonLocalization.bundle)
            /// Filter
            public static let title = String(localized: "Scene.Notification.Policy.Action.Filter.Title",  defaultValue: "Filter", bundle: MastodonLocalization.bundle)
          }
        }
        public enum ModeratedAccounts {
          /// Limited by server moderators
          public static let subtitle = String(localized: "Scene.Notification.Policy.ModeratedAccounts.Subtitle",  defaultValue: "Limited by server moderators", bundle: MastodonLocalization.bundle)
          /// Moderated accounts
          public static let title = String(localized: "Scene.Notification.Policy.ModeratedAccounts.Title",  defaultValue: "Moderated accounts", bundle: MastodonLocalization.bundle)
        }
        public enum NewAccount {
          /// Created within the past 30 days
          public static let subtitle = String(localized: "Scene.Notification.Policy.NewAccount.Subtitle",  defaultValue: "Created within the past 30 days", bundle: MastodonLocalization.bundle)
          /// New accounts
          public static let title = String(localized: "Scene.Notification.Policy.NewAccount.Title",  defaultValue: "New accounts", bundle: MastodonLocalization.bundle)
        }
        public enum NoFollower {
          /// Including people who have been following you fewer than 3 days
          public static let subtitle = String(localized: "Scene.Notification.Policy.NoFollower.Subtitle",  defaultValue: "Including people who have been following you fewer than 3 days", bundle: MastodonLocalization.bundle)
          /// People not following you
          public static let title = String(localized: "Scene.Notification.Policy.NoFollower.Title",  defaultValue: "People not following you", bundle: MastodonLocalization.bundle)
        }
        public enum NotFollowing {
          /// Until you manually approve them
          public static let subtitle = String(localized: "Scene.Notification.Policy.NotFollowing.Subtitle",  defaultValue: "Until you manually approve them", bundle: MastodonLocalization.bundle)
          /// People you don't follow
          public static let title = String(localized: "Scene.Notification.Policy.NotFollowing.Title",  defaultValue: "People you don't follow", bundle: MastodonLocalization.bundle)
        }
        public enum PrivateMentions {
          /// Filtered unless it’s in reply to your own mention or if you follow the sender
          public static let subtitle = String(localized: "Scene.Notification.Policy.PrivateMentions.Subtitle",  defaultValue: "Filtered unless it’s in reply to your own mention or if you follow the sender", bundle: MastodonLocalization.bundle)
          /// Unsolicited private mentions
          public static let title = String(localized: "Scene.Notification.Policy.PrivateMentions.Title",  defaultValue: "Unsolicited private mentions", bundle: MastodonLocalization.bundle)
        }
      }
      public enum Title {
        /// Everything
        public static let everything = String(localized: "Scene.Notification.Title.Everything",  defaultValue: "Everything", bundle: MastodonLocalization.bundle)
        /// Mentions
        public static let mentions = String(localized: "Scene.Notification.Title.Mentions",  defaultValue: "Mentions", bundle: MastodonLocalization.bundle)
      }
      public enum Warning {
        /// Some of your posts have been removed.
        public static let deleteStatuses = String(localized: "Scene.Notification.Warning.DeleteStatuses",  defaultValue: "Some of your posts have been removed.", bundle: MastodonLocalization.bundle)
        /// Your account has been disabled.
        public static let disable = String(localized: "Scene.Notification.Warning.Disable",  defaultValue: "Your account has been disabled.", bundle: MastodonLocalization.bundle)
        /// Learn More
        public static let learnMore = String(localized: "Scene.Notification.Warning.LearnMore",  defaultValue: "Learn More", bundle: MastodonLocalization.bundle)
        /// Some of your posts have been marked as sensitive.
        public static let markStatusesAsSensitive = String(localized: "Scene.Notification.Warning.MarkStatusesAsSensitive",  defaultValue: "Some of your posts have been marked as sensitive.", bundle: MastodonLocalization.bundle)
        /// Your account has received a moderation warning.
        public static let `none` = String(localized: "Scene.Notification.Warning.None",  defaultValue: "Your account has received a moderation warning.", bundle: MastodonLocalization.bundle)
        /// Your posts will be marked as sensitive from now on.
        public static let sensitive = String(localized: "Scene.Notification.Warning.Sensitive",  defaultValue: "Your posts will be marked as sensitive from now on.", bundle: MastodonLocalization.bundle)
        /// Your account has been limited.
        public static let silence = String(localized: "Scene.Notification.Warning.Silence",  defaultValue: "Your account has been limited.", bundle: MastodonLocalization.bundle)
        /// Your account has been suspended.
        public static let suspend = String(localized: "Scene.Notification.Warning.Suspend",  defaultValue: "Your account has been suspended.", bundle: MastodonLocalization.bundle)
      }
    }
    public enum Preview {
      public enum Keyboard {
        /// Close Preview
        public static let closePreview = String(localized: "Scene.Preview.Keyboard.ClosePreview",  defaultValue: "Close Preview", bundle: MastodonLocalization.bundle)
        /// Show Next
        public static let showNext = String(localized: "Scene.Preview.Keyboard.ShowNext",  defaultValue: "Show Next", bundle: MastodonLocalization.bundle)
        /// Show Previous
        public static let showPrevious = String(localized: "Scene.Preview.Keyboard.ShowPrevious",  defaultValue: "Show Previous", bundle: MastodonLocalization.bundle)
      }
    }
    public enum Privacy {
      /// Although the Mastodon app does not collect any data, the server you sign up through may have a different policy.
      /// 
      /// If you disagree with the policy for **%@**, you can go back and pick a different server.
      public static func description(_ p1: Any) -> String {
          return L10n.tr(String.LocalizationValue("Scene.Privacy.Description.\(placeholder: .object)"), args: [String(describing: p1)])
      }
      /// Please review the terms of service for **%@**. If you disagree, you can go back and pick a different server.
      public static func termsOfServiceDescription(_ p1: Any) -> String {
          return L10n.tr(String.LocalizationValue("Scene.Privacy.TermsOfServiceDescription.\(placeholder: .object)"), args: [String(describing: p1)])
      }
      /// Terms of Service
      public static let termsOfServiceTitle = String(localized: "Scene.Privacy.TermsOfServiceTitle",  defaultValue: "Terms of Service", bundle: MastodonLocalization.bundle)
      /// Your Privacy
      public static let title = String(localized: "Scene.Privacy.Title",  defaultValue: "Your Privacy", bundle: MastodonLocalization.bundle)
      public enum Button {
        /// I Agree
        public static let confirm = String(localized: "Scene.Privacy.Button.Confirm",  defaultValue: "I Agree", bundle: MastodonLocalization.bundle)
      }
      public enum Policy {
        /// Privacy Policy - Mastodon for iOS
        public static let ios = String(localized: "Scene.Privacy.Policy.Ios",  defaultValue: "Privacy Policy - Mastodon for iOS", bundle: MastodonLocalization.bundle)
        /// Privacy Policy - %@
        public static func server(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Scene.Privacy.Policy.Server.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// Terms of Service - %@
        public static func termsOfService(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Scene.Privacy.Policy.TermsOfService.\(placeholder: .object)"), args: [String(describing: p1)])
        }
      }
    }
    public enum Profile {
      public enum Accessibility {
        /// Double tap to open the list
        public static let doubleTapToOpenTheList = String(localized: "Scene.Profile.Accessibility.DoubleTapToOpenTheList",  defaultValue: "Double tap to open the list", bundle: MastodonLocalization.bundle)
        /// Edit avatar image
        public static let editAvatarImage = String(localized: "Scene.Profile.Accessibility.EditAvatarImage",  defaultValue: "Edit avatar image", bundle: MastodonLocalization.bundle)
        /// Show avatar image
        public static let showAvatarImage = String(localized: "Scene.Profile.Accessibility.ShowAvatarImage",  defaultValue: "Show avatar image", bundle: MastodonLocalization.bundle)
        /// Show banner image
        public static let showBannerImage = String(localized: "Scene.Profile.Accessibility.ShowBannerImage",  defaultValue: "Show banner image", bundle: MastodonLocalization.bundle)
      }
      public enum Dashboard {
        /// mutuals
        public static let familiarFollowers = String(localized: "Scene.Profile.Dashboard.FamiliarFollowers",  defaultValue: "mutuals", bundle: MastodonLocalization.bundle)
        /// followers
        public static let myFollowers = String(localized: "Scene.Profile.Dashboard.MyFollowers",  defaultValue: "followers", bundle: MastodonLocalization.bundle)
        /// following
        public static let myFollowing = String(localized: "Scene.Profile.Dashboard.MyFollowing",  defaultValue: "following", bundle: MastodonLocalization.bundle)
        /// posts
        public static let myPosts = String(localized: "Scene.Profile.Dashboard.MyPosts",  defaultValue: "posts", bundle: MastodonLocalization.bundle)
        /// followers
        public static let otherFollowers = String(localized: "Scene.Profile.Dashboard.OtherFollowers",  defaultValue: "followers", bundle: MastodonLocalization.bundle)
        /// following
        public static let otherFollowing = String(localized: "Scene.Profile.Dashboard.OtherFollowing",  defaultValue: "following", bundle: MastodonLocalization.bundle)
        /// posts
        public static let otherPosts = String(localized: "Scene.Profile.Dashboard.OtherPosts",  defaultValue: "posts", bundle: MastodonLocalization.bundle)
      }
      public enum Fields {
        /// Add Row
        public static let addRow = String(localized: "Scene.Profile.Fields.AddRow",  defaultValue: "Add Row", bundle: MastodonLocalization.bundle)
        /// Joined
        public static let joined = String(localized: "Scene.Profile.Fields.Joined",  defaultValue: "Joined", bundle: MastodonLocalization.bundle)
        public enum Placeholder {
          /// Content
          public static let content = String(localized: "Scene.Profile.Fields.Placeholder.Content",  defaultValue: "Content", bundle: MastodonLocalization.bundle)
          /// Label
          public static let label = String(localized: "Scene.Profile.Fields.Placeholder.Label",  defaultValue: "Label", bundle: MastodonLocalization.bundle)
        }
        public enum Verified {
          /// Ownership of this link was checked on %@
          public static func long(_ p1: Any) -> String {
              return L10n.tr(String.LocalizationValue("Scene.Profile.Fields.Verified.Long.\(placeholder: .object)"), args: [String(describing: p1)])
          }
          /// Verified on %@
          public static func short(_ p1: Any) -> String {
              return L10n.tr(String.LocalizationValue("Scene.Profile.Fields.Verified.Short.\(placeholder: .object)"), args: [String(describing: p1)])
          }
        }
      }
      public enum Header {
        /// Follows You
        public static let followsYou = String(localized: "Scene.Profile.Header.FollowsYou",  defaultValue: "Follows You", bundle: MastodonLocalization.bundle)
      }
      public enum RelationshipActionAlert {
        public enum ConfirmBlockDomain {
          /// Confirm to block domain %@
          public static func message(_ p1: Any) -> String {
              return L10n.tr(String.LocalizationValue("Scene.Profile.RelationshipActionAlert.ConfirmBlockDomain.Message.\(placeholder: .object)"), args: [String(describing: p1)])
          }
          /// Block domain
          public static let title = String(localized: "Scene.Profile.RelationshipActionAlert.ConfirmBlockDomain.Title",  defaultValue: "Block domain", bundle: MastodonLocalization.bundle)
        }
        public enum ConfirmBlockUser {
          /// Confirm to block %@
          public static func message(_ p1: Any) -> String {
              return L10n.tr(String.LocalizationValue("Scene.Profile.RelationshipActionAlert.ConfirmBlockUser.Message.\(placeholder: .object)"), args: [String(describing: p1)])
          }
          /// Block Account
          public static let title = String(localized: "Scene.Profile.RelationshipActionAlert.ConfirmBlockUser.Title",  defaultValue: "Block Account", bundle: MastodonLocalization.bundle)
        }
        public enum ConfirmHideReblogs {
          /// Confirm to hide boosts
          public static let message = String(localized: "Scene.Profile.RelationshipActionAlert.ConfirmHideReblogs.Message",  defaultValue: "Confirm to hide boosts", bundle: MastodonLocalization.bundle)
          /// Hide Boosts
          public static let title = String(localized: "Scene.Profile.RelationshipActionAlert.ConfirmHideReblogs.Title",  defaultValue: "Hide Boosts", bundle: MastodonLocalization.bundle)
        }
        public enum ConfirmMuteUser {
          /// Confirm to mute %@
          public static func message(_ p1: Any) -> String {
              return L10n.tr(String.LocalizationValue("Scene.Profile.RelationshipActionAlert.ConfirmMuteUser.Message.\(placeholder: .object)"), args: [String(describing: p1)])
          }
          /// Mute Account
          public static let title = String(localized: "Scene.Profile.RelationshipActionAlert.ConfirmMuteUser.Title",  defaultValue: "Mute Account", bundle: MastodonLocalization.bundle)
        }
        public enum ConfirmShowReblogs {
          /// Confirm to show boosts
          public static let message = String(localized: "Scene.Profile.RelationshipActionAlert.ConfirmShowReblogs.Message",  defaultValue: "Confirm to show boosts", bundle: MastodonLocalization.bundle)
          /// Show Boosts
          public static let title = String(localized: "Scene.Profile.RelationshipActionAlert.ConfirmShowReblogs.Title",  defaultValue: "Show Boosts", bundle: MastodonLocalization.bundle)
        }
        public enum ConfirmUnblockDomain {
          /// Confirm to unblock domain %@
          public static func message(_ p1: Any) -> String {
              return L10n.tr(String.LocalizationValue("Scene.Profile.RelationshipActionAlert.ConfirmUnblockDomain.Message.\(placeholder: .object)"), args: [String(describing: p1)])
          }
          /// Unblock domain
          public static let title = String(localized: "Scene.Profile.RelationshipActionAlert.ConfirmUnblockDomain.Title",  defaultValue: "Unblock domain", bundle: MastodonLocalization.bundle)
        }
        public enum ConfirmUnblockUser {
          /// Confirm to unblock %@
          public static func message(_ p1: Any) -> String {
              return L10n.tr(String.LocalizationValue("Scene.Profile.RelationshipActionAlert.ConfirmUnblockUser.Message.\(placeholder: .object)"), args: [String(describing: p1)])
          }
          /// Unblock Account
          public static let title = String(localized: "Scene.Profile.RelationshipActionAlert.ConfirmUnblockUser.Title",  defaultValue: "Unblock Account", bundle: MastodonLocalization.bundle)
        }
        public enum ConfirmUnmuteUser {
          /// Confirm to unmute %@
          public static func message(_ p1: Any) -> String {
              return L10n.tr(String.LocalizationValue("Scene.Profile.RelationshipActionAlert.ConfirmUnmuteUser.Message.\(placeholder: .object)"), args: [String(describing: p1)])
          }
          /// Unmute Account
          public static let title = String(localized: "Scene.Profile.RelationshipActionAlert.ConfirmUnmuteUser.Title",  defaultValue: "Unmute Account", bundle: MastodonLocalization.bundle)
        }
      }
      public enum SegmentedControl {
        /// About
        public static let about = String(localized: "Scene.Profile.SegmentedControl.About",  defaultValue: "About", bundle: MastodonLocalization.bundle)
        /// Media
        public static let media = String(localized: "Scene.Profile.SegmentedControl.Media",  defaultValue: "Media", bundle: MastodonLocalization.bundle)
        /// Posts
        public static let posts = String(localized: "Scene.Profile.SegmentedControl.Posts",  defaultValue: "Posts", bundle: MastodonLocalization.bundle)
        /// Posts and Replies
        public static let postsAndReplies = String(localized: "Scene.Profile.SegmentedControl.PostsAndReplies",  defaultValue: "Posts and Replies", bundle: MastodonLocalization.bundle)
        /// Replies
        public static let replies = String(localized: "Scene.Profile.SegmentedControl.Replies",  defaultValue: "Replies", bundle: MastodonLocalization.bundle)
      }
    }
    public enum RebloggedBy {
      /// Boosted By
      public static let title = String(localized: "Scene.RebloggedBy.Title",  defaultValue: "Boosted By", bundle: MastodonLocalization.bundle)
    }
    public enum Register {
      /// Create Account
      public static let title = String(localized: "Scene.Register.Title",  defaultValue: "Create Account", bundle: MastodonLocalization.bundle)
      public enum Error {
        public enum Item {
          /// Agreement
          public static let agreement = String(localized: "Scene.Register.Error.Item.Agreement",  defaultValue: "Agreement", bundle: MastodonLocalization.bundle)
          /// Email
          public static let email = String(localized: "Scene.Register.Error.Item.Email",  defaultValue: "Email", bundle: MastodonLocalization.bundle)
          /// Locale
          public static let locale = String(localized: "Scene.Register.Error.Item.Locale",  defaultValue: "Locale", bundle: MastodonLocalization.bundle)
          /// Password
          public static let password = String(localized: "Scene.Register.Error.Item.Password",  defaultValue: "Password", bundle: MastodonLocalization.bundle)
          /// Reason
          public static let reason = String(localized: "Scene.Register.Error.Item.Reason",  defaultValue: "Reason", bundle: MastodonLocalization.bundle)
          /// Username
          public static let username = String(localized: "Scene.Register.Error.Item.Username",  defaultValue: "Username", bundle: MastodonLocalization.bundle)
        }
        public enum Reason {
          /// %@ must be accepted
          public static func accepted(_ p1: Any) -> String {
              return L10n.tr(String.LocalizationValue("Scene.Register.Error.Reason.Accepted.\(placeholder: .object)"), args: [String(describing: p1)])
          }
          /// %@ is required
          public static func blank(_ p1: Any) -> String {
              return L10n.tr(String.LocalizationValue("Scene.Register.Error.Reason.Blank.\(placeholder: .object)"), args: [String(describing: p1)])
          }
          /// %@ contains a disallowed email provider
          public static func blocked(_ p1: Any) -> String {
              return L10n.tr(String.LocalizationValue("Scene.Register.Error.Reason.Blocked.\(placeholder: .object)"), args: [String(describing: p1)])
          }
          /// %@ is not a supported value
          public static func inclusion(_ p1: Any) -> String {
              return L10n.tr(String.LocalizationValue("Scene.Register.Error.Reason.Inclusion.\(placeholder: .object)"), args: [String(describing: p1)])
          }
          /// %@ is invalid
          public static func invalid(_ p1: Any) -> String {
              return L10n.tr(String.LocalizationValue("Scene.Register.Error.Reason.Invalid.\(placeholder: .object)"), args: [String(describing: p1)])
          }
          /// %@ is a reserved keyword
          public static func reserved(_ p1: Any) -> String {
              return L10n.tr(String.LocalizationValue("Scene.Register.Error.Reason.Reserved.\(placeholder: .object)"), args: [String(describing: p1)])
          }
          /// %@ is already taken. How about:
          public static func taken(_ p1: Any) -> String {
              return L10n.tr(String.LocalizationValue("Scene.Register.Error.Reason.Taken.\(placeholder: .object)"), args: [String(describing: p1)])
          }
          /// %@ is too long
          public static func tooLong(_ p1: Any) -> String {
              return L10n.tr(String.LocalizationValue("Scene.Register.Error.Reason.TooLong.\(placeholder: .object)"), args: [String(describing: p1)])
          }
          /// %@ is too short
          public static func tooShort(_ p1: Any) -> String {
              return L10n.tr(String.LocalizationValue("Scene.Register.Error.Reason.TooShort.\(placeholder: .object)"), args: [String(describing: p1)])
          }
          /// %@ does not seem to exist
          public static func unreachable(_ p1: Any) -> String {
              return L10n.tr(String.LocalizationValue("Scene.Register.Error.Reason.Unreachable.\(placeholder: .object)"), args: [String(describing: p1)])
          }
        }
        public enum Special {
          /// This is not a valid email address
          public static let emailInvalid = String(localized: "Scene.Register.Error.Special.EmailInvalid",  defaultValue: "This is not a valid email address", bundle: MastodonLocalization.bundle)
          /// Password is too short (must be at least 8 characters)
          public static let passwordTooShort = String(localized: "Scene.Register.Error.Special.PasswordTooShort",  defaultValue: "Password is too short (must be at least 8 characters)", bundle: MastodonLocalization.bundle)
          /// Username must only contain alphanumeric characters and underscores
          public static let usernameInvalid = String(localized: "Scene.Register.Error.Special.UsernameInvalid",  defaultValue: "Username must only contain alphanumeric characters and underscores", bundle: MastodonLocalization.bundle)
          /// Username is too long (can’t be longer than 30 characters)
          public static let usernameTooLong = String(localized: "Scene.Register.Error.Special.UsernameTooLong",  defaultValue: "Username is too long (can’t be longer than 30 characters)", bundle: MastodonLocalization.bundle)
        }
      }
      public enum Input {
        public enum Avatar {
          /// Delete
          public static let delete = String(localized: "Scene.Register.Input.Avatar.Delete",  defaultValue: "Delete", bundle: MastodonLocalization.bundle)
        }
        public enum BirthDate {
          /// We have to make sure you're at least %d to join %@. This won't get stored after signup.
          public static func explanationMessage(_ p1: Int, _ p2: Any) -> String {
              return L10n.tr(String.LocalizationValue("Scene.Register.Input.BirthDate.ExplanationMessage.\(placeholder: .int).\(placeholder: .object)"), args: [p1, String(describing: p2)])
          }
          /// Date of Birth
          public static let label = String(localized: "Scene.Register.Input.BirthDate.Label",  defaultValue: "Date of Birth", bundle: MastodonLocalization.bundle)
        }
        public enum DisplayName {
          /// display name
          public static let placeholder = String(localized: "Scene.Register.Input.DisplayName.Placeholder",  defaultValue: "display name", bundle: MastodonLocalization.bundle)
        }
        public enum Email {
          /// email
          public static let placeholder = String(localized: "Scene.Register.Input.Email.Placeholder",  defaultValue: "email", bundle: MastodonLocalization.bundle)
        }
        public enum Invite {
          /// Why do you want to join?
          public static let registrationUserInviteRequest = String(localized: "Scene.Register.Input.Invite.RegistrationUserInviteRequest",  defaultValue: "Why do you want to join?", bundle: MastodonLocalization.bundle)
        }
        public enum Password {
          /// 8 characters
          public static let characterLimit = String(localized: "Scene.Register.Input.Password.CharacterLimit",  defaultValue: "8 characters", bundle: MastodonLocalization.bundle)
          /// Confirm Password
          public static let confirmationPlaceholder = String(localized: "Scene.Register.Input.Password.ConfirmationPlaceholder",  defaultValue: "Confirm Password", bundle: MastodonLocalization.bundle)
          /// Your password needs at least eight characters
          public static let hint = String(localized: "Scene.Register.Input.Password.Hint",  defaultValue: "Your password needs at least eight characters", bundle: MastodonLocalization.bundle)
          /// password
          public static let placeholder = String(localized: "Scene.Register.Input.Password.Placeholder",  defaultValue: "password", bundle: MastodonLocalization.bundle)
          /// Your password needs at least:
          public static let require = String(localized: "Scene.Register.Input.Password.Require",  defaultValue: "Your password needs at least:", bundle: MastodonLocalization.bundle)
          public enum Accessibility {
            /// checked
            public static let checked = String(localized: "Scene.Register.Input.Password.Accessibility.Checked",  defaultValue: "checked", bundle: MastodonLocalization.bundle)
            /// unchecked
            public static let unchecked = String(localized: "Scene.Register.Input.Password.Accessibility.Unchecked",  defaultValue: "unchecked", bundle: MastodonLocalization.bundle)
          }
        }
        public enum Username {
          /// This username is taken.
          public static let duplicatePrompt = String(localized: "Scene.Register.Input.Username.DuplicatePrompt",  defaultValue: "This username is taken.", bundle: MastodonLocalization.bundle)
          /// username
          public static let placeholder = String(localized: "Scene.Register.Input.Username.Placeholder",  defaultValue: "username", bundle: MastodonLocalization.bundle)
          /// amazing_%@
          public static func suggestion(_ p1: Any) -> String {
              return L10n.tr(String.LocalizationValue("Scene.Register.Input.Username.Suggestion.\(placeholder: .object)"), args: [String(describing: p1)])
          }
        }
      }
    }
    public enum Report {
      /// Are there any other posts you’d like to add to the report?
      public static let content1 = String(localized: "Scene.Report.Content1",  defaultValue: "Are there any other posts you’d like to add to the report?", bundle: MastodonLocalization.bundle)
      /// Is there anything the moderators should know about this report?
      public static let content2 = String(localized: "Scene.Report.Content2",  defaultValue: "Is there anything the moderators should know about this report?", bundle: MastodonLocalization.bundle)
      /// REPORTED
      public static let reported = String(localized: "Scene.Report.Reported",  defaultValue: "REPORTED", bundle: MastodonLocalization.bundle)
      /// Thanks for reporting, we’ll look into this.
      public static let reportSentTitle = String(localized: "Scene.Report.ReportSentTitle",  defaultValue: "Thanks for reporting, we’ll look into this.", bundle: MastodonLocalization.bundle)
      /// Send Report
      public static let send = String(localized: "Scene.Report.Send",  defaultValue: "Send Report", bundle: MastodonLocalization.bundle)
      /// Send without comment
      public static let skipToSend = String(localized: "Scene.Report.SkipToSend",  defaultValue: "Send without comment", bundle: MastodonLocalization.bundle)
      /// Step 1 of 2
      public static let step1 = String(localized: "Scene.Report.Step1",  defaultValue: "Step 1 of 2", bundle: MastodonLocalization.bundle)
      /// Step 2 of 2
      public static let step2 = String(localized: "Scene.Report.Step2",  defaultValue: "Step 2 of 2", bundle: MastodonLocalization.bundle)
      /// Type or paste additional comments
      public static let textPlaceholder = String(localized: "Scene.Report.TextPlaceholder",  defaultValue: "Type or paste additional comments", bundle: MastodonLocalization.bundle)
      /// Report %@
      public static func title(_ p1: Any) -> String {
          return L10n.tr(String.LocalizationValue("Scene.Report.Title.\(placeholder: .object)"), args: [String(describing: p1)])
      }
      /// Report
      public static let titleReport = String(localized: "Scene.Report.TitleReport",  defaultValue: "Report", bundle: MastodonLocalization.bundle)
      public enum StepFinal {
        /// Block %@
        public static func blockUser(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Scene.Report.StepFinal.BlockUser.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// Don’t want to see this?
        public static let dontWantToSeeThis = String(localized: "Scene.Report.StepFinal.DontWantToSeeThis",  defaultValue: "Don’t want to see this?", bundle: MastodonLocalization.bundle)
        /// Mute %@
        public static func muteUser(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Scene.Report.StepFinal.MuteUser.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// They will no longer be able to follow or see your posts, but they can see if they’ve been blocked.
        public static let theyWillNoLongerBeAbleToFollowOrSeeYourPostsButTheyCanSeeIfTheyveBeenBlocked = String(localized: "Scene.Report.StepFinal.TheyWillNoLongerBeAbleToFollowOrSeeYourPostsButTheyCanSeeIfTheyveBeenBlocked",  defaultValue: "They will no longer be able to follow or see your posts, but they can see if they’ve been blocked.", bundle: MastodonLocalization.bundle)
        /// Unfollow
        public static let unfollow = String(localized: "Scene.Report.StepFinal.Unfollow",  defaultValue: "Unfollow", bundle: MastodonLocalization.bundle)
        /// Unfollowed
        public static let unfollowed = String(localized: "Scene.Report.StepFinal.Unfollowed",  defaultValue: "Unfollowed", bundle: MastodonLocalization.bundle)
        /// Unfollow %@
        public static func unfollowUser(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Scene.Report.StepFinal.UnfollowUser.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// When you see something you don’t like on Mastodon, you can remove the person from your experience.
        public static let whenYouSeeSomethingYouDontLikeOnMastodonYouCanRemoveThePersonFromYourExperience = String(localized: "Scene.Report.StepFinal.WhenYouSeeSomethingYouDontLikeOnMastodonYouCanRemoveThePersonFromYourExperience.",  defaultValue: "When you see something you don’t like on Mastodon, you can remove the person from your experience.", bundle: MastodonLocalization.bundle)
        /// While we review this, you can take action against %@
        public static func whileWeReviewThisYouCanTakeActionAgainstUser(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Scene.Report.StepFinal.WhileWeReviewThisYouCanTakeActionAgainstUser.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// You won’t see their posts or boosts in your home feed. They won’t know they’ve been muted.
        public static let youWontSeeTheirPostsOrReblogsInYourHomeFeedTheyWontKnowTheyVeBeenMuted = String(localized: "Scene.Report.StepFinal.YouWontSeeTheirPostsOrReblogsInYourHomeFeedTheyWontKnowTheyVeBeenMuted",  defaultValue: "You won’t see their posts or boosts in your home feed. They won’t know they’ve been muted.", bundle: MastodonLocalization.bundle)
      }
      public enum StepFour {
        /// Is there anything else we should know?
        public static let isThereAnythingElseWeShouldKnow = String(localized: "Scene.Report.StepFour.IsThereAnythingElseWeShouldKnow",  defaultValue: "Is there anything else we should know?", bundle: MastodonLocalization.bundle)
        /// Step 4 of 4
        public static let step4Of4 = String(localized: "Scene.Report.StepFour.Step4Of4",  defaultValue: "Step 4 of 4", bundle: MastodonLocalization.bundle)
      }
      public enum StepOne {
        /// I don’t like it
        public static let iDontLikeIt = String(localized: "Scene.Report.StepOne.IDontLikeIt",  defaultValue: "I don’t like it", bundle: MastodonLocalization.bundle)
        /// It is not something you want to see
        public static let itIsNotSomethingYouWantToSee = String(localized: "Scene.Report.StepOne.ItIsNotSomethingYouWantToSee",  defaultValue: "It is not something you want to see", bundle: MastodonLocalization.bundle)
        /// It’s something else
        public static let itsSomethingElse = String(localized: "Scene.Report.StepOne.ItsSomethingElse",  defaultValue: "It’s something else", bundle: MastodonLocalization.bundle)
        /// It’s spam
        public static let itsSpam = String(localized: "Scene.Report.StepOne.ItsSpam",  defaultValue: "It’s spam", bundle: MastodonLocalization.bundle)
        /// It violates server rules
        public static let itViolatesServerRules = String(localized: "Scene.Report.StepOne.ItViolatesServerRules",  defaultValue: "It violates server rules", bundle: MastodonLocalization.bundle)
        /// Malicious links, fake engagement, or repetetive replies
        public static let maliciousLinksFakeEngagementOrRepetetiveReplies = String(localized: "Scene.Report.StepOne.MaliciousLinksFakeEngagementOrRepetetiveReplies",  defaultValue: "Malicious links, fake engagement, or repetetive replies", bundle: MastodonLocalization.bundle)
        /// Select the best match
        public static let selectTheBestMatch = String(localized: "Scene.Report.StepOne.SelectTheBestMatch",  defaultValue: "Select the best match", bundle: MastodonLocalization.bundle)
        /// Step 1 of 4
        public static let step1Of4 = String(localized: "Scene.Report.StepOne.Step1Of4",  defaultValue: "Step 1 of 4", bundle: MastodonLocalization.bundle)
        /// The issue does not fit into other categories
        public static let theIssueDoesNotFitIntoOtherCategories = String(localized: "Scene.Report.StepOne.TheIssueDoesNotFitIntoOtherCategories",  defaultValue: "The issue does not fit into other categories", bundle: MastodonLocalization.bundle)
        /// What's wrong with this account?
        public static let whatsWrongWithThisAccount = String(localized: "Scene.Report.StepOne.WhatsWrongWithThisAccount",  defaultValue: "What's wrong with this account?", bundle: MastodonLocalization.bundle)
        /// What's wrong with this post?
        public static let whatsWrongWithThisPost = String(localized: "Scene.Report.StepOne.WhatsWrongWithThisPost",  defaultValue: "What's wrong with this post?", bundle: MastodonLocalization.bundle)
        /// What's wrong with %@?
        public static func whatsWrongWithThisUsername(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Scene.Report.StepOne.WhatsWrongWithThisUsername.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// You are aware that it breaks specific rules
        public static let youAreAwareThatItBreaksSpecificRules = String(localized: "Scene.Report.StepOne.YouAreAwareThatItBreaksSpecificRules",  defaultValue: "You are aware that it breaks specific rules", bundle: MastodonLocalization.bundle)
      }
      public enum StepThree {
        /// Are there any posts that back up this report?
        public static let areThereAnyPostsThatBackUpThisReport = String(localized: "Scene.Report.StepThree.AreThereAnyPostsThatBackUpThisReport",  defaultValue: "Are there any posts that back up this report?", bundle: MastodonLocalization.bundle)
        /// Select all that apply
        public static let selectAllThatApply = String(localized: "Scene.Report.StepThree.SelectAllThatApply",  defaultValue: "Select all that apply", bundle: MastodonLocalization.bundle)
        /// Step 3 of 4
        public static let step3Of4 = String(localized: "Scene.Report.StepThree.Step3Of4",  defaultValue: "Step 3 of 4", bundle: MastodonLocalization.bundle)
      }
      public enum StepTwo {
        /// I just don’t like it
        public static let iJustDonTLikeIt = String(localized: "Scene.Report.StepTwo.IJustDon’tLikeIt",  defaultValue: "I just don’t like it", bundle: MastodonLocalization.bundle)
        /// Select all that apply
        public static let selectAllThatApply = String(localized: "Scene.Report.StepTwo.SelectAllThatApply",  defaultValue: "Select all that apply", bundle: MastodonLocalization.bundle)
        /// Step 2 of 4
        public static let step2Of4 = String(localized: "Scene.Report.StepTwo.Step2Of4",  defaultValue: "Step 2 of 4", bundle: MastodonLocalization.bundle)
        /// Which rules are being violated?
        public static let whichRulesAreBeingViolated = String(localized: "Scene.Report.StepTwo.WhichRulesAreBeingViolated",  defaultValue: "Which rules are being violated?", bundle: MastodonLocalization.bundle)
      }
    }
    public enum Search {
      /// Search
      public static let title = String(localized: "Scene.Search.Title",  defaultValue: "Search", bundle: MastodonLocalization.bundle)
      public enum Recommend {
        /// See All
        public static let buttonText = String(localized: "Scene.Search.Recommend.ButtonText",  defaultValue: "See All", bundle: MastodonLocalization.bundle)
        public enum Accounts {
          /// You may like to follow these accounts
          public static let description = String(localized: "Scene.Search.Recommend.Accounts.Description",  defaultValue: "You may like to follow these accounts", bundle: MastodonLocalization.bundle)
          /// Follow
          public static let follow = String(localized: "Scene.Search.Recommend.Accounts.Follow",  defaultValue: "Follow", bundle: MastodonLocalization.bundle)
          /// Accounts you might like
          public static let title = String(localized: "Scene.Search.Recommend.Accounts.Title",  defaultValue: "Accounts you might like", bundle: MastodonLocalization.bundle)
        }
        public enum HashTag {
          /// Hashtags that are getting quite a bit of attention
          public static let description = String(localized: "Scene.Search.Recommend.HashTag.Description",  defaultValue: "Hashtags that are getting quite a bit of attention", bundle: MastodonLocalization.bundle)
          /// %@ people are talking
          public static func peopleTalking(_ p1: Any) -> String {
              return L10n.tr(String.LocalizationValue("Scene.Search.Recommend.HashTag.PeopleTalking.\(placeholder: .object)"), args: [String(describing: p1)])
          }
          /// Trending on Mastodon
          public static let title = String(localized: "Scene.Search.Recommend.HashTag.Title",  defaultValue: "Trending on Mastodon", bundle: MastodonLocalization.bundle)
        }
      }
      public enum SearchBar {
        /// Cancel
        public static let cancel = String(localized: "Scene.Search.SearchBar.Cancel",  defaultValue: "Cancel", bundle: MastodonLocalization.bundle)
        /// Search hashtags and users
        public static let placeholder = String(localized: "Scene.Search.SearchBar.Placeholder",  defaultValue: "Search hashtags and users", bundle: MastodonLocalization.bundle)
      }
      public enum Searching {
        /// Clear
        public static let clear = String(localized: "Scene.Search.Searching.Clear",  defaultValue: "Clear", bundle: MastodonLocalization.bundle)
        /// Clear all
        public static let clearAll = String(localized: "Scene.Search.Searching.ClearAll",  defaultValue: "Clear all", bundle: MastodonLocalization.bundle)
        /// Go to #%@
        public static func hashtag(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Scene.Search.Searching.Hashtag.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// No recent searches.
        public static let noRecentSearches = String(localized: "Scene.Search.Searching.NoRecentSearches",  defaultValue: "No recent searches.", bundle: MastodonLocalization.bundle)
        /// People matching "%@"
        public static func people(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Scene.Search.Searching.People.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// Posts matching "%@"
        public static func posts(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Scene.Search.Searching.Posts.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// Go to @%@@%@
        public static func profile(_ p1: Any, _ p2: Any) -> String {
            return L10n.tr(String.LocalizationValue("Scene.Search.Searching.Profile.\(placeholder: .object).\(placeholder: .object)"), args: [String(describing: p1), String(describing: p2)])
        }
        /// Recent searches
        public static let recentSearch = String(localized: "Scene.Search.Searching.RecentSearch",  defaultValue: "Recent searches", bundle: MastodonLocalization.bundle)
        /// Open URL in Mastodon
        public static let url = String(localized: "Scene.Search.Searching.Url",  defaultValue: "Open URL in Mastodon", bundle: MastodonLocalization.bundle)
        public enum EmptyState {
          /// No results
          public static let noResults = String(localized: "Scene.Search.Searching.EmptyState.NoResults",  defaultValue: "No results", bundle: MastodonLocalization.bundle)
        }
        public enum NoUser {
          /// There's no Useraccount "%@" on %@
          public static func message(_ p1: Any, _ p2: Any) -> String {
              return L10n.tr(String.LocalizationValue("Scene.Search.Searching.NoUser.Message.\(placeholder: .object).\(placeholder: .object)"), args: [String(describing: p1), String(describing: p2)])
          }
          /// No User Account Found
          public static let title = String(localized: "Scene.Search.Searching.NoUser.Title",  defaultValue: "No User Account Found", bundle: MastodonLocalization.bundle)
        }
      }
    }
    public enum ServerPicker {
      /// We’ll pick a server based on your language if you continue without making a selection.
      public static let noServerSelectedHint = String(localized: "Scene.ServerPicker.NoServerSelectedHint",  defaultValue: "We’ll pick a server based on your language if you continue without making a selection.", bundle: MastodonLocalization.bundle)
      /// Pick Server
      public static let title = String(localized: "Scene.ServerPicker.Title",  defaultValue: "Pick Server", bundle: MastodonLocalization.bundle)
      public enum Button {
        /// Language
        public static let language = String(localized: "Scene.ServerPicker.Button.Language",  defaultValue: "Language", bundle: MastodonLocalization.bundle)
        /// See Less
        public static let seeLess = String(localized: "Scene.ServerPicker.Button.SeeLess",  defaultValue: "See Less", bundle: MastodonLocalization.bundle)
        /// See More
        public static let seeMore = String(localized: "Scene.ServerPicker.Button.SeeMore",  defaultValue: "See More", bundle: MastodonLocalization.bundle)
        /// Sign-up Speed
        public static let signupSpeed = String(localized: "Scene.ServerPicker.Button.SignupSpeed",  defaultValue: "Sign-up Speed", bundle: MastodonLocalization.bundle)
        public enum Category {
          /// academia
          public static let academia = String(localized: "Scene.ServerPicker.Button.Category.Academia",  defaultValue: "academia", bundle: MastodonLocalization.bundle)
          /// activism
          public static let activism = String(localized: "Scene.ServerPicker.Button.Category.Activism",  defaultValue: "activism", bundle: MastodonLocalization.bundle)
          /// All
          public static let all = String(localized: "Scene.ServerPicker.Button.Category.All",  defaultValue: "All", bundle: MastodonLocalization.bundle)
          /// Category: All
          public static let allAccessiblityDescription = String(localized: "Scene.ServerPicker.Button.Category.AllAccessiblityDescription",  defaultValue: "Category: All", bundle: MastodonLocalization.bundle)
          /// art
          public static let art = String(localized: "Scene.ServerPicker.Button.Category.Art",  defaultValue: "art", bundle: MastodonLocalization.bundle)
          /// food
          public static let food = String(localized: "Scene.ServerPicker.Button.Category.Food",  defaultValue: "food", bundle: MastodonLocalization.bundle)
          /// furry
          public static let furry = String(localized: "Scene.ServerPicker.Button.Category.Furry",  defaultValue: "furry", bundle: MastodonLocalization.bundle)
          /// games
          public static let games = String(localized: "Scene.ServerPicker.Button.Category.Games",  defaultValue: "games", bundle: MastodonLocalization.bundle)
          /// general
          public static let general = String(localized: "Scene.ServerPicker.Button.Category.General",  defaultValue: "general", bundle: MastodonLocalization.bundle)
          /// journalism
          public static let journalism = String(localized: "Scene.ServerPicker.Button.Category.Journalism",  defaultValue: "journalism", bundle: MastodonLocalization.bundle)
          /// lgbt
          public static let lgbt = String(localized: "Scene.ServerPicker.Button.Category.Lgbt",  defaultValue: "lgbt", bundle: MastodonLocalization.bundle)
          /// music
          public static let music = String(localized: "Scene.ServerPicker.Button.Category.Music",  defaultValue: "music", bundle: MastodonLocalization.bundle)
          /// regional
          public static let regional = String(localized: "Scene.ServerPicker.Button.Category.Regional",  defaultValue: "regional", bundle: MastodonLocalization.bundle)
          /// tech
          public static let tech = String(localized: "Scene.ServerPicker.Button.Category.Tech",  defaultValue: "tech", bundle: MastodonLocalization.bundle)
        }
      }
      public enum EmptyState {
        /// Something went wrong while loading the data. Check your internet connection.
        public static let badNetwork = String(localized: "Scene.ServerPicker.EmptyState.BadNetwork",  defaultValue: "Something went wrong while loading the data. Check your internet connection.", bundle: MastodonLocalization.bundle)
        /// Finding available servers...
        public static let findingServers = String(localized: "Scene.ServerPicker.EmptyState.FindingServers",  defaultValue: "Finding available servers...", bundle: MastodonLocalization.bundle)
        /// No results
        public static let noResults = String(localized: "Scene.ServerPicker.EmptyState.NoResults",  defaultValue: "No results", bundle: MastodonLocalization.bundle)
      }
      public enum Input {
        /// Search communities or enter URL
        public static let searchServersOrEnterUrl = String(localized: "Scene.ServerPicker.Input.SearchServersOrEnterUrl",  defaultValue: "Search communities or enter URL", bundle: MastodonLocalization.bundle)
      }
      public enum Label {
        /// CATEGORY
        public static let category = String(localized: "Scene.ServerPicker.Label.Category",  defaultValue: "CATEGORY", bundle: MastodonLocalization.bundle)
        /// LANGUAGE
        public static let language = String(localized: "Scene.ServerPicker.Label.Language",  defaultValue: "LANGUAGE", bundle: MastodonLocalization.bundle)
        /// USERS
        public static let users = String(localized: "Scene.ServerPicker.Label.Users",  defaultValue: "USERS", bundle: MastodonLocalization.bundle)
      }
      public enum Language {
        /// All
        public static let all = String(localized: "Scene.ServerPicker.Language.All",  defaultValue: "All", bundle: MastodonLocalization.bundle)
      }
      public enum Search {
        /// Search name or URL
        public static let placeholder = String(localized: "Scene.ServerPicker.Search.Placeholder",  defaultValue: "Search name or URL", bundle: MastodonLocalization.bundle)
      }
      public enum SignupSpeed {
        /// All
        public static let all = String(localized: "Scene.ServerPicker.SignupSpeed.All",  defaultValue: "All", bundle: MastodonLocalization.bundle)
        /// Instant Sign-up
        public static let instant = String(localized: "Scene.ServerPicker.SignupSpeed.Instant",  defaultValue: "Instant Sign-up", bundle: MastodonLocalization.bundle)
        /// Manual Review
        public static let manuallyReviewed = String(localized: "Scene.ServerPicker.SignupSpeed.ManuallyReviewed",  defaultValue: "Manual Review", bundle: MastodonLocalization.bundle)
      }
    }
    public enum ServerRules {
      /// privacy policy
      public static let privacyPolicy = String(localized: "Scene.ServerRules.PrivacyPolicy",  defaultValue: "privacy policy", bundle: MastodonLocalization.bundle)
      /// By continuing, you’re subject to the terms of service and privacy policy for %@.
      public static func prompt(_ p1: Any) -> String {
          return L10n.tr(String.LocalizationValue("Scene.ServerRules.Prompt.\(placeholder: .object)"), args: [String(describing: p1)])
      }
      /// By continuing, you agree to follow by the following rules set and enforced by the **%@** moderators.
      public static func subtitle(_ p1: Any) -> String {
          return L10n.tr(String.LocalizationValue("Scene.ServerRules.Subtitle.\(placeholder: .object)"), args: [String(describing: p1)])
      }
      /// terms of service
      public static let termsOfService = String(localized: "Scene.ServerRules.TermsOfService",  defaultValue: "terms of service", bundle: MastodonLocalization.bundle)
      /// Server Rules
      public static let title = String(localized: "Scene.ServerRules.Title",  defaultValue: "Server Rules", bundle: MastodonLocalization.bundle)
      public enum Button {
        /// I Agree
        public static let confirm = String(localized: "Scene.ServerRules.Button.Confirm",  defaultValue: "I Agree", bundle: MastodonLocalization.bundle)
        /// Disagree
        public static let disagree = String(localized: "Scene.ServerRules.Button.Disagree",  defaultValue: "Disagree", bundle: MastodonLocalization.bundle)
      }
    }
    public enum Settings {
      public enum AboutMastodon {
        /// Clear Media Storage
        public static let clearMediaStorage = String(localized: "Scene.Settings.AboutMastodon.ClearMediaStorage",  defaultValue: "Clear Media Storage", bundle: MastodonLocalization.bundle)
        /// Contribute to Mastodon
        public static let contributeToMastodon = String(localized: "Scene.Settings.AboutMastodon.ContributeToMastodon",  defaultValue: "Contribute to Mastodon", bundle: MastodonLocalization.bundle)
        /// Even More Settings
        public static let moreSettings = String(localized: "Scene.Settings.AboutMastodon.MoreSettings",  defaultValue: "Even More Settings", bundle: MastodonLocalization.bundle)
        /// Privacy Policy
        public static let privacyPolicy = String(localized: "Scene.Settings.AboutMastodon.PrivacyPolicy",  defaultValue: "Privacy Policy", bundle: MastodonLocalization.bundle)
        /// About
        public static let title = String(localized: "Scene.Settings.AboutMastodon.Title",  defaultValue: "About", bundle: MastodonLocalization.bundle)
      }
      public enum Donation {
        /// Manage donations
        public static let manage = String(localized: "Scene.Settings.Donation.Manage",  defaultValue: "Manage donations", bundle: MastodonLocalization.bundle)
        /// Donate to Mastodon
        public static let title = String(localized: "Scene.Settings.Donation.Title",  defaultValue: "Donate to Mastodon", bundle: MastodonLocalization.bundle)
      }
      public enum General {
        /// General
        public static let title = String(localized: "Scene.Settings.General.Title",  defaultValue: "General", bundle: MastodonLocalization.bundle)
        public enum Appearance {
          /// Dark
          public static let dark = String(localized: "Scene.Settings.General.Appearance.Dark",  defaultValue: "Dark", bundle: MastodonLocalization.bundle)
          /// Light
          public static let light = String(localized: "Scene.Settings.General.Appearance.Light",  defaultValue: "Light", bundle: MastodonLocalization.bundle)
          /// Appearance
          public static let sectionTitle = String(localized: "Scene.Settings.General.Appearance.SectionTitle",  defaultValue: "Appearance", bundle: MastodonLocalization.bundle)
          /// Use Device Appearance
          public static let system = String(localized: "Scene.Settings.General.Appearance.System",  defaultValue: "Use Device Appearance", bundle: MastodonLocalization.bundle)
        }
        public enum AskBefore {
          /// Boosting a Post
          public static let boostingAPost = String(localized: "Scene.Settings.General.AskBefore.BoostingAPost",  defaultValue: "Boosting a Post", bundle: MastodonLocalization.bundle)
          /// Deleting a Post
          public static let deletingAPost = String(localized: "Scene.Settings.General.AskBefore.DeletingAPost",  defaultValue: "Deleting a Post", bundle: MastodonLocalization.bundle)
          /// Posting without Alt Text
          public static let postingWithoutAltText = String(localized: "Scene.Settings.General.AskBefore.PostingWithoutAltText",  defaultValue: "Posting without Alt Text", bundle: MastodonLocalization.bundle)
          /// Ask before…
          public static let sectionTitle = String(localized: "Scene.Settings.General.AskBefore.SectionTitle",  defaultValue: "Ask before…", bundle: MastodonLocalization.bundle)
          /// Unfollowing Someone
          public static let unfollowingSomeone = String(localized: "Scene.Settings.General.AskBefore.UnfollowingSomeone",  defaultValue: "Unfollowing Someone", bundle: MastodonLocalization.bundle)
        }
        public enum Design {
          /// Design
          public static let sectionTitle = String(localized: "Scene.Settings.General.Design.SectionTitle",  defaultValue: "Design", bundle: MastodonLocalization.bundle)
          /// Play Animated Avatars and Emoji
          public static let showAnimations = String(localized: "Scene.Settings.General.Design.ShowAnimations",  defaultValue: "Play Animated Avatars and Emoji", bundle: MastodonLocalization.bundle)
        }
        public enum Language {
          /// Default Post Language
          public static let defaultPostLanguage = String(localized: "Scene.Settings.General.Language.DefaultPostLanguage",  defaultValue: "Default Post Language", bundle: MastodonLocalization.bundle)
          /// Language
          public static let sectionTitle = String(localized: "Scene.Settings.General.Language.SectionTitle",  defaultValue: "Language", bundle: MastodonLocalization.bundle)
        }
        public enum Links {
          /// Open in Browser
          public static let openInBrowser = String(localized: "Scene.Settings.General.Links.OpenInBrowser",  defaultValue: "Open in Browser", bundle: MastodonLocalization.bundle)
          /// Open in Mastodon
          public static let openInMastodon = String(localized: "Scene.Settings.General.Links.OpenInMastodon",  defaultValue: "Open in Mastodon", bundle: MastodonLocalization.bundle)
          /// Links
          public static let sectionTitle = String(localized: "Scene.Settings.General.Links.SectionTitle",  defaultValue: "Links", bundle: MastodonLocalization.bundle)
        }
      }
      public enum Notifications {
        /// Notifications
        public static let title = String(localized: "Scene.Settings.Notifications.Title",  defaultValue: "Notifications", bundle: MastodonLocalization.bundle)
        public enum Alert {
          /// Boosts
          public static let boosts = String(localized: "Scene.Settings.Notifications.Alert.Boosts",  defaultValue: "Boosts", bundle: MastodonLocalization.bundle)
          /// Favorites
          public static let favorites = String(localized: "Scene.Settings.Notifications.Alert.Favorites",  defaultValue: "Favorites", bundle: MastodonLocalization.bundle)
          /// Mentions & Replies
          public static let mentionsAndReplies = String(localized: "Scene.Settings.Notifications.Alert.MentionsAndReplies",  defaultValue: "Mentions & Replies", bundle: MastodonLocalization.bundle)
          /// New Followers
          public static let newFollowers = String(localized: "Scene.Settings.Notifications.Alert.NewFollowers",  defaultValue: "New Followers", bundle: MastodonLocalization.bundle)
        }
        public enum Disabled {
          /// Go to Notification Settings
          public static let goToSettings = String(localized: "Scene.Settings.Notifications.Disabled.GoToSettings",  defaultValue: "Go to Notification Settings", bundle: MastodonLocalization.bundle)
          /// Turn on notifications from your device settings to see updates on your lock screen.
          public static let notificationHint = String(localized: "Scene.Settings.Notifications.Disabled.NotificationHint",  defaultValue: "Turn on notifications from your device settings to see updates on your lock screen.", bundle: MastodonLocalization.bundle)
        }
        public enum Policy {
          /// Anyone
          public static let anyone = String(localized: "Scene.Settings.Notifications.Policy.Anyone",  defaultValue: "Anyone", bundle: MastodonLocalization.bundle)
          /// People you follow
          public static let follow = String(localized: "Scene.Settings.Notifications.Policy.Follow",  defaultValue: "People you follow", bundle: MastodonLocalization.bundle)
          /// People who follow you
          public static let followers = String(localized: "Scene.Settings.Notifications.Policy.Followers",  defaultValue: "People who follow you", bundle: MastodonLocalization.bundle)
          /// No one
          public static let noone = String(localized: "Scene.Settings.Notifications.Policy.Noone",  defaultValue: "No one", bundle: MastodonLocalization.bundle)
          /// Get Notifications from
          public static let title = String(localized: "Scene.Settings.Notifications.Policy.Title",  defaultValue: "Get Notifications from", bundle: MastodonLocalization.bundle)
        }
      }
      public enum Overview {
        /// About Mastodon
        public static let aboutMastodon = String(localized: "Scene.Settings.Overview.AboutMastodon",  defaultValue: "About Mastodon", bundle: MastodonLocalization.bundle)
        /// General
        public static let general = String(localized: "Scene.Settings.Overview.General",  defaultValue: "General", bundle: MastodonLocalization.bundle)
        /// Logout %@
        public static func logout(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Scene.Settings.Overview.Logout.\(placeholder: .object)"), args: [String(describing: p1)])
        }
        /// Notifications
        public static let notifications = String(localized: "Scene.Settings.Overview.Notifications",  defaultValue: "Notifications", bundle: MastodonLocalization.bundle)
        /// Privacy & Safety
        public static let privacySafety = String(localized: "Scene.Settings.Overview.PrivacySafety",  defaultValue: "Privacy & Safety", bundle: MastodonLocalization.bundle)
        /// Server Details
        public static let serverDetails = String(localized: "Scene.Settings.Overview.ServerDetails",  defaultValue: "Server Details", bundle: MastodonLocalization.bundle)
        /// Donate to Mastodon
        public static let supportMastodon = String(localized: "Scene.Settings.Overview.SupportMastodon",  defaultValue: "Donate to Mastodon", bundle: MastodonLocalization.bundle)
        /// Settings
        public static let title = String(localized: "Scene.Settings.Overview.Title",  defaultValue: "Settings", bundle: MastodonLocalization.bundle)
      }
      public enum PrivacySafety {
        /// Appear in Search Engines
        public static let appearInSearchEngines = String(localized: "Scene.Settings.PrivacySafety.AppearInSearchEngines",  defaultValue: "Appear in Search Engines", bundle: MastodonLocalization.bundle)
        /// Manually Approve Follow Requests
        public static let manuallyApproveFollowRequests = String(localized: "Scene.Settings.PrivacySafety.ManuallyApproveFollowRequests",  defaultValue: "Manually Approve Follow Requests", bundle: MastodonLocalization.bundle)
        /// Show Followers & Following
        public static let showFollowersAndFollowing = String(localized: "Scene.Settings.PrivacySafety.ShowFollowersAndFollowing",  defaultValue: "Show Followers & Following", bundle: MastodonLocalization.bundle)
        /// Suggest My Account to Others
        public static let suggestMyAccountToOthers = String(localized: "Scene.Settings.PrivacySafety.SuggestMyAccountToOthers",  defaultValue: "Suggest My Account to Others", bundle: MastodonLocalization.bundle)
        /// Privacy & Safety
        public static let title = String(localized: "Scene.Settings.PrivacySafety.Title",  defaultValue: "Privacy & Safety", bundle: MastodonLocalization.bundle)
        public enum DefaultPostVisibility {
          /// Default Post Visibility
          public static let title = String(localized: "Scene.Settings.PrivacySafety.DefaultPostVisibility.Title",  defaultValue: "Default Post Visibility", bundle: MastodonLocalization.bundle)
        }
        public enum Preset {
          /// Custom
          public static let custom = String(localized: "Scene.Settings.PrivacySafety.Preset.Custom",  defaultValue: "Custom", bundle: MastodonLocalization.bundle)
          /// Open & Public
          public static let openAndPublic = String(localized: "Scene.Settings.PrivacySafety.Preset.OpenAndPublic",  defaultValue: "Open & Public", bundle: MastodonLocalization.bundle)
          /// Private & Restricted
          public static let privateAndRestricted = String(localized: "Scene.Settings.PrivacySafety.Preset.PrivateAndRestricted",  defaultValue: "Private & Restricted", bundle: MastodonLocalization.bundle)
          /// Preset
          public static let title = String(localized: "Scene.Settings.PrivacySafety.Preset.Title",  defaultValue: "Preset", bundle: MastodonLocalization.bundle)
        }
      }
      public enum ServerDetails {
        /// About
        public static let about = String(localized: "Scene.Settings.ServerDetails.About",  defaultValue: "About", bundle: MastodonLocalization.bundle)
        /// Rules
        public static let rules = String(localized: "Scene.Settings.ServerDetails.Rules",  defaultValue: "Rules", bundle: MastodonLocalization.bundle)
        public enum AboutInstance {
          /// A legal notice
          public static let legalNotice = String(localized: "Scene.Settings.ServerDetails.AboutInstance.LegalNotice",  defaultValue: "A legal notice", bundle: MastodonLocalization.bundle)
          /// Message Admin
          public static let messageAdmin = String(localized: "Scene.Settings.ServerDetails.AboutInstance.MessageAdmin",  defaultValue: "Message Admin", bundle: MastodonLocalization.bundle)
          /// Administrator
          public static let title = String(localized: "Scene.Settings.ServerDetails.AboutInstance.Title",  defaultValue: "Administrator", bundle: MastodonLocalization.bundle)
        }
      }
    }
    public enum SuggestionAccount {
      /// Follow all
      public static let followAll = String(localized: "Scene.SuggestionAccount.FollowAll",  defaultValue: "Follow all", bundle: MastodonLocalization.bundle)
      /// Popular on Mastodon
      public static let title = String(localized: "Scene.SuggestionAccount.Title",  defaultValue: "Popular on Mastodon", bundle: MastodonLocalization.bundle)
    }
    public enum Thread {
      /// Post
      public static let backTitle = String(localized: "Scene.Thread.BackTitle",  defaultValue: "Post", bundle: MastodonLocalization.bundle)
      /// Post from %@
      public static func title(_ p1: Any) -> String {
          return L10n.tr(String.LocalizationValue("Scene.Thread.Title.\(placeholder: .object)"), args: [String(describing: p1)])
      }
    }
    public enum Welcome {
      /// Join %@
      public static func joinDefaultServer(_ p1: Any) -> String {
          return L10n.tr(String.LocalizationValue("Scene.Welcome.JoinDefaultServer.\(placeholder: .object)"), args: [String(describing: p1)])
      }
      /// Learn more
      public static let learnMore = String(localized: "Scene.Welcome.LearnMore",  defaultValue: "Learn more", bundle: MastodonLocalization.bundle)
      /// Log In
      public static let logIn = String(localized: "Scene.Welcome.LogIn",  defaultValue: "Log In", bundle: MastodonLocalization.bundle)
      /// Pick another server
      public static let pickServer = String(localized: "Scene.Welcome.PickServer",  defaultValue: "Pick another server", bundle: MastodonLocalization.bundle)
      public enum Education {
        public enum A11Y {
          public enum WhatIsMastodon {
            /// What is Mastodon?
            public static let title = String(localized: "Scene.Welcome.Education.A11Y.WhatIsMastodon.Title",  defaultValue: "What is Mastodon?", bundle: MastodonLocalization.bundle)
          }
        }
        public enum Mastodon {
          /// Mastodon is a decentralized social network, meaning no single company controls it. It’s made up of many independently-run servers, all connected together.
          public static let description = String(localized: "Scene.Welcome.Education.Mastodon.Description",  defaultValue: "Mastodon is a decentralized social network, meaning no single company controls it. It’s made up of many independently-run servers, all connected together.", bundle: MastodonLocalization.bundle)
          /// Welcome to Mastodon
          public static let title = String(localized: "Scene.Welcome.Education.Mastodon.Title",  defaultValue: "Welcome to Mastodon", bundle: MastodonLocalization.bundle)
        }
        public enum Servers {
          /// Every Mastodon account is hosted on a server — each with its own values, rules, & admins. No matter which one you pick, you can follow and interact with people on any server.
          public static let description = String(localized: "Scene.Welcome.Education.Servers.Description",  defaultValue: "Every Mastodon account is hosted on a server — each with its own values, rules, & admins. No matter which one you pick, you can follow and interact with people on any server.", bundle: MastodonLocalization.bundle)
          /// What are servers?
          public static let title = String(localized: "Scene.Welcome.Education.Servers.Title",  defaultValue: "What are servers?", bundle: MastodonLocalization.bundle)
        }
      }
      public enum Separator {
        /// or
        public static let or = String(localized: "Scene.Welcome.Separator.Or",  defaultValue: "or", bundle: MastodonLocalization.bundle)
      }
    }
  }
  public enum Widget {
    public enum Common {
      /// Sorry but this Widget family is unsupported.
      public static let unsupportedWidgetFamily = String(localized: "Widget.Common.UnsupportedWidgetFamily",  defaultValue: "Sorry but this Widget family is unsupported.", bundle: MastodonLocalization.bundle)
      /// Please open Mastodon to log in to an Account.
      public static let userNotLoggedIn = String(localized: "Widget.Common.UserNotLoggedIn",  defaultValue: "Please open Mastodon to log in to an Account.", bundle: MastodonLocalization.bundle)
    }
    public enum FollowersCount {
      /// Show number of followers.
      public static let configurationDescription = String(localized: "Widget.FollowersCount.ConfigurationDescription",  defaultValue: "Show number of followers.", bundle: MastodonLocalization.bundle)
      /// Followers
      public static let configurationDisplayName = String(localized: "Widget.FollowersCount.ConfigurationDisplayName",  defaultValue: "Followers", bundle: MastodonLocalization.bundle)
      /// %@ followers today
      public static func followersToday(_ p1: Any) -> String {
          return L10n.tr(String.LocalizationValue("Widget.FollowersCount.FollowersToday.\(placeholder: .object)"), args: [String(describing: p1)])
      }
      /// FOLLOWERS
      public static let title = String(localized: "Widget.FollowersCount.Title",  defaultValue: "FOLLOWERS", bundle: MastodonLocalization.bundle)
    }
    public enum Hashtag {
      public enum Configuration {
        /// Shows a recent post with the selected hashtag.
        public static let description = String(localized: "Widget.Hashtag.Configuration.Description",  defaultValue: "Shows a recent post with the selected hashtag.", bundle: MastodonLocalization.bundle)
        /// Hashtag
        public static let displayName = String(localized: "Widget.Hashtag.Configuration.DisplayName",  defaultValue: "Hashtag", bundle: MastodonLocalization.bundle)
      }
      public enum NotFound {
        /// @johnMastodon@no-such.account
        public static let account = String(localized: "Widget.Hashtag.NotFound.Account",  defaultValue: "@johnMastodon@no-such.account", bundle: MastodonLocalization.bundle)
        /// John Mastodon
        public static let accountName = String(localized: "Widget.Hashtag.NotFound.AccountName",  defaultValue: "John Mastodon", bundle: MastodonLocalization.bundle)
        /// Sorry, we couldn’t find any posts with the hashtag <a>#%@</a>. Please try a <a>#DifferentHashtag</a> or check the widget settings.
        public static func content(_ p1: Any) -> String {
            return L10n.tr(String.LocalizationValue("Widget.Hashtag.NotFound.Content.\(placeholder: .object)"), args: [String(describing: p1)])
        }
      }
      public enum Placeholder {
        /// @johnMastodon@no-such.account
        public static let account = String(localized: "Widget.Hashtag.Placeholder.Account",  defaultValue: "@johnMastodon@no-such.account", bundle: MastodonLocalization.bundle)
        /// John Mastodon
        public static let accountName = String(localized: "Widget.Hashtag.Placeholder.AccountName",  defaultValue: "John Mastodon", bundle: MastodonLocalization.bundle)
        /// This is how a post with a <a>#hashtag</a> would look. Pick whichever <a>#hashtag</a> you want in the widget settings.
        public static let content = String(localized: "Widget.Hashtag.Placeholder.Content",  defaultValue: "This is how a post with a <a>#hashtag</a> would look. Pick whichever <a>#hashtag</a> you want in the widget settings.", bundle: MastodonLocalization.bundle)
      }
    }
    public enum LatestFollowers {
      /// Show latest followers.
      public static let configurationDescription = String(localized: "Widget.LatestFollowers.ConfigurationDescription",  defaultValue: "Show latest followers.", bundle: MastodonLocalization.bundle)
      /// Latest followers
      public static let configurationDisplayName = String(localized: "Widget.LatestFollowers.ConfigurationDisplayName",  defaultValue: "Latest followers", bundle: MastodonLocalization.bundle)
      /// Last update: %@
      public static func lastUpdate(_ p1: Any) -> String {
          return L10n.tr(String.LocalizationValue("Widget.LatestFollowers.LastUpdate.\(placeholder: .object)"), args: [String(describing: p1)])
      }
      /// Latest followers
      public static let title = String(localized: "Widget.LatestFollowers.Title",  defaultValue: "Latest followers", bundle: MastodonLocalization.bundle)
    }
    public enum MultipleFollowers {
      /// Show number of followers for multiple accounts.
      public static let configurationDescription = String(localized: "Widget.MultipleFollowers.ConfigurationDescription",  defaultValue: "Show number of followers for multiple accounts.", bundle: MastodonLocalization.bundle)
      /// Multiple followers
      public static let configurationDisplayName = String(localized: "Widget.MultipleFollowers.ConfigurationDisplayName",  defaultValue: "Multiple followers", bundle: MastodonLocalization.bundle)
      public enum MockUser {
        /// another@follower.social
        public static let accountName = String(localized: "Widget.MultipleFollowers.MockUser.AccountName",  defaultValue: "another@follower.social", bundle: MastodonLocalization.bundle)
        /// Another follower
        public static let displayName = String(localized: "Widget.MultipleFollowers.MockUser.DisplayName",  defaultValue: "Another follower", bundle: MastodonLocalization.bundle)
      }
    }
  }
  public enum A11y {
    public enum Plural {
      public enum Count {
        /// Plural format key: "%#@character_count@"
        public static func charactersLeft(_ p1: Int) -> String {
            return L10n.tr(String.LocalizationValue("a11y.plural.count.characters_left.\(placeholder: .int)"), args: [p1])
        }
        /// Plural format key: "Input limit exceeds %#@character_count@"
        public static func inputLimitExceeds(_ p1: Int) -> String {
            return L10n.tr(String.LocalizationValue("a11y.plural.count.input_limit_exceeds.\(placeholder: .int)"), args: [p1])
        }
        /// Plural format key: "Input limit remains %#@character_count@"
        public static func inputLimitRemains(_ p1: Int) -> String {
            return L10n.tr(String.LocalizationValue("a11y.plural.count.input_limit_remains.\(placeholder: .int)"), args: [p1])
        }
        public enum Unread {
          /// Plural format key: "%#@notification_count_unread_notification@"
          public static func notification(_ p1: Int) -> String {
              return L10n.tr(String.LocalizationValue("a11y.plural.count.unread.notification.\(placeholder: .int)"), args: [p1])
          }
        }
      }
    }
  }
  public enum Date {
    public enum Day {
      /// Plural format key: "%#@count_day_left@"
      public static func `left`(_ p1: Int) -> String {
          return L10n.tr(String.LocalizationValue("date.day.left.\(placeholder: .int)"), args: [p1])
      }
      public enum Ago {
        /// Plural format key: "%#@count_day_ago_abbr@"
        public static func abbr(_ p1: Int) -> String {
            return L10n.tr(String.LocalizationValue("date.day.ago.abbr.\(placeholder: .int)"), args: [p1])
        }
      }
    }
    public enum Hour {
      /// Plural format key: "%#@count_hour_left@"
      public static func `left`(_ p1: Int) -> String {
          return L10n.tr(String.LocalizationValue("date.hour.left.\(placeholder: .int)"), args: [p1])
      }
      public enum Ago {
        /// Plural format key: "%#@count_hour_ago_abbr@"
        public static func abbr(_ p1: Int) -> String {
            return L10n.tr(String.LocalizationValue("date.hour.ago.abbr.\(placeholder: .int)"), args: [p1])
        }
      }
    }
    public enum Minute {
      /// Plural format key: "%#@count_minute_left@"
      public static func `left`(_ p1: Int) -> String {
          return L10n.tr(String.LocalizationValue("date.minute.left.\(placeholder: .int)"), args: [p1])
      }
      public enum Ago {
        /// Plural format key: "%#@count_minute_ago_abbr@"
        public static func abbr(_ p1: Int) -> String {
            return L10n.tr(String.LocalizationValue("date.minute.ago.abbr.\(placeholder: .int)"), args: [p1])
        }
      }
    }
    public enum Month {
      /// Plural format key: "%#@count_month_left@"
      public static func `left`(_ p1: Int) -> String {
          return L10n.tr(String.LocalizationValue("date.month.left.\(placeholder: .int)"), args: [p1])
      }
      public enum Ago {
        /// Plural format key: "%#@count_month_ago_abbr@"
        public static func abbr(_ p1: Int) -> String {
            return L10n.tr(String.LocalizationValue("date.month.ago.abbr.\(placeholder: .int)"), args: [p1])
        }
      }
    }
    public enum Second {
      /// Plural format key: "%#@count_second_left@"
      public static func `left`(_ p1: Int) -> String {
          return L10n.tr(String.LocalizationValue("date.second.left.\(placeholder: .int)"), args: [p1])
      }
      public enum Ago {
        /// Plural format key: "%#@count_second_ago_abbr@"
        public static func abbr(_ p1: Int) -> String {
            return L10n.tr(String.LocalizationValue("date.second.ago.abbr.\(placeholder: .int)"), args: [p1])
        }
      }
    }
    public enum Year {
      /// Plural format key: "%#@count_year_left@"
      public static func `left`(_ p1: Int) -> String {
          return L10n.tr(String.LocalizationValue("date.year.left.\(placeholder: .int)"), args: [p1])
      }
      public enum Ago {
        /// Plural format key: "%#@count_year_ago_abbr@"
        public static func abbr(_ p1: Int) -> String {
            return L10n.tr(String.LocalizationValue("date.year.ago.abbr.\(placeholder: .int)"), args: [p1])
        }
      }
    }
  }
  public enum Plural {
    /// Plural format key: "%#@count_people_talking@"
    public static func peopleTalking(_ p1: Int) -> String {
        return L10n.tr(String.LocalizationValue("plural.people_talking.\(placeholder: .int)"), args: [p1])
    }
      public static func followedByAndMutuals(_ names: String, p2: Int) -> String {
          return L10n.tr(String.LocalizationValue("plural.followed_by_and_mutual.\(placeholder: .object).\(placeholder: .int)"), args: [names, p2])
      }
      
    public enum Count {
      /// Plural format key: "%#@count_accounts_that_you_follow@"
      public static func accountsThatYouFollow(_ p1: Int) -> String {
          return L10n.tr(String.LocalizationValue("plural.count.accounts_that_you_follow.\(placeholder: .int)"), args: [p1])
      }
      /// Plural format key: "%#@attachment_count@"
      public static func attachment(_ p1: Int) -> String {
          return L10n.tr(String.LocalizationValue("plural.count.attachment.\(placeholder: .int)"), args: [p1])
      }
      /// Plural format key: "%#@audio_count@"
      public static func audio(_ p1: Int) -> String {
          return L10n.tr(String.LocalizationValue("plural.count.audio.\(placeholder: .int)"), args: [p1])
      }
      /// Plural format key: "%#@favorite_count@"
      public static func favorite(_ p1: Int) -> String {
          return L10n.tr(String.LocalizationValue("plural.count.favorite.\(placeholder: .int)"), args: [p1])
      }
      /// Plural format key: "%#@count_follower@"
      public static func follower(_ p1: Int) -> String {
          return L10n.tr(String.LocalizationValue("plural.count.follower.\(placeholder: .int)"), args: [p1])
      }
      /// Plural format key: "%#@count_following@"
      public static func following(_ p1: Int) -> String {
          return L10n.tr(String.LocalizationValue("plural.count.following.\(placeholder: .int)"), args: [p1])
      }
      /// Plural format key: "%#@gif_count@"
      public static func gif(_ p1: Int) -> String {
          return L10n.tr(String.LocalizationValue("plural.count.gif.\(placeholder: .int)"), args: [p1])
      }
      /// Plural format key: "%#@image_count@"
      public static func image(_ p1: Int) -> String {
          return L10n.tr(String.LocalizationValue("plural.count.image.\(placeholder: .int)"), args: [p1])
      }
      /// Plural format key: "%#@media_count@"
      public static func media(_ p1: Int) -> String {
          return L10n.tr(String.LocalizationValue("plural.count.media.\(placeholder: .int)"), args: [p1])
      }
      /// Plural format key: "%#@count_signups@"
      public static func newSignups(_ p1: Int) -> String {
          return L10n.tr(String.LocalizationValue("plural.count.new_signups.\(placeholder: .int)"), args: [p1])
      }
      /// Plural format key: "%#@count_of_your_followers@"
      public static func ofYourFollowers(_ p1: Int) -> String {
          return L10n.tr(String.LocalizationValue("plural.count.of_your_followers.\(placeholder: .int)"), args: [p1])
      }
      /// Plural format key: "%#@count_others@"
      public static func others(_ p1: Int) -> String {
          return L10n.tr(String.LocalizationValue("plural.count.others.\(placeholder: .int)"), args: [p1])
      }
      /// Plural format key: "%#@count_people@"
      public static func peopleBoosted(_ p1: Int) -> String {
          return L10n.tr(String.LocalizationValue("plural.count.people_boosted.\(placeholder: .int)"), args: [p1])
      }
      /// Plural format key: "%#@count_people@"
      public static func peopleFavourited(_ p1: Int) -> String {
          return L10n.tr(String.LocalizationValue("plural.count.people_favourited.\(placeholder: .int)"), args: [p1])
      }
      /// Plural format key: "%#@count_people@"
      public static func peopleFollowedYou(_ p1: Int) -> String {
          return L10n.tr(String.LocalizationValue("plural.count.people_followed_you.\(placeholder: .int)"), args: [p1])
      }
      /// Plural format key: "%#@poll_count@"
      public static func poll(_ p1: Int) -> String {
          return L10n.tr(String.LocalizationValue("plural.count.poll.\(placeholder: .int).\(placeholder: .int)"), args: [p1])
      }
      /// Plural format key: "%#@count_others@"
      public static func pollThatYouAndOthersVotedIn(_ p1: Int) -> String {
          return L10n.tr(String.LocalizationValue("plural.count.poll_that_you_and_others_voted_in.\(placeholder: .int)"), args: [p1])
      }
      /// Plural format key: "%#@post_count@"
      public static func post(_ p1: Int) -> String {
          return L10n.tr(String.LocalizationValue("plural.count.post.\(placeholder: .int)"), args: [p1])
      }
      /// Plural format key: "%#@reblog_count@"
      public static func reblog(_ p1: Int) -> String {
          return L10n.tr(String.LocalizationValue("plural.count.reblog.\(placeholder: .int)"), args: [p1])
      }
      /// Plural format key: "%#@reblog_count@"
      public static func reblogA11y(_ p1: Int) -> String {
          return L10n.tr(String.LocalizationValue("plural.count.reblog_a11y.\(placeholder: .int)"), args: [p1])
      }
      /// Plural format key: "%#@reply_count@"
      public static func reply(_ p1: Int) -> String {
          return L10n.tr(String.LocalizationValue("plural.count.reply.\(placeholder: .int)"), args: [p1])
      }
      /// Plural format key: "%#@video_count@"
      public static func video(_ p1: Int) -> String {
          return L10n.tr(String.LocalizationValue("plural.count.video.\(placeholder: .int)"), args: [p1])
      }
      /// Plural format key: "%#@vote_count@"
      public static func vote(_ p1: Int) -> String {
          return L10n.tr(String.LocalizationValue("plural.count.vote.\(placeholder: .int)"), args: [p1])
      }
      /// Plural format key: "%#@voter_count@"
      public static func voter(_ p1: Int) -> String {
          return L10n.tr(String.LocalizationValue("plural.count.voter.\(placeholder: .int)"), args: [p1])
      }
    }
    public enum FilteredNotificationBanner {
      /// Plural format key: "%#@number_of_requests@"
      public static func subtitle(_ p1: Int) -> String {
          return L10n.tr(String.LocalizationValue("plural.filtered_notification_banner.subtitle.\(placeholder: .int)"), args: [p1])
      }
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

extension L10n {
    private static func replacementOptions(_ replacementArgs: [CVarArg]) -> String.LocalizationOptions {
        var options = String.LocalizationOptions()
        options.replacements = replacementArgs
        return options
    }
    
    private static func tr(_ replaceable: String.LocalizationValue, args: [CVarArg]) -> String {
        var options = replacementOptions(args)
        let localized = String(localized: replaceable, options: options, bundle: MastodonLocalization.bundle)
        return localized
    }
}
