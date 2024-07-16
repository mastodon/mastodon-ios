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
        public static let blockEntireDomain = L10n.tr("Localizable", "Common.Alerts.BlockDomain.BlockEntireDomain", fallback: "Block Domain")
        /// Are you really, really sure you want to block the entire %@? In most cases a few targeted blocks or mutes are sufficient and preferable. You will not see content from that domain and any of your followers from that domain will be removed.
        public static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.BlockDomain.Title", String(describing: p1), fallback: "Are you really, really sure you want to block the entire %@? In most cases a few targeted blocks or mutes are sufficient and preferable. You will not see content from that domain and any of your followers from that domain will be removed.")
        }
      }
      public enum BoostAPost {
        /// Boost
        public static let boost = L10n.tr("Localizable", "Common.Alerts.BoostAPost.Boost", fallback: "Boost")
        /// Cancel
        public static let cancel = L10n.tr("Localizable", "Common.Alerts.BoostAPost.Cancel", fallback: "Cancel")
        /// Boost Post?
        public static let titleBoost = L10n.tr("Localizable", "Common.Alerts.BoostAPost.TitleBoost", fallback: "Boost Post?")
        /// Unboost Post?
        public static let titleUnboost = L10n.tr("Localizable", "Common.Alerts.BoostAPost.TitleUnboost", fallback: "Unboost Post?")
        /// Unboost
        public static let unboost = L10n.tr("Localizable", "Common.Alerts.BoostAPost.Unboost", fallback: "Unboost")
      }
      public enum CleanCache {
        /// Successfully cleaned %@ cache.
        public static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.CleanCache.Message", String(describing: p1), fallback: "Successfully cleaned %@ cache.")
        }
        /// Clean Cache
        public static let title = L10n.tr("Localizable", "Common.Alerts.CleanCache.Title", fallback: "Clean Cache")
      }
      public enum Common {
        /// Please try again.
        public static let pleaseTryAgain = L10n.tr("Localizable", "Common.Alerts.Common.PleaseTryAgain", fallback: "Please try again.")
        /// Please try again later.
        public static let pleaseTryAgainLater = L10n.tr("Localizable", "Common.Alerts.Common.PleaseTryAgainLater", fallback: "Please try again later.")
      }
      public enum DeletePost {
        /// Are you sure you want to delete this post?
        public static let message = L10n.tr("Localizable", "Common.Alerts.DeletePost.Message", fallback: "Are you sure you want to delete this post?")
        /// Delete Post
        public static let title = L10n.tr("Localizable", "Common.Alerts.DeletePost.Title", fallback: "Delete Post")
      }
      public enum EditProfileFailure {
        /// Cannot edit profile. Please try again.
        public static let message = L10n.tr("Localizable", "Common.Alerts.EditProfileFailure.Message", fallback: "Cannot edit profile. Please try again.")
        /// Edit Profile Error
        public static let title = L10n.tr("Localizable", "Common.Alerts.EditProfileFailure.Title", fallback: "Edit Profile Error")
      }
      public enum MediaMissingAltText {
        /// Cancel
        public static let cancel = L10n.tr("Localizable", "Common.Alerts.MediaMissingAltText.Cancel", fallback: "Cancel")
        /// %d of your images are missing alt text.
        /// Post Anyway?
        public static func message(_ p1: Int) -> String {
          return L10n.tr("Localizable", "Common.Alerts.MediaMissingAltText.Message", p1, fallback: "%d of your images are missing alt text.\nPost Anyway?")
        }
        /// Post
        public static let post = L10n.tr("Localizable", "Common.Alerts.MediaMissingAltText.Post", fallback: "Post")
        /// Media Missing Alt Text
        public static let title = L10n.tr("Localizable", "Common.Alerts.MediaMissingAltText.Title", fallback: "Media Missing Alt Text")
      }
      public enum PublishPostFailure {
        /// Failed to publish the post.
        /// Please check your internet connection.
        public static let message = L10n.tr("Localizable", "Common.Alerts.PublishPostFailure.Message", fallback: "Failed to publish the post.\nPlease check your internet connection.")
        /// Publish Failure
        public static let title = L10n.tr("Localizable", "Common.Alerts.PublishPostFailure.Title", fallback: "Publish Failure")
        public enum AttachmentsMessage {
          /// Cannot attach more than one video.
          public static let moreThanOneVideo = L10n.tr("Localizable", "Common.Alerts.PublishPostFailure.AttachmentsMessage.MoreThanOneVideo", fallback: "Cannot attach more than one video.")
          /// Cannot attach a video to a post that already contains images.
          public static let videoAttachWithPhoto = L10n.tr("Localizable", "Common.Alerts.PublishPostFailure.AttachmentsMessage.VideoAttachWithPhoto", fallback: "Cannot attach a video to a post that already contains images.")
        }
      }
      public enum SavePhotoFailure {
        /// Please enable the photo library access permission to save the photo.
        public static let message = L10n.tr("Localizable", "Common.Alerts.SavePhotoFailure.Message", fallback: "Please enable the photo library access permission to save the photo.")
        /// Save Photo Failure
        public static let title = L10n.tr("Localizable", "Common.Alerts.SavePhotoFailure.Title", fallback: "Save Photo Failure")
      }
      public enum ServerError {
        /// Server Error
        public static let title = L10n.tr("Localizable", "Common.Alerts.ServerError.Title", fallback: "Server Error")
      }
      public enum SignOut {
        /// Sign Out
        public static let confirm = L10n.tr("Localizable", "Common.Alerts.SignOut.Confirm", fallback: "Sign Out")
        /// Are you sure you want to sign out?
        public static let message = L10n.tr("Localizable", "Common.Alerts.SignOut.Message", fallback: "Are you sure you want to sign out?")
        /// Sign Out
        public static let title = L10n.tr("Localizable", "Common.Alerts.SignOut.Title", fallback: "Sign Out")
      }
      public enum SignUpFailure {
        /// Sign Up Failure
        public static let title = L10n.tr("Localizable", "Common.Alerts.SignUpFailure.Title", fallback: "Sign Up Failure")
      }
      public enum TranslationFailed {
        /// OK
        public static let button = L10n.tr("Localizable", "Common.Alerts.TranslationFailed.Button", fallback: "OK")
        /// Translation failed. Maybe the administrator has not enabled translations on this server or this server is running an older version of Mastodon where translations are not yet supported.
        public static let message = L10n.tr("Localizable", "Common.Alerts.TranslationFailed.Message", fallback: "Translation failed. Maybe the administrator has not enabled translations on this server or this server is running an older version of Mastodon where translations are not yet supported.")
        /// Note
        public static let title = L10n.tr("Localizable", "Common.Alerts.TranslationFailed.Title", fallback: "Note")
      }
      public enum UnfollowUser {
        /// Cancel
        public static let cancel = L10n.tr("Localizable", "Common.Alerts.UnfollowUser.Cancel", fallback: "Cancel")
        /// Unfollow %@?
        public static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.UnfollowUser.Title", String(describing: p1), fallback: "Unfollow %@?")
        }
        /// Unfollow
        public static let unfollow = L10n.tr("Localizable", "Common.Alerts.UnfollowUser.Unfollow", fallback: "Unfollow")
      }
      public enum VoteFailure {
        /// The poll has ended
        public static let pollEnded = L10n.tr("Localizable", "Common.Alerts.VoteFailure.PollEnded", fallback: "The poll has ended")
        /// Vote Failure
        public static let title = L10n.tr("Localizable", "Common.Alerts.VoteFailure.Title", fallback: "Vote Failure")
      }
    }
    public enum Controls {
      public enum Actions {
        /// Add
        public static let add = L10n.tr("Localizable", "Common.Controls.Actions.Add", fallback: "Add")
        /// Back
        public static let back = L10n.tr("Localizable", "Common.Controls.Actions.Back", fallback: "Back")
        /// Block %@
        public static func blockDomain(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Actions.BlockDomain", String(describing: p1), fallback: "Block %@")
        }
        /// Bookmark
        public static let bookmark = L10n.tr("Localizable", "Common.Controls.Actions.Bookmark", fallback: "Bookmark")
        /// Cancel
        public static let cancel = L10n.tr("Localizable", "Common.Controls.Actions.Cancel", fallback: "Cancel")
        /// Compose
        public static let compose = L10n.tr("Localizable", "Common.Controls.Actions.Compose", fallback: "Compose")
        /// Confirm
        public static let confirm = L10n.tr("Localizable", "Common.Controls.Actions.Confirm", fallback: "Confirm")
        /// Continue
        public static let `continue` = L10n.tr("Localizable", "Common.Controls.Actions.Continue", fallback: "Continue")
        /// Copy
        public static let copy = L10n.tr("Localizable", "Common.Controls.Actions.Copy", fallback: "Copy")
        /// Copy Photo
        public static let copyPhoto = L10n.tr("Localizable", "Common.Controls.Actions.CopyPhoto", fallback: "Copy Photo")
        /// Delete
        public static let delete = L10n.tr("Localizable", "Common.Controls.Actions.Delete", fallback: "Delete")
        /// Discard
        public static let discard = L10n.tr("Localizable", "Common.Controls.Actions.Discard", fallback: "Discard")
        /// Done
        public static let done = L10n.tr("Localizable", "Common.Controls.Actions.Done", fallback: "Done")
        /// Edit
        public static let edit = L10n.tr("Localizable", "Common.Controls.Actions.Edit", fallback: "Edit")
        /// Edit
        public static let editPost = L10n.tr("Localizable", "Common.Controls.Actions.EditPost", fallback: "Edit")
        /// Find people to follow
        public static let findPeople = L10n.tr("Localizable", "Common.Controls.Actions.FindPeople", fallback: "Find people to follow")
        /// Follow %@
        public static func follow(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Actions.Follow", String(describing: p1), fallback: "Follow %@")
        }
        /// Manually search instead
        public static let manuallySearch = L10n.tr("Localizable", "Common.Controls.Actions.ManuallySearch", fallback: "Manually search instead")
        /// Next
        public static let next = L10n.tr("Localizable", "Common.Controls.Actions.Next", fallback: "Next")
        /// OK
        public static let ok = L10n.tr("Localizable", "Common.Controls.Actions.Ok", fallback: "OK")
        /// Open
        public static let `open` = L10n.tr("Localizable", "Common.Controls.Actions.Open", fallback: "Open")
        /// Open in Browser
        public static let openInBrowser = L10n.tr("Localizable", "Common.Controls.Actions.OpenInBrowser", fallback: "Open in Browser")
        /// Open in Safari
        public static let openInSafari = L10n.tr("Localizable", "Common.Controls.Actions.OpenInSafari", fallback: "Open in Safari")
        /// Preview
        public static let preview = L10n.tr("Localizable", "Common.Controls.Actions.Preview", fallback: "Preview")
        /// Previous
        public static let previous = L10n.tr("Localizable", "Common.Controls.Actions.Previous", fallback: "Previous")
        /// Remove
        public static let remove = L10n.tr("Localizable", "Common.Controls.Actions.Remove", fallback: "Remove")
        /// Remove Bookmark
        public static let removeBookmark = L10n.tr("Localizable", "Common.Controls.Actions.RemoveBookmark", fallback: "Remove Bookmark")
        /// Reply
        public static let reply = L10n.tr("Localizable", "Common.Controls.Actions.Reply", fallback: "Reply")
        /// Report %@
        public static func reportUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Actions.ReportUser", String(describing: p1), fallback: "Report %@")
        }
        /// Save
        public static let save = L10n.tr("Localizable", "Common.Controls.Actions.Save", fallback: "Save")
        /// Save Photo
        public static let savePhoto = L10n.tr("Localizable", "Common.Controls.Actions.SavePhoto", fallback: "Save Photo")
        /// See More
        public static let seeMore = L10n.tr("Localizable", "Common.Controls.Actions.SeeMore", fallback: "See More")
        /// Settings
        public static let settings = L10n.tr("Localizable", "Common.Controls.Actions.Settings", fallback: "Settings")
        /// Share
        public static let share = L10n.tr("Localizable", "Common.Controls.Actions.Share", fallback: "Share")
        /// Share Post
        public static let sharePost = L10n.tr("Localizable", "Common.Controls.Actions.SharePost", fallback: "Share Post")
        /// Share %@
        public static func shareUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Actions.ShareUser", String(describing: p1), fallback: "Share %@")
        }
        /// Log in
        public static let signIn = L10n.tr("Localizable", "Common.Controls.Actions.SignIn", fallback: "Log in")
        /// Skip
        public static let skip = L10n.tr("Localizable", "Common.Controls.Actions.Skip", fallback: "Skip")
        /// Take Photo
        public static let takePhoto = L10n.tr("Localizable", "Common.Controls.Actions.TakePhoto", fallback: "Take Photo")
        /// Try Again
        public static let tryAgain = L10n.tr("Localizable", "Common.Controls.Actions.TryAgain", fallback: "Try Again")
        /// Unblock %@
        public static func unblockDomain(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Actions.UnblockDomain", String(describing: p1), fallback: "Unblock %@")
        }
        /// Unfollow %@
        public static func unfollow(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Actions.Unfollow", String(describing: p1), fallback: "Unfollow %@")
        }
        public enum TranslatePost {
          /// Translate from %@
          public static func title(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Actions.TranslatePost.Title", String(describing: p1), fallback: "Translate from %@")
          }
          /// Unknown
          public static let unknownLanguage = L10n.tr("Localizable", "Common.Controls.Actions.TranslatePost.UnknownLanguage", fallback: "Unknown")
        }
      }
      public enum Friendship {
        /// Block
        public static let block = L10n.tr("Localizable", "Common.Controls.Friendship.Block", fallback: "Block")
        /// Block domain %@
        public static func blockDomain(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Friendship.BlockDomain", String(describing: p1), fallback: "Block domain %@")
        }
        /// Blocked
        public static let blocked = L10n.tr("Localizable", "Common.Controls.Friendship.Blocked", fallback: "Blocked")
        /// Block %@
        public static func blockUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Friendship.BlockUser", String(describing: p1), fallback: "Block %@")
        }
        /// Domain Blocked
        public static let domainBlocked = L10n.tr("Localizable", "Common.Controls.Friendship.DomainBlocked", fallback: "Domain Blocked")
        /// Edit Info
        public static let editInfo = L10n.tr("Localizable", "Common.Controls.Friendship.EditInfo", fallback: "Edit Info")
        /// Follow
        public static let follow = L10n.tr("Localizable", "Common.Controls.Friendship.Follow", fallback: "Follow")
        /// Following
        public static let following = L10n.tr("Localizable", "Common.Controls.Friendship.Following", fallback: "Following")
        /// Hide Boosts
        public static let hideReblogs = L10n.tr("Localizable", "Common.Controls.Friendship.HideReblogs", fallback: "Hide Boosts")
        /// Mute
        public static let mute = L10n.tr("Localizable", "Common.Controls.Friendship.Mute", fallback: "Mute")
        /// Muted
        public static let muted = L10n.tr("Localizable", "Common.Controls.Friendship.Muted", fallback: "Muted")
        /// Mute %@
        public static func muteUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Friendship.MuteUser", String(describing: p1), fallback: "Mute %@")
        }
        /// Pending
        public static let pending = L10n.tr("Localizable", "Common.Controls.Friendship.Pending", fallback: "Pending")
        /// Request
        public static let request = L10n.tr("Localizable", "Common.Controls.Friendship.Request", fallback: "Request")
        /// Show Boosts
        public static let showReblogs = L10n.tr("Localizable", "Common.Controls.Friendship.ShowReblogs", fallback: "Show Boosts")
        /// Unblock
        public static let unblock = L10n.tr("Localizable", "Common.Controls.Friendship.Unblock", fallback: "Unblock")
        /// Unblock %@
        public static func unblockUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Friendship.UnblockUser", String(describing: p1), fallback: "Unblock %@")
        }
        /// Unmute
        public static let unmute = L10n.tr("Localizable", "Common.Controls.Friendship.Unmute", fallback: "Unmute")
        /// Unmute %@
        public static func unmuteUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Friendship.UnmuteUser", String(describing: p1), fallback: "Unmute %@")
        }
      }
      public enum Keyboard {
        public enum Common {
          /// Compose New Post
          public static let composeNewPost = L10n.tr("Localizable", "Common.Controls.Keyboard.Common.ComposeNewPost", fallback: "Compose New Post")
          /// Open Settings
          public static let openSettings = L10n.tr("Localizable", "Common.Controls.Keyboard.Common.OpenSettings", fallback: "Open Settings")
          /// Show Favorites
          public static let showFavorites = L10n.tr("Localizable", "Common.Controls.Keyboard.Common.ShowFavorites", fallback: "Show Favorites")
          /// Switch to %@
          public static func switchToTab(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Keyboard.Common.SwitchToTab", String(describing: p1), fallback: "Switch to %@")
          }
        }
        public enum SegmentedControl {
          /// Next Section
          public static let nextSection = L10n.tr("Localizable", "Common.Controls.Keyboard.SegmentedControl.NextSection", fallback: "Next Section")
          /// Previous Section
          public static let previousSection = L10n.tr("Localizable", "Common.Controls.Keyboard.SegmentedControl.PreviousSection", fallback: "Previous Section")
        }
        public enum Timeline {
          /// Next Post
          public static let nextStatus = L10n.tr("Localizable", "Common.Controls.Keyboard.Timeline.NextStatus", fallback: "Next Post")
          /// Open Author's Profile
          public static let openAuthorProfile = L10n.tr("Localizable", "Common.Controls.Keyboard.Timeline.OpenAuthorProfile", fallback: "Open Author's Profile")
          /// Open Booster's Profile
          public static let openRebloggerProfile = L10n.tr("Localizable", "Common.Controls.Keyboard.Timeline.OpenRebloggerProfile", fallback: "Open Booster's Profile")
          /// Open Post
          public static let openStatus = L10n.tr("Localizable", "Common.Controls.Keyboard.Timeline.OpenStatus", fallback: "Open Post")
          /// Preview Image
          public static let previewImage = L10n.tr("Localizable", "Common.Controls.Keyboard.Timeline.PreviewImage", fallback: "Preview Image")
          /// Previous Post
          public static let previousStatus = L10n.tr("Localizable", "Common.Controls.Keyboard.Timeline.PreviousStatus", fallback: "Previous Post")
          /// Reply to Post
          public static let replyStatus = L10n.tr("Localizable", "Common.Controls.Keyboard.Timeline.ReplyStatus", fallback: "Reply to Post")
          /// Toggle Content Warning
          public static let toggleContentWarning = L10n.tr("Localizable", "Common.Controls.Keyboard.Timeline.ToggleContentWarning", fallback: "Toggle Content Warning")
          /// Toggle Favorite on Post
          public static let toggleFavorite = L10n.tr("Localizable", "Common.Controls.Keyboard.Timeline.ToggleFavorite", fallback: "Toggle Favorite on Post")
          /// Toggle Boost on Post
          public static let toggleReblog = L10n.tr("Localizable", "Common.Controls.Keyboard.Timeline.ToggleReblog", fallback: "Toggle Boost on Post")
        }
      }
      public enum Status {
        /// Content Warning
        public static let contentWarning = L10n.tr("Localizable", "Common.Controls.Status.ContentWarning", fallback: "Content Warning")
        /// Edited %@
        public static func editedAtTimestampPrefix(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Status.EditedAtTimestampPrefix", String(describing: p1), fallback: "Edited %@")
        }
        /// %@ via %@
        public static func linkViaUser(_ p1: Any, _ p2: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Status.LinkViaUser", String(describing: p1), String(describing: p2), fallback: "%@ via %@")
        }
        /// Load Embed
        public static let loadEmbed = L10n.tr("Localizable", "Common.Controls.Status.LoadEmbed", fallback: "Load Embed")
        /// Tap anywhere to reveal
        public static let mediaContentWarning = L10n.tr("Localizable", "Common.Controls.Status.MediaContentWarning", fallback: "Tap anywhere to reveal")
        /// %@ via %@
        public static func postedViaApplication(_ p1: Any, _ p2: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Status.PostedViaApplication", String(describing: p1), String(describing: p2), fallback: "%@ via %@")
        }
        /// Sensitive Content
        public static let sensitiveContent = L10n.tr("Localizable", "Common.Controls.Status.SensitiveContent", fallback: "Sensitive Content")
        /// Show Post
        public static let showPost = L10n.tr("Localizable", "Common.Controls.Status.ShowPost", fallback: "Show Post")
        /// Show user profile
        public static let showUserProfile = L10n.tr("Localizable", "Common.Controls.Status.ShowUserProfile", fallback: "Show user profile")
        /// Tap to reveal
        public static let tapToReveal = L10n.tr("Localizable", "Common.Controls.Status.TapToReveal", fallback: "Tap to reveal")
        /// %@ boosted
        public static func userReblogged(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Status.UserReblogged", String(describing: p1), fallback: "%@ boosted")
        }
        /// Replied to %@
        public static func userRepliedTo(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Status.UserRepliedTo", String(describing: p1), fallback: "Replied to %@")
        }
        public enum Actions {
          /// Copy Link
          public static let copyLink = L10n.tr("Localizable", "Common.Controls.Status.Actions.CopyLink", fallback: "Copy Link")
          /// Favorite
          public static let favorite = L10n.tr("Localizable", "Common.Controls.Status.Actions.Favorite", fallback: "Favorite")
          /// Hide
          public static let hide = L10n.tr("Localizable", "Common.Controls.Status.Actions.Hide", fallback: "Hide")
          /// Menu
          public static let menu = L10n.tr("Localizable", "Common.Controls.Status.Actions.Menu", fallback: "Menu")
          /// Boost
          public static let reblog = L10n.tr("Localizable", "Common.Controls.Status.Actions.Reblog", fallback: "Boost")
          /// Reply
          public static let reply = L10n.tr("Localizable", "Common.Controls.Status.Actions.Reply", fallback: "Reply")
          /// Share Link in Post
          public static let shareLinkInPost = L10n.tr("Localizable", "Common.Controls.Status.Actions.ShareLinkInPost", fallback: "Share Link in Post")
          /// Show GIF
          public static let showGif = L10n.tr("Localizable", "Common.Controls.Status.Actions.ShowGif", fallback: "Show GIF")
          /// Show image
          public static let showImage = L10n.tr("Localizable", "Common.Controls.Status.Actions.ShowImage", fallback: "Show image")
          /// Show video player
          public static let showVideoPlayer = L10n.tr("Localizable", "Common.Controls.Status.Actions.ShowVideoPlayer", fallback: "Show video player")
          /// Tap then hold to show menu
          public static let tapThenHoldToShowMenu = L10n.tr("Localizable", "Common.Controls.Status.Actions.TapThenHoldToShowMenu", fallback: "Tap then hold to show menu")
          /// Unfavorite
          public static let unfavorite = L10n.tr("Localizable", "Common.Controls.Status.Actions.Unfavorite", fallback: "Unfavorite")
          /// Undo boost
          public static let unreblog = L10n.tr("Localizable", "Common.Controls.Status.Actions.Unreblog", fallback: "Undo boost")
          public enum A11YLabels {
            /// Boost
            public static let reblog = L10n.tr("Localizable", "Common.Controls.Status.Actions.A11YLabels.Reblog", fallback: "Boost")
            /// Undo boost
            public static let unreblog = L10n.tr("Localizable", "Common.Controls.Status.Actions.A11YLabels.Unreblog", fallback: "Undo boost")
          }
        }
        public enum Buttons {
          /// Last edit %@
          public static func editHistoryDetail(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Status.Buttons.EditHistoryDetail", String(describing: p1), fallback: "Last edit %@")
          }
          /// Edit History
          public static let editHistoryTitle = L10n.tr("Localizable", "Common.Controls.Status.Buttons.EditHistoryTitle", fallback: "Edit History")
          /// Favorites
          public static let favoritesTitle = L10n.tr("Localizable", "Common.Controls.Status.Buttons.FavoritesTitle", fallback: "Favorites")
          /// Boosts
          public static let reblogsTitle = L10n.tr("Localizable", "Common.Controls.Status.Buttons.ReblogsTitle", fallback: "Boosts")
        }
        public enum Card {
          /// By
          public static let by = L10n.tr("Localizable", "Common.Controls.Status.Card.By", fallback: "By")
          /// By %@
          public static func byAuthor(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Status.Card.ByAuthor", String(describing: p1), fallback: "By %@")
          }
        }
        public enum EditHistory {
          /// Original Post · %@
          public static func originalPost(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Status.EditHistory.OriginalPost", String(describing: p1), fallback: "Original Post · %@")
          }
          /// Edit History
          public static let title = L10n.tr("Localizable", "Common.Controls.Status.EditHistory.Title", fallback: "Edit History")
        }
        public enum Media {
          /// %@, attachment %d of %d
          public static func accessibilityLabel(_ p1: Any, _ p2: Int, _ p3: Int) -> String {
            return L10n.tr("Localizable", "Common.Controls.Status.Media.AccessibilityLabel", String(describing: p1), p2, p3, fallback: "%@, attachment %d of %d")
          }
          /// Expands the GIF. Double-tap and hold to show actions
          public static let expandGifHint = L10n.tr("Localizable", "Common.Controls.Status.Media.ExpandGifHint", fallback: "Expands the GIF. Double-tap and hold to show actions")
          /// Expands the image. Double-tap and hold to show actions
          public static let expandImageHint = L10n.tr("Localizable", "Common.Controls.Status.Media.ExpandImageHint", fallback: "Expands the image. Double-tap and hold to show actions")
          /// Shows the video player. Double-tap and hold to show actions
          public static let expandVideoHint = L10n.tr("Localizable", "Common.Controls.Status.Media.ExpandVideoHint", fallback: "Shows the video player. Double-tap and hold to show actions")
        }
        public enum MetaEntity {
          /// Email address: %@
          public static func email(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Status.MetaEntity.Email", String(describing: p1), fallback: "Email address: %@")
          }
          /// Hashtag: %@
          public static func hashtag(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Status.MetaEntity.Hashtag", String(describing: p1), fallback: "Hashtag: %@")
          }
          /// Show Profile: %@
          public static func mention(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Status.MetaEntity.Mention", String(describing: p1), fallback: "Show Profile: %@")
          }
          /// Link: %@
          public static func url(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Status.MetaEntity.Url", String(describing: p1), fallback: "Link: %@")
          }
        }
        public enum Poll {
          /// Closed
          public static let closed = L10n.tr("Localizable", "Common.Controls.Status.Poll.Closed", fallback: "Closed")
          /// Vote
          public static let vote = L10n.tr("Localizable", "Common.Controls.Status.Poll.Vote", fallback: "Vote")
        }
        public enum Tag {
          /// Email
          public static let email = L10n.tr("Localizable", "Common.Controls.Status.Tag.Email", fallback: "Email")
          /// Emoji
          public static let emoji = L10n.tr("Localizable", "Common.Controls.Status.Tag.Emoji", fallback: "Emoji")
          /// Hashtag
          public static let hashtag = L10n.tr("Localizable", "Common.Controls.Status.Tag.Hashtag", fallback: "Hashtag")
          /// Link
          public static let link = L10n.tr("Localizable", "Common.Controls.Status.Tag.Link", fallback: "Link")
          /// Mention
          public static let mention = L10n.tr("Localizable", "Common.Controls.Status.Tag.Mention", fallback: "Mention")
          /// URL
          public static let url = L10n.tr("Localizable", "Common.Controls.Status.Tag.Url", fallback: "URL")
        }
        public enum Translation {
          /// Show Original
          public static let showOriginal = L10n.tr("Localizable", "Common.Controls.Status.Translation.ShowOriginal", fallback: "Show Original")
          /// Translated from %@ using %@
          public static func translatedFrom(_ p1: Any, _ p2: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Status.Translation.TranslatedFrom", String(describing: p1), String(describing: p2), fallback: "Translated from %@ using %@")
          }
          /// Unknown
          public static let unknownLanguage = L10n.tr("Localizable", "Common.Controls.Status.Translation.UnknownLanguage", fallback: "Unknown")
          /// Unknown
          public static let unknownProvider = L10n.tr("Localizable", "Common.Controls.Status.Translation.UnknownProvider", fallback: "Unknown")
        }
        public enum Visibility {
          /// Only mentioned user can see this post.
          public static let direct = L10n.tr("Localizable", "Common.Controls.Status.Visibility.Direct", fallback: "Only mentioned user can see this post.")
          /// Only their followers can see this post.
          public static let `private` = L10n.tr("Localizable", "Common.Controls.Status.Visibility.Private", fallback: "Only their followers can see this post.")
          /// Only my followers can see this post.
          public static let privateFromMe = L10n.tr("Localizable", "Common.Controls.Status.Visibility.PrivateFromMe", fallback: "Only my followers can see this post.")
          /// Everyone can see this post but not display in the public timeline.
          public static let unlisted = L10n.tr("Localizable", "Common.Controls.Status.Visibility.Unlisted", fallback: "Everyone can see this post but not display in the public timeline.")
        }
      }
      public enum Tabs {
        /// Home
        public static let home = L10n.tr("Localizable", "Common.Controls.Tabs.Home", fallback: "Home")
        /// Notifications
        public static let notifications = L10n.tr("Localizable", "Common.Controls.Tabs.Notifications", fallback: "Notifications")
        /// Profile
        public static let profile = L10n.tr("Localizable", "Common.Controls.Tabs.Profile", fallback: "Profile")
        /// Search and Explore
        public static let searchAndExplore = L10n.tr("Localizable", "Common.Controls.Tabs.SearchAndExplore", fallback: "Search and Explore")
        public enum A11Y {
          /// Explore
          public static let explore = L10n.tr("Localizable", "Common.Controls.Tabs.A11Y.Explore", fallback: "Explore")
          /// Search
          public static let search = L10n.tr("Localizable", "Common.Controls.Tabs.A11Y.Search", fallback: "Search")
        }
      }
      public enum Timeline {
        /// Filtered
        public static let filtered = L10n.tr("Localizable", "Common.Controls.Timeline.Filtered", fallback: "Filtered")
        public enum Header {
          /// You can’t view this user’s profile
          /// until they unblock you.
          public static let blockedWarning = L10n.tr("Localizable", "Common.Controls.Timeline.Header.BlockedWarning", fallback: "You can’t view this user’s profile\nuntil they unblock you.")
          /// You can’t view this user's profile
          /// until you unblock them.
          /// Your profile looks like this to them.
          public static let blockingWarning = L10n.tr("Localizable", "Common.Controls.Timeline.Header.BlockingWarning", fallback: "You can’t view this user's profile\nuntil you unblock them.\nYour profile looks like this to them.")
          /// No Post Found
          public static let noStatusFound = L10n.tr("Localizable", "Common.Controls.Timeline.Header.NoStatusFound", fallback: "No Post Found")
          /// This user has been suspended.
          public static let suspendedWarning = L10n.tr("Localizable", "Common.Controls.Timeline.Header.SuspendedWarning", fallback: "This user has been suspended.")
          /// You can’t view %@’s profile
          /// until they unblock you.
          public static func userBlockedWarning(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Timeline.Header.UserBlockedWarning", String(describing: p1), fallback: "You can’t view %@’s profile\nuntil they unblock you.")
          }
          /// You can’t view %@’s profile
          /// until you unblock them.
          /// Your profile looks like this to them.
          public static func userBlockingWarning(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Timeline.Header.UserBlockingWarning", String(describing: p1), fallback: "You can’t view %@’s profile\nuntil you unblock them.\nYour profile looks like this to them.")
          }
          /// %@’s account has been suspended.
          public static func userSuspendedWarning(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Timeline.Header.UserSuspendedWarning", String(describing: p1), fallback: "%@’s account has been suspended.")
          }
        }
        public enum Loader {
          /// Loading missing posts...
          public static let loadingMissingPosts = L10n.tr("Localizable", "Common.Controls.Timeline.Loader.LoadingMissingPosts", fallback: "Loading missing posts...")
          /// Load missing posts
          public static let loadMissingPosts = L10n.tr("Localizable", "Common.Controls.Timeline.Loader.LoadMissingPosts", fallback: "Load missing posts")
          /// Show more replies
          public static let showMoreReplies = L10n.tr("Localizable", "Common.Controls.Timeline.Loader.ShowMoreReplies", fallback: "Show more replies")
        }
        public enum Timestamp {
          /// Now
          public static let now = L10n.tr("Localizable", "Common.Controls.Timeline.Timestamp.Now", fallback: "Now")
        }
      }
    }
    public enum UserList {
      /// %@ followers
      public static func followersCount(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Common.UserList.FollowersCount", String(describing: p1), fallback: "%@ followers")
      }
      /// No verified link
      public static let noVerifiedLink = L10n.tr("Localizable", "Common.UserList.NoVerifiedLink", fallback: "No verified link")
    }
  }
  public enum Extension {
    public enum OpenIn {
      /// This doesn't seem to be a valid Mastodon link.
      public static let invalidLinkError = L10n.tr("Localizable", "Extension.OpenIn.InvalidLinkError", fallback: "This doesn't seem to be a valid Mastodon link.")
    }
  }
  public enum Scene {
    public enum AccountList {
      /// Add Account
      public static let addAccount = L10n.tr("Localizable", "Scene.AccountList.AddAccount", fallback: "Add Account")
      /// Dismiss Account Switcher
      public static let dismissAccountSwitcher = L10n.tr("Localizable", "Scene.AccountList.DismissAccountSwitcher", fallback: "Dismiss Account Switcher")
      /// Logout
      public static let logout = L10n.tr("Localizable", "Scene.AccountList.Logout", fallback: "Logout")
      /// Log Out Of All Accounts
      public static let logoutAllAccounts = L10n.tr("Localizable", "Scene.AccountList.LogoutAllAccounts", fallback: "Log Out Of All Accounts")
      /// Current selected profile: %@. Double tap then hold to show account switcher
      public static func tabBarHint(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.AccountList.TabBarHint", String(describing: p1), fallback: "Current selected profile: %@. Double tap then hold to show account switcher")
      }
    }
    public enum Bookmark {
      /// Bookmarks
      public static let title = L10n.tr("Localizable", "Scene.Bookmark.Title", fallback: "Bookmarks")
    }
    public enum Compose {
      /// Publish
      public static let composeAction = L10n.tr("Localizable", "Scene.Compose.ComposeAction", fallback: "Publish")
      /// Type or paste what’s on your mind
      public static let contentInputPlaceholder = L10n.tr("Localizable", "Scene.Compose.ContentInputPlaceholder", fallback: "Type or paste what’s on your mind")
      /// replying to %@
      public static func replyingToUser(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.Compose.ReplyingToUser", String(describing: p1), fallback: "replying to %@")
      }
      public enum Accessibility {
        /// Add Attachment
        public static let appendAttachment = L10n.tr("Localizable", "Scene.Compose.Accessibility.AppendAttachment", fallback: "Add Attachment")
        /// Add Poll
        public static let appendPoll = L10n.tr("Localizable", "Scene.Compose.Accessibility.AppendPoll", fallback: "Add Poll")
        /// Custom Emoji Picker
        public static let customEmojiPicker = L10n.tr("Localizable", "Scene.Compose.Accessibility.CustomEmojiPicker", fallback: "Custom Emoji Picker")
        /// Disable Content Warning
        public static let disableContentWarning = L10n.tr("Localizable", "Scene.Compose.Accessibility.DisableContentWarning", fallback: "Disable Content Warning")
        /// Enable Content Warning
        public static let enableContentWarning = L10n.tr("Localizable", "Scene.Compose.Accessibility.EnableContentWarning", fallback: "Enable Content Warning")
        /// Posting as %@
        public static func postingAs(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Scene.Compose.Accessibility.PostingAs", String(describing: p1), fallback: "Posting as %@")
        }
        /// Post Options
        public static let postOptions = L10n.tr("Localizable", "Scene.Compose.Accessibility.PostOptions", fallback: "Post Options")
        /// Post Visibility Menu
        public static let postVisibilityMenu = L10n.tr("Localizable", "Scene.Compose.Accessibility.PostVisibilityMenu", fallback: "Post Visibility Menu")
        /// Remove Poll
        public static let removePoll = L10n.tr("Localizable", "Scene.Compose.Accessibility.RemovePoll", fallback: "Remove Poll")
      }
      public enum Attachment {
        /// This %@ is broken and can’t be
        /// uploaded to Mastodon.
        public static func attachmentBroken(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Scene.Compose.Attachment.AttachmentBroken", String(describing: p1), fallback: "This %@ is broken and can’t be\nuploaded to Mastodon.")
        }
        /// Attachment too large
        public static let attachmentTooLarge = L10n.tr("Localizable", "Scene.Compose.Attachment.AttachmentTooLarge", fallback: "Attachment too large")
        /// Can not recognize this media attachment
        public static let canNotRecognizeThisMediaAttachment = L10n.tr("Localizable", "Scene.Compose.Attachment.CanNotRecognizeThisMediaAttachment", fallback: "Can not recognize this media attachment")
        /// Compressing...
        public static let compressingState = L10n.tr("Localizable", "Scene.Compose.Attachment.CompressingState", fallback: "Compressing...")
        /// Describe the photo for the visually-impaired...
        public static let descriptionPhoto = L10n.tr("Localizable", "Scene.Compose.Attachment.DescriptionPhoto", fallback: "Describe the photo for the visually-impaired...")
        /// Describe the video for the visually-impaired...
        public static let descriptionVideo = L10n.tr("Localizable", "Scene.Compose.Attachment.DescriptionVideo", fallback: "Describe the video for the visually-impaired...")
        /// Load Failed
        public static let loadFailed = L10n.tr("Localizable", "Scene.Compose.Attachment.LoadFailed", fallback: "Load Failed")
        /// photo
        public static let photo = L10n.tr("Localizable", "Scene.Compose.Attachment.Photo", fallback: "photo")
        /// Server Processing...
        public static let serverProcessingState = L10n.tr("Localizable", "Scene.Compose.Attachment.ServerProcessingState", fallback: "Server Processing...")
        /// Upload Failed
        public static let uploadFailed = L10n.tr("Localizable", "Scene.Compose.Attachment.UploadFailed", fallback: "Upload Failed")
        /// video
        public static let video = L10n.tr("Localizable", "Scene.Compose.Attachment.Video", fallback: "video")
      }
      public enum AutoComplete {
        /// Space to add
        public static let spaceToAdd = L10n.tr("Localizable", "Scene.Compose.AutoComplete.SpaceToAdd", fallback: "Space to add")
      }
      public enum ContentWarning {
        /// Write an accurate warning here...
        public static let placeholder = L10n.tr("Localizable", "Scene.Compose.ContentWarning.Placeholder", fallback: "Write an accurate warning here...")
      }
      public enum Keyboard {
        /// Add Attachment - %@
        public static func appendAttachmentEntry(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Scene.Compose.Keyboard.AppendAttachmentEntry", String(describing: p1), fallback: "Add Attachment - %@")
        }
        /// Discard Post
        public static let discardPost = L10n.tr("Localizable", "Scene.Compose.Keyboard.DiscardPost", fallback: "Discard Post")
        /// Publish Post
        public static let publishPost = L10n.tr("Localizable", "Scene.Compose.Keyboard.PublishPost", fallback: "Publish Post")
        /// Select Visibility - %@
        public static func selectVisibilityEntry(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Scene.Compose.Keyboard.SelectVisibilityEntry", String(describing: p1), fallback: "Select Visibility - %@")
        }
        /// Toggle Content Warning
        public static let toggleContentWarning = L10n.tr("Localizable", "Scene.Compose.Keyboard.ToggleContentWarning", fallback: "Toggle Content Warning")
        /// Toggle Poll
        public static let togglePoll = L10n.tr("Localizable", "Scene.Compose.Keyboard.TogglePoll", fallback: "Toggle Poll")
      }
      public enum Language {
        /// Other Language…
        public static let other = L10n.tr("Localizable", "Scene.Compose.Language.Other", fallback: "Other Language…")
        /// Recent
        public static let recent = L10n.tr("Localizable", "Scene.Compose.Language.Recent", fallback: "Recent")
        /// Suggested
        public static let suggested = L10n.tr("Localizable", "Scene.Compose.Language.Suggested", fallback: "Suggested")
        /// Post Language
        public static let title = L10n.tr("Localizable", "Scene.Compose.Language.Title", fallback: "Post Language")
      }
      public enum MediaSelection {
        /// Browse
        public static let browse = L10n.tr("Localizable", "Scene.Compose.MediaSelection.Browse", fallback: "Browse")
        /// Take Photo
        public static let camera = L10n.tr("Localizable", "Scene.Compose.MediaSelection.Camera", fallback: "Take Photo")
        /// Photo Library
        public static let photoLibrary = L10n.tr("Localizable", "Scene.Compose.MediaSelection.PhotoLibrary", fallback: "Photo Library")
      }
      public enum Poll {
        /// Add Option
        public static let addOption = L10n.tr("Localizable", "Scene.Compose.Poll.AddOption", fallback: "Add Option")
        /// Duration: %@
        public static func durationTime(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Scene.Compose.Poll.DurationTime", String(describing: p1), fallback: "Duration: %@")
        }
        /// Move Down
        public static let moveDown = L10n.tr("Localizable", "Scene.Compose.Poll.MoveDown", fallback: "Move Down")
        /// Move Up
        public static let moveUp = L10n.tr("Localizable", "Scene.Compose.Poll.MoveUp", fallback: "Move Up")
        /// 1 Day
        public static let oneDay = L10n.tr("Localizable", "Scene.Compose.Poll.OneDay", fallback: "1 Day")
        /// 1 Hour
        public static let oneHour = L10n.tr("Localizable", "Scene.Compose.Poll.OneHour", fallback: "1 Hour")
        /// Option %ld
        public static func optionNumber(_ p1: Int) -> String {
          return L10n.tr("Localizable", "Scene.Compose.Poll.OptionNumber", p1, fallback: "Option %ld")
        }
        /// Remove Option
        public static let removeOption = L10n.tr("Localizable", "Scene.Compose.Poll.RemoveOption", fallback: "Remove Option")
        /// 7 Days
        public static let sevenDays = L10n.tr("Localizable", "Scene.Compose.Poll.SevenDays", fallback: "7 Days")
        /// 6 Hours
        public static let sixHours = L10n.tr("Localizable", "Scene.Compose.Poll.SixHours", fallback: "6 Hours")
        /// The poll has empty option
        public static let thePollHasEmptyOption = L10n.tr("Localizable", "Scene.Compose.Poll.ThePollHasEmptyOption", fallback: "The poll has empty option")
        /// The poll is invalid
        public static let thePollIsInvalid = L10n.tr("Localizable", "Scene.Compose.Poll.ThePollIsInvalid", fallback: "The poll is invalid")
        /// 30 minutes
        public static let thirtyMinutes = L10n.tr("Localizable", "Scene.Compose.Poll.ThirtyMinutes", fallback: "30 minutes")
        /// 3 Days
        public static let threeDays = L10n.tr("Localizable", "Scene.Compose.Poll.ThreeDays", fallback: "3 Days")
        /// Poll
        public static let title = L10n.tr("Localizable", "Scene.Compose.Poll.Title", fallback: "Poll")
      }
      public enum Title {
        /// Edit Post
        public static let editPost = L10n.tr("Localizable", "Scene.Compose.Title.EditPost", fallback: "Edit Post")
        /// New Post
        public static let newPost = L10n.tr("Localizable", "Scene.Compose.Title.NewPost", fallback: "New Post")
        /// New Reply
        public static let newReply = L10n.tr("Localizable", "Scene.Compose.Title.NewReply", fallback: "New Reply")
      }
      public enum Visibility {
        /// Only people I mention
        public static let direct = L10n.tr("Localizable", "Scene.Compose.Visibility.Direct", fallback: "Only people I mention")
        /// Followers only
        public static let `private` = L10n.tr("Localizable", "Scene.Compose.Visibility.Private", fallback: "Followers only")
        /// Public
        public static let `public` = L10n.tr("Localizable", "Scene.Compose.Visibility.Public", fallback: "Public")
        /// Unlisted
        public static let unlisted = L10n.tr("Localizable", "Scene.Compose.Visibility.Unlisted", fallback: "Unlisted")
      }
    }
    public enum ConfirmEmail {
      /// Tap the link we sent you to verify %@. We’ll wait right here.
      public static func tapTheLinkWeEmailedToYouToVerifyYourAccount(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.ConfirmEmail.TapTheLinkWeEmailedToYouToVerifyYourAccount", String(describing: p1), fallback: "Tap the link we sent you to verify %@. We’ll wait right here.")
      }
      /// Check Your Inbox
      public static let title = L10n.tr("Localizable", "Scene.ConfirmEmail.Title", fallback: "Check Your Inbox")
      public enum Button {
        /// Resend
        public static let resend = L10n.tr("Localizable", "Scene.ConfirmEmail.Button.Resend", fallback: "Resend")
      }
      public enum DidntGetLink {
        /// Didn’t get a link?
        public static let `prefix` = L10n.tr("Localizable", "Scene.ConfirmEmail.DidntGetLink.Prefix", fallback: "Didn’t get a link?")
        /// Resend (%@)
        public static func resendIn(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Scene.ConfirmEmail.DidntGetLink.ResendIn", String(describing: p1), fallback: "Resend (%@)")
        }
        /// Resend now.
        public static let resendNow = L10n.tr("Localizable", "Scene.ConfirmEmail.DidntGetLink.ResendNow", fallback: "Resend now.")
      }
      public enum DontReceiveEmail {
        /// Check if your email address is correct as well as your junk folder if you haven’t.
        public static let description = L10n.tr("Localizable", "Scene.ConfirmEmail.DontReceiveEmail.Description", fallback: "Check if your email address is correct as well as your junk folder if you haven’t.")
        /// Resend Email
        public static let resendEmail = L10n.tr("Localizable", "Scene.ConfirmEmail.DontReceiveEmail.ResendEmail", fallback: "Resend Email")
        /// Check your Email
        public static let title = L10n.tr("Localizable", "Scene.ConfirmEmail.DontReceiveEmail.Title", fallback: "Check your Email")
      }
      public enum OpenEmailApp {
        /// We just sent you an email. Check your junk folder if you haven’t.
        public static let description = L10n.tr("Localizable", "Scene.ConfirmEmail.OpenEmailApp.Description", fallback: "We just sent you an email. Check your junk folder if you haven’t.")
        /// Mail
        public static let mail = L10n.tr("Localizable", "Scene.ConfirmEmail.OpenEmailApp.Mail", fallback: "Mail")
        /// Open Email Client
        public static let openEmailClient = L10n.tr("Localizable", "Scene.ConfirmEmail.OpenEmailApp.OpenEmailClient", fallback: "Open Email Client")
        /// Check your Inbox.
        public static let title = L10n.tr("Localizable", "Scene.ConfirmEmail.OpenEmailApp.Title", fallback: "Check your Inbox.")
      }
    }
    public enum Discovery {
      /// These are the posts gaining traction in your corner of Mastodon.
      public static let intro = L10n.tr("Localizable", "Scene.Discovery.Intro", fallback: "These are the posts gaining traction in your corner of Mastodon.")
      public enum Tabs {
        /// Community
        public static let community = L10n.tr("Localizable", "Scene.Discovery.Tabs.Community", fallback: "Community")
        /// For You
        public static let forYou = L10n.tr("Localizable", "Scene.Discovery.Tabs.ForYou", fallback: "For You")
        /// Hashtags
        public static let hashtags = L10n.tr("Localizable", "Scene.Discovery.Tabs.Hashtags", fallback: "Hashtags")
        /// News
        public static let news = L10n.tr("Localizable", "Scene.Discovery.Tabs.News", fallback: "News")
        /// Posts
        public static let posts = L10n.tr("Localizable", "Scene.Discovery.Tabs.Posts", fallback: "Posts")
      }
    }
    public enum Familiarfollowers {
      /// Followed by %@
      public static func followedByNames(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.Familiarfollowers.FollowedByNames", String(describing: p1), fallback: "Followed by %@")
      }
      /// Followers you familiar
      public static let title = L10n.tr("Localizable", "Scene.Familiarfollowers.Title", fallback: "Followers you familiar")
    }
    public enum Favorite {
      /// Favorites
      public static let title = L10n.tr("Localizable", "Scene.Favorite.Title", fallback: "Favorites")
    }
    public enum FavoritedBy {
      /// Favorited By
      public static let title = L10n.tr("Localizable", "Scene.FavoritedBy.Title", fallback: "Favorited By")
    }
    public enum FollowedTags {
      /// Followed Tags
      public static let title = L10n.tr("Localizable", "Scene.FollowedTags.Title", fallback: "Followed Tags")
      public enum Actions {
        /// Follow
        public static let follow = L10n.tr("Localizable", "Scene.FollowedTags.Actions.Follow", fallback: "Follow")
        /// Unfollow
        public static let unfollow = L10n.tr("Localizable", "Scene.FollowedTags.Actions.Unfollow", fallback: "Unfollow")
      }
      public enum Header {
        /// participants
        public static let participants = L10n.tr("Localizable", "Scene.FollowedTags.Header.Participants", fallback: "participants")
        /// posts
        public static let posts = L10n.tr("Localizable", "Scene.FollowedTags.Header.Posts", fallback: "posts")
        /// posts today
        public static let postsToday = L10n.tr("Localizable", "Scene.FollowedTags.Header.PostsToday", fallback: "posts today")
      }
    }
    public enum Follower {
      /// Followers from other servers are not displayed.
      public static let footer = L10n.tr("Localizable", "Scene.Follower.Footer", fallback: "Followers from other servers are not displayed.")
      /// follower
      public static let title = L10n.tr("Localizable", "Scene.Follower.Title", fallback: "follower")
    }
    public enum Following {
      /// Follows from other servers are not displayed.
      public static let footer = L10n.tr("Localizable", "Scene.Following.Footer", fallback: "Follows from other servers are not displayed.")
      /// following
      public static let title = L10n.tr("Localizable", "Scene.Following.Title", fallback: "following")
    }
    public enum HomeTimeline {
      /// Home
      public static let title = L10n.tr("Localizable", "Scene.HomeTimeline.Title", fallback: "Home")
      public enum TimelineMenu {
        /// Following
        public static let following = L10n.tr("Localizable", "Scene.HomeTimeline.TimelineMenu.Following", fallback: "Following")
        /// Local
        public static let localCommunity = L10n.tr("Localizable", "Scene.HomeTimeline.TimelineMenu.LocalCommunity", fallback: "Local")
        public enum Hashtags {
          /// Followed Hashtags
          public static let title = L10n.tr("Localizable", "Scene.HomeTimeline.TimelineMenu.Hashtags.Title", fallback: "Followed Hashtags")
        }
        public enum Lists {
          /// Lists
          public static let title = L10n.tr("Localizable", "Scene.HomeTimeline.TimelineMenu.Lists.Title", fallback: "Lists")
        }
      }
      public enum TimelinePill {
        /// New Posts
        public static let newPosts = L10n.tr("Localizable", "Scene.HomeTimeline.TimelinePill.NewPosts", fallback: "New Posts")
        /// Offline
        public static let offline = L10n.tr("Localizable", "Scene.HomeTimeline.TimelinePill.Offline", fallback: "Offline")
        /// Post Sent
        public static let postSent = L10n.tr("Localizable", "Scene.HomeTimeline.TimelinePill.PostSent", fallback: "Post Sent")
      }
    }
    public enum Login {
      /// Log in with the server where you created your account.
      public static let subtitle = L10n.tr("Localizable", "Scene.Login.Subtitle", fallback: "Log in with the server where you created your account.")
      /// Welcome Back
      public static let title = L10n.tr("Localizable", "Scene.Login.Title", fallback: "Welcome Back")
      public enum ServerSearchField {
        /// Enter URL or search for your server
        public static let placeholder = L10n.tr("Localizable", "Scene.Login.ServerSearchField.Placeholder", fallback: "Enter URL or search for your server")
      }
    }
    public enum Notification {
      public enum FollowRequest {
        /// Accept
        public static let accept = L10n.tr("Localizable", "Scene.Notification.FollowRequest.Accept", fallback: "Accept")
        /// Accepted
        public static let accepted = L10n.tr("Localizable", "Scene.Notification.FollowRequest.Accepted", fallback: "Accepted")
        /// reject
        public static let reject = L10n.tr("Localizable", "Scene.Notification.FollowRequest.Reject", fallback: "reject")
        /// Rejected
        public static let rejected = L10n.tr("Localizable", "Scene.Notification.FollowRequest.Rejected", fallback: "Rejected")
      }
      public enum Keyobard {
        /// Show Everything
        public static let showEverything = L10n.tr("Localizable", "Scene.Notification.Keyobard.ShowEverything", fallback: "Show Everything")
        /// Show Mentions
        public static let showMentions = L10n.tr("Localizable", "Scene.Notification.Keyobard.ShowMentions", fallback: "Show Mentions")
      }
      public enum NotificationDescription {
        /// favorited your post
        public static let favoritedYourPost = L10n.tr("Localizable", "Scene.Notification.NotificationDescription.FavoritedYourPost", fallback: "favorited your post")
        /// followed you
        public static let followedYou = L10n.tr("Localizable", "Scene.Notification.NotificationDescription.FollowedYou", fallback: "followed you")
        /// mentioned you
        public static let mentionedYou = L10n.tr("Localizable", "Scene.Notification.NotificationDescription.MentionedYou", fallback: "mentioned you")
        /// poll has ended
        public static let pollHasEnded = L10n.tr("Localizable", "Scene.Notification.NotificationDescription.PollHasEnded", fallback: "poll has ended")
        /// boosted your post
        public static let rebloggedYourPost = L10n.tr("Localizable", "Scene.Notification.NotificationDescription.RebloggedYourPost", fallback: "boosted your post")
        /// request to follow you
        public static let requestToFollowYou = L10n.tr("Localizable", "Scene.Notification.NotificationDescription.RequestToFollowYou", fallback: "request to follow you")
      }
      public enum Title {
        /// Everything
        public static let everything = L10n.tr("Localizable", "Scene.Notification.Title.Everything", fallback: "Everything")
        /// Mentions
        public static let mentions = L10n.tr("Localizable", "Scene.Notification.Title.Mentions", fallback: "Mentions")
      }
      public enum Warning {
        /// Some of your posts have been removed.
        public static let deleteStatuses = L10n.tr("Localizable", "Scene.Notification.Warning.DeleteStatuses", fallback: "Some of your posts have been removed.")
        /// Your account has been disabled.
        public static let disable = L10n.tr("Localizable", "Scene.Notification.Warning.Disable", fallback: "Your account has been disabled.")
        /// Learn More
        public static let learnMore = L10n.tr("Localizable", "Scene.Notification.Warning.LearnMore", fallback: "Learn More")
        /// Some of your posts have been marked as sensitive.
        public static let markStatusesAsSensitive = L10n.tr("Localizable", "Scene.Notification.Warning.MarkStatusesAsSensitive", fallback: "Some of your posts have been marked as sensitive.")
        /// Your account has received a moderation warning.
        public static let `none` = L10n.tr("Localizable", "Scene.Notification.Warning.None", fallback: "Your account has received a moderation warning.")
        /// Your posts will be marked as sensitive from now on.
        public static let sensitive = L10n.tr("Localizable", "Scene.Notification.Warning.Sensitive", fallback: "Your posts will be marked as sensitive from now on.")
        /// Your account has been limited.
        public static let silence = L10n.tr("Localizable", "Scene.Notification.Warning.Silence", fallback: "Your account has been limited.")
        /// Your account has been suspended.
        public static let suspend = L10n.tr("Localizable", "Scene.Notification.Warning.Suspend", fallback: "Your account has been suspended.")
      }
    }
    public enum Preview {
      public enum Keyboard {
        /// Close Preview
        public static let closePreview = L10n.tr("Localizable", "Scene.Preview.Keyboard.ClosePreview", fallback: "Close Preview")
        /// Show Next
        public static let showNext = L10n.tr("Localizable", "Scene.Preview.Keyboard.ShowNext", fallback: "Show Next")
        /// Show Previous
        public static let showPrevious = L10n.tr("Localizable", "Scene.Preview.Keyboard.ShowPrevious", fallback: "Show Previous")
      }
    }
    public enum Privacy {
      /// Although the Mastodon app does not collect any data, the server you sign up through may have a different policy.
      /// 
      /// If you disagree with the policy for **%@**, you can go back and pick a different server.
      public static func description(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.Privacy.Description", String(describing: p1), fallback: "Although the Mastodon app does not collect any data, the server you sign up through may have a different policy.\n\nIf you disagree with the policy for **%@**, you can go back and pick a different server.")
      }
      /// Your Privacy
      public static let title = L10n.tr("Localizable", "Scene.Privacy.Title", fallback: "Your Privacy")
      public enum Button {
        /// I Agree
        public static let confirm = L10n.tr("Localizable", "Scene.Privacy.Button.Confirm", fallback: "I Agree")
      }
      public enum Policy {
        /// Privacy Policy - Mastodon for iOS
        public static let ios = L10n.tr("Localizable", "Scene.Privacy.Policy.Ios", fallback: "Privacy Policy - Mastodon for iOS")
        /// Privacy Policy - %@
        public static func server(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Scene.Privacy.Policy.Server", String(describing: p1), fallback: "Privacy Policy - %@")
        }
      }
    }
    public enum Profile {
      public enum Accessibility {
        /// Double tap to open the list
        public static let doubleTapToOpenTheList = L10n.tr("Localizable", "Scene.Profile.Accessibility.DoubleTapToOpenTheList", fallback: "Double tap to open the list")
        /// Edit avatar image
        public static let editAvatarImage = L10n.tr("Localizable", "Scene.Profile.Accessibility.EditAvatarImage", fallback: "Edit avatar image")
        /// Show avatar image
        public static let showAvatarImage = L10n.tr("Localizable", "Scene.Profile.Accessibility.ShowAvatarImage", fallback: "Show avatar image")
        /// Show banner image
        public static let showBannerImage = L10n.tr("Localizable", "Scene.Profile.Accessibility.ShowBannerImage", fallback: "Show banner image")
      }
      public enum Dashboard {
        /// mutuals
        public static let familiarFollowers = L10n.tr("Localizable", "Scene.Profile.Dashboard.FamiliarFollowers", fallback: "mutuals")
        /// followers
        public static let myFollowers = L10n.tr("Localizable", "Scene.Profile.Dashboard.MyFollowers", fallback: "followers")
        /// following
        public static let myFollowing = L10n.tr("Localizable", "Scene.Profile.Dashboard.MyFollowing", fallback: "following")
        /// posts
        public static let myPosts = L10n.tr("Localizable", "Scene.Profile.Dashboard.MyPosts", fallback: "posts")
        /// followers
        public static let otherFollowers = L10n.tr("Localizable", "Scene.Profile.Dashboard.OtherFollowers", fallback: "followers")
        /// following
        public static let otherFollowing = L10n.tr("Localizable", "Scene.Profile.Dashboard.OtherFollowing", fallback: "following")
        /// posts
        public static let otherPosts = L10n.tr("Localizable", "Scene.Profile.Dashboard.OtherPosts", fallback: "posts")
      }
      public enum Fields {
        /// Add Row
        public static let addRow = L10n.tr("Localizable", "Scene.Profile.Fields.AddRow", fallback: "Add Row")
        /// Joined
        public static let joined = L10n.tr("Localizable", "Scene.Profile.Fields.Joined", fallback: "Joined")
        public enum Placeholder {
          /// Content
          public static let content = L10n.tr("Localizable", "Scene.Profile.Fields.Placeholder.Content", fallback: "Content")
          /// Label
          public static let label = L10n.tr("Localizable", "Scene.Profile.Fields.Placeholder.Label", fallback: "Label")
        }
        public enum Verified {
          /// Ownership of this link was checked on %@
          public static func long(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Profile.Fields.Verified.Long", String(describing: p1), fallback: "Ownership of this link was checked on %@")
          }
          /// Verified on %@
          public static func short(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Profile.Fields.Verified.Short", String(describing: p1), fallback: "Verified on %@")
          }
        }
      }
      public enum Header {
        /// Follows You
        public static let followsYou = L10n.tr("Localizable", "Scene.Profile.Header.FollowsYou", fallback: "Follows You")
      }
      public enum RelationshipActionAlert {
        public enum ConfirmBlockDomain {
          /// Confirm to block domain %@
          public static func message(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Profile.RelationshipActionAlert.ConfirmBlockDomain.Message", String(describing: p1), fallback: "Confirm to block domain %@")
          }
          /// Block domain
          public static let title = L10n.tr("Localizable", "Scene.Profile.RelationshipActionAlert.ConfirmBlockDomain.Title", fallback: "Block domain")
        }
        public enum ConfirmBlockUser {
          /// Confirm to block %@
          public static func message(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Profile.RelationshipActionAlert.ConfirmBlockUser.Message", String(describing: p1), fallback: "Confirm to block %@")
          }
          /// Block Account
          public static let title = L10n.tr("Localizable", "Scene.Profile.RelationshipActionAlert.ConfirmBlockUser.Title", fallback: "Block Account")
        }
        public enum ConfirmHideReblogs {
          /// Confirm to hide boosts
          public static let message = L10n.tr("Localizable", "Scene.Profile.RelationshipActionAlert.ConfirmHideReblogs.Message", fallback: "Confirm to hide boosts")
          /// Hide Boosts
          public static let title = L10n.tr("Localizable", "Scene.Profile.RelationshipActionAlert.ConfirmHideReblogs.Title", fallback: "Hide Boosts")
        }
        public enum ConfirmMuteUser {
          /// Confirm to mute %@
          public static func message(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Profile.RelationshipActionAlert.ConfirmMuteUser.Message", String(describing: p1), fallback: "Confirm to mute %@")
          }
          /// Mute Account
          public static let title = L10n.tr("Localizable", "Scene.Profile.RelationshipActionAlert.ConfirmMuteUser.Title", fallback: "Mute Account")
        }
        public enum ConfirmShowReblogs {
          /// Confirm to show boosts
          public static let message = L10n.tr("Localizable", "Scene.Profile.RelationshipActionAlert.ConfirmShowReblogs.Message", fallback: "Confirm to show boosts")
          /// Show Boosts
          public static let title = L10n.tr("Localizable", "Scene.Profile.RelationshipActionAlert.ConfirmShowReblogs.Title", fallback: "Show Boosts")
        }
        public enum ConfirmUnblockDomain {
          /// Confirm to unblock domain %@
          public static func message(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Profile.RelationshipActionAlert.ConfirmUnblockDomain.Message", String(describing: p1), fallback: "Confirm to unblock domain %@")
          }
          /// Unblock domain
          public static let title = L10n.tr("Localizable", "Scene.Profile.RelationshipActionAlert.ConfirmUnblockDomain.Title", fallback: "Unblock domain")
        }
        public enum ConfirmUnblockUser {
          /// Confirm to unblock %@
          public static func message(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Profile.RelationshipActionAlert.ConfirmUnblockUser.Message", String(describing: p1), fallback: "Confirm to unblock %@")
          }
          /// Unblock Account
          public static let title = L10n.tr("Localizable", "Scene.Profile.RelationshipActionAlert.ConfirmUnblockUser.Title", fallback: "Unblock Account")
        }
        public enum ConfirmUnmuteUser {
          /// Confirm to unmute %@
          public static func message(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Profile.RelationshipActionAlert.ConfirmUnmuteUser.Message", String(describing: p1), fallback: "Confirm to unmute %@")
          }
          /// Unmute Account
          public static let title = L10n.tr("Localizable", "Scene.Profile.RelationshipActionAlert.ConfirmUnmuteUser.Title", fallback: "Unmute Account")
        }
      }
      public enum SegmentedControl {
        /// About
        public static let about = L10n.tr("Localizable", "Scene.Profile.SegmentedControl.About", fallback: "About")
        /// Media
        public static let media = L10n.tr("Localizable", "Scene.Profile.SegmentedControl.Media", fallback: "Media")
        /// Posts
        public static let posts = L10n.tr("Localizable", "Scene.Profile.SegmentedControl.Posts", fallback: "Posts")
        /// Posts and Replies
        public static let postsAndReplies = L10n.tr("Localizable", "Scene.Profile.SegmentedControl.PostsAndReplies", fallback: "Posts and Replies")
        /// Replies
        public static let replies = L10n.tr("Localizable", "Scene.Profile.SegmentedControl.Replies", fallback: "Replies")
      }
    }
    public enum RebloggedBy {
      /// Boosted By
      public static let title = L10n.tr("Localizable", "Scene.RebloggedBy.Title", fallback: "Boosted By")
    }
    public enum Register {
      /// Create Account
      public static let title = L10n.tr("Localizable", "Scene.Register.Title", fallback: "Create Account")
      public enum Error {
        public enum Item {
          /// Agreement
          public static let agreement = L10n.tr("Localizable", "Scene.Register.Error.Item.Agreement", fallback: "Agreement")
          /// Email
          public static let email = L10n.tr("Localizable", "Scene.Register.Error.Item.Email", fallback: "Email")
          /// Locale
          public static let locale = L10n.tr("Localizable", "Scene.Register.Error.Item.Locale", fallback: "Locale")
          /// Password
          public static let password = L10n.tr("Localizable", "Scene.Register.Error.Item.Password", fallback: "Password")
          /// Reason
          public static let reason = L10n.tr("Localizable", "Scene.Register.Error.Item.Reason", fallback: "Reason")
          /// Username
          public static let username = L10n.tr("Localizable", "Scene.Register.Error.Item.Username", fallback: "Username")
        }
        public enum Reason {
          /// %@ must be accepted
          public static func accepted(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Register.Error.Reason.Accepted", String(describing: p1), fallback: "%@ must be accepted")
          }
          /// %@ is required
          public static func blank(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Register.Error.Reason.Blank", String(describing: p1), fallback: "%@ is required")
          }
          /// %@ contains a disallowed email provider
          public static func blocked(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Register.Error.Reason.Blocked", String(describing: p1), fallback: "%@ contains a disallowed email provider")
          }
          /// %@ is not a supported value
          public static func inclusion(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Register.Error.Reason.Inclusion", String(describing: p1), fallback: "%@ is not a supported value")
          }
          /// %@ is invalid
          public static func invalid(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Register.Error.Reason.Invalid", String(describing: p1), fallback: "%@ is invalid")
          }
          /// %@ is a reserved keyword
          public static func reserved(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Register.Error.Reason.Reserved", String(describing: p1), fallback: "%@ is a reserved keyword")
          }
          /// %@ is already taken. How about:
          public static func taken(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Register.Error.Reason.Taken", String(describing: p1), fallback: "%@ is already taken. How about:")
          }
          /// %@ is too long
          public static func tooLong(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Register.Error.Reason.TooLong", String(describing: p1), fallback: "%@ is too long")
          }
          /// %@ is too short
          public static func tooShort(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Register.Error.Reason.TooShort", String(describing: p1), fallback: "%@ is too short")
          }
          /// %@ does not seem to exist
          public static func unreachable(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Register.Error.Reason.Unreachable", String(describing: p1), fallback: "%@ does not seem to exist")
          }
        }
        public enum Special {
          /// This is not a valid email address
          public static let emailInvalid = L10n.tr("Localizable", "Scene.Register.Error.Special.EmailInvalid", fallback: "This is not a valid email address")
          /// Password is too short (must be at least 8 characters)
          public static let passwordTooShort = L10n.tr("Localizable", "Scene.Register.Error.Special.PasswordTooShort", fallback: "Password is too short (must be at least 8 characters)")
          /// Username must only contain alphanumeric characters and underscores
          public static let usernameInvalid = L10n.tr("Localizable", "Scene.Register.Error.Special.UsernameInvalid", fallback: "Username must only contain alphanumeric characters and underscores")
          /// Username is too long (can’t be longer than 30 characters)
          public static let usernameTooLong = L10n.tr("Localizable", "Scene.Register.Error.Special.UsernameTooLong", fallback: "Username is too long (can’t be longer than 30 characters)")
        }
      }
      public enum Input {
        public enum Avatar {
          /// Delete
          public static let delete = L10n.tr("Localizable", "Scene.Register.Input.Avatar.Delete", fallback: "Delete")
        }
        public enum DisplayName {
          /// display name
          public static let placeholder = L10n.tr("Localizable", "Scene.Register.Input.DisplayName.Placeholder", fallback: "display name")
        }
        public enum Email {
          /// email
          public static let placeholder = L10n.tr("Localizable", "Scene.Register.Input.Email.Placeholder", fallback: "email")
        }
        public enum Invite {
          /// Why do you want to join?
          public static let registrationUserInviteRequest = L10n.tr("Localizable", "Scene.Register.Input.Invite.RegistrationUserInviteRequest", fallback: "Why do you want to join?")
        }
        public enum Password {
          /// 8 characters
          public static let characterLimit = L10n.tr("Localizable", "Scene.Register.Input.Password.CharacterLimit", fallback: "8 characters")
          /// Confirm Password
          public static let confirmationPlaceholder = L10n.tr("Localizable", "Scene.Register.Input.Password.ConfirmationPlaceholder", fallback: "Confirm Password")
          /// Your password needs at least eight characters
          public static let hint = L10n.tr("Localizable", "Scene.Register.Input.Password.Hint", fallback: "Your password needs at least eight characters")
          /// password
          public static let placeholder = L10n.tr("Localizable", "Scene.Register.Input.Password.Placeholder", fallback: "password")
          /// Your password needs at least:
          public static let require = L10n.tr("Localizable", "Scene.Register.Input.Password.Require", fallback: "Your password needs at least:")
          public enum Accessibility {
            /// checked
            public static let checked = L10n.tr("Localizable", "Scene.Register.Input.Password.Accessibility.Checked", fallback: "checked")
            /// unchecked
            public static let unchecked = L10n.tr("Localizable", "Scene.Register.Input.Password.Accessibility.Unchecked", fallback: "unchecked")
          }
        }
        public enum Username {
          /// This username is taken.
          public static let duplicatePrompt = L10n.tr("Localizable", "Scene.Register.Input.Username.DuplicatePrompt", fallback: "This username is taken.")
          /// username
          public static let placeholder = L10n.tr("Localizable", "Scene.Register.Input.Username.Placeholder", fallback: "username")
          /// amazing_%@
          public static func suggestion(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Register.Input.Username.Suggestion", String(describing: p1), fallback: "amazing_%@")
          }
        }
      }
    }
    public enum Report {
      /// Are there any other posts you’d like to add to the report?
      public static let content1 = L10n.tr("Localizable", "Scene.Report.Content1", fallback: "Are there any other posts you’d like to add to the report?")
      /// Is there anything the moderators should know about this report?
      public static let content2 = L10n.tr("Localizable", "Scene.Report.Content2", fallback: "Is there anything the moderators should know about this report?")
      /// REPORTED
      public static let reported = L10n.tr("Localizable", "Scene.Report.Reported", fallback: "REPORTED")
      /// Thanks for reporting, we’ll look into this.
      public static let reportSentTitle = L10n.tr("Localizable", "Scene.Report.ReportSentTitle", fallback: "Thanks for reporting, we’ll look into this.")
      /// Send Report
      public static let send = L10n.tr("Localizable", "Scene.Report.Send", fallback: "Send Report")
      /// Send without comment
      public static let skipToSend = L10n.tr("Localizable", "Scene.Report.SkipToSend", fallback: "Send without comment")
      /// Step 1 of 2
      public static let step1 = L10n.tr("Localizable", "Scene.Report.Step1", fallback: "Step 1 of 2")
      /// Step 2 of 2
      public static let step2 = L10n.tr("Localizable", "Scene.Report.Step2", fallback: "Step 2 of 2")
      /// Type or paste additional comments
      public static let textPlaceholder = L10n.tr("Localizable", "Scene.Report.TextPlaceholder", fallback: "Type or paste additional comments")
      /// Report %@
      public static func title(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.Report.Title", String(describing: p1), fallback: "Report %@")
      }
      /// Report
      public static let titleReport = L10n.tr("Localizable", "Scene.Report.TitleReport", fallback: "Report")
      public enum StepFinal {
        /// Block %@
        public static func blockUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Scene.Report.StepFinal.BlockUser", String(describing: p1), fallback: "Block %@")
        }
        /// Don’t want to see this?
        public static let dontWantToSeeThis = L10n.tr("Localizable", "Scene.Report.StepFinal.DontWantToSeeThis", fallback: "Don’t want to see this?")
        /// Mute %@
        public static func muteUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Scene.Report.StepFinal.MuteUser", String(describing: p1), fallback: "Mute %@")
        }
        /// They will no longer be able to follow or see your posts, but they can see if they’ve been blocked.
        public static let theyWillNoLongerBeAbleToFollowOrSeeYourPostsButTheyCanSeeIfTheyveBeenBlocked = L10n.tr("Localizable", "Scene.Report.StepFinal.TheyWillNoLongerBeAbleToFollowOrSeeYourPostsButTheyCanSeeIfTheyveBeenBlocked", fallback: "They will no longer be able to follow or see your posts, but they can see if they’ve been blocked.")
        /// Unfollow
        public static let unfollow = L10n.tr("Localizable", "Scene.Report.StepFinal.Unfollow", fallback: "Unfollow")
        /// Unfollowed
        public static let unfollowed = L10n.tr("Localizable", "Scene.Report.StepFinal.Unfollowed", fallback: "Unfollowed")
        /// Unfollow %@
        public static func unfollowUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Scene.Report.StepFinal.UnfollowUser", String(describing: p1), fallback: "Unfollow %@")
        }
        /// When you see something you don’t like on Mastodon, you can remove the person from your experience.
        public static let whenYouSeeSomethingYouDontLikeOnMastodonYouCanRemoveThePersonFromYourExperience = L10n.tr("Localizable", "Scene.Report.StepFinal.WhenYouSeeSomethingYouDontLikeOnMastodonYouCanRemoveThePersonFromYourExperience.", fallback: "When you see something you don’t like on Mastodon, you can remove the person from your experience.")
        /// While we review this, you can take action against %@
        public static func whileWeReviewThisYouCanTakeActionAgainstUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Scene.Report.StepFinal.WhileWeReviewThisYouCanTakeActionAgainstUser", String(describing: p1), fallback: "While we review this, you can take action against %@")
        }
        /// You won’t see their posts or boosts in your home feed. They won’t know they’ve been muted.
        public static let youWontSeeTheirPostsOrReblogsInYourHomeFeedTheyWontKnowTheyVeBeenMuted = L10n.tr("Localizable", "Scene.Report.StepFinal.YouWontSeeTheirPostsOrReblogsInYourHomeFeedTheyWontKnowTheyVeBeenMuted", fallback: "You won’t see their posts or boosts in your home feed. They won’t know they’ve been muted.")
      }
      public enum StepFour {
        /// Is there anything else we should know?
        public static let isThereAnythingElseWeShouldKnow = L10n.tr("Localizable", "Scene.Report.StepFour.IsThereAnythingElseWeShouldKnow", fallback: "Is there anything else we should know?")
        /// Step 4 of 4
        public static let step4Of4 = L10n.tr("Localizable", "Scene.Report.StepFour.Step4Of4", fallback: "Step 4 of 4")
      }
      public enum StepOne {
        /// I don’t like it
        public static let iDontLikeIt = L10n.tr("Localizable", "Scene.Report.StepOne.IDontLikeIt", fallback: "I don’t like it")
        /// It is not something you want to see
        public static let itIsNotSomethingYouWantToSee = L10n.tr("Localizable", "Scene.Report.StepOne.ItIsNotSomethingYouWantToSee", fallback: "It is not something you want to see")
        /// It’s something else
        public static let itsSomethingElse = L10n.tr("Localizable", "Scene.Report.StepOne.ItsSomethingElse", fallback: "It’s something else")
        /// It’s spam
        public static let itsSpam = L10n.tr("Localizable", "Scene.Report.StepOne.ItsSpam", fallback: "It’s spam")
        /// It violates server rules
        public static let itViolatesServerRules = L10n.tr("Localizable", "Scene.Report.StepOne.ItViolatesServerRules", fallback: "It violates server rules")
        /// Malicious links, fake engagement, or repetetive replies
        public static let maliciousLinksFakeEngagementOrRepetetiveReplies = L10n.tr("Localizable", "Scene.Report.StepOne.MaliciousLinksFakeEngagementOrRepetetiveReplies", fallback: "Malicious links, fake engagement, or repetetive replies")
        /// Select the best match
        public static let selectTheBestMatch = L10n.tr("Localizable", "Scene.Report.StepOne.SelectTheBestMatch", fallback: "Select the best match")
        /// Step 1 of 4
        public static let step1Of4 = L10n.tr("Localizable", "Scene.Report.StepOne.Step1Of4", fallback: "Step 1 of 4")
        /// The issue does not fit into other categories
        public static let theIssueDoesNotFitIntoOtherCategories = L10n.tr("Localizable", "Scene.Report.StepOne.TheIssueDoesNotFitIntoOtherCategories", fallback: "The issue does not fit into other categories")
        /// What's wrong with this account?
        public static let whatsWrongWithThisAccount = L10n.tr("Localizable", "Scene.Report.StepOne.WhatsWrongWithThisAccount", fallback: "What's wrong with this account?")
        /// What's wrong with this post?
        public static let whatsWrongWithThisPost = L10n.tr("Localizable", "Scene.Report.StepOne.WhatsWrongWithThisPost", fallback: "What's wrong with this post?")
        /// What's wrong with %@?
        public static func whatsWrongWithThisUsername(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Scene.Report.StepOne.WhatsWrongWithThisUsername", String(describing: p1), fallback: "What's wrong with %@?")
        }
        /// You are aware that it breaks specific rules
        public static let youAreAwareThatItBreaksSpecificRules = L10n.tr("Localizable", "Scene.Report.StepOne.YouAreAwareThatItBreaksSpecificRules", fallback: "You are aware that it breaks specific rules")
      }
      public enum StepThree {
        /// Are there any posts that back up this report?
        public static let areThereAnyPostsThatBackUpThisReport = L10n.tr("Localizable", "Scene.Report.StepThree.AreThereAnyPostsThatBackUpThisReport", fallback: "Are there any posts that back up this report?")
        /// Select all that apply
        public static let selectAllThatApply = L10n.tr("Localizable", "Scene.Report.StepThree.SelectAllThatApply", fallback: "Select all that apply")
        /// Step 3 of 4
        public static let step3Of4 = L10n.tr("Localizable", "Scene.Report.StepThree.Step3Of4", fallback: "Step 3 of 4")
      }
      public enum StepTwo {
        /// I just don’t like it
        public static let iJustDonTLikeIt = L10n.tr("Localizable", "Scene.Report.StepTwo.IJustDon’tLikeIt", fallback: "I just don’t like it")
        /// Select all that apply
        public static let selectAllThatApply = L10n.tr("Localizable", "Scene.Report.StepTwo.SelectAllThatApply", fallback: "Select all that apply")
        /// Step 2 of 4
        public static let step2Of4 = L10n.tr("Localizable", "Scene.Report.StepTwo.Step2Of4", fallback: "Step 2 of 4")
        /// Which rules are being violated?
        public static let whichRulesAreBeingViolated = L10n.tr("Localizable", "Scene.Report.StepTwo.WhichRulesAreBeingViolated", fallback: "Which rules are being violated?")
      }
    }
    public enum Search {
      /// Search
      public static let title = L10n.tr("Localizable", "Scene.Search.Title", fallback: "Search")
      public enum Recommend {
        /// See All
        public static let buttonText = L10n.tr("Localizable", "Scene.Search.Recommend.ButtonText", fallback: "See All")
        public enum Accounts {
          /// You may like to follow these accounts
          public static let description = L10n.tr("Localizable", "Scene.Search.Recommend.Accounts.Description", fallback: "You may like to follow these accounts")
          /// Follow
          public static let follow = L10n.tr("Localizable", "Scene.Search.Recommend.Accounts.Follow", fallback: "Follow")
          /// Accounts you might like
          public static let title = L10n.tr("Localizable", "Scene.Search.Recommend.Accounts.Title", fallback: "Accounts you might like")
        }
        public enum HashTag {
          /// Hashtags that are getting quite a bit of attention
          public static let description = L10n.tr("Localizable", "Scene.Search.Recommend.HashTag.Description", fallback: "Hashtags that are getting quite a bit of attention")
          /// %@ people are talking
          public static func peopleTalking(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Search.Recommend.HashTag.PeopleTalking", String(describing: p1), fallback: "%@ people are talking")
          }
          /// Trending on Mastodon
          public static let title = L10n.tr("Localizable", "Scene.Search.Recommend.HashTag.Title", fallback: "Trending on Mastodon")
        }
      }
      public enum SearchBar {
        /// Cancel
        public static let cancel = L10n.tr("Localizable", "Scene.Search.SearchBar.Cancel", fallback: "Cancel")
        /// Search hashtags and users
        public static let placeholder = L10n.tr("Localizable", "Scene.Search.SearchBar.Placeholder", fallback: "Search hashtags and users")
      }
      public enum Searching {
        /// Clear
        public static let clear = L10n.tr("Localizable", "Scene.Search.Searching.Clear", fallback: "Clear")
        /// Clear all
        public static let clearAll = L10n.tr("Localizable", "Scene.Search.Searching.ClearAll", fallback: "Clear all")
        /// Go to #%@
        public static func hashtag(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Scene.Search.Searching.Hashtag", String(describing: p1), fallback: "Go to #%@")
        }
        /// People matching "%@"
        public static func people(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Scene.Search.Searching.People", String(describing: p1), fallback: "People matching \"%@\"")
        }
        /// Posts matching "%@"
        public static func posts(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Scene.Search.Searching.Posts", String(describing: p1), fallback: "Posts matching \"%@\"")
        }
        /// Go to @%@@%@
        public static func profile(_ p1: Any, _ p2: Any) -> String {
          return L10n.tr("Localizable", "Scene.Search.Searching.Profile", String(describing: p1), String(describing: p2), fallback: "Go to @%@@%@")
        }
        /// Recent searches
        public static let recentSearch = L10n.tr("Localizable", "Scene.Search.Searching.RecentSearch", fallback: "Recent searches")
        /// Open URL in Mastodon
        public static let url = L10n.tr("Localizable", "Scene.Search.Searching.Url", fallback: "Open URL in Mastodon")
        public enum EmptyState {
          /// No results
          public static let noResults = L10n.tr("Localizable", "Scene.Search.Searching.EmptyState.NoResults", fallback: "No results")
        }
        public enum NoUser {
          /// There's no Useraccount "%@" on %@
          public static func message(_ p1: Any, _ p2: Any) -> String {
            return L10n.tr("Localizable", "Scene.Search.Searching.NoUser.Message", String(describing: p1), String(describing: p2), fallback: "There's no Useraccount \"%@\" on %@")
          }
          /// No User Account Found
          public static let title = L10n.tr("Localizable", "Scene.Search.Searching.NoUser.Title", fallback: "No User Account Found")
        }
      }
    }
    public enum ServerPicker {
      /// We’ll pick a server based on your language if you continue without making a selection.
      public static let noServerSelectedHint = L10n.tr("Localizable", "Scene.ServerPicker.NoServerSelectedHint", fallback: "We’ll pick a server based on your language if you continue without making a selection.")
      /// Pick Server
      public static let title = L10n.tr("Localizable", "Scene.ServerPicker.Title", fallback: "Pick Server")
      public enum Button {
        /// Language
        public static let language = L10n.tr("Localizable", "Scene.ServerPicker.Button.Language", fallback: "Language")
        /// See Less
        public static let seeLess = L10n.tr("Localizable", "Scene.ServerPicker.Button.SeeLess", fallback: "See Less")
        /// See More
        public static let seeMore = L10n.tr("Localizable", "Scene.ServerPicker.Button.SeeMore", fallback: "See More")
        /// Sign-up Speed
        public static let signupSpeed = L10n.tr("Localizable", "Scene.ServerPicker.Button.SignupSpeed", fallback: "Sign-up Speed")
        public enum Category {
          /// academia
          public static let academia = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.Academia", fallback: "academia")
          /// activism
          public static let activism = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.Activism", fallback: "activism")
          /// All
          public static let all = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.All", fallback: "All")
          /// Category: All
          public static let allAccessiblityDescription = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.AllAccessiblityDescription", fallback: "Category: All")
          /// art
          public static let art = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.Art", fallback: "art")
          /// food
          public static let food = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.Food", fallback: "food")
          /// furry
          public static let furry = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.Furry", fallback: "furry")
          /// games
          public static let games = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.Games", fallback: "games")
          /// general
          public static let general = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.General", fallback: "general")
          /// journalism
          public static let journalism = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.Journalism", fallback: "journalism")
          /// lgbt
          public static let lgbt = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.Lgbt", fallback: "lgbt")
          /// music
          public static let music = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.Music", fallback: "music")
          /// regional
          public static let regional = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.Regional", fallback: "regional")
          /// tech
          public static let tech = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.Tech", fallback: "tech")
        }
      }
      public enum EmptyState {
        /// Something went wrong while loading the data. Check your internet connection.
        public static let badNetwork = L10n.tr("Localizable", "Scene.ServerPicker.EmptyState.BadNetwork", fallback: "Something went wrong while loading the data. Check your internet connection.")
        /// Finding available servers...
        public static let findingServers = L10n.tr("Localizable", "Scene.ServerPicker.EmptyState.FindingServers", fallback: "Finding available servers...")
        /// No results
        public static let noResults = L10n.tr("Localizable", "Scene.ServerPicker.EmptyState.NoResults", fallback: "No results")
      }
      public enum Input {
        /// Search communities or enter URL
        public static let searchServersOrEnterUrl = L10n.tr("Localizable", "Scene.ServerPicker.Input.SearchServersOrEnterUrl", fallback: "Search communities or enter URL")
      }
      public enum Label {
        /// CATEGORY
        public static let category = L10n.tr("Localizable", "Scene.ServerPicker.Label.Category", fallback: "CATEGORY")
        /// LANGUAGE
        public static let language = L10n.tr("Localizable", "Scene.ServerPicker.Label.Language", fallback: "LANGUAGE")
        /// USERS
        public static let users = L10n.tr("Localizable", "Scene.ServerPicker.Label.Users", fallback: "USERS")
      }
      public enum Language {
        /// All
        public static let all = L10n.tr("Localizable", "Scene.ServerPicker.Language.All", fallback: "All")
      }
      public enum Search {
        /// Search name or URL
        public static let placeholder = L10n.tr("Localizable", "Scene.ServerPicker.Search.Placeholder", fallback: "Search name or URL")
      }
      public enum SignupSpeed {
        /// All
        public static let all = L10n.tr("Localizable", "Scene.ServerPicker.SignupSpeed.All", fallback: "All")
        /// Instant Sign-up
        public static let instant = L10n.tr("Localizable", "Scene.ServerPicker.SignupSpeed.Instant", fallback: "Instant Sign-up")
        /// Manual Review
        public static let manuallyReviewed = L10n.tr("Localizable", "Scene.ServerPicker.SignupSpeed.ManuallyReviewed", fallback: "Manual Review")
      }
    }
    public enum ServerRules {
      /// privacy policy
      public static let privacyPolicy = L10n.tr("Localizable", "Scene.ServerRules.PrivacyPolicy", fallback: "privacy policy")
      /// By continuing, you’re subject to the terms of service and privacy policy for %@.
      public static func prompt(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.ServerRules.Prompt", String(describing: p1), fallback: "By continuing, you’re subject to the terms of service and privacy policy for %@.")
      }
      /// By continuing, you agree to follow by the following rules set and enforced by the **%@** moderators.
      public static func subtitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.ServerRules.Subtitle", String(describing: p1), fallback: "By continuing, you agree to follow by the following rules set and enforced by the **%@** moderators.")
      }
      /// terms of service
      public static let termsOfService = L10n.tr("Localizable", "Scene.ServerRules.TermsOfService", fallback: "terms of service")
      /// Server Rules
      public static let title = L10n.tr("Localizable", "Scene.ServerRules.Title", fallback: "Server Rules")
      public enum Button {
        /// I Agree
        public static let confirm = L10n.tr("Localizable", "Scene.ServerRules.Button.Confirm", fallback: "I Agree")
        /// Disagree
        public static let disagree = L10n.tr("Localizable", "Scene.ServerRules.Button.Disagree", fallback: "Disagree")
      }
    }
    public enum Settings {
      public enum AboutMastodon {
        /// Clear Media Storage
        public static let clearMediaStorage = L10n.tr("Localizable", "Scene.Settings.AboutMastodon.ClearMediaStorage", fallback: "Clear Media Storage")
        /// Contribute to Mastodon
        public static let contributeToMastodon = L10n.tr("Localizable", "Scene.Settings.AboutMastodon.ContributeToMastodon", fallback: "Contribute to Mastodon")
        /// Even More Settings
        public static let moreSettings = L10n.tr("Localizable", "Scene.Settings.AboutMastodon.MoreSettings", fallback: "Even More Settings")
        /// Privacy Policy
        public static let privacyPolicy = L10n.tr("Localizable", "Scene.Settings.AboutMastodon.PrivacyPolicy", fallback: "Privacy Policy")
        /// About
        public static let title = L10n.tr("Localizable", "Scene.Settings.AboutMastodon.Title", fallback: "About")
      }
      public enum General {
        /// General
        public static let title = L10n.tr("Localizable", "Scene.Settings.General.Title", fallback: "General")
        public enum Appearance {
          /// Dark
          public static let dark = L10n.tr("Localizable", "Scene.Settings.General.Appearance.Dark", fallback: "Dark")
          /// Light
          public static let light = L10n.tr("Localizable", "Scene.Settings.General.Appearance.Light", fallback: "Light")
          /// Appearance
          public static let sectionTitle = L10n.tr("Localizable", "Scene.Settings.General.Appearance.SectionTitle", fallback: "Appearance")
          /// Use Device Appearance
          public static let system = L10n.tr("Localizable", "Scene.Settings.General.Appearance.System", fallback: "Use Device Appearance")
        }
        public enum AskBefore {
          /// Boosting a Post
          public static let boostingAPost = L10n.tr("Localizable", "Scene.Settings.General.AskBefore.BoostingAPost", fallback: "Boosting a Post")
          /// Deleting a Post
          public static let deletingAPost = L10n.tr("Localizable", "Scene.Settings.General.AskBefore.DeletingAPost", fallback: "Deleting a Post")
          /// Posting without Alt Text
          public static let postingWithoutAltText = L10n.tr("Localizable", "Scene.Settings.General.AskBefore.PostingWithoutAltText", fallback: "Posting without Alt Text")
          /// Ask before…
          public static let sectionTitle = L10n.tr("Localizable", "Scene.Settings.General.AskBefore.SectionTitle", fallback: "Ask before…")
          /// Unfollowing Someone
          public static let unfollowingSomeone = L10n.tr("Localizable", "Scene.Settings.General.AskBefore.UnfollowingSomeone", fallback: "Unfollowing Someone")
        }
        public enum Design {
          /// Design
          public static let sectionTitle = L10n.tr("Localizable", "Scene.Settings.General.Design.SectionTitle", fallback: "Design")
          /// Play Animated Avatars and Emoji
          public static let showAnimations = L10n.tr("Localizable", "Scene.Settings.General.Design.ShowAnimations", fallback: "Play Animated Avatars and Emoji")
        }
        public enum Language {
          /// Default Post Language
          public static let defaultPostLanguage = L10n.tr("Localizable", "Scene.Settings.General.Language.DefaultPostLanguage", fallback: "Default Post Language")
          /// Language
          public static let sectionTitle = L10n.tr("Localizable", "Scene.Settings.General.Language.SectionTitle", fallback: "Language")
        }
        public enum Links {
          /// Open in Browser
          public static let openInBrowser = L10n.tr("Localizable", "Scene.Settings.General.Links.OpenInBrowser", fallback: "Open in Browser")
          /// Open in Mastodon
          public static let openInMastodon = L10n.tr("Localizable", "Scene.Settings.General.Links.OpenInMastodon", fallback: "Open in Mastodon")
          /// Links
          public static let sectionTitle = L10n.tr("Localizable", "Scene.Settings.General.Links.SectionTitle", fallback: "Links")
        }
      }
      public enum Notifications {
        /// Notifications
        public static let title = L10n.tr("Localizable", "Scene.Settings.Notifications.Title", fallback: "Notifications")
        public enum Alert {
          /// Boosts
          public static let boosts = L10n.tr("Localizable", "Scene.Settings.Notifications.Alert.Boosts", fallback: "Boosts")
          /// Favorites
          public static let favorites = L10n.tr("Localizable", "Scene.Settings.Notifications.Alert.Favorites", fallback: "Favorites")
          /// Mentions & Replies
          public static let mentionsAndReplies = L10n.tr("Localizable", "Scene.Settings.Notifications.Alert.MentionsAndReplies", fallback: "Mentions & Replies")
          /// New Followers
          public static let newFollowers = L10n.tr("Localizable", "Scene.Settings.Notifications.Alert.NewFollowers", fallback: "New Followers")
        }
        public enum Disabled {
          /// Go to Notification Settings
          public static let goToSettings = L10n.tr("Localizable", "Scene.Settings.Notifications.Disabled.GoToSettings", fallback: "Go to Notification Settings")
          /// Turn on notifications from your device settings to see updates on your lock screen.
          public static let notificationHint = L10n.tr("Localizable", "Scene.Settings.Notifications.Disabled.NotificationHint", fallback: "Turn on notifications from your device settings to see updates on your lock screen.")
        }
        public enum Policy {
          /// Anyone
          public static let anyone = L10n.tr("Localizable", "Scene.Settings.Notifications.Policy.Anyone", fallback: "Anyone")
          /// People you follow
          public static let follow = L10n.tr("Localizable", "Scene.Settings.Notifications.Policy.Follow", fallback: "People you follow")
          /// People who follow you
          public static let followers = L10n.tr("Localizable", "Scene.Settings.Notifications.Policy.Followers", fallback: "People who follow you")
          /// No one
          public static let noone = L10n.tr("Localizable", "Scene.Settings.Notifications.Policy.Noone", fallback: "No one")
          /// Get Notifications from
          public static let title = L10n.tr("Localizable", "Scene.Settings.Notifications.Policy.Title", fallback: "Get Notifications from")
        }
      }
      public enum Overview {
        /// About Mastodon
        public static let aboutMastodon = L10n.tr("Localizable", "Scene.Settings.Overview.AboutMastodon", fallback: "About Mastodon")
        /// General
        public static let general = L10n.tr("Localizable", "Scene.Settings.Overview.General", fallback: "General")
        /// Logout %@
        public static func logout(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Scene.Settings.Overview.Logout", String(describing: p1), fallback: "Logout %@")
        }
        /// Notifications
        public static let notifications = L10n.tr("Localizable", "Scene.Settings.Overview.Notifications", fallback: "Notifications")
        /// Privacy & Safety
        public static let privacySafety = L10n.tr("Localizable", "Scene.Settings.Overview.PrivacySafety", fallback: "Privacy & Safety")
        /// Server Details
        public static let serverDetails = L10n.tr("Localizable", "Scene.Settings.Overview.ServerDetails", fallback: "Server Details")
        /// Support Mastodon
        public static let supportMastodon = L10n.tr("Localizable", "Scene.Settings.Overview.SupportMastodon", fallback: "Support Mastodon")
        /// Settings
        public static let title = L10n.tr("Localizable", "Scene.Settings.Overview.Title", fallback: "Settings")
      }
      public enum PrivacySafety {
        /// Appear in Search Engines
        public static let appearInSearchEngines = L10n.tr("Localizable", "Scene.Settings.PrivacySafety.AppearInSearchEngines", fallback: "Appear in Search Engines")
        /// Manually Approve Follow Requests
        public static let manuallyApproveFollowRequests = L10n.tr("Localizable", "Scene.Settings.PrivacySafety.ManuallyApproveFollowRequests", fallback: "Manually Approve Follow Requests")
        /// Show Followers & Following
        public static let showFollowersAndFollowing = L10n.tr("Localizable", "Scene.Settings.PrivacySafety.ShowFollowersAndFollowing", fallback: "Show Followers & Following")
        /// Suggest My Account to Others
        public static let suggestMyAccountToOthers = L10n.tr("Localizable", "Scene.Settings.PrivacySafety.SuggestMyAccountToOthers", fallback: "Suggest My Account to Others")
        /// Privacy & Safety
        public static let title = L10n.tr("Localizable", "Scene.Settings.PrivacySafety.Title", fallback: "Privacy & Safety")
        public enum DefaultPostVisibility {
          /// Followers Only
          public static let followersOnly = L10n.tr("Localizable", "Scene.Settings.PrivacySafety.DefaultPostVisibility.FollowersOnly", fallback: "Followers Only")
          /// Only People Mentioned
          public static let onlyPeopleMentioned = L10n.tr("Localizable", "Scene.Settings.PrivacySafety.DefaultPostVisibility.OnlyPeopleMentioned", fallback: "Only People Mentioned")
          /// Public
          public static let `public` = L10n.tr("Localizable", "Scene.Settings.PrivacySafety.DefaultPostVisibility.Public", fallback: "Public")
          /// Default Post Visibility
          public static let title = L10n.tr("Localizable", "Scene.Settings.PrivacySafety.DefaultPostVisibility.Title", fallback: "Default Post Visibility")
        }
        public enum Preset {
          /// Custom
          public static let custom = L10n.tr("Localizable", "Scene.Settings.PrivacySafety.Preset.Custom", fallback: "Custom")
          /// Open & Public
          public static let openAndPublic = L10n.tr("Localizable", "Scene.Settings.PrivacySafety.Preset.OpenAndPublic", fallback: "Open & Public")
          /// Private & Restricted
          public static let privateAndRestricted = L10n.tr("Localizable", "Scene.Settings.PrivacySafety.Preset.PrivateAndRestricted", fallback: "Private & Restricted")
          /// Preset
          public static let title = L10n.tr("Localizable", "Scene.Settings.PrivacySafety.Preset.Title", fallback: "Preset")
        }
      }
      public enum ServerDetails {
        /// About
        public static let about = L10n.tr("Localizable", "Scene.Settings.ServerDetails.About", fallback: "About")
        /// Rules
        public static let rules = L10n.tr("Localizable", "Scene.Settings.ServerDetails.Rules", fallback: "Rules")
        public enum AboutInstance {
          /// A legal notice
          public static let legalNotice = L10n.tr("Localizable", "Scene.Settings.ServerDetails.AboutInstance.LegalNotice", fallback: "A legal notice")
          /// Message Admin
          public static let messageAdmin = L10n.tr("Localizable", "Scene.Settings.ServerDetails.AboutInstance.MessageAdmin", fallback: "Message Admin")
          /// Administrator
          public static let title = L10n.tr("Localizable", "Scene.Settings.ServerDetails.AboutInstance.Title", fallback: "Administrator")
        }
      }
    }
    public enum SuggestionAccount {
      /// Follow all
      public static let followAll = L10n.tr("Localizable", "Scene.SuggestionAccount.FollowAll", fallback: "Follow all")
      /// Popular on Mastodon
      public static let title = L10n.tr("Localizable", "Scene.SuggestionAccount.Title", fallback: "Popular on Mastodon")
    }
    public enum Thread {
      /// Post
      public static let backTitle = L10n.tr("Localizable", "Scene.Thread.BackTitle", fallback: "Post")
      /// Post from %@
      public static func title(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.Thread.Title", String(describing: p1), fallback: "Post from %@")
      }
    }
    public enum Welcome {
      /// Join %@
      public static func joinDefaultServer(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.Welcome.JoinDefaultServer", String(describing: p1), fallback: "Join %@")
      }
      /// Learn more
      public static let learnMore = L10n.tr("Localizable", "Scene.Welcome.LearnMore", fallback: "Learn more")
      /// Log In
      public static let logIn = L10n.tr("Localizable", "Scene.Welcome.LogIn", fallback: "Log In")
      /// Pick another server
      public static let pickServer = L10n.tr("Localizable", "Scene.Welcome.PickServer", fallback: "Pick another server")
      public enum Education {
        public enum A11Y {
          public enum WhatIsMastodon {
            /// What is Mastodon?
            public static let title = L10n.tr("Localizable", "Scene.Welcome.Education.A11Y.WhatIsMastodon.Title", fallback: "What is Mastodon?")
          }
        }
        public enum Mastodon {
          /// Mastodon is a decentralized social network, meaning no single company controls it. It’s made up of many independently-run servers, all connected together.
          public static let description = L10n.tr("Localizable", "Scene.Welcome.Education.Mastodon.Description", fallback: "Mastodon is a decentralized social network, meaning no single company controls it. It’s made up of many independently-run servers, all connected together.")
          /// Welcome to Mastodon
          public static let title = L10n.tr("Localizable", "Scene.Welcome.Education.Mastodon.Title", fallback: "Welcome to Mastodon")
        }
        public enum Servers {
          /// Every Mastodon account is hosted on a server — each with its own values, rules, & admins. No matter which one you pick, you can follow and interact with people on any server.
          public static let description = L10n.tr("Localizable", "Scene.Welcome.Education.Servers.Description", fallback: "Every Mastodon account is hosted on a server — each with its own values, rules, & admins. No matter which one you pick, you can follow and interact with people on any server.")
          /// What are servers?
          public static let title = L10n.tr("Localizable", "Scene.Welcome.Education.Servers.Title", fallback: "What are servers?")
        }
      }
      public enum Separator {
        /// or
        public static let or = L10n.tr("Localizable", "Scene.Welcome.Separator.Or", fallback: "or")
      }
    }
  }
  public enum Widget {
    public enum Common {
      /// Sorry but this Widget family is unsupported.
      public static let unsupportedWidgetFamily = L10n.tr("Localizable", "Widget.Common.UnsupportedWidgetFamily", fallback: "Sorry but this Widget family is unsupported.")
      /// Please open Mastodon to log in to an Account.
      public static let userNotLoggedIn = L10n.tr("Localizable", "Widget.Common.UserNotLoggedIn", fallback: "Please open Mastodon to log in to an Account.")
    }
    public enum FollowersCount {
      /// Show number of followers.
      public static let configurationDescription = L10n.tr("Localizable", "Widget.FollowersCount.ConfigurationDescription", fallback: "Show number of followers.")
      /// Followers
      public static let configurationDisplayName = L10n.tr("Localizable", "Widget.FollowersCount.ConfigurationDisplayName", fallback: "Followers")
      /// %@ followers today
      public static func followersToday(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Widget.FollowersCount.FollowersToday", String(describing: p1), fallback: "%@ followers today")
      }
      /// FOLLOWERS
      public static let title = L10n.tr("Localizable", "Widget.FollowersCount.Title", fallback: "FOLLOWERS")
    }
    public enum Hashtag {
      public enum Configuration {
        /// Shows a recent post with the selected hashtag.
        public static let description = L10n.tr("Localizable", "Widget.Hashtag.Configuration.Description", fallback: "Shows a recent post with the selected hashtag.")
        /// Hashtag
        public static let displayName = L10n.tr("Localizable", "Widget.Hashtag.Configuration.DisplayName", fallback: "Hashtag")
      }
      public enum NotFound {
        /// @johnMastodon@no-such.account
        public static let account = L10n.tr("Localizable", "Widget.Hashtag.NotFound.Account", fallback: "@johnMastodon@no-such.account")
        /// John Mastodon
        public static let accountName = L10n.tr("Localizable", "Widget.Hashtag.NotFound.AccountName", fallback: "John Mastodon")
        /// Sorry, we couldn’t find any posts with the hashtag <a>#%@</a>. Please try a <a>#DifferentHashtag</a> or check the widget settings.
        public static func content(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Widget.Hashtag.NotFound.Content", String(describing: p1), fallback: "Sorry, we couldn’t find any posts with the hashtag <a>#%@</a>. Please try a <a>#DifferentHashtag</a> or check the widget settings.")
        }
      }
      public enum Placeholder {
        /// @johnMastodon@no-such.account
        public static let account = L10n.tr("Localizable", "Widget.Hashtag.Placeholder.Account", fallback: "@johnMastodon@no-such.account")
        /// John Mastodon
        public static let accountName = L10n.tr("Localizable", "Widget.Hashtag.Placeholder.AccountName", fallback: "John Mastodon")
        /// This is how a post with a <a>#hashtag</a> would look. Pick whichever <a>#hashtag</a> you want in the widget settings.
        public static let content = L10n.tr("Localizable", "Widget.Hashtag.Placeholder.Content", fallback: "This is how a post with a <a>#hashtag</a> would look. Pick whichever <a>#hashtag</a> you want in the widget settings.")
      }
    }
    public enum LatestFollowers {
      /// Show latest followers.
      public static let configurationDescription = L10n.tr("Localizable", "Widget.LatestFollowers.ConfigurationDescription", fallback: "Show latest followers.")
      /// Latest followers
      public static let configurationDisplayName = L10n.tr("Localizable", "Widget.LatestFollowers.ConfigurationDisplayName", fallback: "Latest followers")
      /// Last update: %@
      public static func lastUpdate(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Widget.LatestFollowers.LastUpdate", String(describing: p1), fallback: "Last update: %@")
      }
      /// Latest followers
      public static let title = L10n.tr("Localizable", "Widget.LatestFollowers.Title", fallback: "Latest followers")
    }
    public enum MultipleFollowers {
      /// Show number of followers for multiple accounts.
      public static let configurationDescription = L10n.tr("Localizable", "Widget.MultipleFollowers.ConfigurationDescription", fallback: "Show number of followers for multiple accounts.")
      /// Multiple followers
      public static let configurationDisplayName = L10n.tr("Localizable", "Widget.MultipleFollowers.ConfigurationDisplayName", fallback: "Multiple followers")
      public enum MockUser {
        /// another@follower.social
        public static let accountName = L10n.tr("Localizable", "Widget.MultipleFollowers.MockUser.AccountName", fallback: "another@follower.social")
        /// Another follower
        public static let displayName = L10n.tr("Localizable", "Widget.MultipleFollowers.MockUser.DisplayName", fallback: "Another follower")
      }
    }
  }
  public enum A11y {
    public enum Plural {
      public enum Count {
        /// Plural format key: "%#@character_count@"
        public static func charactersLeft(_ p1: Int) -> String {
          return L10n.tr("Localizable", "a11y.plural.count.characters_left", p1, fallback: "Plural format key: \"%#@character_count@\"")
        }
        /// Plural format key: "Input limit exceeds %#@character_count@"
        public static func inputLimitExceeds(_ p1: Int) -> String {
          return L10n.tr("Localizable", "a11y.plural.count.input_limit_exceeds", p1, fallback: "Plural format key: \"Input limit exceeds %#@character_count@\"")
        }
        /// Plural format key: "Input limit remains %#@character_count@"
        public static func inputLimitRemains(_ p1: Int) -> String {
          return L10n.tr("Localizable", "a11y.plural.count.input_limit_remains", p1, fallback: "Plural format key: \"Input limit remains %#@character_count@\"")
        }
        public enum Unread {
          /// Plural format key: "%#@notification_count_unread_notification@"
          public static func notification(_ p1: Int) -> String {
            return L10n.tr("Localizable", "a11y.plural.count.unread.notification", p1, fallback: "Plural format key: \"%#@notification_count_unread_notification@\"")
          }
        }
      }
    }
  }
  public enum Date {
    public enum Day {
      /// Plural format key: "%#@count_day_left@"
      public static func `left`(_ p1: Int) -> String {
        return L10n.tr("Localizable", "date.day.left", p1, fallback: "Plural format key: \"%#@count_day_left@\"")
      }
      public enum Ago {
        /// Plural format key: "%#@count_day_ago_abbr@"
        public static func abbr(_ p1: Int) -> String {
          return L10n.tr("Localizable", "date.day.ago.abbr", p1, fallback: "Plural format key: \"%#@count_day_ago_abbr@\"")
        }
      }
    }
    public enum Hour {
      /// Plural format key: "%#@count_hour_left@"
      public static func `left`(_ p1: Int) -> String {
        return L10n.tr("Localizable", "date.hour.left", p1, fallback: "Plural format key: \"%#@count_hour_left@\"")
      }
      public enum Ago {
        /// Plural format key: "%#@count_hour_ago_abbr@"
        public static func abbr(_ p1: Int) -> String {
          return L10n.tr("Localizable", "date.hour.ago.abbr", p1, fallback: "Plural format key: \"%#@count_hour_ago_abbr@\"")
        }
      }
    }
    public enum Minute {
      /// Plural format key: "%#@count_minute_left@"
      public static func `left`(_ p1: Int) -> String {
        return L10n.tr("Localizable", "date.minute.left", p1, fallback: "Plural format key: \"%#@count_minute_left@\"")
      }
      public enum Ago {
        /// Plural format key: "%#@count_minute_ago_abbr@"
        public static func abbr(_ p1: Int) -> String {
          return L10n.tr("Localizable", "date.minute.ago.abbr", p1, fallback: "Plural format key: \"%#@count_minute_ago_abbr@\"")
        }
      }
    }
    public enum Month {
      /// Plural format key: "%#@count_month_left@"
      public static func `left`(_ p1: Int) -> String {
        return L10n.tr("Localizable", "date.month.left", p1, fallback: "Plural format key: \"%#@count_month_left@\"")
      }
      public enum Ago {
        /// Plural format key: "%#@count_month_ago_abbr@"
        public static func abbr(_ p1: Int) -> String {
          return L10n.tr("Localizable", "date.month.ago.abbr", p1, fallback: "Plural format key: \"%#@count_month_ago_abbr@\"")
        }
      }
    }
    public enum Second {
      /// Plural format key: "%#@count_second_left@"
      public static func `left`(_ p1: Int) -> String {
        return L10n.tr("Localizable", "date.second.left", p1, fallback: "Plural format key: \"%#@count_second_left@\"")
      }
      public enum Ago {
        /// Plural format key: "%#@count_second_ago_abbr@"
        public static func abbr(_ p1: Int) -> String {
          return L10n.tr("Localizable", "date.second.ago.abbr", p1, fallback: "Plural format key: \"%#@count_second_ago_abbr@\"")
        }
      }
    }
    public enum Year {
      /// Plural format key: "%#@count_year_left@"
      public static func `left`(_ p1: Int) -> String {
        return L10n.tr("Localizable", "date.year.left", p1, fallback: "Plural format key: \"%#@count_year_left@\"")
      }
      public enum Ago {
        /// Plural format key: "%#@count_year_ago_abbr@"
        public static func abbr(_ p1: Int) -> String {
          return L10n.tr("Localizable", "date.year.ago.abbr", p1, fallback: "Plural format key: \"%#@count_year_ago_abbr@\"")
        }
      }
    }
  }
  public enum Plural {
    /// Plural format key: "%#@count_people_talking@"
    public static func peopleTalking(_ p1: Int) -> String {
      return L10n.tr("Localizable", "plural.people_talking", p1, fallback: "Plural format key: \"%#@count_people_talking@\"")
    }
    public enum Count {
      /// Plural format key: "%#@favorite_count@"
      public static func favorite(_ p1: Int) -> String {
        return L10n.tr("Localizable", "plural.count.favorite", p1, fallback: "Plural format key: \"%#@favorite_count@\"")
      }
      /// Plural format key: "%#@names@%#@count_mutual@"
      public static func followedByAndMutual(_ p1: Int, _ p2: Int) -> String {
        return L10n.tr("Localizable", "plural.count.followed_by_and_mutual", p1, p2, fallback: "Plural format key: \"%#@names@%#@count_mutual@\"")
      }
      /// Plural format key: "%#@count_follower@"
      public static func follower(_ p1: Int) -> String {
        return L10n.tr("Localizable", "plural.count.follower", p1, fallback: "Plural format key: \"%#@count_follower@\"")
      }
      /// Plural format key: "%#@count_following@"
      public static func following(_ p1: Int) -> String {
        return L10n.tr("Localizable", "plural.count.following", p1, fallback: "Plural format key: \"%#@count_following@\"")
      }
      /// Plural format key: "%#@media_count@"
      public static func media(_ p1: Int) -> String {
        return L10n.tr("Localizable", "plural.count.media", p1, fallback: "Plural format key: \"%#@media_count@\"")
      }
      /// Plural format key: "%#@post_count@"
      public static func post(_ p1: Int) -> String {
        return L10n.tr("Localizable", "plural.count.post", p1, fallback: "Plural format key: \"%#@post_count@\"")
      }
      /// Plural format key: "%#@reblog_count@"
      public static func reblog(_ p1: Int) -> String {
        return L10n.tr("Localizable", "plural.count.reblog", p1, fallback: "Plural format key: \"%#@reblog_count@\"")
      }
      /// Plural format key: "%#@reblog_count@"
      public static func reblogA11y(_ p1: Int) -> String {
        return L10n.tr("Localizable", "plural.count.reblog_a11y", p1, fallback: "Plural format key: \"%#@reblog_count@\"")
      }
      /// Plural format key: "%#@reply_count@"
      public static func reply(_ p1: Int) -> String {
        return L10n.tr("Localizable", "plural.count.reply", p1, fallback: "Plural format key: \"%#@reply_count@\"")
      }
      /// Plural format key: "%#@vote_count@"
      public static func vote(_ p1: Int) -> String {
        return L10n.tr("Localizable", "plural.count.vote", p1, fallback: "Plural format key: \"%#@vote_count@\"")
      }
      /// Plural format key: "%#@voter_count@"
      public static func voter(_ p1: Int) -> String {
        return L10n.tr("Localizable", "plural.count.voter", p1, fallback: "Plural format key: \"%#@voter_count@\"")
      }
      public enum MetricFormatted {
        /// Plural format key: "%@ %#@post_count@"
        public static func post(_ p1: Any, _ p2: Int) -> String {
          return L10n.tr("Localizable", "plural.count.metric_formatted.post", String(describing: p1), p2, fallback: "Plural format key: \"%@ %#@post_count@\"")
        }
      }
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = Bundle.module.localizedString(forKey: key, value: value, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}
