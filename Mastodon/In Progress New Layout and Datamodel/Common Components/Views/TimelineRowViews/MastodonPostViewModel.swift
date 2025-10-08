// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonSDK
import MastodonCore
import MastodonLocalization

@MainActor
@Observable class MastodonPostViewModel {
    
    let threadedContext: ThreadedConversationModel.ThreadContext?
    
    var fullQuotedPostViewModel: MastodonPostViewModel?
    var placeholderQuotedPost: MastodonQuotedPost?
    
    enum DisplayPrepStatus {
        case unprepared
        case donePreparing
    }
    
    nonisolated let initialDisplayInfo: GenericMastodonPost.InitialDisplayInfo
    
    private(set) var fullPost: GenericMastodonPost? = nil
    
    func initialSetFullPost(_ post: GenericMastodonPost?) {
        fullPost = post
        deriveNewQuotedPostViewModel()
    }
    
    func deriveNewQuotedPostViewModel() {
        if let potentialQuotePost = fullPost?.actionablePost as? MastodonBasicPost {
            if let quoted = potentialQuotePost.quotedPost, let quotedFullPost = quoted.fullPost {
                let updated = MastodonPostViewModel(quotedFullPost.initialDisplayInfo(inContext: filterContext), fullPost: quotedFullPost, filterContext: filterContext, threadedConversationContext: nil)
                updated.actionHandler = actionHandler
                self.fullQuotedPostViewModel = updated
                placeholderQuotedPost = nil
            } else {
                self.fullQuotedPostViewModel = nil
                placeholderQuotedPost = potentialQuotePost.quotedPost
            }
        }
    }
    
    private let myRelationshipToAuthorViewModel = RelationshipViewModel()
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
    
    var actionHandler: MastodonPostMenuActionHandler? = nil {
        didSet {
            fullQuotedPostViewModel?.actionHandler = actionHandler
        }
    }
    let filterContext: Mastodon.Entity.FilterContext?
    
    private(set) var translation: Mastodon.Entity.Translation? = nil
    
    var currentUserQuoteButton: (title: String?, subtitle: String?, isEnabled: Bool) {
        if let specified = fullPost?.actionablePost?._legacyEntity.quoteApproval?.currentUser {
            switch specified {
            case .automatic:
                (L10n.Common.Alerts.QuoteAPost.quote, nil, true)
            case .manual:
                (L10n.Common.Alerts.QuoteAPost.requestToQuote, L10n.Common.Alerts.QuoteAPost.authorWillReview, true)
            default:
                if let policy = fullPost?.actionablePost?._legacyEntity.quoteApproval?.automatic, policy.contains(.followersOnly) {
                    (nil, L10n.Common.Alerts.QuoteAPost.mustFollowToQuote, false)
                } else {
                    (nil, L10n.Common.Alerts.QuoteAPost.quotesDisabled, false)
                }
            }
        } else {
            (nil, L10n.Common.Alerts.QuoteAPost.quotesDisabled, false)
        }
    }
    
    nonisolated
    init(_ initialDisplay: GenericMastodonPost.InitialDisplayInfo, filterContext: Mastodon.Entity.FilterContext?, threadedConversationContext: ThreadedConversationModel.ThreadContext?) {
        self.initialDisplayInfo = initialDisplay
        self.filterContext = filterContext
        self.threadedContext = threadedConversationContext
    }
    
    private init(_ initialDisplay: GenericMastodonPost.InitialDisplayInfo, fullPost: GenericMastodonPost? = nil, isShowingTranslation: Bool? = nil, isDoingAction: MastodonPostMenuAction? = nil, myRelationshipToAuthor: MastodonAccount.Relationship? = nil, actionHandler: MastodonPostMenuActionHandler? = nil, translation: Mastodon.Entity.Translation? = nil, filterContext: Mastodon.Entity.FilterContext?, threadedConversationContext: ThreadedConversationModel.ThreadContext?) {
        self.initialDisplayInfo = initialDisplay
        self.fullPost = fullPost
        self.filterContext = filterContext
        self.threadedContext = threadedConversationContext
        self.deriveNewQuotedPostViewModel()
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
    
    func openThreadView() {
        guard let actionablePost = fullPost?.actionablePost, let currentUser = AuthenticationServiceProvider.shared.currentActiveUser.value else { return }
        actionHandler?.presentScene(
            .thread(
                viewModel: ThreadViewModel(
                    authenticationBox: currentUser,
                    optionalRoot: .root(
                        context: .init(
                            status: MastodonStatus(
                                entity: actionablePost._legacyEntity,
                                showDespiteContentWarning:
                                    false))))), fromPost: initialDisplayInfo.id, transition: .show)
    }
    
    func openURL(_ url: URL) -> Bool {
        if let mention = fullPost?.actionablePost?.content.htmlWithEntities?.mentions.first(where: { $0.url == url.absoluteString }) {
            goToProfile(mention)
            return true
        } else if let hashtag = fullPost?.actionablePost?.content.htmlWithEntities?.tags.first(where: { $0.name.lowercased() == url.lastPathComponent.lowercased() && url.pathComponents.contains("tags") }) {
            guard let currentUser = AuthenticationServiceProvider.shared.currentActiveUser.value else { return false }
            actionHandler?.presentScene(.hashtagTimeline(hashtag), fromPost: initialDisplayInfo.id, transition: .show)
            return true
        } else {
            // fix non-ascii character URL link can not open issue
            actionHandler?.presentScene(.safari(url: url), fromPost: initialDisplayInfo.id, transition: .safariPresent(animated: true, completion: nil))
            return true
        }
    }
    
    func goToProfile(_ account: MastodonAccount) {
        guard let me = AuthenticationServiceProvider.shared.currentActiveUser.value?.cachedAccount else { return }
        if let relationshipToAuthor = myRelationshipToAuthor {
            switch relationshipToAuthor {
            case .isNotMe(let info):
                if let info, account.id == info.id {
                    let profile: ProfileViewController.ProfileType = .notMe(me: me, displayAccount: account._legacyEntity, relationship: info._legacyEntity)
                    actionHandler?.presentScene(.profile(profile), fromPost: initialDisplayInfo.id, transition: .show)
                    return
                }
            case .isMe:
                if account.id == me.id {
                    let profile: ProfileViewController.ProfileType = .me(account._legacyEntity)
                    actionHandler?.presentScene(.profile(profile), fromPost: initialDisplayInfo.id, transition: .show)
                    return
                }
            }
        }
        // if we have reached here, then we are trying to view an account other than the author of this post (probably a mention)
        if account.id == me.id {
            let profile: ProfileViewController.ProfileType = .me(account._legacyEntity)
            actionHandler?.presentScene(.profile(profile), fromPost: initialDisplayInfo.id, transition: .show)
        } else {
            let profile: ProfileViewController.ProfileType = .notMe(me: me, displayAccount: account._legacyEntity, relationship: nil) // we don't have the relationship info at this point
            actionHandler?.presentScene(.profile(profile), fromPost: initialDisplayInfo.id, transition: .show)
        }
    }
    
    func goToProfile(_ mention: Mastodon.Entity.Mention) {
        Task {
            guard let currentUser = AuthenticationServiceProvider.shared.currentActiveUser.value else { return }
            let account = try await APIService.shared.accountInfo(
                domain: currentUser.domain,
                userID:
                    mention.id,
                authorization: currentUser.userAuthorization
            )
            goToProfile(MastodonAccount.fromEntity(account))
        }
    }
}

extension MastodonPostViewModel {
    var composeViewModelQuotingThisPost: ComposeViewModel? {
        guard let currentUser = AuthenticationServiceProvider.shared.currentActiveUser.value, let quotedPost = fullPost?.actionablePost else { return nil }
        return ComposeViewModel(authenticationBox: currentUser, composeContext: .composeStatus(quoting: (quotedPost._legacyEntity, {
            AnyView(
                EmbeddedPostView(layoutWidth: 200, isSummary: false)
                    .environment(self)
                    .environment(TimestampUpdater.timestamper(withInterval: 30))
                    .environment(ContentConcealViewModel.alwaysShow)
            )
        })), destination: .topLevel)
    }
}

extension MastodonPostViewModel {
    @ViewBuilder func accessibilityActionButton(_ action: MastodonPostMenuAction) -> some View {
        Button(action.labelText(username: fullPost?.initialDisplayInfo(inContext: nil).actionableAuthorDisplayName, postLanguage: (fullPost?.actionablePost as? MastodonContentPost)?.content.language)) { [weak self] in
            guard let self else { return }
            self.actionHandler?.doAction(action, forPost: self)
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
                return L10n.Plural.Count.youAndOthersBoosted(metrics.boostCount - 1)
            } else {
                return L10n.Plural.Count.reblogA11y(metrics.boostCount)
            }
        }()
        let favoriteLabel: String? = {
            guard metrics.favoriteCount > 0 else { return nil }
            if myActions.favorited {
                return L10n.Plural.Count.youAndOthersFavorited(metrics.favoriteCount - 1)
            } else {
                return L10n.Plural.Count.favorite(metrics.favoriteCount)
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
    
    @ViewBuilder var socialContextHeader: some View {
        if let socialContext {
            socialContext
        } else {
            EmptyView()
        }
    }
    
    var socialContext: SocialContextHeader? {
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
                    let replyToAccount = actionHandler?.account(replyInfo.accountID)
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

    func textContentView(isInlinePreview: Bool) -> MastodonContentView {
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
            guard deletedID != self.initialDisplayInfo.id else { /*assertionFailure("owner must delete this view model");*/ return }
            if fullQuotedPostViewModel?.initialDisplayInfo.id == deletedID {
                fullQuotedPostViewModel = nil
                placeholderQuotedPost = MastodonQuotedPost(deletedID: deletedID)
            }
        case .post(let updated):
            do {
                self.fullPost = try fullPost?.byReplacingActionablePost(with: updated)
                deriveNewQuotedPostViewModel()
            } catch {
                // the full post wasn't a match, but the quoted post might be
                fullQuotedPostViewModel?.incorporateUpdate(update)
            }
        case .relationship(let updated):
            fullQuotedPostViewModel?.incorporateUpdate(update)
            guard myRelationshipToAuthor?.refersToSameAccount(as: updated) == true else { return }
            myRelationshipToAuthorViewModel.prepareForDisplay(relationship: updated, theirAccountIsLocked: fullPost?.actionablePost?.metaData.author.locked ?? false)
            myRelationshipToAuthor = updated
        }
    }
}
