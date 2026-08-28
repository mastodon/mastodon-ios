// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonSDK
import MastodonCore
import MastodonLocalization

struct PrecalculatedHeight {
    let contentWidth: CGFloat
    let contentConcealed: ContentConcealViewModel.ContentDisplayMode
    let showingTranslation: Bool
    let calculatedHeight: CGFloat
}

@MainActor
@Observable class MastodonPostViewModel {
    
    var precalculatedHeights = [PrecalculatedHeight]()
    
#if DEBUG
    var actualLayoutHeight: CGFloat?
#endif
    
    var fullQuotedPostViewModel: MastodonPostViewModel?
    var placeholderQuotedPost: MastodonQuotedPost?
    
    var collectionViewModel: CollectionViewModel?
    
    enum DisplayPrepStatus {
        case unprepared
        case donePreparing
    }
    
    enum DisplayType: Equatable {
        case standard
        case editHistory(isOriginal: Bool)
    }
    
    nonisolated let initialDisplayInfo: GenericMastodonPost.InitialDisplayInfo
    nonisolated let displayType: DisplayType
    
    private(set) var fullPost: GenericMastodonPost? = nil
    
    func initialSetFullPost(_ post: GenericMastodonPost?) {
        fullPost = post
        deriveNewQuotedPostViewModel()
        deriveNewTaggedCollectionViewModel()
    }
    
    func deriveNewQuotedPostViewModel() {
        if let potentialQuotePost = fullPost?.actionablePost as? MastodonBasicPost {
            if let quoted = potentialQuotePost.quotedPost, let quotedFullPost = quoted.fullPost {
                let updated = MastodonPostViewModel(quotedFullPost.initialDisplayInfo(), fullPost: quotedFullPost, displayType: .standard)
                self.fullQuotedPostViewModel = updated
                placeholderQuotedPost = nil
            } else {
                self.fullQuotedPostViewModel = nil
                placeholderQuotedPost = potentialQuotePost.quotedPost
            }
        }
    }
    
    func deriveNewTaggedCollectionViewModel() {
        if let taggedCollection = fullPost?.actionablePost?.content.htmlWithEntities?.collections.first {
            collectionViewModel = CollectionViewModel(collection: taggedCollection)
        }
    }
    
    let myRelationshipToAuthorViewModel = RelationshipViewModel()
    private(set) var myRelationshipToAuthor: MastodonAccount.Relationship?
    var isQuotingMe: Bool {
        guard let quoted = fullQuotedPostViewModel else { return false }
        switch quoted.myRelationshipToAuthor {
        case .isMe:
            return true
        case nil:
            return false
        default:
            return false
        }
    }

    var displayPrepStatus: DisplayPrepStatus = .unprepared
    var isShowingTranslation: Bool? = nil
    var isDoingAction: MastodonPostMenuAction? = nil
    
    
    private(set) var translation: Mastodon.Entity.Translation? = nil
    
    var currentUserQuoteButton: (title: String?, subtitle: String?, isEnabled: Bool) {
        
        let defaultPostingVisibilityIsMentionedOnly = {
            guard let currentUserDefault = AuthenticationServiceProvider.shared.currentActiveUser.value?.cachedAccount?.source?.privacy else { return false }
            return currentUserDefault == .direct
        }()
        
        guard !defaultPostingVisibilityIsMentionedOnly else {
            // Mastodon does not currently allow setting your default posting visibility to mentionedOnly, but we handle the possibility (by not allowing quotes) just in case
            return (nil, L10n.Common.Alerts.QuoteAPost.directMentionQuotesForbidden, false)
        }
        
        if let specified = fullPost?.actionablePost?._legacyEntity.quoteApproval?.currentUser {
            switch specified {
            case .automatic:
                return (L10n.Common.Alerts.QuoteAPost.quote, nil, true)
            case .manual:
                return (L10n.Common.Alerts.QuoteAPost.requestToQuote, L10n.Common.Alerts.QuoteAPost.authorWillReview, true)
            default:
                if let policy = fullPost?.actionablePost?._legacyEntity.quoteApproval?.automatic, policy.contains(.followersOnly) {
                    return (nil, L10n.Common.Alerts.QuoteAPost.mustFollowToQuote, false)
                } else {
                    return (nil, L10n.Common.Alerts.QuoteAPost.quotesDisabled, false)
                }
            }
        } else {
            return (nil, L10n.Common.Alerts.QuoteAPost.quotesDisabled, false)
        }
    }
    
    nonisolated
    init(_ initialDisplay: GenericMastodonPost.InitialDisplayInfo, displayType: DisplayType) {
        self.initialDisplayInfo = initialDisplay
        self.displayType = displayType
    }
    
    private init(_ initialDisplay: GenericMastodonPost.InitialDisplayInfo, fullPost: GenericMastodonPost? = nil, displayType: DisplayType, isShowingTranslation: Bool? = nil, isDoingAction: MastodonPostMenuAction? = nil, myRelationshipToAuthor: MastodonAccount.Relationship? = nil, actionHandler: MastodonPostMenuActionHandler? = nil, translation: Mastodon.Entity.Translation? = nil) {
        self.initialDisplayInfo = initialDisplay
        self.displayType = displayType
        self.fullPost = fullPost
        self.deriveNewQuotedPostViewModel()
        self.deriveNewTaggedCollectionViewModel()
    }
    
    public func prepareForDisplay(relationship: MastodonAccount.Relationship, theirAccountIsLocked: Bool) {
        myRelationshipToAuthorViewModel.prepareForDisplay(relationship: relationship, theirAccountIsLocked: theirAccountIsLocked)
        myRelationshipToAuthor = relationship
    }
    
    var altTextTranslations: [String : String]? {
        guard isShowingTranslation == true else { return nil }
        guard let attachmentTranslations = translation?.mediaAttachments else { return nil }
        
        let dictionary = attachmentTranslations.reduce(into: [ String : String]()) { partialResult, attachment in
            partialResult[attachment.id] = attachment.description
        }
        return dictionary
    }
    
    var pollOptionTranslations: [String]? {
        guard isShowingTranslation == true else { return nil }
        guard let pollTranslation = translation?.poll else { return nil }
        return pollTranslation.options.map { $0.title }
    }
    
    func openThreadView(navigator: MastodonNavigationRouter) {
        guard let actionablePost = fullPost?.actionablePost as? MastodonContentPost else { return }
        navigator.push(.timeline(.thread(root: actionablePost)))
    }
    
    func openURL(_ url: URL, navigator: MastodonNavigationRouter) -> Bool {
        if let mention = fullPost?.actionablePost?.content.htmlWithEntities?.mentions.first(where: { $0.url == url.absoluteString }) {
            goToProfile(mention, navigator: navigator)
            return true
        } else if let hashtag = fullPost?.actionablePost?.content.htmlWithEntities?.tags.first(where: { $0.name.lowercased() == url.lastPathComponent.lowercased() && url.pathComponents.contains("tags") }) {
            guard AuthenticationServiceProvider.shared.currentActiveUser.value != nil else { return false }
            navigator.push(.timeline(.hashtag(hashtag)))
            return true
        } else if let collection = fullPost?.actionablePost?.content.htmlWithEntities?.collections.first(where: { $0.id == url.lastPathComponent && url.pathComponents.contains("collections") }) {
            let collectionModel = {
                if self.collectionViewModel?.collection.id == collection.id {
                    return self.collectionViewModel!
                } else {
                    return CollectionViewModel(collection: collection)
                }
            }()
            navigator.push(.timeline(.collection(collectionModel)))
            return true
        } else {
            // fix non-ascii character URL link can not open issue
            navigator.openUrl(url, afterDeconflictionDelay: true)
            return true
        }
    }
    
    func goToProfile(_ account: MastodonAccount, navigator: MastodonNavigationRouter) {
        navigator.push(.profile(account: account._legacyEntity, relationship: myRelationshipToAuthor))
    }
    
    func goToProfile(_ mention: Mastodon.Entity.Mention, navigator: MastodonNavigationRouter) {
        Task {
            guard let currentUser = AuthenticationServiceProvider.shared.currentActiveUser.value else { return }
            let account = try await APIService.shared.accountInfo(
                domain: currentUser.domain,
                userID:
                    mention.id,
                authorization: currentUser.userAuthorization
            )
            goToProfile(MastodonAccount.fromEntity(account, authenticatedDomain: currentUser.domain), navigator: navigator)
        }
    }
    
    public var formattedExactDate: String {
        let date = fullPost?.actionablePost?.metaData.createdAt ?? initialDisplayInfo.actionableCreatedAt
        let dateYear = Calendar.current.component(.year, from: date)
        let currentYear = Calendar.current.component(.year, from: .now)
        if dateYear == currentYear {
            return date.formatted(.dateTime.month(.abbreviated).day(.defaultDigits).hour().minute())
        } else {
            return date.formatted(.dateTime.year().month(.abbreviated).day(.defaultDigits).hour().minute())
        }
    }
}

extension MastodonPostViewModel {
    var composeViewModelQuotingThisPost: ComposeViewModel? {
        guard let currentUser = AuthenticationServiceProvider.shared.currentActiveUser.value, let quotedPost = fullPost?.actionablePost else { return nil }
        return ComposeViewModel(authenticationBox: currentUser, composeContext: .composeStatus(quoting: (quotedPost._legacyEntity, {
            AnyView(
                EmbeddedPostView(layoutWidth: 200, isSummary: false, actionHandler: nil, linkHandler: nil)
                    .environment(self)
                    .environment(TimestampUpdater.timestamper(withInterval: 30))
                    .environment(ContentConcealViewModel.alwaysShow)
            )
        })), destination: .topLevel)
    }
}

extension MastodonPostViewModel {
    @ViewBuilder func accessibilityActionButton(_ action: MastodonPostMenuAction, actionHandler: MastodonPostMenuActionHandler?, navigator: MastodonNavigationRouter) -> some View {
        let actionLabel = action.labelText(username: fullPost?.initialDisplayInfo().actionableAuthorDisplayName, postLanguage: (fullPost?.actionablePost as? MastodonContentPost)?.content.language)
        switch action {
        case .sharePost:
            if let urlString = fullPost?.actionablePost?.metaData.url ?? fullPost?.actionablePost?.metaData.uriForFediverse, let url = URL(string: urlString) {
                ShareLink(item: url) {
                    Text(actionLabel)
                }
            }
        default:
            Button(actionLabel) { [weak self] in
                guard let self else { return }
                actionHandler?.doAction(action, forPost: self, navigator: navigator)
            }
        }
    }
    
    var accessibilityActionBarLabel: String {
        guard let metrics = fullPost?.actionablePost?.content.metrics, let myActions = fullPost?.actionablePost?.content.myActions else { print("no post!"); return "" }
        
        let replyLabel: String? = {
            guard metrics.replyCount > 0 else { return nil }
            return L10n.Plural.Count.reply(metrics.replyCount)
        }()
        let boostLabel: String? = {
            guard metrics.boostCount > 0 else { return nil }
            if myActions.boosted {
                return L10nLookup.Scene.Notification.GroupedNotificationDescription.youAndOthersBoosted(othersCount: metrics.boostCount - 1)
            } else {
                return L10nLookup.Scene.Notification.GroupedNotificationDescription.peopleBoosted(boostCount: metrics.boostCount)
            }
        }()
        let favoriteLabel: String? = {
            guard metrics.favoriteCount > 0 else { return nil }
            if myActions.favorited {
                return L10nLookup.Scene.Notification.GroupedNotificationDescription.youAndOthersFavorited(othersCount: metrics.favoriteCount - 1)
            } else {
                return L10nLookup.Scene.Notification.GroupedNotificationDescription.peopleFavourited(favouriteCount: metrics.favoriteCount)
            }
        }()
        let bookmarkLabel: String? = {
            guard myActions.bookmarked else { return nil }
            return L10n.Common.Controls.Status.Actions.A11YLabels.bookmarked
        }()
        
        return [replyLabel, boostLabel, favoriteLabel, bookmarkLabel].compactMap { $0 }.joined(separator: ", ")
    }
}

extension MastodonPostViewModel {
    
    @ViewBuilder func socialContextHeader(inThreadContext threadedContext: ThreadedConversationModel.ThreadContext?, getAccount: (Mastodon.Entity.Account.ID)->MastodonAccount?) -> some View {
        if let socialContext = socialContext(inThreadContext: threadedContext, getAccount: getAccount) {
            socialContext
        } else {
            EmptyView()
        }
    }
    
    func socialContext(inThreadContext threadedContext: ThreadedConversationModel.ThreadContext?, getAccount: (Mastodon.Entity.Account.ID)->(MastodonAccount?)) -> SocialContextHeader? {
        guard let fullPost else { return nil }
        if fullPost is MastodonBoostPost {
            // BOOSTED BY
            return SocialContextHeader.boosted(by: fullPost.metaData.author.displayInfo.displayName, emojis: fullPost.metaData.author.displayInfo.emojis)
        } else if let basicPost = fullPost as? MastodonBasicPost {
            // REPLIED and/or PRIVATE MENTION or QUOTES ME
            let isPrivate = basicPost.metaData.privacyLevel == .mentionedOnly
            let quotesMe = {
                if let quotedPost = fullQuotedPostViewModel {
                    switch quotedPost.myRelationshipToAuthor {
                    case .isMe:
                        return true
                    default:
                        return false
                    }
                } else {
                    return false
                }
            }()
            if isPrivate || threadedContext == nil {
                let replyInfo = basicPost.inReplyTo
                if let replyInfo {
                    let replyToAccount = getAccount(replyInfo.accountID)// actionHandler?.account(replyInfo.accountID)
                    return SocialContextHeader.reply(to: replyToAccount?.displayInfo.displayName ?? "unknown", isPrivate: isPrivate, isNotification: false, emojis: replyToAccount?.displayInfo.emojis ?? [])
                } else if isPrivate {
                    return SocialContextHeader.mention(isPrivate: true)
                } else if quotesMe {
                    return SocialContextHeader.quoted(by: fullPost.metaData.author.displayInfo.displayName, emojis: fullPost.metaData.author.displayInfo.emojis)
                }
            }
        }
        return nil
    }

    func textContentView(isInlinePreview: Bool, actionHandler: MastodonPostMenuActionHandler?) -> MastodonContentView {
        let emptyTextContent: MastodonContentView = .timelinePost(html: "", emojis: MastodonContentView.Emojis(), isInlinePreview: false)
        
        guard let actionablePost = fullPost?.actionablePost, let untranslatedContent = actionablePost.content.htmlWithEntities?.html else { return emptyTextContent }
        let emojis = actionablePost.content.htmlWithEntities?.emojis ?? MastodonContentView.Emojis()
        
        if isShowingTranslation == true, let translation = actionHandler?.translation(forContentPostId: actionablePost.id)?.content {
            return .timelinePost(html: translation, emojis: emojis, isInlinePreview: isInlinePreview)
        } else {
            return .timelinePost(html: untranslatedContent, emojis: emojis, isInlinePreview: isInlinePreview)
        }
    }
}

extension MastodonPostViewModel: FeedCoordinatorUpdatable {
    func incorporateUpdate(_ update: UpdatedElement) {
        switch update {
        case .hashtag:
            fullQuotedPostViewModel?.incorporateUpdate(update)
        case .deletedPost(let deletedID):
            guard deletedID != self.initialDisplayInfo.id else { assertionFailure("owner must delete this view model"); return }
            if fullQuotedPostViewModel?.initialDisplayInfo.id == deletedID {
                fullQuotedPostViewModel = nil
                placeholderQuotedPost = MastodonQuotedPost(deletedID: deletedID)
            }
        case .post(let updated):
            do {
                self.fullPost = try fullPost?.byReplacingActionablePost(with: updated)
                deriveNewQuotedPostViewModel()
                deriveNewTaggedCollectionViewModel()
            } catch {
                // the full post wasn't a match, but the quoted post might be
                fullQuotedPostViewModel?.incorporateUpdate(update)
            }
        case .relationship(let updated):
            fullQuotedPostViewModel?.incorporateUpdate(update)
            guard myRelationshipToAuthor?.refersToSameAccount(as: updated) == true else { return }
            myRelationshipToAuthorViewModel.prepareForDisplay(relationship: updated, theirAccountIsLocked: fullPost?.actionablePost?.metaData.author.locked ?? false)
            myRelationshipToAuthor = updated
        case .domainBlockChange(let domain, let isBlocked):
            fullQuotedPostViewModel?.incorporateUpdate(update)
            guard domain == fullPost?.metaData.author.domain else { return }
            myRelationshipToAuthorViewModel.updateForDomainBlockChange(isBlocked: isBlocked)
        }
    }
}
