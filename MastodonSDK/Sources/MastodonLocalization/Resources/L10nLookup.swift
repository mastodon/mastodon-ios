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
                    let result = tr("Localizable", "Scene.Settings.Overview.AccountSwitcherTip")
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
                let result = tr("Localizable", "Scene.Profile.ViewAllPinnedPosts", pinnedPostCount)
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
            
            public struct FeaturedTab {
                public static let accountsHeading: String = {
                    let result = tr("Localizable-Profile", "Scene.Profile.FeaturedTab.accountsHeading")
                    return result
                }()
                public static let collectionsHeading: String = {
                    let result = tr("Localizable-Profile", "Scene.Profile.FeaturedTab.collectionsHeading")
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
}

// These translations are in the Localizable-Profile.xcstrings file
public extension L10nLookup.Common.Controls.RelationshipAction {
    static let showAnyway = {
        let result = tr("Localizable-Profile", "Common.Controls.RelationshipAction.showAnyway")
        return result
    }()
    static let acceptFollowRequest = {
        let result = tr("Localizable-Profile", "Common.Controls.RelationshipAction.acceptFollowRequest")
        return result
    }()
    static let rejectFollowRequest = {
        let result = tr("Localizable-Profile", "Common.Controls.RelationshipAction.rejectFollowRequest")
        return result
    }()
}

// These translations are in the Localizable-Profile.xcstrings file
public extension L10nLookup.Scene.Profile {
    struct PersonalNote {
        public static let explainerText: String = {
            let result = tr("Localizable-Profile", "Scene.Profile.PersonalNote.explainerText")
            return result
        }()
        public static let editTitle: String = {
            let result = tr("Localizable-Profile", "Scene.Profile.PersonalNote.editTitle")
            return result
        }()
        public static let addPersonalNote: String = {
            let result = tr("Localizable-Profile", "Scene.Profile.PersonalNote.addPersonalNote")
            return result
        }()
        public static let editPersonalNote: String = {
            let result = tr("Localizable-Profile", "Scene.Profile.PersonalNote.editPersonalNote")
            return result
        }()
        public static let title: String = {
            let result = tr("Localizable-Profile", "Scene.Profile.PersonalNote.title")
            return result
        }()
    }
    
    struct SuspendedAccount {
        public static let title = {
            let result = tr("Localizable-Profile", "Scene.Profile.SuspendedAccount.title")
            return result
        }()
        public static func explanationWithDomain(_ domainName: String) -> String {
            let result = tr("Localizable-Profile", "Scene.Profile.SuspendedAccount.explanationWithDomain", domainName)
            return result
        }
        public static let explanation = {
            let result = tr("Localizable-Profile", "Scene.Profile.SuspendedAccount.explanation")
            return result
        }()
    }
    
    static func requestedToFollowYou(_ username: String) -> String {
        let result = tr("Localizable-Profile", "Scene.Profile.requestedToFollowYou", username)
        return result
    }
    static let copyHandle = {
        let result = tr("Localizable-Profile", "Scene.Profile.copyHandle")
        return result
    }()
    static let followsYou = {
        let result = tr("Localizable-Profile", "Scene.Profile.followsYou")
        return result
    }()
    static let automatedAccount = {
        let result = tr("Localizable-Profile", "Scene.Profile.automatedAccount")
        return result
    }()
}

// These translations are in the Localizable-Profile.xcstrings file
public extension L10nLookup.Scene.EditProfile {
    struct NavigationTitle {
        public static let displayName = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.NavigationTitle.displayName")
            return result
        }()
        public static let addBio = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.NavigationTitle.addBio")
            return result
        }()
        public static let bio = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.NavigationTitle.bio")
            return result
        }()
        public static let customFields = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.NavigationTitle.customFields")
            return result
        }()
        public static let customFieldsSubtitle = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.NavigationTitle.customFieldsSubtitle")
            return result
        }()
        public static let featuredHashtags = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.NavigationTitle.featuredHashtags")
            return result
        }()
        public static let featuredHashtagsSubtitle = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.NavigationTitle.featuredHashtagsStubtitle")
            return result
        }()
        public static let profileTabSettings = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.NavigationTitle.profileTabSettings")
            return result
        }()
    }
    struct SubpageTitle {
        public static let editDisplayName = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.SubpageTitle.editDisplayName")
            return result
        }()
        public static let addBio = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.SubpageTitle.addBio")
            return result
        }()
        public static let editBio = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.SubpageTitle.editBio")
            return result
        }()
        public static let bioPlaceholder = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.SubpageTitle.bioPlaceholder")
            return result
        }()
        public static let customFields = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.SubpageTitle.customFields")
            return result
        }()
        public static let featuredHashtags = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.SubpageTitle.featuredHashtags")
            return result
        }()
        public static let profileTabSettings = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.SubpageTitle.profileTabSettings")
            return result
        }()
        public static let verifiedLinkHelp = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.SubpageTitle.verifiedLinkHelp")
            return result
        }()
        public static let addField = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.SubpageTitle.addField")
            return result
        }()
        public static let editField = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.SubpageTitle.editField")
            return result
        }()
        public static let reorderFields = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.SubpageTitle.reorderFields")
            return result
        }()
        public static let addHashtag = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.SubpageTitle.addHashtag")
            return result
        }()
    }
    
    struct FeaturedHashtags {
        public static let remove = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.FeaturedHashtags.remove")
            return result
        }()
        public static let keep = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.FeaturedHashtags.keep")
            return result
        }()
        public static func removeConfirmation(tagName: String) -> String {
            let result = tr("Localizable-Profile", "Scene.EditProfile.FeaturedHashtags.removeConfirmation", tagName)
            return result
        }
        public static let add = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.FeaturedHashtags.add")
            return result
        }()
        public static func addConfirmedTitle(tagName: String) -> String {
            let result = tr("Localizable-Profile", "Scene.EditProfile.FeaturedHashtags.addConfirmedTitle", tagName)
            return result
        }
        public static let addAnother: String = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.FeaturedHashtags.addAnother")
            return result
        }()
        public static func addConfirmedText(tagName: String) -> String {
            let result = tr("Localizable-Profile", "Scene.EditProfile.FeaturedHashtags.addConfirmedText", tagName)
            return result
        }
        public static func usedInCountPosts(count: Int) -> String {
            let result = tr("Localizable-Profile", "Scene.EditProfile.FeaturedHashtags.usedInCountPosts", count)
            return result
        }
    }
    
    struct CustomFields {
        public static let customFieldPrompt = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.CustomFields.prompt")
            return result
        }()
        public static let addField = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.CustomFields.addField")
            return result
        }()
        public static let deleteField = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.CustomFields.deleteField")
            return result
        }()
        public static let reorderFields = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.CustomFields.reorderFields")
            return result
        }()
        public static let reorderOrDeleteFields = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.CustomFields.reorderOrDeleteFields")
            return result
        }()
        public static let verifiedLinkTip = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.CustomFields.verifiedLinkTip")
            return result
        }()
        public static let label = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.CustomFields.label")
            return result
        }()
        public static let value = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.CustomFields.value")
            return result
        }()
        public static let characterCountTip = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.CustomFields.characterCountTip")
            return result
        }()
        public static let deleteCustomFieldConfirmationAlertTitle: String = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.CustomFields.deleteCustomFieldConfirmationAlertTitle")
            return result
        }()
        public static let deleteCustomFieldConfirmationAlertMessage: String = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.CustomFields.deleteCustomFieldConfirmationAlertMessage")
            return result
        }()
        public static let labelPlaceholder: String = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.CustomFields.labelPlaceholder")
            return result
        }()
        public static let valuePlaceholder: String = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.CustomFields.valuePlaceholder")
            return result
        }()
        public static func reachedMaxFields(max: Int, domain: String) -> String {
            let result = tr("Localizable-Profile", "Scene.EditProfile.CustomFields.reachedMaxFieldsForDomain")
            return result
        }
        public static func reachedMaxFields(max: Int) -> String {
            let result = tr("Localizable-Profile", "Scene.EditProfile.CustomFields.reachedMaxFields")
            return result
        }
    }
    
    struct VerifiedLinksExplainer {
        public static let intro = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.VerifiedLinks.intro")
            return result
        }()
        public static let copyTheCodeBelow = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.VerifiedLinks.copyTheCodeBelow")
            return result
        }()
        public static let copyCode = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.VerifiedLinks.copyCode")
            return result
        }()
        public static let pasteCode = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.VerifiedLinks.pasteCode")
            return result
        }()
        public static let explanation = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.VerifiedLinks.explanation")
            return result
        }()
        public static let addWebsiteAsCustomField = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.VerifiedLinks.addWebsiteAsCustomField")
            return result
        }()
        public static let addWebsiteDetailExplainer = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.VerifiedLinks.addWebsiteDetailExplainer")
            return result
        }()
    }
    
    struct TabSettings {
        public static let mediaTabTitle = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.TabSettings.mediaTabTitle")
            return result
        }()
        public static let mediaTabSubtitle = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.TabSettings.mediaTabSubtitle")
            return result
        }()
        public static let includeReplies = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.TabSettings.includeReplies")
            return result
        }()
        public static let featuredTabTitle = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.TabSettings.featuredTabTitle")
            return result
        }()
        public static let featuredTabSubtitle = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.TabSettings.featuredTabSubtitle")
            return result
        }()
        public static let federationDisclaimer = {
            let result = tr("Localizable-Profile", "Scene.EditProfile.TabSettings.federationDisclaimer")
            return result
        }()
    }
}

// These translations are in the Localizable-MastodonMenuAction.xcstrings file
public extension L10nLookup {
    struct MastodonMenuAction {
        public static func follow(_ username: String) -> String {
            return L10n.Common.Controls.Actions.follow(username)
        }
        public static func unfollow(_ username: String) -> String {
            return L10n.Common.Controls.Actions.unfollow(username)
        }
        public static let featureOnMyProfile: String = {
            let result = tr("Localizable-MastodonMenuAction", "Common.Controls.Actions.featureOnMyProfile")
            return result
        }()
        public static let stopFeaturingOnMyProfile: String = {
            let result = tr("Localizable-MastodonMenuAction", "Common.Controls.Actions.stopFeaturingOnMyProfile")
            return result
        }()
        public static let hideBoosts: String = {
            let result = tr("Localizable-MastodonMenuAction", "Common.Controls.Actions.hideBoosts")
            return result
        }()
        public static var showBoosts: String = {
            let result = tr("Localizable-MastodonMenuAction", "Common.Controls.Actions.showBoosts")
            return result
        }()
        public static func mute(_ username: String) -> String {
            return L10n.Common.Controls.Friendship.muteUser(username)
        }
        public static func unmute(_ username: String) -> String {
            return L10n.Common.Controls.Friendship.unmuteUser(username)
            
        }
        public static let removeFollower: String = {
            let result = tr("Localizable-MastodonMenuAction", "Common.Controls.Actions.removeFollower")
            return result
        }()
        public static func blockUser(_ username: String) -> String {
            return L10n.Common.Controls.Friendship.blockUser(username)
        }
        public static func unblockUser(_ username: String) -> String {
            return L10n.Common.Controls.Friendship.unblockUser(username)
        }
        public static func reportUser(_ username: String) -> String {
            return L10n.Common.Controls.Actions.reportUser(username)
        }
        public static func blockDomain(_ domainName: String) -> String {
            let result = tr("Localizable-MastodonMenuAction", "Common.Controls.Actions.blockDomain", domainName)
            return result
        }
        public static func unblockDomain(_ domainName: String) -> String {
            let result = tr("Localizable-MastodonMenuAction", "Common.Controls.Actions.unblockDomain", domainName)
            return result
        }
        public static let editPersonalNote: String = {
            let result = tr("Localizable-MastodonMenuAction", "Common.Controls.Actions.editPersonalNote")
            return result
        }()
        public static let addPersonalNote: String = {
            let result = tr("Localizable-MastodonMenuAction", "Common.Controls.Actions.addPersonalNote")
            return result
        }()
        
        public static let confirmShowFeaturedTabTitle: String = {
            let result = tr("Localizable-MastodonMenuAction", "Common.Controls.Actions.confirmShowFeaturedTabTitle")
            return result
        }()
        public static func confirmFollowBeforeAddingToListTitle(username: String) -> String {
            let result = tr("Localizable-MastodonMenuAction", "Common.Controls.Actions.confirmFollowBeforeAddingToListTitle", username)
            return result
        }
        public static let confirmRemoveFollowerTitle: String = {
            let result = tr("Localizable-MastodonMenuAction", "Common.Controls.Actions.confirmRemoveFollowerTitle")
            return result
        }()
        public static func confirmShowFeatureTabMessage(featureItem: String) -> String {
            let result = tr("Localizable-MastodonMenuAction", "Common.Controls.Actions.confirmShowFeatureTabMessage", featureItem)
            return result
        }
        public static func confirmFollowBeforeAddingToListMessage(username: String) -> String {
            let result = tr("Localizable-MastodonMenuAction", "Common.Controls.Actions.confirmFollowBeforeAddingToListMessage", username)
            return result
        }
        public static func confirmRemoveFollowerMessage(username: String) -> String {
            let result = tr("Localizable-MastodonMenuAction", "Common.Controls.Actions.confirmRemoveFollowerMessage", username)
            return result
        }
        public static let confirmShowFeaturedTabButton: String = {
            let result = tr("Localizable-MastodonMenuAction", "Common.Controls.Actions.confirmShowFeaturedTabButton")
            return result
        }()
        public static let confirmFollowButton: String = {
            let result = tr("Localizable-MastodonMenuAction", "Common.Controls.Actions.confirmFollowButton")
            return result
        }()
        
        public static func confirmBlockUserMessage(bulletNumber: Int) -> String {
            let result = tr("Localizable-MastodonMenuAction", "RelationshipActions.ConfirmBlockUserMessage.bullet\(bulletNumber)")
            return result
        }
    }
}

public extension L10nLookup.MastodonMenuAction {
    struct Navigation {
        public static let share: String = {
            let result = tr("Localizable-MastodonMenuAction", "Common.Controls.Actions.Navigation.share")
            return result
        }()
        public static let openInBrowser: String = {
            let result = tr("Localizable-MastodonMenuAction", "Common.Controls.Actions.Navigation.openInBrowser")
            return result
        }()
        public static let favorites: String = {
            let result = tr("Localizable-MastodonMenuAction", "Common.Controls.Actions.Navigation.favorites")
            return result
        }()
        public static let bookmarks: String = {
            let result = tr("Localizable-MastodonMenuAction", "Common.Controls.Actions.Navigation.bookmarks")
            return result
        }()
        public static let followedHashtags: String = {
            let result = tr("Localizable-MastodonMenuAction", "Common.Controls.Actions.Navigation.followedHashtags")
            return result
        }()
        public static let accountSettings: String = {
            let result = tr("Localizable-MastodonMenuAction", "Common.Controls.Actions.Navigation.accountSettings")
            return result
        }()
        public static let viewCollection: String = {
            let result = tr("Localizable-MastodonMenuAction", "Common.Controls.Actions.Navigation.viewCollection")
            return result
        }()
        public static let compose: String = {
            let result = tr("Localizable-MastodonMenuAction", "Common.Controls.Actions.Navigation.compose")
            return result
        }()
        public static let edit: String = {
            let result = tr("Localizable-MastodonMenuAction", "Common.Controls.Actions.Navigation.edit")
            return result
        }()
        public static let quote: String = {
            let result = tr("Localizable-MastodonMenuAction", "Common.Controls.Actions.Navigation.quote")
            return result
        }()
        public static let mention: String = {
            let result = tr("Localizable-MastodonMenuAction", "Common.Controls.Actions.Navigation.mention")
            return result
        }()
        public static let privatelyMention: String = {
            let result = tr("Localizable-MastodonMenuAction", "Common.Controls.Actions.Navigation.privatelyMention")
            return result
        }()
        public static let addToList: String = {
            let result = tr("Localizable-MastodonMenuAction", "Common.Controls.Actions.Navigation.addToList")
            return result
        }()
    }
}

public extension L10nLookup {
    struct CommonControls {
        public static let learnMore: String = {
            let result = tr("Localizable-CommonControls", "Common.Controls.learnMore")
            return result
        }()
        public static let genericImageDescription: String = {
            let result = tr("Localizable-CommonControls", "Common.Controls.genericImageDescription")
            return result
        }()
        public struct CharacterLimits {
            public static func simpleCharacterCount(_ count: Int) -> String {
                let result = tr("Localizable-CommonControls", "Common.Controls.simpleCharacterCount")
                return result
            }
            public static func characterCount(_ count: Int, outOf: Int) -> String {
                let result = tr("Localizable-CommonControls", "Common.Controls.characterCount")
                return result
            }
            public static func characterCountSuggestion(_ count: Int) -> String {
                let result = tr("Localizable-CommonControls", "Common.Controls.characterCountSuggestion")
                return result
            }
        }
    }
}

public extension L10nLookup.Scene {
    struct Lists {
        public static let listName: String = {
            let result = tr("Localizable-Lists", "Scene.Lists.listName")
            return result
        }()
        public static let includeRepliesTo: String = {
            let result = tr("Localizable-Lists", "Scene.Lists.includeRepliesTo")
            return result
        }()
        
        public struct ReplyFilterOptions {
            public static let noOne: String = {
                let result = tr("Localizable-Lists", "Scene.Lists.ReplyFilterOptions.noOne")
                return result
            }()

            public static let membersOfTheList: String = {
                let result = tr("Localizable-Lists", "Scene.Lists.ReplyFilterOptions.membersOfTheList")
                return result
            }()

            public static let anyFollowedUser: String = {
                let result = tr("Localizable-Lists", "Scene.Lists.ReplyFilterOptions.anyFollowedUser")
                return result
            }()

        }
        public static let hideMembersInHomeFeed: String = {
            let result = tr("Localizable-Lists", "Scene.Lists.hideMembersInHomeFeed")
            return result
        }()
        public static let hideMembersExplainer: String = {
            let result = tr("Localizable-Lists", "Scene.Lists.hideMembersExplainer")
            return result
        }()
        public static func listCreationError(_ error: String) -> String {
            let result = tr("Localizable-Lists", "Scene.Lists.listCreationError", error)
            return result
        }
        public static let create: String = {
            let result = tr("Localizable-Lists", "Scene.Lists.create")
            return result
        }()
        public static let createNewList: String = {
            let result = tr("Localizable-Lists", "Scene.Lists.createNewList")
            return result
        }()
        public static let createList: String = {
            let result = tr("Localizable-Lists", "Scene.Lists.createList")
            return result
        }()
    }
}

public extension L10nLookup {
    struct Timeline {
        public struct EmptyState {
            public static let showcaseYourFavoriteAccounts: String = {
                let result = tr("Localizable-Timeline", "Scene.Timeline.EmptyState.showcaseYourFavoriteAccounts")
                return result
            }()
            public static let nothingToSeeHere: String = {
                let result = tr("Localizable-Timeline", "Scene.Timeline.EmptyState.nothingToSeeHere")
                return result
            }()
            public static let someNotificationsHaveBeenFiltered: String = {
                let result = tr("Localizable-Timeline", "Scene.Timeline.EmptyState.someNotificationsHaveBeenFiltered")
                return result
            }()
            public static let featuredTabEmptyStateMessage: String = {
                let result = tr("Localizable-Timeline", "Scene.Timeline.EmptyState.featuredTabEmptyStateMessage")
                return result
            }()
            public static func featuredTabEmptyStateMessageWithUsername(_ username: String) -> String {
                let result = tr("Localizable-Timeline", "Scene.Timeline.EmptyState.featuredTabEmptyStateMessageWithUsername", username)
                return result
            }
        }
    }
}

public extension L10nLookup.Scene {
    struct Collections {
        public static let stayTunedForCollections: String = {
            let result = tr("Localizable-Collections", "Scene.Collections.stayTunedForCollections")
            return result
        }()
        public static let collectionsExplainerShort: String = {
            let result = tr("Localizable-Collections", "Scene.Collections.collectionsExplainerShort")
            return result
        }()
        public static let collectionsExplainerLong: String = {
            let result = tr("Localizable-Collections", "Scene.Collections.collectionsExplainerLong")
            return result
        }()
        public static let reportCollection: String = {
            let result = tr("Localizable-Collections", "Scene.Collections.reportCollection")
            return result
        }()
        public static let removeMe: String = {
            let result = tr("Localizable-Collections", "Scene.Collections.removeMe")
            return result
        }()
        public static let remove: String = {
            let result = tr("Localizable-Collections", "Scene.Collections.remove")
            return result
        }()
        public static let createCollection: String = {
            let result = tr("Localizable-Collections", "Scene.Collections.createCollection")
            return result
        }()
        public static let hideThisTabInstead: String = {
            let result = tr("Localizable-Collections", "Scene.Collections.hideThisTabInstead")
            return result
        }()
        public static let sensitiveContentHeading: String = {
            let result = tr("Localizable-Collections", "Scene.Collections.sensitiveContentHeading")
            return result
        }()
        public static let sensitiveContentMessage: String = {
            let result = tr("Localizable-Collections", "Scene.Collections.sensitiveContentMessage")
            return result
        }()
        public static func authorLabel(_ author: String) -> String {
            let result = tr("Localizable-Collections", "Scene.Collections.authorLabel", author)
            return result
        }
        public static func numberOfAccounts(_ count: Int) -> String {
            let result = tr("Localizable-Collections", "Scene.Collections.numberOfAccounts", count)
            return result
        }
        public static let youAreFeaturedInThisCollection: String = {
            let result = tr("Localizable-Collections", "Scene.Collections.youAreFeaturedInThisCollection")
            return result
        }()
        private static let dayMonthYearFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter
        }()
        public static func collectionAuthorAddedYouOnDate(author: String, date: Date) -> String {
            let dateString = dayMonthYearFormatter.string(from: date)
            let result = tr("Localizable-Collections", "Scene.Collections.collectionAuthorAddedYouOnDate", author, dateString)
            return result
        }
    }
}

private func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
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

private var englishBundle: Bundle? = {
    guard let enBundlePath = Bundle.module.path(forResource: "en", ofType: "lproj") else { return nil }
    return Bundle(path: enBundlePath)
}()
