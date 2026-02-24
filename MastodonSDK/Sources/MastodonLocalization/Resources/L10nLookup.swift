//
//  L10nLookup.swift
//  MastodonSDK
//
//  Created by Shannon Hughes on 11/19/25.
//

import Foundation
import RegexBuilder

/// This bridge seems to be necessary for now because our localizations are contained within a Swift package. Also, nesting inside meaningful structs is helpful for organization and the automatic symbol generation is limited in that regard.
///
/// See Documentation/CONTRIBUTING.md for details on adding new strings and updating translations (and keep that file updated with any changes to the workflow).

public struct L10nLookup {
    
    public struct Common {
        public struct Controls {
            public struct Timeline {
                public struct Loader {
                    public static func unreadItemsButtonTitle(unreadCount: Int) -> String {
                        let result = tr("Localizable", "Common.Controls.Timeline.Loader.UnreadItemsButtonTitle", unreadCount)
                        return result
                    }
                    public static let showMoreReplies: String = {
                        let result = tr("Localizable", "Common.Controls.Timeline.Loader.ShowMoreReplies")
                        return result
                    }()
                }
            }
            
            public struct RelationshipAction {
                public static let follow: String = {
                    let result = tr("Localizable", "Common.Controls.Friendship.Follow")
                    return result
                }()
                public static func requestToFollow(longForm: Bool) -> String {
                    if longForm {
                        let result = tr("Localizable", "Common.Controls.Friendship.RequestToFollow") // needs new
                        return result
                    } else {
                        let result = tr("Localizable", "Common.Controls.Friendship.Request")
                        return result
                    }
                }
                public static func cancelRequestToFollow(longForm: Bool) -> String {
                    if longForm {
                        let result = tr("Localizable", "Common.Controls.Friendship.CancelRequest")
                        return result
                    } else {
                        let result = tr("Localizable", "Common.Controls.Friendship.Cancel")
                        return result
                    }
                }
                public static let unfollow: String = {
                    let result = tr("Localizable", "Common.Controls.Friendship.Unfollow")
                    return result
                }()
                public static let followBack: String = {
                    let result = tr("Localizable", "Common.Controls.Friendship.FollowBack")
                    return result
                }()
                public static let unblock: String = {
                    let result = tr("Localizable", "Common.Controls.Friendship.Unblock")
                    return result
                }()
                public static let unmute: String = {
                    let result = tr("Localizable", "Common.Controls.Friendship.Unmute")
                    return result
                }()
            }
            
            public static let editProfileButton: String = {
                let result = tr("Localizable", "Common.Controls.EditProfileButton")
                return result
            }()
        }
    }
    
    public struct Scene {
        public struct Settings {
            public struct Overview {
                public static func loggedInAs(_ username: String)-> String {
                    let result = tr("Localizable", "Scene.Settings.Overview.LoggedInAs", username)
                    return result
                }
                
                public static var accountSwitcherTip: String {
                    let result = tr("Localizable", "L10nLookup.Scene.Settings.Overview.AccountSwitcherTip")
                    return result
                }
            }
        }
        
        public struct Notification {
            public struct GroupedNotificationDescription {
                public static func youAndOthersFavorited(othersCount: Int) -> String {
                    let result = tr("Localizable", "Scene.Notification.GroupedNotificationDescription.YouAndOthersFavorited", othersCount)
                    return result
                }
                
                public static func peopleFavourited(favouriteCount: Int) -> String {
                    let result = tr("Localizable", "Scene.Notification.GroupedNotificationDescription.PeopleFavourited", favouriteCount)
                    return result
                }
                
                public static func youAndOthersBoosted(othersCount: Int) -> String {
                    let result = tr("Localizable", "Scene.Notification.GroupedNotificationDescription.YouAndOthersBoosted", othersCount)
                    return result
                }
                
                public static func peopleBoosted(boostCount: Int) -> String {
                    let result = tr("Localizable", "Scene.Notification.GroupedNotificationDescription.PeopleBoosted", boostCount)
                    return result
                }
                
                public static func peopleFollowedYou(newFollowerCount: Int) -> String {
                    let result = tr("Localizable", "Scene.Notification.GroupedNotificationDescription.PeopleFollowedYou", newFollowerCount)
                    return result
                }
                
                public static func pollHasEnded(pollAuthor: String, otherVotersCount: Int) -> String {
                    let result = tr("Localizable", "Scene.Notification.GroupedNotificationDescription.PollHasEnded", pollAuthor, otherVotersCount)
                    return result
                }
                
                public static func someoneReportedPosts(postCount: Int, violatingAccountName: String) -> String {
                    let result = tr("Localizable", "Scene.Notification.GroupedNotificationDescription.SomeoneReportedPosts", postCount, violatingAccountName)
                    return result
                }
                
                public static func someoneReportedPostsForRuleViolation(postCount: Int, violatingAccountName: String) -> String {
                    let result = tr("Localizable", "Scene.Notification.GroupedNotificationDescription.SomeoneReportedPostsForRuleViolation", postCount, violatingAccountName)
                    return result
                }
                
                public static func someoneReportedPostsForSpam(postCount: Int, violatingAccountName: String) -> String {
                    let result = tr("Localizable", "Scene.Notification.GroupedNotificationDescription.SomeoneReportedPostsForSpam", postCount, violatingAccountName)
                    return result
                }
            }
        }
        
        public struct FamiliarFollowers {
            
            public static func followedByOneName(_ account: String) -> String {
                let result = tr("Localizable", "Scene.FamiliarFollowers.FollowedByNames", account)
                return result
            }
            
            public static func followedByTwoNames(firstAccount: String, secondAccount: String) -> String {
                let result = tr("Localizable", "Scene.FamiliarFollowers.FollowedByTwoNames", firstAccount, secondAccount)
                return result
            }
            
            public static func followedByTwoNamesAndOthers(firstAccount: String, secondAccount: String, otherCount: Int) -> String {
                let result = tr("Localizable", "Scene.FamiliarFollowers.FollowedByTwoNamesAndOthers", firstAccount, secondAccount, otherCount)
                return result
            }
            
            public static func followersYouKnow(_ count: Int) -> String {
                let result = tr("Localizable", "Scene.FamiliarFollowers.FollowersYouKnow", count)
                return result
            }
        }
        
        public struct Profile {
            public struct SegmentedControl {
                public static let about: String = {
                    let result = tr("Localizable", "Scene.Profile.SegmentedControl.About")
                    return result
                }()
                public static let activity: String = {
                    let result = tr("Localizable", "Scene.Profile.SegmentedControl.Activity")
                    return result
                }()
                public static let media: String = {
                    let result = tr("Localizable", "Scene.Profile.SegmentedControl.Media")
                    return result
                }()
                public static let featured: String = {
                    let result = tr("Localizable", "Scene.Profile.SegmentedControl.Featured")
                    return result
                }()
            }
            
            public struct ActivityFilter {
                public static let directPostsOnly: String = {
                   let result = tr("Localizable", "Scene.Profile.ActivityFilter.directPostsOnly")
                    return result
                }()
                public static let includeBoosts: String = {
                    let result = tr("Localizable", "Scene.Profile.ActivityFilter.includeBoosts")
                    return result
                }()
                public static let includeReplies: String = {
                    let result = tr("Localizable", "Scene.Profile.ActivityFilter.includeReplies")
                    return result
                }()
                public static let includeBoostsAndReplies: String = {
                    let result = tr("Localizable", "Scene.Profile.ActivityFilter.includeBoostsAndReplies")
                    return result
                }()
                public static let showBoostsToggleLabel: String = {
                    let result = tr("Localizable", "Scene.Profile.ActivityFilter.showBoostsToggleLabel")
                    return result
                }()
                public static let showRepliesToggleLabel: String = {
                    let result = tr("Localizable", "Scene.Profile.ActivityFilter.showRepliesToggleLabel")
                    return result
                }()
            }
            
            public struct HandleExplainerView {
                public static let title: String = {
                    let result = tr("Localizable", "Scene.Profile.HandleExplainerView.Title")
                    return result
                }()
                public static let federationExplainerText: AttributedString = {
                    // We have to use an AttributedString and insert the link ourselves because localization, modules, and markdown in SwiftUI do not work together at all
                    var localized = tr("Localizable", "Scene.Profile.HandleExplainerView.FederationExplainerText")
                    let bracketRegex = try! Regex("\\[.*?\\]")
                    if let linkRange = localized.matches(of: bracketRegex).first?.range {
                        let linkTextStripped = localized[linkRange].trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
                        localized.replaceSubrange(linkRange, with: linkTextStripped)
                        var attrString = AttributedString(localized)
                        if let linkRange = attrString.range(of: linkTextStripped) {
                            attrString[linkRange].link = URL(string: "https://docs.joinmastodon.org/#fediverse")
                            return attrString
                        }
                    }
                    return AttributedString(localized)
                }()
                public static func serverDetailWithExample(serverName: String) -> String {
                    let result = tr("Localizable", "Scene.Profile.HandleExplainerView.ServerDetailWithExample", serverName)
                    return result
                }
                public static func usernameDetailWithExample(username: String) -> String {
                    let result = tr("Localizable", "Scene.Profile.HandleExplainerView.UsernameDetailWithExample", username)
                    return result
                }
            }
            
            public static func viewAllPinnedPosts(pinnedPostCount: Int) -> String {
                let result = tr("Localizable", "Scene.Profile.HandleExplainerView.ViewAllPinnedPosts", pinnedPostCount)
                return result
            }
            
            public struct Badge {
                public static let admin: String = {
                    let result = tr("Localizable", "Scene.Profile.Badge.Admin")
                    return result
                }()
                public static let moderator: String = {
                    let result = tr("Localizable", "Scene.Profile.Badge.Moderator")
                    return result
                }()
                public static let pinned: String = {
                    let result = tr("Localizable", "Scene.Profile.Badge.Pinned")
                    return result
                }()
            }
        }
        
        public struct EditProfile {
            public static let title: String = {
                let result = tr("Localizable", "Scene.EditProfile.Title")
                return result
            }()
        }
    }

    public static func pluralCountPoll(_ count: Int) -> String {
        let result = tr("Localizable", "plural.count.poll", count)
        return result
    }
    
    private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
        let missingKey = "_MISSING_"
        let format = {
            let localized = Bundle.module.localizedString(forKey: key, value: missingKey, table: table)
            if localized != missingKey {
                return localized
            } else {
                return englishBundle?.localizedString(forKey: key, value: key, table: table) ?? key
            }
        }()
        return String(format: format, locale: Locale.current, arguments: args)
    }
    
    private static var englishBundle: Bundle? = {
        guard let enBundlePath = Bundle.module.path(forResource: "en", ofType: "lproj") else { return nil }
        return Bundle(path: enBundlePath)
    }()
}
