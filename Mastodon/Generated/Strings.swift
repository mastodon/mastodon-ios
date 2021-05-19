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
        /// Block entire domain
        internal static let blockEntireDomain = L10n.tr("Localizable", "Common.Alerts.BlockDomain.BlockEntireDomain")
        /// Are you really, really sure you want to block the entire %@? In most cases a few targeted blocks or mutes are sufficient and preferable. You will not see content from that domain in any public timelines or your notifications. Your followers from that domain will be removed.
        internal static func title(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Alerts.BlockDomain.Title", String(describing: p1))
        }
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
      internal enum SavePhotoFailure {
        /// Please enable photo libaray access permission to save photo.
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
        /// Sign out
        internal static let title = L10n.tr("Localizable", "Common.Alerts.SignOut.Title")
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
        /// OK
        internal static let ok = L10n.tr("Localizable", "Common.Controls.Actions.Ok")
        /// Open in Safari
        internal static let openInSafari = L10n.tr("Localizable", "Common.Controls.Actions.OpenInSafari")
        /// Preview
        internal static let preview = L10n.tr("Localizable", "Common.Controls.Actions.Preview")
        /// Remove
        internal static let remove = L10n.tr("Localizable", "Common.Controls.Actions.Remove")
        /// Report %@
        internal static func reportUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Actions.ReportUser", String(describing: p1))
        }
        /// Save
        internal static let save = L10n.tr("Localizable", "Common.Controls.Actions.Save")
        /// Save photo
        internal static let savePhoto = L10n.tr("Localizable", "Common.Controls.Actions.SavePhoto")
        /// See More
        internal static let seeMore = L10n.tr("Localizable", "Common.Controls.Actions.SeeMore")
        /// Settings
        internal static let settings = L10n.tr("Localizable", "Common.Controls.Actions.Settings")
        /// Share
        internal static let share = L10n.tr("Localizable", "Common.Controls.Actions.Share")
        /// Share post
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
        /// Take photo
        internal static let takePhoto = L10n.tr("Localizable", "Common.Controls.Actions.TakePhoto")
        /// Try Again
        internal static let tryAgain = L10n.tr("Localizable", "Common.Controls.Actions.TryAgain")
        /// Unblock %@
        internal static func unblockDomain(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Actions.UnblockDomain", String(describing: p1))
        }
      }
      internal enum Firendship {
        /// Block
        internal static let block = L10n.tr("Localizable", "Common.Controls.Firendship.Block")
        /// Block %@
        internal static func blockDomain(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Firendship.BlockDomain", String(describing: p1))
        }
        /// Blocked
        internal static let blocked = L10n.tr("Localizable", "Common.Controls.Firendship.Blocked")
        /// Block %@
        internal static func blockUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Firendship.BlockUser", String(describing: p1))
        }
        /// Edit info
        internal static let editInfo = L10n.tr("Localizable", "Common.Controls.Firendship.EditInfo")
        /// Follow
        internal static let follow = L10n.tr("Localizable", "Common.Controls.Firendship.Follow")
        /// Following
        internal static let following = L10n.tr("Localizable", "Common.Controls.Firendship.Following")
        /// Mute
        internal static let mute = L10n.tr("Localizable", "Common.Controls.Firendship.Mute")
        /// Muted
        internal static let muted = L10n.tr("Localizable", "Common.Controls.Firendship.Muted")
        /// Mute %@
        internal static func muteUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Firendship.MuteUser", String(describing: p1))
        }
        /// Pending
        internal static let pending = L10n.tr("Localizable", "Common.Controls.Firendship.Pending")
        /// Request
        internal static let request = L10n.tr("Localizable", "Common.Controls.Firendship.Request")
        /// Unblock
        internal static let unblock = L10n.tr("Localizable", "Common.Controls.Firendship.Unblock")
        /// Unblock %@
        internal static func unblockUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Firendship.UnblockUser", String(describing: p1))
        }
        /// Unmute
        internal static let unmute = L10n.tr("Localizable", "Common.Controls.Firendship.Unmute")
        /// Unmute %@
        internal static func unmuteUser(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Firendship.UnmuteUser", String(describing: p1))
        }
      }
      internal enum Status {
        /// content warning
        internal static let contentWarning = L10n.tr("Localizable", "Common.Controls.Status.ContentWarning")
        /// cw: %@
        internal static func contentWarningText(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Common.Controls.Status.ContentWarningText", String(describing: p1))
        }
        /// Tap to reveal that may be sensitive
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
          /// Unreblog
          internal static let unreblog = L10n.tr("Localizable", "Common.Controls.Status.Actions.Unreblog")
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
        internal enum Keyboard {
          /// Switch to %@
          internal static func switchToTab(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Tabs.Keyboard.SwitchToTab", String(describing: p1))
          }
        }
      }
      internal enum Timeline {
        internal enum Accessibility {
          /// %@ favorites
          internal static func countFavorites(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Timeline.Accessibility.CountFavorites", String(describing: p1))
          }
          /// %@ reblogs
          internal static func countReblogs(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Timeline.Accessibility.CountReblogs", String(describing: p1))
          }
          /// %@ replies
          internal static func countReplies(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Common.Controls.Timeline.Accessibility.CountReplies", String(describing: p1))
          }
        }
        internal enum Header {
          /// You can’t view Artbot’s profile\n until they unblock you.
          internal static let blockedWarning = L10n.tr("Localizable", "Common.Controls.Timeline.Header.BlockedWarning")
          /// You can’t view Artbot’s profile\n until you unblock them.\nYour account looks like this to them.
          internal static let blockingWarning = L10n.tr("Localizable", "Common.Controls.Timeline.Header.BlockingWarning")
          /// No Status Found
          internal static let noStatusFound = L10n.tr("Localizable", "Common.Controls.Timeline.Header.NoStatusFound")
          /// This account has been suspended.
          internal static let suspendedWarning = L10n.tr("Localizable", "Common.Controls.Timeline.Header.SuspendedWarning")
          /// %@'s account has been suspended.
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
      /// replying to %@
      internal static func replyingToUser(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.Compose.ReplyingToUser", String(describing: p1))
      }
      internal enum Accessibility {
        /// Append attachment
        internal static let appendAttachment = L10n.tr("Localizable", "Scene.Compose.Accessibility.AppendAttachment")
        /// Append poll
        internal static let appendPoll = L10n.tr("Localizable", "Scene.Compose.Accessibility.AppendPoll")
        /// Custom emoji picker
        internal static let customEmojiPicker = L10n.tr("Localizable", "Scene.Compose.Accessibility.CustomEmojiPicker")
        /// Disable content warning
        internal static let disableContentWarning = L10n.tr("Localizable", "Scene.Compose.Accessibility.DisableContentWarning")
        /// Enable content warning
        internal static let enableContentWarning = L10n.tr("Localizable", "Scene.Compose.Accessibility.EnableContentWarning")
        /// Input limit exceeds %ld
        internal static func inputLimitExceedsCount(_ p1: Int) -> String {
          return L10n.tr("Localizable", "Scene.Compose.Accessibility.InputLimitExceedsCount", p1)
        }
        /// Input limit remains %ld
        internal static func inputLimitRemainsCount(_ p1: Int) -> String {
          return L10n.tr("Localizable", "Scene.Compose.Accessibility.InputLimitRemainsCount", p1)
        }
        /// Post visibility menu
        internal static let postVisibilityMenu = L10n.tr("Localizable", "Scene.Compose.Accessibility.PostVisibilityMenu")
        /// Remove poll
        internal static let removePoll = L10n.tr("Localizable", "Scene.Compose.Accessibility.RemovePoll")
      }
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
      internal enum AutoComplete {
        /// %ld people talking
        internal static func multiplePeopleTalking(_ p1: Int) -> String {
          return L10n.tr("Localizable", "Scene.Compose.AutoComplete.MultiplePeopleTalking", p1)
        }
        /// %ld people talking
        internal static func singlePeopleTalking(_ p1: Int) -> String {
          return L10n.tr("Localizable", "Scene.Compose.AutoComplete.SinglePeopleTalking", p1)
        }
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
    internal enum Hashtag {
      /// %@ people talking
      internal static func prompt(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.Hashtag.Prompt", String(describing: p1))
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
    internal enum Notification {
      internal enum Action {
        /// favorited your post
        internal static let favourite = L10n.tr("Localizable", "Scene.Notification.Action.Favourite")
        /// followed you
        internal static let follow = L10n.tr("Localizable", "Scene.Notification.Action.Follow")
        /// request to follow you
        internal static let followRequest = L10n.tr("Localizable", "Scene.Notification.Action.FollowRequest")
        /// mentioned you
        internal static let mention = L10n.tr("Localizable", "Scene.Notification.Action.Mention")
        /// Your poll has ended
        internal static let poll = L10n.tr("Localizable", "Scene.Notification.Action.Poll")
        /// rebloged your post
        internal static let reblog = L10n.tr("Localizable", "Scene.Notification.Action.Reblog")
      }
      internal enum Title {
        /// Everything
        internal static let everything = L10n.tr("Localizable", "Scene.Notification.Title.Everything")
        /// Mentions
        internal static let mentions = L10n.tr("Localizable", "Scene.Notification.Title.Mentions")
      }
    }
    internal enum Profile {
      /// %@ posts
      internal static func subtitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "Scene.Profile.Subtitle", String(describing: p1))
      }
      internal enum Dashboard {
        /// followers
        internal static let followers = L10n.tr("Localizable", "Scene.Profile.Dashboard.Followers")
        /// following
        internal static let following = L10n.tr("Localizable", "Scene.Profile.Dashboard.Following")
        /// posts
        internal static let posts = L10n.tr("Localizable", "Scene.Profile.Dashboard.Posts")
        internal enum Accessibility {
          /// %ld followers
          internal static func countFollowers(_ p1: Int) -> String {
            return L10n.tr("Localizable", "Scene.Profile.Dashboard.Accessibility.CountFollowers", p1)
          }
          /// %ld following
          internal static func countFollowing(_ p1: Int) -> String {
            return L10n.tr("Localizable", "Scene.Profile.Dashboard.Accessibility.CountFollowing", p1)
          }
          /// %ld posts
          internal static func countPosts(_ p1: Int) -> String {
            return L10n.tr("Localizable", "Scene.Profile.Dashboard.Accessibility.CountPosts", p1)
          }
        }
      }
      internal enum RelationshipActionAlert {
        internal enum ConfirmUnblockUsre {
          /// Confirm unblock %@
          internal static func message(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Profile.RelationshipActionAlert.ConfirmUnblockUsre.Message", String(describing: p1))
          }
          /// Unblock Account
          internal static let title = L10n.tr("Localizable", "Scene.Profile.RelationshipActionAlert.ConfirmUnblockUsre.Title")
        }
        internal enum ConfirmUnmuteUser {
          /// Confirm unmute %@
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
          /// Hashtags that are getting quite a bit of attention among people you follow
          internal static let description = L10n.tr("Localizable", "Scene.Search.Recommend.HashTag.Description")
          /// %@ people are talking
          internal static func peopleTalking(_ p1: Any) -> String {
            return L10n.tr("Localizable", "Scene.Search.Recommend.HashTag.PeopleTalking", String(describing: p1))
          }
          /// Trending in your timeline
          internal static let title = L10n.tr("Localizable", "Scene.Search.Recommend.HashTag.Title")
        }
      }
      internal enum Searchbar {
        /// Cancel
        internal static let cancel = L10n.tr("Localizable", "Scene.Search.Searchbar.Cancel")
        /// Search hashtags and users
        internal static let placeholder = L10n.tr("Localizable", "Scene.Search.Searchbar.Placeholder")
      }
      internal enum Searching {
        /// clear
        internal static let clear = L10n.tr("Localizable", "Scene.Search.Searching.Clear")
        /// Recent searches
        internal static let recentSearch = L10n.tr("Localizable", "Scene.Search.Searching.RecentSearch")
        internal enum Segment {
          /// All
          internal static let all = L10n.tr("Localizable", "Scene.Search.Searching.Segment.All")
          /// Hashtags
          internal static let hashtags = L10n.tr("Localizable", "Scene.Search.Searching.Segment.Hashtags")
          /// People
          internal static let people = L10n.tr("Localizable", "Scene.Search.Searching.Segment.People")
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
        /// Something went wrong while loading data. Check your internet connection.
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
      /// By continuing, you're subject to the terms of service and privacy policy for %@.
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
        internal enum Boringzone {
          /// Privacy Policy
          internal static let privacy = L10n.tr("Localizable", "Scene.Settings.Section.Boringzone.Privacy")
          /// Terms of Service
          internal static let terms = L10n.tr("Localizable", "Scene.Settings.Section.Boringzone.Terms")
          /// The Boring zone
          internal static let title = L10n.tr("Localizable", "Scene.Settings.Section.Boringzone.Title")
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
        internal enum Spicyzone {
          /// Clear Media Cache
          internal static let clear = L10n.tr("Localizable", "Scene.Settings.Section.Spicyzone.Clear")
          /// Sign Out
          internal static let signout = L10n.tr("Localizable", "Scene.Settings.Section.Spicyzone.Signout")
          /// The spicy zone
          internal static let title = L10n.tr("Localizable", "Scene.Settings.Section.Spicyzone.Title")
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
      internal enum Favorite {
        /// %@ favorites
        internal static func multiple(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Scene.Thread.Favorite.Multiple", String(describing: p1))
        }
        /// %@ favorite
        internal static func single(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Scene.Thread.Favorite.Single", String(describing: p1))
        }
      }
      internal enum Reblog {
        /// %@ reblogs
        internal static func multiple(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Scene.Thread.Reblog.Multiple", String(describing: p1))
        }
        /// %@ reblog
        internal static func single(_ p1: Any) -> String {
          return L10n.tr("Localizable", "Scene.Thread.Reblog.Single", String(describing: p1))
        }
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
