//
//  L10nLookup.swift
//  MastodonSDK
//
//  Created by Shannon Hughes on 11/19/25.
//

import Foundation

/// This bridge seems to be necessary for now because our localizations are contained within a Swift package. Also, nesting inside meaningful structs is helpful for organization and the automatic symbol generation is limited in that regard.
///
/// To add new strings:
///  1. Add the entry in .xcstrings with the English string and any pluralization variants
///  2. Use the "Convert Strings to Symbols" option in .xcstrings to create the function name and set the argument labels
///  3. Add a function here (in the expected nested struct) that matches the new function signature and looks up the new key.
///
/// NOTE: Take care not to modify existing keys without checking to maintain agreement here and on CrowdIn.

public struct L10nLookup {
    
    public struct Scene {
        public struct Notification {
            public struct GroupedNotificationDescription {
                public static func youAndOthersFavorited(othersCount: Int) -> String {
                    let result = tr("Localizable", "Scene.Notification.GroupedNotificationDescription.YouAndOthersFavorited", othersCount, fallback: "sceneNotificationGroupedNotificationDescriptionYouAndOthersFavorited")
                    return result
                }
                
                public static func peopleFavourited(favouriteCount: Int) -> String {
                    let result = tr("Localizable", "Scene.Notification.GroupedNotificationDescription.PeopleFavourited", favouriteCount, fallback: "Scene.Notification.GroupedNotificationDescription.PeopleFavourited")
                    return result
                }
                
                public static func youAndOthersBoosted(othersCount: Int) -> String {
                    let result = tr("Localizable", "Scene.Notification.GroupedNotificationDescription.YouAndOthersBoosted", othersCount, fallback: "Scene.Notification.GroupedNotificationDescription.YouAndOthersBoosted")
                    return result
                }
                
                public static func peopleBoosted(boostCount: Int) -> String {
                    let result = tr("Localizable", "Scene.Notification.GroupedNotificationDescription.PeopleBoosted", boostCount, fallback: "Scene.Notification.GroupedNotificationDescription.PeopleBoosted")
                    return result
                }
                
                public static func peopleFollowedYou(newFollowerCount: Int) -> String {
                    let result = tr("Localizable", "Scene.Notification.GroupedNotificationDescription.PeopleFollowedYou", newFollowerCount, fallback: "sceneNotificationGroupedNotificationDescriptionPeopleFollowedYou")
                    return result
                }
                
                public static func pollHasEnded(pollAuthor: String, otherVotersCount: Int) -> String {
                    let result = tr("Localizable", "Scene.Notification.GroupedNotificationDescription.PollHasEnded", pollAuthor, otherVotersCount, fallback: "sceneNotificationGroupedNotificationDescriptionPollHasEnded")
                    return result
                }
                
                public static func someoneReportedPosts(postCount: Int, violatingAccountName: String) -> String {
                    let result = tr("Localizable", "Scene.Notification.GroupedNotificationDescription.SomeonReportedPosts", postCount, violatingAccountName, fallback: "sceneNotificationGroupedNotificationDescriptionSomeoneReportedPosts")
                    return result
                }
                
                public static func someoneReportedPostsForRuleViolation(postCount: Int, violatingAccountName: String) -> String {
                    let result = tr("Localizable", "Scene.Notification.GroupedNotificationDescription.SomeonReportedPostsForRuleViolation", postCount, violatingAccountName, fallback: "sceneNotificationGroupedNotificationDescriptionSomeoneReportedPostsForRuleViolation")
                    return result
                }
                
                public static func someoneReportedPostsForSpam(postCount: Int, violatingAccountName: String) -> String {
                    let result = tr("Localizable", "Scene.Notification.GroupedNotificationDescription.SomeonReportedPostsForSpam", postCount, violatingAccountName, fallback: "sceneNotificationGroupedNotificationDescriptionSomeoneReportedPostsForSpam")
                    return result
                }
            }
        }
    }

    public static func pluralCountPoll(_ count: Int) -> String {
        let result = tr("Localizable", "plural.count.poll", count, fallback: "pluralCountPoll")
        return result
    }
    
    private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
        let missingKey = "_MISSING_"
        let format = {
            let localized = Bundle.module.localizedString(forKey: key, value: missingKey, table: table)
            if localized != missingKey {
                return localized
            } else {
                return englishBundle?.localizedString(forKey: key, value: value, table: table) ?? value
            }
        }()
        return String(format: format, locale: Locale.current, arguments: args)
    }
    
    private static var englishBundle: Bundle? = {
        guard let enBundlePath = Bundle.module.path(forResource: "en", ofType: "lproj") else { return nil }
        return Bundle(path: enBundlePath)
    }()
}
