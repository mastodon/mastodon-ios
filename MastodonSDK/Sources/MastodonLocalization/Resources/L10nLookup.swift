//
//  L10nLookup.swift
//  MastodonSDK
//
//  Created by Shannon Hughes on 11/19/25.
//

import Foundation

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
        }
    }
    
    public struct Scene {
        
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
                    let result = tr("Localizable", "Scene.Notification.GroupedNotificationDescription.SomeonReportedPostsForRuleViolation", postCount, violatingAccountName)
                    return result
                }
                
                public static func someoneReportedPostsForSpam(postCount: Int, violatingAccountName: String) -> String {
                    let result = tr("Localizable", "Scene.Notification.GroupedNotificationDescription.SomeonReportedPostsForSpam", postCount, violatingAccountName)
                    return result
                }
            }
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
