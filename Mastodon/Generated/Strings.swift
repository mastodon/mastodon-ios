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
      internal enum BlockDomain {
        /// Block Domain
        internal static let blockEntireDomain = L10n.tr("Localizable", "Common.Alerts.BlockDomain.BlockEntireDomain")
        /// Are you really, really sure you want to block the entire %@? In most cases a few targeted blocks or mutes are sufficient and preferable. You will not see content from that domain and any of your followers from that domain will be removed.
        internal static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.BlockDomain.Title", String(describing: p1))
        }
      }
      internal enum CleanCache {
        /// Successfully cleaned %@ cache.
        internal static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.CleanCache.Message", String(describing: p1))
        }
        /// Clean Cache
        internal static let title = L10n.tr("Localizable", "Common.Alerts.CleanCache.Title")
      }
      internal enum Common {
        /// Please try again.
        internal static let pleaseTryAgain = L10n.tr("Localizable", "Common.Alerts.Common.PleaseTryAgain")
        /// Please try again later.
        internal static let pleaseTryAgainLater = L10n.tr("Localizable", "Common.Alerts.Common.PleaseTryAgainLater")
      }
      internal enum DeletePost {
        /// Delete
        internal static let delete = L10n.tr("Localizable", "Common.Alerts.DeletePost.Delete")
        /// Are you sure you want to delete this post?
        internal static let title = L10n.tr("Localizable", "Common.Alerts.DeletePost.Title")
      }
      internal enum DiscardPostContent {
        /// Confirm to discard composed post content.
        internal static let message = L10n.tr("Localizable", "Common.Alerts.DiscardPostContent.Message")
        /// Discard Draft
        internal static let title = L10n.tr("Localizable", "Common.Alerts.DiscardPostContent.Title")
      }
      internal enum EditProfileFailure {
        /// Cannot edit profile. Please try again.
        internal static let message = L10n.tr("Localizable", "Common.Alerts.EditProfileFailure.Message")
        /// Edit Profile Error
        internal static let title = L10n.tr("Localizable", "Common.Alerts.EditProfileFailure.Title")
      }
      internal enum PublishPostFailure {
        /// Failed to publish the post.\nPlease check your internet connection.
        internal static let message = L10n.tr("Localizable", "Common.Alerts.PublishPostFailure.Message")
        /// Publish Failure
        internal static let title = L10n.tr("Localizable", "Common.Alerts.PublishPostFailure.Title")
        internal enum AttachmentsMessage {
          /// Cannot attach more than one video.
          internal static let moreThanOneVideo = L10n.tr("Localizable", "Common.Alerts.PublishPostFailure.AttachmentsMessage.MoreThanOneVideo")
          /// Cannot attach a video to a post that already contains images.
          internal static let videoAttachWithPhoto = L10n.tr("Localizable", "Common.Alerts.PublishPostFailure.AttachmentsMessage.VideoAttachWithPhoto")
        }
      }
      internal enum SavePhotoFailure {
        /// Please enable the photo library access permission to save the photo.
        internal static let message = L10n.tr("Localizable", "Common.Alerts.SavePhotoFailure.Message")
        /// Save Photo Failure
        internal static let title = L10n.tr("Localizable", "Common.Alerts.SavePhotoFailure.Title")
      }
      internal enum ServerError {
        /// Server Error
        internal static let title = L10n.tr("Localizable", "Common.Alerts.ServerError.Title")
      }
      internal enum SignOut {
        /// Sign Out
        internal static let confirm = L10n.tr("Localizable", "Common.Alerts.SignOut.Confirm")
        /// Are you sure you want to sign out?
        internal static let message = L10n.tr("Localizable", "Common.Alerts.SignOut.Message")
        /// Sign Out
        internal static let title = L10n.tr("Localizable", "Common.Alerts.SignOut.Title")
      }
      internal enum SignUpFailure {
        /// Sign Up Failure
        internal static let title = L10n.tr("Localizable", "Common.Alerts.SignUpFailure.Title")
      }
      internal enum VoteFailure {
        /// The poll has ended
        internal static let pollEnded = L10n.tr("Localizable", "Common.Alerts.VoteFailure.PollEnded")
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
        /// Block %@
        internal static func blockDomain(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Actions.BlockDomain", String(describing: p1))
        }
        /// Cancel
        internal static let cancel = L10n.tr("Localizable", "Common.Controls.Actions.Cancel")
        /// Confirm
        internal static let confirm = L10n.tr("Localizable", "Common.Controls.Actions.Confirm")
        /// Continue
        internal static let `continue` = L10n.tr("Localizable", "Common.Controls.Actions.Continue")
        /// Copy Photo
        internal static let copyPhoto = L10n.tr("Localizable", "Common.Controls.Actions.CopyPhoto")
        /// Delete
        internal static let delete = L10n.tr("Localizable", "Common.Controls.Actions.Delete")
        /// Discard
        internal static let discard = L10n.tr("Localizable", "Common.Controls.Actions.Discard")
        /// Done
        internal static let done = L10n.tr("Localizable", "Common.Controls.Actions.Done")
        /// Edit
        internal static let edit = L10n.tr("Localizable", "Common.Controls.Actions.Edit")
        /// Find people to follow
        internal static let findPeople = L10n.tr("Localizable", "Common.Controls.Actions.FindPeople")
        /// Manually search instead
        internal static let manuallySearch = L10n.tr("Localizable", "Common.Controls.Actions.ManuallySearch")
        /// Next
        internal static let next = L10n.tr("Localizable", "Common.Controls.Actions.Next")
        /// OK
        internal static let ok = L10n.tr("Localizable", "Common.Controls.Actions.Ok")
        /// Open
        internal static let `open` = L10n.tr("Localizable", "Common.Controls.Actions.Open")
        /// Open in Safari
        internal static let openInSafari = L10n.tr("Localizable", "Common.Controls.Actions.OpenInSafari")
        /// Preview
        internal static let preview = L10n.tr("Localizable", "Common.Controls.Actions.Preview")
        /// Previous
        internal static let previous = L10n.tr("Localizable", "Common.Controls.Actions.Previous")
        /// Remove
        internal static let remove = L10n.tr("Localizable", "Common.Controls.Actions.Remove")
        /// Reply
        internal static let reply = L10n.tr("Localizable", "Common.Controls.Actions.Reply")
        /// Report %@
        internal static func reportUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Actions.ReportUser", String(describing: p1))
        }
        /// Save
        internal static let save = L10n.tr("Localizable", "Common.Controls.Actions.Save")
        /// Save Photo
        internal static let savePhoto = L10n.tr("Localizable", "Common.Controls.Actions.SavePhoto")
        /// See More
        internal static let seeMore = L10n.tr("Localizable", "Common.Controls.Actions.SeeMore")
        /// Settings
        internal static let settings = L10n.tr("Localizable", "Common.Controls.Actions.Settings")
        /// Share
        internal static let share = L10n.tr("Localizable", "Common.Controls.Actions.Share")
        /// Share Post
        internal static let sharePost = L10n.tr("Localizable", "Common.Controls.Actions.SharePost")
        /// Share %@
        internal static func shareUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Actions.ShareUser", String(describing: p1))
        }
        /// Sign In
        internal static let signIn = L10n.tr("Localizable", "Common.Controls.Actions.SignIn")
        /// Sign Up
        internal static let signUp = L10n.tr("Localizable", "Common.Controls.Actions.SignUp")
        /// Skip
        internal static let skip = L10n.tr("Localizable", "Common.Controls.Actions.Skip")
        /// Take Photo
        internal static let takePhoto = L10n.tr("Localizable", "Common.Controls.Actions.TakePhoto")
        /// Try Again
        internal static let tryAgain = L10n.tr("Localizable", "Common.Controls.Actions.TryAgain")
        /// Unblock %@
        internal static func unblockDomain(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Actions.UnblockDomain", String(describing: p1))
        }
      }
      internal enum Friendship {
        /// Block
        internal static let block = L10n.tr("Localizable", "Common.Controls.Friendship.Block")
        /// Block %@
        internal static func blockDomain(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Friendship.BlockDomain", String(describing: p1))
        }
        /// Blocked
        internal static let blocked = L10n.tr("Localizable", "Common.Controls.Friendship.Blocked")
        /// Block %@
        internal static func blockUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Friendship.BlockUser", String(describing: p1))
        }
        /// Edit Info
        internal static let editInfo = L10n.tr("Localizable", "Common.Controls.Friendship.EditInfo")
        /// Follow
        internal static let follow = L10n.tr("Localizable", "Common.Controls.Friendship.Follow")
        /// Following
        internal static let following = L10n.tr("Localizable", "Common.Controls.Friendship.Following")
        /// Mute
        internal static let mute = L10n.tr("Localizable", "Common.Controls.Friendship.Mute")
        /// Muted
        internal static let muted = L10n.tr("Localizable", "Common.Controls.Friendship.Muted")
        /// Mute %@
        internal static func muteUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Friendship.MuteUser", String(describing: p1))
        }
        /// Pending
        internal static let pending = L10n.tr("Localizable", "Common.Controls.Friendship.Pending")
        /// Request
        internal static let request = L10n.tr("Localizable", "Common.Controls.Friendship.Request")
        /// Unblock
        internal static let unblock = L10n.tr("Localizable", "Common.Controls.Friendship.Unblock")
        /// Unblock %@
        internal static func unblockUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Friendship.UnblockUser", String(describing: p1))
        }
        /// Unmute
        internal static let unmute = L10n.tr("Localizable", "Common.Controls.Friendship.Unmute")
        /// Unmute %@
        internal static func unmuteUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Friendship.UnmuteUser", String(describing: p1))
        }
      }
      internal enum Keyboard {
        internal enum Common {
          /// Compose New Post
          internal static let composeNewPost = L10n.tr("Localizable", "Common.Controls.Keyboard.Common.ComposeNewPost")
          /// Open Settings
          internal static let openSettings = L10n.tr("Localizable", "Common.Controls.Keyboard.Common.OpenSettings")
          /// Show Favorites
          internal static let showFavorites = L10n.tr("Localizable", "Common.Controls.Keyboard.Common.ShowFavorites")
          /// Switch to %@
          internal static func switchToTab(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Keyboard.Common.SwitchToTab", String(describing: p1))
          }
        }
        internal enum SegmentedControl {
          /// Next Section
          internal static let nextSection = L10n.tr("Localizable", "Common.Controls.Keyboard.SegmentedControl.NextSection")
          /// Previous Section
          internal static let previousSection = L10n.tr("Localizable", "Common.Controls.Keyboard.SegmentedControl.PreviousSection")
        }
        internal enum Timeline {
          /// Next Post
          internal static let nextStatus = L10n.tr("Localizable", "Common.Controls.Keyboard.Timeline.NextStatus")
          /// Open Author's Profile
          internal static let openAuthorProfile = L10n.tr("Localizable", "Common.Controls.Keyboard.Timeline.OpenAuthorProfile")
          /// Open Reblogger's Profile
          internal static let openRebloggerProfile = L10n.tr("Localizable", "Common.Controls.Keyboard.Timeline.OpenRebloggerProfile")
          /// Open Post
          internal static let openStatus = L10n.tr("Localizable", "Common.Controls.Keyboard.Timeline.OpenStatus")
          /// Preview Image
          internal static let previewImage = L10n.tr("Localizable", "Common.Controls.Keyboard.Timeline.PreviewImage")
          /// Previous Post
          internal static let previousStatus = L10n.tr("Localizable", "Common.Controls.Keyboard.Timeline.PreviousStatus")
          /// Reply to Post
          internal static let replyStatus = L10n.tr("Localizable", "Common.Controls.Keyboard.Timeline.ReplyStatus")
          /// Toggle Content Warning
          internal static let toggleContentWarning = L10n.tr("Localizable", "Common.Controls.Keyboard.Timeline.ToggleContentWarning")
          /// Toggle Favorite on Post
          internal static let toggleFavorite = L10n.tr("Localizable", "Common.Controls.Keyboard.Timeline.ToggleFavorite")
          /// Toggle Reblog on Post
          internal static let toggleReblog = L10n.tr("Localizable", "Common.Controls.Keyboard.Timeline.ToggleReblog")
        }
      }
      internal enum Status {
        /// Content Warning
        internal static let contentWarning = L10n.tr("Localizable", "Common.Controls.Status.ContentWarning")
        /// Tap anywhere to reveal
        internal static let mediaContentWarning = L10n.tr("Localizable", "Common.Controls.Status.MediaContentWarning")
        /// Show Post
        internal static let showPost = L10n.tr("Localizable", "Common.Controls.Status.ShowPost")
        /// Show user profile
        internal static let showUserProfile = L10n.tr("Localizable", "Common.Controls.Status.ShowUserProfile")
        /// %@ reblogged
        internal static func userReblogged(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Status.UserReblogged", String(describing: p1))
        }
        /// Replied to %@
        internal static func userRepliedTo(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Status.UserRepliedTo", String(describing: p1))
        }
        internal enum Actions {
          /// Favorite
          internal static let favorite = L10n.tr("Localizable", "Common.Controls.Status.Actions.Favorite")
          /// Menu
          internal static let menu = L10n.tr("Localizable", "Common.Controls.Status.Actions.Menu")
          /// Reblog
          internal static let reblog = L10n.tr("Localizable", "Common.Controls.Status.Actions.Reblog")
          /// Reply
          internal static let reply = L10n.tr("Localizable", "Common.Controls.Status.Actions.Reply")
          /// Unfavorite
          internal static let unfavorite = L10n.tr("Localizable", "Common.Controls.Status.Actions.Unfavorite")
          /// Undo reblog
          internal static let unreblog = L10n.tr("Localizable", "Common.Controls.Status.Actions.Unreblog")
        }
        internal enum Poll {
          /// Closed
          internal static let closed = L10n.tr("Localizable", "Common.Controls.Status.Poll.Closed")
          /// Vote
          internal static let vote = L10n.tr("Localizable", "Common.Controls.Status.Poll.Vote")
        }
        internal enum Tag {
          /// Email
          internal static let email = L10n.tr("Localizable", "Common.Controls.Status.Tag.Email")
          /// Emoji
          internal static let emoji = L10n.tr("Localizable", "Common.Controls.Status.Tag.Emoji")
          /// Hashtag
          internal static let hashtag = L10n.tr("Localizable", "Common.Controls.Status.Tag.Hashtag")
          /// Link
          internal static let link = L10n.tr("Localizable", "Common.Controls.Status.Tag.Link")
          /// Mention
          internal static let mention = L10n.tr("Localizable", "Common.Controls.Status.Tag.Mention")
          /// URL
          internal static let url = L10n.tr("Localizable", "Common.Controls.Status.Tag.Url")
        }
      }
      internal enum Tabs {
        /// Home
        internal static let home = L10n.tr("Localizable", "Common.Controls.Tabs.Home")
        /// Notification
        internal static let notification = L10n.tr("Localizable", "Common.Controls.Tabs.Notification")
        /// Profile
        internal static let profile = L10n.tr("Localizable", "Common.Controls.Tabs.Profile")
        /// Search
        internal static let search = L10n.tr("Localizable", "Common.Controls.Tabs.Search")
      }
      internal enum Timeline {
        /// Filtered
        internal static let filtered = L10n.tr("Localizable", "Common.Controls.Timeline.Filtered")
        internal enum Header {
          /// You can’t view this user’s profile\nuntil they unblock you.
          internal static let blockedWarning = L10n.tr("Localizable", "Common.Controls.Timeline.Header.BlockedWarning")
          /// You can’t view this user's profile\nuntil you unblock them.\nYour profile looks like this to them.
          internal static let blockingWarning = L10n.tr("Localizable", "Common.Controls.Timeline.Header.BlockingWarning")
          /// No Post Found
          internal static let noStatusFound = L10n.tr("Localizable", "Common.Controls.Timeline.Header.NoStatusFound")
          /// This user has been suspended.
          internal static let suspendedWarning = L10n.tr("Localizable", "Common.Controls.Timeline.Header.SuspendedWarning")
          /// You can’t view %@’s profile\nuntil they unblock you.
          internal static func userBlockedWarning(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Timeline.Header.UserBlockedWarning", String(describing: p1))
          }
          /// You can’t view %@’s profile\nuntil you unblock them.\nYour profile looks like this to them.
          internal static func userBlockingWarning(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Timeline.Header.UserBlockingWarning", String(describing: p1))
          }
          /// %@’s account has been suspended.
          internal static func userSuspendedWarning(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Timeline.Header.UserSuspendedWarning", String(describing: p1))
          }
        }
        internal enum Loader {
          /// Loading missing posts...
          internal static let loadingMissingPosts = L10n.tr("Localizable", "Common.Controls.Timeline.Loader.LoadingMissingPosts")
          /// Load missing posts
          internal static let loadMissingPosts = L10n.tr("Localizable", "Common.Controls.Timeline.Loader.LoadMissingPosts")
          /// Show more replies
          internal static let showMoreReplies = L10n.tr("Localizable", "Common.Controls.Timeline.Loader.ShowMoreReplies")
        }
        internal enum Timestamp {
          /// Now
          internal static let now = L10n.tr("Localizable", "Common.Controls.Timeline.Timestamp.Now")
        }
      }
    }
  }

  internal enum Scene {
    internal enum AccountList {
      /// Add Account
      internal static let addAccount = L10n.tr("Localizable", "Scene.AccountList.AddAccount")
      /// Dismiss Account Switcher
      internal static let dismissAccountSwitcher = L10n.tr("Localizable", "Scene.AccountList.DismissAccountSwitcher")
      /// Current selected profile: %@. Double tap then hold to show account switcher
      internal static func tabBarHint(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.AccountList.TabBarHint", String(describing: p1))
      }
    }
    internal enum Compose {
      /// Publish
      internal static let composeAction = L10n.tr("Localizable", "Scene.Compose.ComposeAction")
      /// Type or paste what’s on your mind
      internal static let contentInputPlaceholder = L10n.tr("Localizable", "Scene.Compose.ContentInputPlaceholder")
      /// replying to %@
      internal static func replyingToUser(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.Compose.ReplyingToUser", String(describing: p1))
      }
      internal enum Accessibility {
        /// Add Attachment
        internal static let appendAttachment = L10n.tr("Localizable", "Scene.Compose.Accessibility.AppendAttachment")
        /// Add Poll
        internal static let appendPoll = L10n.tr("Localizable", "Scene.Compose.Accessibility.AppendPoll")
        /// Custom Emoji Picker
        internal static let customEmojiPicker = L10n.tr("Localizable", "Scene.Compose.Accessibility.CustomEmojiPicker")
        /// Disable Content Warning
        internal static let disableContentWarning = L10n.tr("Localizable", "Scene.Compose.Accessibility.DisableContentWarning")
        /// Enable Content Warning
        internal static let enableContentWarning = L10n.tr("Localizable", "Scene.Compose.Accessibility.EnableContentWarning")
        /// Post Visibility Menu
        internal static let postVisibilityMenu = L10n.tr("Localizable", "Scene.Compose.Accessibility.PostVisibilityMenu")
        /// Remove Poll
        internal static let removePoll = L10n.tr("Localizable", "Scene.Compose.Accessibility.RemovePoll")
      }
      internal enum Attachment {
        /// This %@ is broken and can’t be\nuploaded to Mastodon.
        internal static func attachmentBroken(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Scene.Compose.Attachment.AttachmentBroken", String(describing: p1))
        }
        /// Describe the photo for the visually-impaired...
        internal static let descriptionPhoto = L10n.tr("Localizable", "Scene.Compose.Attachment.DescriptionPhoto")
        /// Describe the video for the visually-impaired...
        internal static let descriptionVideo = L10n.tr("Localizable", "Scene.Compose.Attachment.DescriptionVideo")
        /// photo
        internal static let photo = L10n.tr("Localizable", "Scene.Compose.Attachment.Photo")
        /// video
        internal static let video = L10n.tr("Localizable", "Scene.Compose.Attachment.Video")
      }
      internal enum AutoComplete {
        /// Space to add
        internal static let spaceToAdd = L10n.tr("Localizable", "Scene.Compose.AutoComplete.SpaceToAdd")
      }
      internal enum ContentWarning {
        /// Write an accurate warning here...
        internal static let placeholder = L10n.tr("Localizable", "Scene.Compose.ContentWarning.Placeholder")
      }
      internal enum Keyboard {
        /// Add Attachment - %@
        internal static func appendAttachmentEntry(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Scene.Compose.Keyboard.AppendAttachmentEntry", String(describing: p1))
        }
        /// Discard Post
        internal static let discardPost = L10n.tr("Localizable", "Scene.Compose.Keyboard.DiscardPost")
        /// Publish Post
        internal static let publishPost = L10n.tr("Localizable", "Scene.Compose.Keyboard.PublishPost")
        /// Select Visibility - %@
        internal static func selectVisibilityEntry(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Scene.Compose.Keyboard.SelectVisibilityEntry", String(describing: p1))
        }
        /// Toggle Content Warning
        internal static let toggleContentWarning = L10n.tr("Localizable", "Scene.Compose.Keyboard.ToggleContentWarning")
        /// Toggle Poll
        internal static let togglePoll = L10n.tr("Localizable", "Scene.Compose.Keyboard.TogglePoll")
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
        /// Option %ld
        internal static func optionNumber(_ p1: Int) -> String {
          return L10n.tr("Localizable", "Scene.Compose.Poll.OptionNumber", p1)
        }
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
    internal enum Favorite {
      /// Your Favorites
      internal static let title = L10n.tr("Localizable", "Scene.Favorite.Title")
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
    internal enum Notification {
      /// %@ favorited your post
      internal static func userFavoritedYourPost(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.Notification.UserFavorited Your Post", String(describing: p1))
      }
      /// %@ followed you
      internal static func userFollowedYou(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.Notification.UserFollowedYou", String(describing: p1))
      }
      /// %@ mentioned you
      internal static func userMentionedYou(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.Notification.UserMentionedYou", String(describing: p1))
      }
      /// %@ reblogged your post
      internal static func userRebloggedYourPost(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.Notification.UserRebloggedYourPost", String(describing: p1))
      }
      /// %@ requested to follow you
      internal static func userRequestedToFollowYou(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.Notification.UserRequestedToFollowYou", String(describing: p1))
      }
      /// %@ Your poll has ended
      internal static func userYourPollHasEnded(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.Notification.UserYourPollHasEnded", String(describing: p1))
      }
      internal enum Keyobard {
        /// Show Everything
        internal static let showEverything = L10n.tr("Localizable", "Scene.Notification.Keyobard.ShowEverything")
        /// Show Mentions
        internal static let showMentions = L10n.tr("Localizable", "Scene.Notification.Keyobard.ShowMentions")
      }
      internal enum Title {
        /// Everything
        internal static let everything = L10n.tr("Localizable", "Scene.Notification.Title.Everything")
        /// Mentions
        internal static let mentions = L10n.tr("Localizable", "Scene.Notification.Title.Mentions")
      }
    }
    internal enum Preview {
      internal enum Keyboard {
        /// Close Preview
        internal static let closePreview = L10n.tr("Localizable", "Scene.Preview.Keyboard.ClosePreview")
        /// Show Next
        internal static let showNext = L10n.tr("Localizable", "Scene.Preview.Keyboard.ShowNext")
        /// Show Previous
        internal static let showPrevious = L10n.tr("Localizable", "Scene.Preview.Keyboard.ShowPrevious")
      }
    }
    internal enum Profile {
      internal enum Dashboard {
        /// followers
        internal static let followers = L10n.tr("Localizable", "Scene.Profile.Dashboard.Followers")
        /// following
        internal static let following = L10n.tr("Localizable", "Scene.Profile.Dashboard.Following")
        /// posts
        internal static let posts = L10n.tr("Localizable", "Scene.Profile.Dashboard.Posts")
      }
      internal enum Fields {
        /// Add Row
        internal static let addRow = L10n.tr("Localizable", "Scene.Profile.Fields.AddRow")
        internal enum Placeholder {
          /// Content
          internal static let content = L10n.tr("Localizable", "Scene.Profile.Fields.Placeholder.Content")
          /// Label
          internal static let label = L10n.tr("Localizable", "Scene.Profile.Fields.Placeholder.Label")
        }
      }
      internal enum RelationshipActionAlert {
        internal enum ConfirmUnblockUsre {
          /// Confirm to unblock %@
          internal static func message(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Profile.RelationshipActionAlert.ConfirmUnblockUsre.Message", String(describing: p1))
          }
          /// Unblock Account
          internal static let title = L10n.tr("Localizable", "Scene.Profile.RelationshipActionAlert.ConfirmUnblockUsre.Title")
        }
        internal enum ConfirmUnmuteUser {
          /// Confirm to unmute %@
          internal static func message(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Profile.RelationshipActionAlert.ConfirmUnmuteUser.Message", String(describing: p1))
          }
          /// Unmute Account
          internal static let title = L10n.tr("Localizable", "Scene.Profile.RelationshipActionAlert.ConfirmUnmuteUser.Title")
        }
      }
      internal enum SegmentedControl {
        /// Media
        internal static let media = L10n.tr("Localizable", "Scene.Profile.SegmentedControl.Media")
        /// Posts
        internal static let posts = L10n.tr("Localizable", "Scene.Profile.SegmentedControl.Posts")
        /// Replies
        internal static let replies = L10n.tr("Localizable", "Scene.Profile.SegmentedControl.Replies")
      }
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
          /// %@ contains a disallowed email provider
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
          /// This is not a valid email address
          internal static let emailInvalid = L10n.tr("Localizable", "Scene.Register.Error.Special.EmailInvalid")
          /// Password is too short (must be at least 8 characters)
          internal static let passwordTooShort = L10n.tr("Localizable", "Scene.Register.Error.Special.PasswordTooShort")
          /// Username must only contain alphanumeric characters and underscores
          internal static let usernameInvalid = L10n.tr("Localizable", "Scene.Register.Error.Special.UsernameInvalid")
          /// Username is too long (can’t be longer than 30 characters)
          internal static let usernameTooLong = L10n.tr("Localizable", "Scene.Register.Error.Special.UsernameTooLong")
        }
      }
      internal enum Input {
        internal enum Avatar {
          /// Delete
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
    internal enum Report {
      /// Are there any other posts you’d like to add to the report?
      internal static let content1 = L10n.tr("Localizable", "Scene.Report.Content1")
      /// Is there anything the moderators should know about this report?
      internal static let content2 = L10n.tr("Localizable", "Scene.Report.Content2")
      /// Send Report
      internal static let send = L10n.tr("Localizable", "Scene.Report.Send")
      /// Send without comment
      internal static let skipToSend = L10n.tr("Localizable", "Scene.Report.SkipToSend")
      /// Step 1 of 2
      internal static let step1 = L10n.tr("Localizable", "Scene.Report.Step1")
      /// Step 2 of 2
      internal static let step2 = L10n.tr("Localizable", "Scene.Report.Step2")
      /// Type or paste additional comments
      internal static let textPlaceholder = L10n.tr("Localizable", "Scene.Report.TextPlaceholder")
      /// Report %@
      internal static func title(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.Report.Title", String(describing: p1))
      }
    }
    internal enum Search {
      /// Search
      internal static let title = L10n.tr("Localizable", "Scene.Search.Title")
      internal enum Recommend {
        /// See All
        internal static let buttonText = L10n.tr("Localizable", "Scene.Search.Recommend.ButtonText")
        internal enum Accounts {
          /// You may like to follow these accounts
          internal static let description = L10n.tr("Localizable", "Scene.Search.Recommend.Accounts.Description")
          /// Follow
          internal static let follow = L10n.tr("Localizable", "Scene.Search.Recommend.Accounts.Follow")
          /// Accounts you might like
          internal static let title = L10n.tr("Localizable", "Scene.Search.Recommend.Accounts.Title")
        }
        internal enum HashTag {
          /// Hashtags that are getting quite a bit of attention
          internal static let description = L10n.tr("Localizable", "Scene.Search.Recommend.HashTag.Description")
          /// %@ people are talking
          internal static func peopleTalking(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Search.Recommend.HashTag.PeopleTalking", String(describing: p1))
          }
          /// Trending on Mastodon
          internal static let title = L10n.tr("Localizable", "Scene.Search.Recommend.HashTag.Title")
        }
      }
      internal enum SearchBar {
        /// Cancel
        internal static let cancel = L10n.tr("Localizable", "Scene.Search.SearchBar.Cancel")
        /// Search hashtags and users
        internal static let placeholder = L10n.tr("Localizable", "Scene.Search.SearchBar.Placeholder")
      }
      internal enum Searching {
        /// Clear
        internal static let clear = L10n.tr("Localizable", "Scene.Search.Searching.Clear")
        /// Recent searches
        internal static let recentSearch = L10n.tr("Localizable", "Scene.Search.Searching.RecentSearch")
        internal enum EmptyState {
          /// No results
          internal static let noResults = L10n.tr("Localizable", "Scene.Search.Searching.EmptyState.NoResults")
        }
        internal enum Segment {
          /// All
          internal static let all = L10n.tr("Localizable", "Scene.Search.Searching.Segment.All")
          /// Hashtags
          internal static let hashtags = L10n.tr("Localizable", "Scene.Search.Searching.Segment.Hashtags")
          /// People
          internal static let people = L10n.tr("Localizable", "Scene.Search.Searching.Segment.People")
          /// Posts
          internal static let posts = L10n.tr("Localizable", "Scene.Search.Searching.Segment.Posts")
        }
      }
    }
    internal enum ServerPicker {
      /// Pick a server,\nany server.
      internal static let title = L10n.tr("Localizable", "Scene.ServerPicker.Title")
      internal enum Button {
        /// See Less
        internal static let seeLess = L10n.tr("Localizable", "Scene.ServerPicker.Button.SeeLess")
        /// See More
        internal static let seeMore = L10n.tr("Localizable", "Scene.ServerPicker.Button.SeeMore")
        internal enum Category {
          /// academia
          internal static let academia = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.Academia")
          /// activism
          internal static let activism = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.Activism")
          /// All
          internal static let all = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.All")
          /// Category: All
          internal static let allAccessiblityDescription = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.AllAccessiblityDescription")
          /// art
          internal static let art = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.Art")
          /// food
          internal static let food = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.Food")
          /// furry
          internal static let furry = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.Furry")
          /// games
          internal static let games = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.Games")
          /// general
          internal static let general = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.General")
          /// journalism
          internal static let journalism = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.Journalism")
          /// lgbt
          internal static let lgbt = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.Lgbt")
          /// music
          internal static let music = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.Music")
          /// regional
          internal static let regional = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.Regional")
          /// tech
          internal static let tech = L10n.tr("Localizable", "Scene.ServerPicker.Button.Category.Tech")
        }
      }
      internal enum EmptyState {
        /// Something went wrong while loading the data. Check your internet connection.
        internal static let badNetwork = L10n.tr("Localizable", "Scene.ServerPicker.EmptyState.BadNetwork")
        /// Finding available servers...
        internal static let findingServers = L10n.tr("Localizable", "Scene.ServerPicker.EmptyState.FindingServers")
        /// No results
        internal static let noResults = L10n.tr("Localizable", "Scene.ServerPicker.EmptyState.NoResults")
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
      /// privacy policy
      internal static let privacyPolicy = L10n.tr("Localizable", "Scene.ServerRules.PrivacyPolicy")
      /// By continuing, you’re subject to the terms of service and privacy policy for %@.
      internal static func prompt(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.ServerRules.Prompt", String(describing: p1))
      }
      /// These rules are set by the admins of %@.
      internal static func subtitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.ServerRules.Subtitle", String(describing: p1))
      }
      /// terms of service
      internal static let termsOfService = L10n.tr("Localizable", "Scene.ServerRules.TermsOfService")
      /// Some ground rules.
      internal static let title = L10n.tr("Localizable", "Scene.ServerRules.Title")
      internal enum Button {
        /// I Agree
        internal static let confirm = L10n.tr("Localizable", "Scene.ServerRules.Button.Confirm")
      }
    }
    internal enum Settings {
      /// Settings
      internal static let title = L10n.tr("Localizable", "Scene.Settings.Title")
      internal enum Footer {
        /// Mastodon is open source software. You can report issues on GitHub at %@ (%@)
        internal static func mastodonDescription(_ p1: Any, _ p2: Any) -> String {
          return L10n.tr("Localizable", "Scene.Settings.Footer.MastodonDescription", String(describing: p1), String(describing: p2))
        }
      }
      internal enum Keyboard {
        /// Close Settings Window
        internal static let closeSettingsWindow = L10n.tr("Localizable", "Scene.Settings.Keyboard.CloseSettingsWindow")
      }
      internal enum Section {
        internal enum Appearance {
          /// Automatic
          internal static let automatic = L10n.tr("Localizable", "Scene.Settings.Section.Appearance.Automatic")
          /// Always Dark
          internal static let dark = L10n.tr("Localizable", "Scene.Settings.Section.Appearance.Dark")
          /// Always Light
          internal static let light = L10n.tr("Localizable", "Scene.Settings.Section.Appearance.Light")
          /// Appearance
          internal static let title = L10n.tr("Localizable", "Scene.Settings.Section.Appearance.Title")
        }
        internal enum BoringZone {
          /// Account Settings
          internal static let accountSettings = L10n.tr("Localizable", "Scene.Settings.Section.BoringZone.AccountSettings")
          /// Privacy Policy
          internal static let privacy = L10n.tr("Localizable", "Scene.Settings.Section.BoringZone.Privacy")
          /// Terms of Service
          internal static let terms = L10n.tr("Localizable", "Scene.Settings.Section.BoringZone.Terms")
          /// The Boring Zone
          internal static let title = L10n.tr("Localizable", "Scene.Settings.Section.BoringZone.Title")
        }
        internal enum Notifications {
          /// Reblogs my post
          internal static let boosts = L10n.tr("Localizable", "Scene.Settings.Section.Notifications.Boosts")
          /// Favorites my post
          internal static let favorites = L10n.tr("Localizable", "Scene.Settings.Section.Notifications.Favorites")
          /// Follows me
          internal static let follows = L10n.tr("Localizable", "Scene.Settings.Section.Notifications.Follows")
          /// Mentions me
          internal static let mentions = L10n.tr("Localizable", "Scene.Settings.Section.Notifications.Mentions")
          /// Notifications
          internal static let title = L10n.tr("Localizable", "Scene.Settings.Section.Notifications.Title")
          internal enum Trigger {
            /// anyone
            internal static let anyone = L10n.tr("Localizable", "Scene.Settings.Section.Notifications.Trigger.Anyone")
            /// anyone I follow
            internal static let follow = L10n.tr("Localizable", "Scene.Settings.Section.Notifications.Trigger.Follow")
            /// a follower
            internal static let follower = L10n.tr("Localizable", "Scene.Settings.Section.Notifications.Trigger.Follower")
            /// no one
            internal static let noone = L10n.tr("Localizable", "Scene.Settings.Section.Notifications.Trigger.Noone")
            /// Notify me when
            internal static let title = L10n.tr("Localizable", "Scene.Settings.Section.Notifications.Trigger.Title")
          }
        }
        internal enum Preference {
          /// Disable animated avatars
          internal static let disableAvatarAnimation = L10n.tr("Localizable", "Scene.Settings.Section.Preference.DisableAvatarAnimation")
          /// Disable animated emojis
          internal static let disableEmojiAnimation = L10n.tr("Localizable", "Scene.Settings.Section.Preference.DisableEmojiAnimation")
          /// Preferences
          internal static let title = L10n.tr("Localizable", "Scene.Settings.Section.Preference.Title")
          /// True black dark mode
          internal static let trueBlackDarkMode = L10n.tr("Localizable", "Scene.Settings.Section.Preference.TrueBlackDarkMode")
          /// Use default browser to open links
          internal static let usingDefaultBrowser = L10n.tr("Localizable", "Scene.Settings.Section.Preference.UsingDefaultBrowser")
        }
        internal enum SpicyZone {
          /// Clear Media Cache
          internal static let clear = L10n.tr("Localizable", "Scene.Settings.Section.SpicyZone.Clear")
          /// Sign Out
          internal static let signout = L10n.tr("Localizable", "Scene.Settings.Section.SpicyZone.Signout")
          /// The Spicy Zone
          internal static let title = L10n.tr("Localizable", "Scene.Settings.Section.SpicyZone.Title")
        }
      }
    }
    internal enum SuggestionAccount {
      /// When you follow someone, you’ll see their posts in your home feed.
      internal static let followExplain = L10n.tr("Localizable", "Scene.SuggestionAccount.FollowExplain")
      /// Find People to Follow
      internal static let title = L10n.tr("Localizable", "Scene.SuggestionAccount.Title")
    }
    internal enum Thread {
      /// Post
      internal static let backTitle = L10n.tr("Localizable", "Scene.Thread.BackTitle")
      /// Post from %@
      internal static func title(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.Thread.Title", String(describing: p1))
      }
    }
    internal enum Welcome {
      /// Social networking\nback in your hands.
      internal static let slogan = L10n.tr("Localizable", "Scene.Welcome.Slogan")
    }
    internal enum Wizard {
      /// Double tap to dismiss this wizard
      internal static let accessibilityHint = L10n.tr("Localizable", "Scene.Wizard.AccessibilityHint")
      /// Switch between multiple accounts by holding the profile button.
      internal static let multipleAccountSwitchIntroDescription = L10n.tr("Localizable", "Scene.Wizard.MultipleAccountSwitchIntroDescription")
      /// New in Mastodon
      internal static let newInMastodon = L10n.tr("Localizable", "Scene.Wizard.NewInMastodon")
    }
  }

  internal enum A11y {
    internal enum Plural {
      internal enum Count {
        /// Plural format key: "Input limit exceeds %#@character_count@"
        internal static func inputLimitExceeds(_ p1: Int) -> String {
          return L10n.tr("Localizable", "a11y.plural.count.input_limit_exceeds", p1)
        }
        /// Plural format key: "Input limit remains %#@character_count@"
        internal static func inputLimitRemains(_ p1: Int) -> String {
          return L10n.tr("Localizable", "a11y.plural.count.input_limit_remains", p1)
        }
        internal enum Unread {
          /// Plural format key: "%#@notification_count_unread_notification@"
          internal static func notification(_ p1: Int) -> String {
            return L10n.tr("Localizable", "a11y.plural.count.unread.notification", p1)
          }
        }
      }
    }
  }

  internal enum Date {
    internal enum Day {
      /// Plural format key: "%#@count_day_left@"
      internal static func `left`(_ p1: Int) -> String {
        return L10n.tr("Localizable", "date.day.left", p1)
      }
      internal enum Ago {
        /// Plural format key: "%#@count_day_ago_abbr@"
        internal static func abbr(_ p1: Int) -> String {
          return L10n.tr("Localizable", "date.day.ago.abbr", p1)
        }
      }
    }
    internal enum Hour {
      /// Plural format key: "%#@count_hour_left@"
      internal static func `left`(_ p1: Int) -> String {
        return L10n.tr("Localizable", "date.hour.left", p1)
      }
      internal enum Ago {
        /// Plural format key: "%#@count_hour_ago_abbr@"
        internal static func abbr(_ p1: Int) -> String {
          return L10n.tr("Localizable", "date.hour.ago.abbr", p1)
        }
      }
    }
    internal enum Minute {
      /// Plural format key: "%#@count_minute_left@"
      internal static func `left`(_ p1: Int) -> String {
        return L10n.tr("Localizable", "date.minute.left", p1)
      }
      internal enum Ago {
        /// Plural format key: "%#@count_minute_ago_abbr@"
        internal static func abbr(_ p1: Int) -> String {
          return L10n.tr("Localizable", "date.minute.ago.abbr", p1)
        }
      }
    }
    internal enum Month {
      /// Plural format key: "%#@count_month_left@"
      internal static func `left`(_ p1: Int) -> String {
        return L10n.tr("Localizable", "date.month.left", p1)
      }
      internal enum Ago {
        /// Plural format key: "%#@count_month_ago_abbr@"
        internal static func abbr(_ p1: Int) -> String {
          return L10n.tr("Localizable", "date.month.ago.abbr", p1)
        }
      }
    }
    internal enum Second {
      /// Plural format key: "%#@count_second_left@"
      internal static func `left`(_ p1: Int) -> String {
        return L10n.tr("Localizable", "date.second.left", p1)
      }
      internal enum Ago {
        /// Plural format key: "%#@count_second_ago_abbr@"
        internal static func abbr(_ p1: Int) -> String {
          return L10n.tr("Localizable", "date.second.ago.abbr", p1)
        }
      }
    }
    internal enum Year {
      /// Plural format key: "%#@count_year_left@"
      internal static func `left`(_ p1: Int) -> String {
        return L10n.tr("Localizable", "date.year.left", p1)
      }
      internal enum Ago {
        /// Plural format key: "%#@count_year_ago_abbr@"
        internal static func abbr(_ p1: Int) -> String {
          return L10n.tr("Localizable", "date.year.ago.abbr", p1)
        }
      }
    }
  }

  internal enum Plural {
    /// Plural format key: "%#@count_people_talking@"
    internal static func peopleTalking(_ p1: Int) -> String {
      return L10n.tr("Localizable", "plural.people_talking", p1)
    }
    internal enum Count {
      /// Plural format key: "%#@favorite_count@"
      internal static func favorite(_ p1: Int) -> String {
        return L10n.tr("Localizable", "plural.count.favorite", p1)
      }
      /// Plural format key: "%#@count_follower@"
      internal static func follower(_ p1: Int) -> String {
        return L10n.tr("Localizable", "plural.count.follower", p1)
      }
      /// Plural format key: "%#@count_following@"
      internal static func following(_ p1: Int) -> String {
        return L10n.tr("Localizable", "plural.count.following", p1)
      }
      /// Plural format key: "%#@post_count@"
      internal static func post(_ p1: Int) -> String {
        return L10n.tr("Localizable", "plural.count.post", p1)
      }
      /// Plural format key: "%#@reblog_count@"
      internal static func reblog(_ p1: Int) -> String {
        return L10n.tr("Localizable", "plural.count.reblog", p1)
      }
      /// Plural format key: "%#@vote_count@"
      internal static func vote(_ p1: Int) -> String {
        return L10n.tr("Localizable", "plural.count.vote", p1)
      }
      /// Plural format key: "%#@voter_count@"
      internal static func voter(_ p1: Int) -> String {
        return L10n.tr("Localizable", "plural.count.voter", p1)
      }
      internal enum MetricFormatted {
        /// Plural format key: "%@ %#@post_count@"
        internal static func post(_ p1: Any, _ p2: Int) -> String {
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
