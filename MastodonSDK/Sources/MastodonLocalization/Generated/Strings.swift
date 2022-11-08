// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum L10n {

  public enum Common {
    public enum Alerts {
      public enum BlockDomain {
        /// Block Domain
        public static let blockEntireDomain = L10n.tr("Localizable", "Common.Alerts.BlockDomain.BlockEntireDomain")
        /// Are you really, really sure you want to block the entire %@? In most cases a few targeted blocks or mutes are sufficient and preferable. You will not see content from that domain and any of your followers from that domain will be removed.
        public static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.BlockDomain.Title", String(describing: p1))
        }
      }
      public enum CleanCache {
        /// Successfully cleaned %@ cache.
        public static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.CleanCache.Message", String(describing: p1))
        }
        /// Clean Cache
        public static let title = L10n.tr("Localizable", "Common.Alerts.CleanCache.Title")
      }
      public enum Common {
        /// Please try again.
        public static let pleaseTryAgain = L10n.tr("Localizable", "Common.Alerts.Common.PleaseTryAgain")
        /// Please try again later.
        public static let pleaseTryAgainLater = L10n.tr("Localizable", "Common.Alerts.Common.PleaseTryAgainLater")
      }
      public enum DeletePost {
        /// Are you sure you want to delete this post?
        public static let message = L10n.tr("Localizable", "Common.Alerts.DeletePost.Message")
        /// Delete Post
        public static let title = L10n.tr("Localizable", "Common.Alerts.DeletePost.Title")
      }
      public enum DiscardPostContent {
        /// Confirm to discard composed post content.
        public static let message = L10n.tr("Localizable", "Common.Alerts.DiscardPostContent.Message")
        /// Discard Draft
        public static let title = L10n.tr("Localizable", "Common.Alerts.DiscardPostContent.Title")
      }
      public enum EditProfileFailure {
        /// Cannot edit profile. Please try again.
        public static let message = L10n.tr("Localizable", "Common.Alerts.EditProfileFailure.Message")
        /// Edit Profile Error
        public static let title = L10n.tr("Localizable", "Common.Alerts.EditProfileFailure.Title")
      }
      public enum PublishPostFailure {
        /// Failed to publish the post.\nPlease check your internet connection.
        public static let message = L10n.tr("Localizable", "Common.Alerts.PublishPostFailure.Message")
        /// Publish Failure
        public static let title = L10n.tr("Localizable", "Common.Alerts.PublishPostFailure.Title")
        public enum AttachmentsMessage {
          /// Cannot attach more than one video.
          public static let moreThanOneVideo = L10n.tr("Localizable", "Common.Alerts.PublishPostFailure.AttachmentsMessage.MoreThanOneVideo")
          /// Cannot attach a video to a post that already contains images.
          public static let videoAttachWithPhoto = L10n.tr("Localizable", "Common.Alerts.PublishPostFailure.AttachmentsMessage.VideoAttachWithPhoto")
        }
      }
      public enum SavePhotoFailure {
        /// Please enable the photo library access permission to save the photo.
        public static let message = L10n.tr("Localizable", "Common.Alerts.SavePhotoFailure.Message")
        /// Save Photo Failure
        public static let title = L10n.tr("Localizable", "Common.Alerts.SavePhotoFailure.Title")
      }
      public enum ServerError {
        /// Server Error
        public static let title = L10n.tr("Localizable", "Common.Alerts.ServerError.Title")
      }
      public enum SignOut {
        /// Sign Out
        public static let confirm = L10n.tr("Localizable", "Common.Alerts.SignOut.Confirm")
        /// Are you sure you want to sign out?
        public static let message = L10n.tr("Localizable", "Common.Alerts.SignOut.Message")
        /// Sign Out
        public static let title = L10n.tr("Localizable", "Common.Alerts.SignOut.Title")
      }
      public enum SignUpFailure {
        /// Sign Up Failure
        public static let title = L10n.tr("Localizable", "Common.Alerts.SignUpFailure.Title")
      }
      public enum VoteFailure {
        /// The poll has ended
        public static let pollEnded = L10n.tr("Localizable", "Common.Alerts.VoteFailure.PollEnded")
        /// Vote Failure
        public static let title = L10n.tr("Localizable", "Common.Alerts.VoteFailure.Title")
      }
    }
    public enum Controls {
      public enum Actions {
        /// Add
        public static let add = L10n.tr("Localizable", "Common.Controls.Actions.Add")
        /// Back
        public static let back = L10n.tr("Localizable", "Common.Controls.Actions.Back")
        /// Block %@
        public static func blockDomain(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Actions.BlockDomain", String(describing: p1))
        }
        /// Cancel
        public static let cancel = L10n.tr("Localizable", "Common.Controls.Actions.Cancel")
        /// Compose
        public static let compose = L10n.tr("Localizable", "Common.Controls.Actions.Compose")
        /// Confirm
        public static let confirm = L10n.tr("Localizable", "Common.Controls.Actions.Confirm")
        /// Continue
        public static let `continue` = L10n.tr("Localizable", "Common.Controls.Actions.Continue")
        /// Copy Photo
        public static let copyPhoto = L10n.tr("Localizable", "Common.Controls.Actions.CopyPhoto")
        /// Delete
        public static let delete = L10n.tr("Localizable", "Common.Controls.Actions.Delete")
        /// Discard
        public static let discard = L10n.tr("Localizable", "Common.Controls.Actions.Discard")
        /// Done
        public static let done = L10n.tr("Localizable", "Common.Controls.Actions.Done")
        /// Edit
        public static let edit = L10n.tr("Localizable", "Common.Controls.Actions.Edit")
        /// Find people to follow
        public static let findPeople = L10n.tr("Localizable", "Common.Controls.Actions.FindPeople")
        /// Manually search instead
        public static let manuallySearch = L10n.tr("Localizable", "Common.Controls.Actions.ManuallySearch")
        /// Next
        public static let next = L10n.tr("Localizable", "Common.Controls.Actions.Next")
        /// OK
        public static let ok = L10n.tr("Localizable", "Common.Controls.Actions.Ok")
        /// Open
        public static let `open` = L10n.tr("Localizable", "Common.Controls.Actions.Open")
        /// Open in Browser
        public static let openInBrowser = L10n.tr("Localizable", "Common.Controls.Actions.OpenInBrowser")
        /// Open in Safari
        public static let openInSafari = L10n.tr("Localizable", "Common.Controls.Actions.OpenInSafari")
        /// Preview
        public static let preview = L10n.tr("Localizable", "Common.Controls.Actions.Preview")
        /// Previous
        public static let previous = L10n.tr("Localizable", "Common.Controls.Actions.Previous")
        /// Remove
        public static let remove = L10n.tr("Localizable", "Common.Controls.Actions.Remove")
        /// Reply
        public static let reply = L10n.tr("Localizable", "Common.Controls.Actions.Reply")
        /// Report %@
        public static func reportUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Actions.ReportUser", String(describing: p1))
        }
        /// Save
        public static let save = L10n.tr("Localizable", "Common.Controls.Actions.Save")
        /// Save Photo
        public static let savePhoto = L10n.tr("Localizable", "Common.Controls.Actions.SavePhoto")
        /// See More
        public static let seeMore = L10n.tr("Localizable", "Common.Controls.Actions.SeeMore")
        /// Settings
        public static let settings = L10n.tr("Localizable", "Common.Controls.Actions.Settings")
        /// Share
        public static let share = L10n.tr("Localizable", "Common.Controls.Actions.Share")
        /// Share Post
        public static let sharePost = L10n.tr("Localizable", "Common.Controls.Actions.SharePost")
        /// Share %@
        public static func shareUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Actions.ShareUser", String(describing: p1))
        }
        /// Sign In
        public static let signIn = L10n.tr("Localizable", "Common.Controls.Actions.SignIn")
        /// Sign Up
        public static let signUp = L10n.tr("Localizable", "Common.Controls.Actions.SignUp")
        /// Skip
        public static let skip = L10n.tr("Localizable", "Common.Controls.Actions.Skip")
        /// Take Photo
        public static let takePhoto = L10n.tr("Localizable", "Common.Controls.Actions.TakePhoto")
        /// Try Again
        public static let tryAgain = L10n.tr("Localizable", "Common.Controls.Actions.TryAgain")
        /// Unblock %@
        public static func unblockDomain(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Actions.UnblockDomain", String(describing: p1))
        }
      }
      public enum Friendship {
        /// Block
        public static let block = L10n.tr("Localizable", "Common.Controls.Friendship.Block")
        /// Block %@
        public static func blockDomain(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Friendship.BlockDomain", String(describing: p1))
        }
        /// Blocked
        public static let blocked = L10n.tr("Localizable", "Common.Controls.Friendship.Blocked")
        /// Block %@
        public static func blockUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Friendship.BlockUser", String(describing: p1))
        }
        /// Edit Info
        public static let editInfo = L10n.tr("Localizable", "Common.Controls.Friendship.EditInfo")
        /// Follow
        public static let follow = L10n.tr("Localizable", "Common.Controls.Friendship.Follow")
        /// Following
        public static let following = L10n.tr("Localizable", "Common.Controls.Friendship.Following")
        /// Mute
        public static let mute = L10n.tr("Localizable", "Common.Controls.Friendship.Mute")
        /// Muted
        public static let muted = L10n.tr("Localizable", "Common.Controls.Friendship.Muted")
        /// Mute %@
        public static func muteUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Friendship.MuteUser", String(describing: p1))
        }
        /// Pending
        public static let pending = L10n.tr("Localizable", "Common.Controls.Friendship.Pending")
        /// Request
        public static let request = L10n.tr("Localizable", "Common.Controls.Friendship.Request")
        /// Unblock
        public static let unblock = L10n.tr("Localizable", "Common.Controls.Friendship.Unblock")
        /// Unblock %@
        public static func unblockUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Friendship.UnblockUser", String(describing: p1))
        }
        /// Unmute
        public static let unmute = L10n.tr("Localizable", "Common.Controls.Friendship.Unmute")
        /// Unmute %@
        public static func unmuteUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Friendship.UnmuteUser", String(describing: p1))
        }
      }
      public enum Keyboard {
        public enum Common {
          /// Compose New Post
          public static let composeNewPost = L10n.tr("Localizable", "Common.Controls.Keyboard.Common.ComposeNewPost")
          /// Open Settings
          public static let openSettings = L10n.tr("Localizable", "Common.Controls.Keyboard.Common.OpenSettings")
          /// Show Favorites
          public static let showFavorites = L10n.tr("Localizable", "Common.Controls.Keyboard.Common.ShowFavorites")
          /// Switch to %@
          public static func switchToTab(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Keyboard.Common.SwitchToTab", String(describing: p1))
          }
        }
        public enum SegmentedControl {
          /// Next Section
          public static let nextSection = L10n.tr("Localizable", "Common.Controls.Keyboard.SegmentedControl.NextSection")
          /// Previous Section
          public static let previousSection = L10n.tr("Localizable", "Common.Controls.Keyboard.SegmentedControl.PreviousSection")
        }
        public enum Timeline {
          /// Next Post
          public static let nextStatus = L10n.tr("Localizable", "Common.Controls.Keyboard.Timeline.NextStatus")
          /// Open Author's Profile
          public static let openAuthorProfile = L10n.tr("Localizable", "Common.Controls.Keyboard.Timeline.OpenAuthorProfile")
          /// Open Reblogger's Profile
          public static let openRebloggerProfile = L10n.tr("Localizable", "Common.Controls.Keyboard.Timeline.OpenRebloggerProfile")
          /// Open Post
          public static let openStatus = L10n.tr("Localizable", "Common.Controls.Keyboard.Timeline.OpenStatus")
          /// Preview Image
          public static let previewImage = L10n.tr("Localizable", "Common.Controls.Keyboard.Timeline.PreviewImage")
          /// Previous Post
          public static let previousStatus = L10n.tr("Localizable", "Common.Controls.Keyboard.Timeline.PreviousStatus")
          /// Reply to Post
          public static let replyStatus = L10n.tr("Localizable", "Common.Controls.Keyboard.Timeline.ReplyStatus")
          /// Toggle Content Warning
          public static let toggleContentWarning = L10n.tr("Localizable", "Common.Controls.Keyboard.Timeline.ToggleContentWarning")
          /// Toggle Favorite on Post
          public static let toggleFavorite = L10n.tr("Localizable", "Common.Controls.Keyboard.Timeline.ToggleFavorite")
          /// Toggle Reblog on Post
          public static let toggleReblog = L10n.tr("Localizable", "Common.Controls.Keyboard.Timeline.ToggleReblog")
        }
      }
      public enum Status {
        /// Content Warning
        public static let contentWarning = L10n.tr("Localizable", "Common.Controls.Status.ContentWarning")
        /// Tap anywhere to reveal
        public static let mediaContentWarning = L10n.tr("Localizable", "Common.Controls.Status.MediaContentWarning")
        /// Sensitive Content
        public static let sensitiveContent = L10n.tr("Localizable", "Common.Controls.Status.SensitiveContent")
        /// Show Post
        public static let showPost = L10n.tr("Localizable", "Common.Controls.Status.ShowPost")
        /// Show user profile
        public static let showUserProfile = L10n.tr("Localizable", "Common.Controls.Status.ShowUserProfile")
        /// Tap to reveal
        public static let tapToReveal = L10n.tr("Localizable", "Common.Controls.Status.TapToReveal")
        /// %@ reblogged
        public static func userReblogged(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Status.UserReblogged", String(describing: p1))
        }
        /// Replied to %@
        public static func userRepliedTo(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Status.UserRepliedTo", String(describing: p1))
        }
        public enum Actions {
          /// Bookmark
          public static let bookmark = L10n.tr("Localizable", "Common.Controls.Status.Actions.Bookmark")
          /// Favorite
          public static let favorite = L10n.tr("Localizable", "Common.Controls.Status.Actions.Favorite")
          /// Hide
          public static let hide = L10n.tr("Localizable", "Common.Controls.Status.Actions.Hide")
          /// Menu
          public static let menu = L10n.tr("Localizable", "Common.Controls.Status.Actions.Menu")
          /// Reblog
          public static let reblog = L10n.tr("Localizable", "Common.Controls.Status.Actions.Reblog")
          /// Reply
          public static let reply = L10n.tr("Localizable", "Common.Controls.Status.Actions.Reply")
          /// Show GIF
          public static let showGif = L10n.tr("Localizable", "Common.Controls.Status.Actions.ShowGif")
          /// Show image
          public static let showImage = L10n.tr("Localizable", "Common.Controls.Status.Actions.ShowImage")
          /// Show video player
          public static let showVideoPlayer = L10n.tr("Localizable", "Common.Controls.Status.Actions.ShowVideoPlayer")
          /// Tap then hold to show menu
          public static let tapThenHoldToShowMenu = L10n.tr("Localizable", "Common.Controls.Status.Actions.TapThenHoldToShowMenu")
          /// Unbookmark
          public static let unbookmark = L10n.tr("Localizable", "Common.Controls.Status.Actions.Unbookmark")
          /// Unfavorite
          public static let unfavorite = L10n.tr("Localizable", "Common.Controls.Status.Actions.Unfavorite")
          /// Undo reblog
          public static let unreblog = L10n.tr("Localizable", "Common.Controls.Status.Actions.Unreblog")
        }
        public enum MetaEntity {
          /// Email address: %@
          public static func email(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Status.MetaEntity.Email", String(describing: p1))
          }
          /// Hastag %@
          public static func hashtag(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Status.MetaEntity.Hashtag", String(describing: p1))
          }
          /// Show Profile: %@
          public static func mention(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Status.MetaEntity.Mention", String(describing: p1))
          }
          /// Link: %@
          public static func url(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Status.MetaEntity.Url", String(describing: p1))
          }
        }
        public enum Poll {
          /// Closed
          public static let closed = L10n.tr("Localizable", "Common.Controls.Status.Poll.Closed")
          /// Vote
          public static let vote = L10n.tr("Localizable", "Common.Controls.Status.Poll.Vote")
        }
        public enum Tag {
          /// Email
          public static let email = L10n.tr("Localizable", "Common.Controls.Status.Tag.Email")
          /// Emoji
          public static let emoji = L10n.tr("Localizable", "Common.Controls.Status.Tag.Emoji")
          /// Hashtag
          public static let hashtag = L10n.tr("Localizable", "Common.Controls.Status.Tag.Hashtag")
          /// Link
          public static let link = L10n.tr("Localizable", "Common.Controls.Status.Tag.Link")
          /// Mention
          public static let mention = L10n.tr("Localizable", "Common.Controls.Status.Tag.Mention")
          /// URL
          public static let url = L10n.tr("Localizable", "Common.Controls.Status.Tag.Url")
        }
        public enum Visibility {
          /// Only mentioned user can see this post.
          public static let direct = L10n.tr("Localizable", "Common.Controls.Status.Visibility.Direct")
          /// Only their followers can see this post.
          public static let `private` = L10n.tr("Localizable", "Common.Controls.Status.Visibility.Private")
          /// Only my followers can see this post.
          public static let privateFromMe = L10n.tr("Localizable", "Common.Controls.Status.Visibility.PrivateFromMe")
          /// Everyone can see this post but not display in the public timeline.
          public static let unlisted = L10n.tr("Localizable", "Common.Controls.Status.Visibility.Unlisted")
        }
      }
      public enum Tabs {
        /// Home
        public static let home = L10n.tr("Localizable", "Common.Controls.Tabs.Home")
        /// Notification
        public static let notification = L10n.tr("Localizable", "Common.Controls.Tabs.Notification")
        /// Profile
        public static let profile = L10n.tr("Localizable", "Common.Controls.Tabs.Profile")
        /// Search
        public static let search = L10n.tr("Localizable", "Common.Controls.Tabs.Search")
      }
      public enum Timeline {
        /// Filtered
        public static let filtered = L10n.tr("Localizable", "Common.Controls.Timeline.Filtered")
        public enum Header {
          /// You can’t view this user’s profile\nuntil they unblock you.
          public static let blockedWarning = L10n.tr("Localizable", "Common.Controls.Timeline.Header.BlockedWarning")
          /// You can’t view this user's profile\nuntil you unblock them.\nYour profile looks like this to them.
          public static let blockingWarning = L10n.tr("Localizable", "Common.Controls.Timeline.Header.BlockingWarning")
          /// No Post Found
          public static let noStatusFound = L10n.tr("Localizable", "Common.Controls.Timeline.Header.NoStatusFound")
          /// This user has been suspended.
          public static let suspendedWarning = L10n.tr("Localizable", "Common.Controls.Timeline.Header.SuspendedWarning")
          /// You can’t view %@’s profile\nuntil they unblock you.
          public static func userBlockedWarning(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Timeline.Header.UserBlockedWarning", String(describing: p1))
          }
          /// You can’t view %@’s profile\nuntil you unblock them.\nYour profile looks like this to them.
          public static func userBlockingWarning(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Timeline.Header.UserBlockingWarning", String(describing: p1))
          }
          /// %@’s account has been suspended.
          public static func userSuspendedWarning(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Timeline.Header.UserSuspendedWarning", String(describing: p1))
          }
        }
        public enum Loader {
          /// Loading missing posts...
          public static let loadingMissingPosts = L10n.tr("Localizable", "Common.Controls.Timeline.Loader.LoadingMissingPosts")
          /// Load missing posts
          public static let loadMissingPosts = L10n.tr("Localizable", "Common.Controls.Timeline.Loader.LoadMissingPosts")
          /// Show more replies
          public static let showMoreReplies = L10n.tr("Localizable", "Common.Controls.Timeline.Loader.ShowMoreReplies")
        }
        public enum Timestamp {
          /// Now
          public static let now = L10n.tr("Localizable", "Common.Controls.Timeline.Timestamp.Now")
        }
      }
    }
  }

  public enum Scene {
    public enum AccountList {
      /// Add Account
      public static let addAccount = L10n.tr("Localizable", "Scene.AccountList.AddAccount")
      /// Dismiss Account Switcher
      public static let dismissAccountSwitcher = L10n.tr("Localizable", "Scene.AccountList.DismissAccountSwitcher")
      /// Current selected profile: %@. Double tap then hold to show account switcher
      public static func tabBarHint(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.AccountList.TabBarHint", String(describing: p1))
      }
    }
    public enum Bookmark {
      /// Your Bookmarks
      public static let title = L10n.tr("Localizable", "Scene.Bookmark.Title")
    }
    public enum Compose {
      /// Publish
      public static let composeAction = L10n.tr("Localizable", "Scene.Compose.ComposeAction")
      /// Type or paste what’s on your mind
      public static let contentInputPlaceholder = L10n.tr("Localizable", "Scene.Compose.ContentInputPlaceholder")
      /// replying to %@
      public static func replyingToUser(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.Compose.ReplyingToUser", String(describing: p1))
      }
      public enum Accessibility {
        /// Add Attachment
        public static let appendAttachment = L10n.tr("Localizable", "Scene.Compose.Accessibility.AppendAttachment")
        /// Add Poll
        public static let appendPoll = L10n.tr("Localizable", "Scene.Compose.Accessibility.AppendPoll")
        /// Custom Emoji Picker
        public static let customEmojiPicker = L10n.tr("Localizable", "Scene.Compose.Accessibility.CustomEmojiPicker")
        /// Disable Content Warning
        public static let disableContentWarning = L10n.tr("Localizable", "Scene.Compose.Accessibility.DisableContentWarning")
        /// Enable Content Warning
        public static let enableContentWarning = L10n.tr("Localizable", "Scene.Compose.Accessibility.EnableContentWarning")
        /// Post Visibility Menu
        public static let postVisibilityMenu = L10n.tr("Localizable", "Scene.Compose.Accessibility.PostVisibilityMenu")
        /// Remove Poll
        public static let removePoll = L10n.tr("Localizable", "Scene.Compose.Accessibility.RemovePoll")
      }
      public enum Attachment {
        /// This %@ is broken and can’t be\nuploaded to Mastodon.
        public static func attachmentBroken(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Scene.Compose.Attachment.AttachmentBroken", String(describing: p1))
        }
        /// Describe the photo for the visually-impaired...
        public static let descriptionPhoto = L10n.tr("Localizable", "Scene.Compose.Attachment.DescriptionPhoto")
        /// Describe the video for the visually-impaired...
        public static let descriptionVideo = L10n.tr("Localizable", "Scene.Compose.Attachment.DescriptionVideo")
        /// photo
        public static let photo = L10n.tr("Localizable", "Scene.Compose.Attachment.Photo")
        /// video
        public static let video = L10n.tr("Localizable", "Scene.Compose.Attachment.Video")
      }
      public enum AutoComplete {
        /// Space to add
        public static let spaceToAdd = L10n.tr("Localizable", "Scene.Compose.AutoComplete.SpaceToAdd")
      }
      public enum ContentWarning {
        /// Write an accurate warning here...
        public static let placeholder = L10n.tr("Localizable", "Scene.Compose.ContentWarning.Placeholder")
      }
      public enum Keyboard {
        /// Add Attachment - %@
        public static func appendAttachmentEntry(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Scene.Compose.Keyboard.AppendAttachmentEntry", String(describing: p1))
        }
        /// Discard Post
        public static let discardPost = L10n.tr("Localizable", "Scene.Compose.Keyboard.DiscardPost")
        /// Publish Post
        public static let publishPost = L10n.tr("Localizable", "Scene.Compose.Keyboard.PublishPost")
        /// Select Visibility - %@
        public static func selectVisibilityEntry(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Scene.Compose.Keyboard.SelectVisibilityEntry", String(describing: p1))
        }
        /// Toggle Content Warning
        public static let toggleContentWarning = L10n.tr("Localizable", "Scene.Compose.Keyboard.ToggleContentWarning")
        /// Toggle Poll
        public static let togglePoll = L10n.tr("Localizable", "Scene.Compose.Keyboard.TogglePoll")
      }
      public enum MediaSelection {
        /// Browse
        public static let browse = L10n.tr("Localizable", "Scene.Compose.MediaSelection.Browse")
        /// Take Photo
        public static let camera = L10n.tr("Localizable", "Scene.Compose.MediaSelection.Camera")
        /// Photo Library
        public static let photoLibrary = L10n.tr("Localizable", "Scene.Compose.MediaSelection.PhotoLibrary")
      }
      public enum Poll {
        /// Duration: %@
        public static func durationTime(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Scene.Compose.Poll.DurationTime", String(describing: p1))
        }
        /// 1 Day
        public static let oneDay = L10n.tr("Localizable", "Scene.Compose.Poll.OneDay")
        /// 1 Hour
        public static let oneHour = L10n.tr("Localizable", "Scene.Compose.Poll.OneHour")
        /// Option %ld
        public static func optionNumber(_ p1: Int) -> String {
          return L10n.tr("Localizable", "Scene.Compose.Poll.OptionNumber", p1)
        }
        /// 7 Days
        public static let sevenDays = L10n.tr("Localizable", "Scene.Compose.Poll.SevenDays")
        /// 6 Hours
        public static let sixHours = L10n.tr("Localizable", "Scene.Compose.Poll.SixHours")
        /// 30 minutes
        public static let thirtyMinutes = L10n.tr("Localizable", "Scene.Compose.Poll.ThirtyMinutes")
        /// 3 Days
        public static let threeDays = L10n.tr("Localizable", "Scene.Compose.Poll.ThreeDays")
      }
      public enum Title {
        /// New Post
        public static let newPost = L10n.tr("Localizable", "Scene.Compose.Title.NewPost")
        /// New Reply
        public static let newReply = L10n.tr("Localizable", "Scene.Compose.Title.NewReply")
      }
      public enum Visibility {
        /// Only people I mention
        public static let direct = L10n.tr("Localizable", "Scene.Compose.Visibility.Direct")
        /// Followers only
        public static let `private` = L10n.tr("Localizable", "Scene.Compose.Visibility.Private")
        /// Public
        public static let `public` = L10n.tr("Localizable", "Scene.Compose.Visibility.Public")
        /// Unlisted
        public static let unlisted = L10n.tr("Localizable", "Scene.Compose.Visibility.Unlisted")
      }
    }
    public enum ConfirmEmail {
      /// Tap the link we emailed to you to verify your account.
      public static let subtitle = L10n.tr("Localizable", "Scene.ConfirmEmail.Subtitle")
      /// Tap the link we emailed to you to verify your account
      public static let tapTheLinkWeEmailedToYouToVerifyYourAccount = L10n.tr("Localizable", "Scene.ConfirmEmail.TapTheLinkWeEmailedToYouToVerifyYourAccount")
      /// One last thing.
      public static let title = L10n.tr("Localizable", "Scene.ConfirmEmail.Title")
      public enum Button {
        /// Open Email App
        public static let openEmailApp = L10n.tr("Localizable", "Scene.ConfirmEmail.Button.OpenEmailApp")
        /// Resend
        public static let resend = L10n.tr("Localizable", "Scene.ConfirmEmail.Button.Resend")
      }
      public enum DontReceiveEmail {
        /// Check if your email address is correct as well as your junk folder if you haven’t.
        public static let description = L10n.tr("Localizable", "Scene.ConfirmEmail.DontReceiveEmail.Description")
        /// Resend Email
        public static let resendEmail = L10n.tr("Localizable", "Scene.ConfirmEmail.DontReceiveEmail.ResendEmail")
        /// Check your email
        public static let title = L10n.tr("Localizable", "Scene.ConfirmEmail.DontReceiveEmail.Title")
      }
      public enum OpenEmailApp {
        /// We just sent you an email. Check your junk folder if you haven’t.
        public static let description = L10n.tr("Localizable", "Scene.ConfirmEmail.OpenEmailApp.Description")
        /// Mail
        public static let mail = L10n.tr("Localizable", "Scene.ConfirmEmail.OpenEmailApp.Mail")
        /// Open Email Client
        public static let openEmailClient = L10n.tr("Localizable", "Scene.ConfirmEmail.OpenEmailApp.OpenEmailClient")
        /// Check your inbox.
        public static let title = L10n.tr("Localizable", "Scene.ConfirmEmail.OpenEmailApp.Title")
      }
    }
    public enum Discovery {
      /// These are the posts gaining traction in your corner of Mastodon.
      public static let intro = L10n.tr("Localizable", "Scene.Discovery.Intro")
      public enum Tabs {
        /// Community
        public static let community = L10n.tr("Localizable", "Scene.Discovery.Tabs.Community")
        /// For You
        public static let forYou = L10n.tr("Localizable", "Scene.Discovery.Tabs.ForYou")
        /// Hashtags
        public static let hashtags = L10n.tr("Localizable", "Scene.Discovery.Tabs.Hashtags")
        /// News
        public static let news = L10n.tr("Localizable", "Scene.Discovery.Tabs.News")
        /// Posts
        public static let posts = L10n.tr("Localizable", "Scene.Discovery.Tabs.Posts")
      }
    }
    public enum Familiarfollowers {
      /// Followed by %@
      public static func followedByNames(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.Familiarfollowers.FollowedByNames", String(describing: p1))
      }
      /// Followers you familiar
      public static let title = L10n.tr("Localizable", "Scene.Familiarfollowers.Title")
    }
    public enum Favorite {
      /// Your Favorites
      public static let title = L10n.tr("Localizable", "Scene.Favorite.Title")
    }
    public enum FavoritedBy {
      /// Favorited By
      public static let title = L10n.tr("Localizable", "Scene.FavoritedBy.Title")
    }
    public enum Follower {
      /// Followers from other servers are not displayed.
      public static let footer = L10n.tr("Localizable", "Scene.Follower.Footer")
      /// follower
      public static let title = L10n.tr("Localizable", "Scene.Follower.Title")
    }
    public enum Following {
      /// Follows from other servers are not displayed.
      public static let footer = L10n.tr("Localizable", "Scene.Following.Footer")
      /// following
      public static let title = L10n.tr("Localizable", "Scene.Following.Title")
    }
    public enum HomeTimeline {
      /// Home
      public static let title = L10n.tr("Localizable", "Scene.HomeTimeline.Title")
      public enum NavigationBarState {
        /// See new posts
        public static let newPosts = L10n.tr("Localizable", "Scene.HomeTimeline.NavigationBarState.NewPosts")
        /// Offline
        public static let offline = L10n.tr("Localizable", "Scene.HomeTimeline.NavigationBarState.Offline")
        /// Published!
        public static let published = L10n.tr("Localizable", "Scene.HomeTimeline.NavigationBarState.Published")
        /// Publishing post...
        public static let publishing = L10n.tr("Localizable", "Scene.HomeTimeline.NavigationBarState.Publishing")
        public enum Accessibility {
          /// Tap to scroll to top and tap again to previous location
          public static let logoHint = L10n.tr("Localizable", "Scene.HomeTimeline.NavigationBarState.Accessibility.LogoHint")
          /// Logo Button
          public static let logoLabel = L10n.tr("Localizable", "Scene.HomeTimeline.NavigationBarState.Accessibility.LogoLabel")
        }
      }
    }
    public enum Notification {
      public enum FollowRequest {
        /// Accept
        public static let accept = L10n.tr("Localizable", "Scene.Notification.FollowRequest.Accept")
        /// Accepted
        public static let accepted = L10n.tr("Localizable", "Scene.Notification.FollowRequest.Accepted")
        /// reject
        public static let reject = L10n.tr("Localizable", "Scene.Notification.FollowRequest.Reject")
        /// Rejected
        public static let rejected = L10n.tr("Localizable", "Scene.Notification.FollowRequest.Rejected")
      }
      public enum Keyobard {
        /// Show Everything
        public static let showEverything = L10n.tr("Localizable", "Scene.Notification.Keyobard.ShowEverything")
        /// Show Mentions
        public static let showMentions = L10n.tr("Localizable", "Scene.Notification.Keyobard.ShowMentions")
      }
      public enum NotificationDescription {
        /// favorited your post
        public static let favoritedYourPost = L10n.tr("Localizable", "Scene.Notification.NotificationDescription.FavoritedYourPost")
        /// followed you
        public static let followedYou = L10n.tr("Localizable", "Scene.Notification.NotificationDescription.FollowedYou")
        /// mentioned you
        public static let mentionedYou = L10n.tr("Localizable", "Scene.Notification.NotificationDescription.MentionedYou")
        /// poll has ended
        public static let pollHasEnded = L10n.tr("Localizable", "Scene.Notification.NotificationDescription.PollHasEnded")
        /// reblogged your post
        public static let rebloggedYourPost = L10n.tr("Localizable", "Scene.Notification.NotificationDescription.RebloggedYourPost")
        /// request to follow you
        public static let requestToFollowYou = L10n.tr("Localizable", "Scene.Notification.NotificationDescription.RequestToFollowYou")
      }
      public enum Title {
        /// Everything
        public static let everything = L10n.tr("Localizable", "Scene.Notification.Title.Everything")
        /// Mentions
        public static let mentions = L10n.tr("Localizable", "Scene.Notification.Title.Mentions")
      }
    }
    public enum Preview {
      public enum Keyboard {
        /// Close Preview
        public static let closePreview = L10n.tr("Localizable", "Scene.Preview.Keyboard.ClosePreview")
        /// Show Next
        public static let showNext = L10n.tr("Localizable", "Scene.Preview.Keyboard.ShowNext")
        /// Show Previous
        public static let showPrevious = L10n.tr("Localizable", "Scene.Preview.Keyboard.ShowPrevious")
      }
    }
    public enum Profile {
      public enum Accessibility {
        /// Double tap to open the list
        public static let doubleTapToOpenTheList = L10n.tr("Localizable", "Scene.Profile.Accessibility.DoubleTapToOpenTheList")
        /// Edit avatar image
        public static let editAvatarImage = L10n.tr("Localizable", "Scene.Profile.Accessibility.EditAvatarImage")
        /// Show avatar image
        public static let showAvatarImage = L10n.tr("Localizable", "Scene.Profile.Accessibility.ShowAvatarImage")
        /// Show banner image
        public static let showBannerImage = L10n.tr("Localizable", "Scene.Profile.Accessibility.ShowBannerImage")
      }
      public enum Dashboard {
        /// followers
        public static let followers = L10n.tr("Localizable", "Scene.Profile.Dashboard.Followers")
        /// following
        public static let following = L10n.tr("Localizable", "Scene.Profile.Dashboard.Following")
        /// posts
        public static let posts = L10n.tr("Localizable", "Scene.Profile.Dashboard.Posts")
      }
      public enum Fields {
        /// Add Row
        public static let addRow = L10n.tr("Localizable", "Scene.Profile.Fields.AddRow")
        public enum Placeholder {
          /// Content
          public static let content = L10n.tr("Localizable", "Scene.Profile.Fields.Placeholder.Content")
          /// Label
          public static let label = L10n.tr("Localizable", "Scene.Profile.Fields.Placeholder.Label")
        }
      }
      public enum Header {
        /// Follows You
        public static let followsYou = L10n.tr("Localizable", "Scene.Profile.Header.FollowsYou")
      }
      public enum RelationshipActionAlert {
        public enum ConfirmBlockUser {
          /// Confirm to block %@
          public static func message(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Profile.RelationshipActionAlert.ConfirmBlockUser.Message", String(describing: p1))
          }
          /// Block Account
          public static let title = L10n.tr("Localizable", "Scene.Profile.RelationshipActionAlert.ConfirmBlockUser.Title")
        }
        public enum ConfirmMuteUser {
          /// Confirm to mute %@
          public static func message(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Profile.RelationshipActionAlert.ConfirmMuteUser.Message", String(describing: p1))
          }
          /// Mute Account
          public static let title = L10n.tr("Localizable", "Scene.Profile.RelationshipActionAlert.ConfirmMuteUser.Title")
        }
        public enum ConfirmUnblockUser {
          /// Confirm to unblock %@
          public static func message(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Profile.RelationshipActionAlert.ConfirmUnblockUser.Message", String(describing: p1))
          }
          /// Unblock Account
          public static let title = L10n.tr("Localizable", "Scene.Profile.RelationshipActionAlert.ConfirmUnblockUser.Title")
        }
        public enum ConfirmUnmuteUser {
          /// Confirm to unmute %@
          public static func message(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Profile.RelationshipActionAlert.ConfirmUnmuteUser.Message", String(describing: p1))
          }
          /// Unmute Account
          public static let title = L10n.tr("Localizable", "Scene.Profile.RelationshipActionAlert.ConfirmUnmuteUser.Title")
        }
      }
      public enum SegmentedControl {
        /// About
        public static let about = L10n.tr("Localizable", "Scene.Profile.SegmentedControl.About")
        /// Media
        public static let media = L10n.tr("Localizable", "Scene.Profile.SegmentedControl.Media")
        /// Posts
        public static let posts = L10n.tr("Localizable", "Scene.Profile.SegmentedControl.Posts")
        /// Posts and Replies
        public static let postsAndReplies = L10n.tr("Localizable", "Scene.Profile.SegmentedControl.PostsAndReplies")
        /// Replies
        public static let replies = L10n.tr("Localizable", "Scene.Profile.SegmentedControl.Replies")
      }
    }
    public enum RebloggedBy {
      /// Reblogged By
      public static let title = L10n.tr("Localizable", "Scene.RebloggedBy.Title")
    }
    public enum Register {
      /// Let’s get you set up on %@
      public static func letsGetYouSetUpOnDomain(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.Register.LetsGetYouSetUpOnDomain", String(describing: p1))
      }
      /// Let’s get you set up on %@
      public static func title(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.Register.Title", String(describing: p1))
      }
      public enum Error {
        public enum Item {
          /// Agreement
          public static let agreement = L10n.tr("Localizable", "Scene.Register.Error.Item.Agreement")
          /// Email
          public static let email = L10n.tr("Localizable", "Scene.Register.Error.Item.Email")
          /// Locale
          public static let locale = L10n.tr("Localizable", "Scene.Register.Error.Item.Locale")
          /// Password
          public static let password = L10n.tr("Localizable", "Scene.Register.Error.Item.Password")
          /// Reason
          public static let reason = L10n.tr("Localizable", "Scene.Register.Error.Item.Reason")
          /// Username
          public static let username = L10n.tr("Localizable", "Scene.Register.Error.Item.Username")
        }
        public enum Reason {
          /// %@ must be accepted
          public static func accepted(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Register.Error.Reason.Accepted", String(describing: p1))
          }
          /// %@ is required
          public static func blank(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Register.Error.Reason.Blank", String(describing: p1))
          }
          /// %@ contains a disallowed email provider
          public static func blocked(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Register.Error.Reason.Blocked", String(describing: p1))
          }
          /// %@ is not a supported value
          public static func inclusion(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Register.Error.Reason.Inclusion", String(describing: p1))
          }
          /// %@ is invalid
          public static func invalid(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Register.Error.Reason.Invalid", String(describing: p1))
          }
          /// %@ is a reserved keyword
          public static func reserved(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Register.Error.Reason.Reserved", String(describing: p1))
          }
          /// %@ is already in use
          public static func taken(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Register.Error.Reason.Taken", String(describing: p1))
          }
          /// %@ is too long
          public static func tooLong(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Register.Error.Reason.TooLong", String(describing: p1))
          }
          /// %@ is too short
          public static func tooShort(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Register.Error.Reason.TooShort", String(describing: p1))
          }
          /// %@ does not seem to exist
          public static func unreachable(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Register.Error.Reason.Unreachable", String(describing: p1))
          }
        }
        public enum Special {
          /// This is not a valid email address
          public static let emailInvalid = L10n.tr("Localizable", "Scene.Register.Error.Special.EmailInvalid")
          /// Password is too short (must be at least 8 characters)
          public static let passwordTooShort = L10n.tr("Localizable", "Scene.Register.Error.Special.PasswordTooShort")
          /// Username must only contain alphanumeric characters and underscores
          public static let usernameInvalid = L10n.tr("Localizable", "Scene.Register.Error.Special.UsernameInvalid")
          /// Username is too long (can’t be longer than 30 characters)
          public static let usernameTooLong = L10n.tr("Localizable", "Scene.Register.Error.Special.UsernameTooLong")
        }
      }
      public enum Input {
        public enum Avatar {
          /// Delete
          public static let delete = L10n.tr("Localizable", "Scene.Register.Input.Avatar.Delete")
        }
        public enum DisplayName {
          /// display name
          public static let placeholder = L10n.tr("Localizable", "Scene.Register.Input.DisplayName.Placeholder")
        }
        public enum Email {
          /// email
          public static let placeholder = L10n.tr("Localizable", "Scene.Register.Input.Email.Placeholder")
        }
        public enum Invite {
          /// Why do you want to join?
          public static let registrationUserInviteRequest = L10n.tr("Localizable", "Scene.Register.Input.Invite.RegistrationUserInviteRequest")
        }
        public enum Password {
          /// 8 characters
          public static let characterLimit = L10n.tr("Localizable", "Scene.Register.Input.Password.CharacterLimit")
          /// Your password needs at least eight characters
          public static let hint = L10n.tr("Localizable", "Scene.Register.Input.Password.Hint")
          /// password
          public static let placeholder = L10n.tr("Localizable", "Scene.Register.Input.Password.Placeholder")
          /// Your password needs at least:
          public static let require = L10n.tr("Localizable", "Scene.Register.Input.Password.Require")
          public enum Accessibility {
            /// checked
            public static let checked = L10n.tr("Localizable", "Scene.Register.Input.Password.Accessibility.Checked")
            /// unchecked
            public static let unchecked = L10n.tr("Localizable", "Scene.Register.Input.Password.Accessibility.Unchecked")
          }
        }
        public enum Username {
          /// This username is taken.
          public static let duplicatePrompt = L10n.tr("Localizable", "Scene.Register.Input.Username.DuplicatePrompt")
          /// username
          public static let placeholder = L10n.tr("Localizable", "Scene.Register.Input.Username.Placeholder")
        }
      }
    }
    public enum Report {
      /// Are there any other posts you’d like to add to the report?
      public static let content1 = L10n.tr("Localizable", "Scene.Report.Content1")
      /// Is there anything the moderators should know about this report?
      public static let content2 = L10n.tr("Localizable", "Scene.Report.Content2")
      /// REPORTED
      public static let reported = L10n.tr("Localizable", "Scene.Report.Reported")
      /// Thanks for reporting, we’ll look into this.
      public static let reportSentTitle = L10n.tr("Localizable", "Scene.Report.ReportSentTitle")
      /// Send Report
      public static let send = L10n.tr("Localizable", "Scene.Report.Send")
      /// Send without comment
      public static let skipToSend = L10n.tr("Localizable", "Scene.Report.SkipToSend")
      /// Step 1 of 2
      public static let step1 = L10n.tr("Localizable", "Scene.Report.Step1")
      /// Step 2 of 2
      public static let step2 = L10n.tr("Localizable", "Scene.Report.Step2")
      /// Type or paste additional comments
      public static let textPlaceholder = L10n.tr("Localizable", "Scene.Report.TextPlaceholder")
      /// Report %@
      public static func title(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.Report.Title", String(describing: p1))
      }
      /// Report
      public static let titleReport = L10n.tr("Localizable", "Scene.Report.TitleReport")
      public enum StepFinal {
        /// Block %@
        public static func blockUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Scene.Report.StepFinal.BlockUser", String(describing: p1))
        }
        /// Don’t want to see this?
        public static let dontWantToSeeThis = L10n.tr("Localizable", "Scene.Report.StepFinal.DontWantToSeeThis")
        /// Mute %@
        public static func muteUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Scene.Report.StepFinal.MuteUser", String(describing: p1))
        }
        /// They will no longer be able to follow or see your posts, but they can see if they’ve been blocked.
        public static let theyWillNoLongerBeAbleToFollowOrSeeYourPostsButTheyCanSeeIfTheyveBeenBlocked = L10n.tr("Localizable", "Scene.Report.StepFinal.TheyWillNoLongerBeAbleToFollowOrSeeYourPostsButTheyCanSeeIfTheyveBeenBlocked")
        /// Unfollow
        public static let unfollow = L10n.tr("Localizable", "Scene.Report.StepFinal.Unfollow")
        /// Unfollowed
        public static let unfollowed = L10n.tr("Localizable", "Scene.Report.StepFinal.Unfollowed")
        /// Unfollow %@
        public static func unfollowUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Scene.Report.StepFinal.UnfollowUser", String(describing: p1))
        }
        /// When you see something you don’t like on Mastodon, you can remove the person from your experience.
        public static let whenYouSeeSomethingYouDontLikeOnMastodonYouCanRemoveThePersonFromYourExperience = L10n.tr("Localizable", "Scene.Report.StepFinal.WhenYouSeeSomethingYouDontLikeOnMastodonYouCanRemoveThePersonFromYourExperience.")
        /// While we review this, you can take action against %@
        public static func whileWeReviewThisYouCanTakeActionAgainstUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Scene.Report.StepFinal.WhileWeReviewThisYouCanTakeActionAgainstUser", String(describing: p1))
        }
        /// You won’t see their posts or reblogs in your home feed. They won’t know they’ve been muted.
        public static let youWontSeeTheirPostsOrReblogsInYourHomeFeedTheyWontKnowTheyVeBeenMuted = L10n.tr("Localizable", "Scene.Report.StepFinal.YouWontSeeTheirPostsOrReblogsInYourHomeFeedTheyWontKnowTheyVeBeenMuted")
      }
      public enum StepFour {
        /// Is there anything else we should know?
        public static let isThereAnythingElseWeShouldKnow = L10n.tr("Localizable", "Scene.Report.StepFour.IsThereAnythingElseWeShouldKnow")
        /// Step 4 of 4
        public static let step4Of4 = L10n.tr("Localizable", "Scene.Report.StepFour.Step4Of4")
      }
      public enum StepOne {
        /// I don’t like it
        public static let iDontLikeIt = L10n.tr("Localizable", "Scene.Report.StepOne.IDontLikeIt")
        /// It is not something you want to see
        public static let itIsNotSomethingYouWantToSee = L10n.tr("Localizable", "Scene.Report.StepOne.ItIsNotSomethingYouWantToSee")
        /// It’s something else
        public static let itsSomethingElse = L10n.tr("Localizable", "Scene.Report.StepOne.ItsSomethingElse")
        /// It’s spam
        public static let itsSpam = L10n.tr("Localizable", "Scene.Report.StepOne.ItsSpam")
        /// It violates server rules
        public static let itViolatesServerRules = L10n.tr("Localizable", "Scene.Report.StepOne.ItViolatesServerRules")
        /// Malicious links, fake engagement, or repetetive replies
        public static let maliciousLinksFakeEngagementOrRepetetiveReplies = L10n.tr("Localizable", "Scene.Report.StepOne.MaliciousLinksFakeEngagementOrRepetetiveReplies")
        /// Select the best match
        public static let selectTheBestMatch = L10n.tr("Localizable", "Scene.Report.StepOne.SelectTheBestMatch")
        /// Step 1 of 4
        public static let step1Of4 = L10n.tr("Localizable", "Scene.Report.StepOne.Step1Of4")
        /// The issue does not fit into other categories
        public static let theIssueDoesNotFitIntoOtherCategories = L10n.tr("Localizable", "Scene.Report.StepOne.TheIssueDoesNotFitIntoOtherCategories")
        /// What's wrong with this account?
        public static let whatsWrongWithThisAccount = L10n.tr("Localizable", "Scene.Report.StepOne.WhatsWrongWithThisAccount")
        /// What's wrong with this post?
        public static let whatsWrongWithThisPost = L10n.tr("Localizable", "Scene.Report.StepOne.WhatsWrongWithThisPost")
        /// What's wrong with %@?
        public static func whatsWrongWithThisUsername(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Scene.Report.StepOne.WhatsWrongWithThisUsername", String(describing: p1))
        }
        /// You are aware that it breaks specific rules
        public static let youAreAwareThatItBreaksSpecificRules = L10n.tr("Localizable", "Scene.Report.StepOne.YouAreAwareThatItBreaksSpecificRules")
      }
      public enum StepThree {
        /// Are there any posts that back up this report?
        public static let areThereAnyPostsThatBackUpThisReport = L10n.tr("Localizable", "Scene.Report.StepThree.AreThereAnyPostsThatBackUpThisReport")
        /// Select all that apply
        public static let selectAllThatApply = L10n.tr("Localizable", "Scene.Report.StepThree.SelectAllThatApply")
        /// Step 3 of 4
        public static let step3Of4 = L10n.tr("Localizable", "Scene.Report.StepThree.Step3Of4")
      }
      public enum StepTwo {
        /// I just don’t like it
        public static let iJustDonTLikeIt = L10n.tr("Localizable", "Scene.Report.StepTwo.IJustDon’tLikeIt")
        /// Select all that apply
        public static let selectAllThatApply = L10n.tr("Localizable", "Scene.Report.StepTwo.SelectAllThatApply")
        /// Step 2 of 4
        public static let step2Of4 = L10n.tr("Localizable", "Scene.Report.StepTwo.Step2Of4")
        /// Which rules are being violated?
        public static let whichRulesAreBeingViolated = L10n.tr("Localizable", "Scene.Report.StepTwo.WhichRulesAreBeingViolated")
      }
    }
    public enum Search {
      /// Search
      public static let title = L10n.tr("Localizable", "Scene.Search.Title")
      public enum Recommend {
        /// See All
        public static let buttonText = L10n.tr("Localizable", "Scene.Search.Recommend.ButtonText")
        public enum Accounts {
          /// You may like to follow these accounts
          public static let description = L10n.tr("Localizable", "Scene.Search.Recommend.Accounts.Description")
          /// Follow
          public static let follow = L10n.tr("Localizable", "Scene.Search.Recommend.Accounts.Follow")
          /// Accounts you might like
          public static let title = L10n.tr("Localizable", "Scene.Search.Recommend.Accounts.Title")
        }
        public enum HashTag {
          /// Hashtags that are getting quite a bit of attention
          public static let description = L10n.tr("Localizable", "Scene.Search.Recommend.HashTag.Description")
          /// %@ people are talking
          public static func peopleTalking(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Search.Recommend.HashTag.PeopleTalking", String(describing: p1))
          }
          /// Trending on Mastodon
          public static let title = L10n.tr("Localizable", "Scene.Search.Recommend.HashTag.Title")
        }
      }
      public enum SearchBar {
        /// Cancel
        public static let cancel = L10n.tr("Localizable", "Scene.Search.SearchBar.Cancel")
        /// Search hashtags and users
        public static let placeholder = L10n.tr("Localizable", "Scene.Search.SearchBar.Placeholder")
      }
      public enum Searching {
        /// Clear
        public static let clear = L10n.tr("Localizable", "Scene.Search.Searching.Clear")
        /// Recent searches
        public static let recentSearch = L10n.tr("Localizable", "Scene.Search.Searching.RecentSearch")
        public enum EmptyState {
          /// No results
          public static let noResults = L10n.tr("Localizable", "Scene.Search.Searching.EmptyState.NoResults")
        }
        public enum Segment {
          /// All
          public static let all = L10n.tr("Localizable", "Scene.Search.Searching.Segment.All")
          /// Hashtags
          public static let hashtags = L10n.tr("Localizable", "Scene.Search.Searching.Segment.Hashtags")
          /// People
          public static let people = L10n.tr("Localizable", "Scene.Search.Searching.Segment.People")
          /// Posts
          public static let posts = L10n.tr("Localizable", "Scene.Search.Searching.Segment.Posts")
        }
      }
    }
    public enum ServerPicker {
      /// Pick a server based on your interests, region, or a general purpose one.
      public static let subtitle = L10n.tr("Localizable", "Scene.ServerPicker.Subtitle")
      /// Pick a server based on your interests, region, or a general purpose one. Each server is operated by an entirely independent organization or individual.
      public static let subtitleExtend = L10n.tr("Localizable", "Scene.ServerPicker.SubtitleExtend")
      /// Mastodon is made of users in different servers.
      public static let title = L10n.tr("Localizable", "Scene.ServerPicker.Title")
      public enum Button {
        /// See Less
        public static let seeLess = L10n.tr("Localizable", "Scene.ServerPicker.Button.SeeLess")
        /// See More
        public static let seeMore = L10n.tr("Localizable", "Scene.ServerPicker.Button.SeeMore")
        public enum Category {
          /// academia
          public static let academia = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.Academia")
          /// activism
          public static let activism = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.Activism")
          /// All
          public static let all = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.All")
          /// Category: All
          public static let allAccessiblityDescription = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.AllAccessiblityDescription")
          /// art
          public static let art = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.Art")
          /// food
          public static let food = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.Food")
          /// furry
          public static let furry = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.Furry")
          /// games
          public static let games = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.Games")
          /// general
          public static let general = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.General")
          /// journalism
          public static let journalism = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.Journalism")
          /// lgbt
          public static let lgbt = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.Lgbt")
          /// music
          public static let music = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.Music")
          /// regional
          public static let regional = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.Regional")
          /// tech
          public static let tech = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.Tech")
        }
      }
      public enum EmptyState {
        /// Something went wrong while loading the data. Check your internet connection.
        public static let badNetwork = L10n.tr("Localizable", "Scene.ServerPicker.EmptyState.BadNetwork")
        /// Finding available servers...
        public static let findingServers = L10n.tr("Localizable", "Scene.ServerPicker.EmptyState.FindingServers")
        /// No results
        public static let noResults = L10n.tr("Localizable", "Scene.ServerPicker.EmptyState.NoResults")
      }
      public enum Input {
        /// Search servers
        public static let placeholder = L10n.tr("Localizable", "Scene.ServerPicker.Input.Placeholder")
        /// Search servers or enter URL
        public static let searchServersOrEnterUrl = L10n.tr("Localizable", "Scene.ServerPicker.Input.SearchServersOrEnterUrl")
      }
      public enum Label {
        /// CATEGORY
        public static let category = L10n.tr("Localizable", "Scene.ServerPicker.Label.Category")
        /// LANGUAGE
        public static let language = L10n.tr("Localizable", "Scene.ServerPicker.Label.Language")
        /// USERS
        public static let users = L10n.tr("Localizable", "Scene.ServerPicker.Label.Users")
      }
    }
    public enum ServerRules {
      /// privacy policy
      public static let privacyPolicy = L10n.tr("Localizable", "Scene.ServerRules.PrivacyPolicy")
      /// By continuing, you’re subject to the terms of service and privacy policy for %@.
      public static func prompt(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.ServerRules.Prompt", String(describing: p1))
      }
      /// These are set and enforced by the %@ moderators.
      public static func subtitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.ServerRules.Subtitle", String(describing: p1))
      }
      /// terms of service
      public static let termsOfService = L10n.tr("Localizable", "Scene.ServerRules.TermsOfService")
      /// Some ground rules.
      public static let title = L10n.tr("Localizable", "Scene.ServerRules.Title")
      public enum Button {
        /// I Agree
        public static let confirm = L10n.tr("Localizable", "Scene.ServerRules.Button.Confirm")
      }
    }
    public enum Settings {
      /// Settings
      public static let title = L10n.tr("Localizable", "Scene.Settings.Title")
      public enum Footer {
        /// Mastodon is open source software. You can report issues on GitHub at %@ (%@)
        public static func mastodonDescription(_ p1: Any, _ p2: Any) -> String {
          return L10n.tr("Localizable", "Scene.Settings.Footer.MastodonDescription", String(describing: p1), String(describing: p2))
        }
      }
      public enum Keyboard {
        /// Close Settings Window
        public static let closeSettingsWindow = L10n.tr("Localizable", "Scene.Settings.Keyboard.CloseSettingsWindow")
      }
      public enum Section {
        public enum Appearance {
          /// Automatic
          public static let automatic = L10n.tr("Localizable", "Scene.Settings.Section.Appearance.Automatic")
          /// Always Dark
          public static let dark = L10n.tr("Localizable", "Scene.Settings.Section.Appearance.Dark")
          /// Always Light
          public static let light = L10n.tr("Localizable", "Scene.Settings.Section.Appearance.Light")
          /// Appearance
          public static let title = L10n.tr("Localizable", "Scene.Settings.Section.Appearance.Title")
        }
        public enum BoringZone {
          /// Account Settings
          public static let accountSettings = L10n.tr("Localizable", "Scene.Settings.Section.BoringZone.AccountSettings")
          /// Privacy Policy
          public static let privacy = L10n.tr("Localizable", "Scene.Settings.Section.BoringZone.Privacy")
          /// Terms of Service
          public static let terms = L10n.tr("Localizable", "Scene.Settings.Section.BoringZone.Terms")
          /// The Boring Zone
          public static let title = L10n.tr("Localizable", "Scene.Settings.Section.BoringZone.Title")
        }
        public enum LookAndFeel {
          /// Light
          public static let light = L10n.tr("Localizable", "Scene.Settings.Section.LookAndFeel.Light")
          /// Really Dark
          public static let reallyDark = L10n.tr("Localizable", "Scene.Settings.Section.LookAndFeel.ReallyDark")
          /// Sorta Dark
          public static let sortaDark = L10n.tr("Localizable", "Scene.Settings.Section.LookAndFeel.SortaDark")
          /// Look and Feel
          public static let title = L10n.tr("Localizable", "Scene.Settings.Section.LookAndFeel.Title")
          /// Use System
          public static let useSystem = L10n.tr("Localizable", "Scene.Settings.Section.LookAndFeel.UseSystem")
        }
        public enum Notifications {
          /// Reblogs my post
          public static let boosts = L10n.tr("Localizable", "Scene.Settings.Section.Notifications.Boosts")
          /// Favorites my post
          public static let favorites = L10n.tr("Localizable", "Scene.Settings.Section.Notifications.Favorites")
          /// Follows me
          public static let follows = L10n.tr("Localizable", "Scene.Settings.Section.Notifications.Follows")
          /// Mentions me
          public static let mentions = L10n.tr("Localizable", "Scene.Settings.Section.Notifications.Mentions")
          /// Notifications
          public static let title = L10n.tr("Localizable", "Scene.Settings.Section.Notifications.Title")
          public enum Trigger {
            /// anyone
            public static let anyone = L10n.tr("Localizable", "Scene.Settings.Section.Notifications.Trigger.Anyone")
            /// anyone I follow
            public static let follow = L10n.tr("Localizable", "Scene.Settings.Section.Notifications.Trigger.Follow")
            /// a follower
            public static let follower = L10n.tr("Localizable", "Scene.Settings.Section.Notifications.Trigger.Follower")
            /// no one
            public static let noone = L10n.tr("Localizable", "Scene.Settings.Section.Notifications.Trigger.Noone")
            /// Notify me when
            public static let title = L10n.tr("Localizable", "Scene.Settings.Section.Notifications.Trigger.Title")
          }
        }
        public enum Preference {
          /// Disable animated avatars
          public static let disableAvatarAnimation = L10n.tr("Localizable", "Scene.Settings.Section.Preference.DisableAvatarAnimation")
          /// Disable animated emojis
          public static let disableEmojiAnimation = L10n.tr("Localizable", "Scene.Settings.Section.Preference.DisableEmojiAnimation")
          /// Open links in Mastodon
          public static let openLinksInMastodon = L10n.tr("Localizable", "Scene.Settings.Section.Preference.OpenLinksInMastodon")
          /// Preferences
          public static let title = L10n.tr("Localizable", "Scene.Settings.Section.Preference.Title")
          /// True black dark mode
          public static let trueBlackDarkMode = L10n.tr("Localizable", "Scene.Settings.Section.Preference.TrueBlackDarkMode")
          /// Use default browser to open links
          public static let usingDefaultBrowser = L10n.tr("Localizable", "Scene.Settings.Section.Preference.UsingDefaultBrowser")
        }
        public enum SpicyZone {
          /// Clear Media Cache
          public static let clear = L10n.tr("Localizable", "Scene.Settings.Section.SpicyZone.Clear")
          /// Sign Out
          public static let signout = L10n.tr("Localizable", "Scene.Settings.Section.SpicyZone.Signout")
          /// The Spicy Zone
          public static let title = L10n.tr("Localizable", "Scene.Settings.Section.SpicyZone.Title")
        }
      }
    }
    public enum SuggestionAccount {
      /// When you follow someone, you’ll see their posts in your home feed.
      public static let followExplain = L10n.tr("Localizable", "Scene.SuggestionAccount.FollowExplain")
      /// Find People to Follow
      public static let title = L10n.tr("Localizable", "Scene.SuggestionAccount.Title")
    }
    public enum Thread {
      /// Post
      public static let backTitle = L10n.tr("Localizable", "Scene.Thread.BackTitle")
      /// Post from %@
      public static func title(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.Thread.Title", String(describing: p1))
      }
    }
    public enum Welcome {
      /// Get Started
      public static let getStarted = L10n.tr("Localizable", "Scene.Welcome.GetStarted")
      /// Log In
      public static let logIn = L10n.tr("Localizable", "Scene.Welcome.LogIn")
      /// Social networking\nback in your hands.
      public static let slogan = L10n.tr("Localizable", "Scene.Welcome.Slogan")
    }
    public enum Wizard {
      /// Double tap to dismiss this wizard
      public static let accessibilityHint = L10n.tr("Localizable", "Scene.Wizard.AccessibilityHint")
      /// Switch between multiple accounts by holding the profile button.
      public static let multipleAccountSwitchIntroDescription = L10n.tr("Localizable", "Scene.Wizard.MultipleAccountSwitchIntroDescription")
      /// New in Mastodon
      public static let newInMastodon = L10n.tr("Localizable", "Scene.Wizard.NewInMastodon")
    }
  }

  public enum A11y {
    public enum Plural {
      public enum Count {
        /// Plural format key: "Input limit exceeds %#@character_count@"
        public static func inputLimitExceeds(_ p1: Int) -> String {
          return L10n.tr("Localizable", "a11y.plural.count.input_limit_exceeds", p1)
        }
        /// Plural format key: "Input limit remains %#@character_count@"
        public static func inputLimitRemains(_ p1: Int) -> String {
          return L10n.tr("Localizable", "a11y.plural.count.input_limit_remains", p1)
        }
        public enum Unread {
          /// Plural format key: "%#@notification_count_unread_notification@"
          public static func notification(_ p1: Int) -> String {
            return L10n.tr("Localizable", "a11y.plural.count.unread.notification", p1)
          }
        }
      }
    }
  }

  public enum Date {
    public enum Day {
      /// Plural format key: "%#@count_day_left@"
      public static func `left`(_ p1: Int) -> String {
        return L10n.tr("Localizable", "date.day.left", p1)
      }
      public enum Ago {
        /// Plural format key: "%#@count_day_ago_abbr@"
        public static func abbr(_ p1: Int) -> String {
          return L10n.tr("Localizable", "date.day.ago.abbr", p1)
        }
      }
    }
    public enum Hour {
      /// Plural format key: "%#@count_hour_left@"
      public static func `left`(_ p1: Int) -> String {
        return L10n.tr("Localizable", "date.hour.left", p1)
      }
      public enum Ago {
        /// Plural format key: "%#@count_hour_ago_abbr@"
        public static func abbr(_ p1: Int) -> String {
          return L10n.tr("Localizable", "date.hour.ago.abbr", p1)
        }
      }
    }
    public enum Minute {
      /// Plural format key: "%#@count_minute_left@"
      public static func `left`(_ p1: Int) -> String {
        return L10n.tr("Localizable", "date.minute.left", p1)
      }
      public enum Ago {
        /// Plural format key: "%#@count_minute_ago_abbr@"
        public static func abbr(_ p1: Int) -> String {
          return L10n.tr("Localizable", "date.minute.ago.abbr", p1)
        }
      }
    }
    public enum Month {
      /// Plural format key: "%#@count_month_left@"
      public static func `left`(_ p1: Int) -> String {
        return L10n.tr("Localizable", "date.month.left", p1)
      }
      public enum Ago {
        /// Plural format key: "%#@count_month_ago_abbr@"
        public static func abbr(_ p1: Int) -> String {
          return L10n.tr("Localizable", "date.month.ago.abbr", p1)
        }
      }
    }
    public enum Second {
      /// Plural format key: "%#@count_second_left@"
      public static func `left`(_ p1: Int) -> String {
        return L10n.tr("Localizable", "date.second.left", p1)
      }
      public enum Ago {
        /// Plural format key: "%#@count_second_ago_abbr@"
        public static func abbr(_ p1: Int) -> String {
          return L10n.tr("Localizable", "date.second.ago.abbr", p1)
        }
      }
    }
    public enum Year {
      /// Plural format key: "%#@count_year_left@"
      public static func `left`(_ p1: Int) -> String {
        return L10n.tr("Localizable", "date.year.left", p1)
      }
      public enum Ago {
        /// Plural format key: "%#@count_year_ago_abbr@"
        public static func abbr(_ p1: Int) -> String {
          return L10n.tr("Localizable", "date.year.ago.abbr", p1)
        }
      }
    }
  }

  public enum Plural {
    /// Plural format key: "%#@count_people_talking@"
    public static func peopleTalking(_ p1: Int) -> String {
      return L10n.tr("Localizable", "plural.people_talking", p1)
    }
    public enum Count {
      /// Plural format key: "%#@favorite_count@"
      public static func favorite(_ p1: Int) -> String {
        return L10n.tr("Localizable", "plural.count.favorite", p1)
      }
      /// Plural format key: "%#@names@%#@count_mutual@"
      public static func followedByAndMutual(_ p1: Int, _ p2: Int) -> String {
        return L10n.tr("Localizable", "plural.count.followed_by_and_mutual", p1, p2)
      }
      /// Plural format key: "%#@count_follower@"
      public static func follower(_ p1: Int) -> String {
        return L10n.tr("Localizable", "plural.count.follower", p1)
      }
      /// Plural format key: "%#@count_following@"
      public static func following(_ p1: Int) -> String {
        return L10n.tr("Localizable", "plural.count.following", p1)
      }
      /// Plural format key: "%#@media_count@"
      public static func media(_ p1: Int) -> String {
        return L10n.tr("Localizable", "plural.count.media", p1)
      }
      /// Plural format key: "%#@post_count@"
      public static func post(_ p1: Int) -> String {
        return L10n.tr("Localizable", "plural.count.post", p1)
      }
      /// Plural format key: "%#@reblog_count@"
      public static func reblog(_ p1: Int) -> String {
        return L10n.tr("Localizable", "plural.count.reblog", p1)
      }
      /// Plural format key: "%#@reply_count@"
      public static func reply(_ p1: Int) -> String {
        return L10n.tr("Localizable", "plural.count.reply", p1)
      }
      /// Plural format key: "%#@vote_count@"
      public static func vote(_ p1: Int) -> String {
        return L10n.tr("Localizable", "plural.count.vote", p1)
      }
      /// Plural format key: "%#@voter_count@"
      public static func voter(_ p1: Int) -> String {
        return L10n.tr("Localizable", "plural.count.voter", p1)
      }
      public enum MetricFormatted {
        /// Plural format key: "%@ %#@post_count@"
        public static func post(_ p1: Any, _ p2: Int) -> String {
          return L10n.tr("Localizable", "plural.count.metric_formatted.post", String(describing: p1), p2)
        }
      }
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = Bundle.module.localizedString(forKey: key, value: nil, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}
