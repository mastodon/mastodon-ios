// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonAsset
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
    
    func setFullPost(_ post: GenericMastodonPost?) {
        fullPost = post
        updateQuotedPostViewModel()
    }
    
    func updateQuotedPostViewModel() {
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
    
    var myRelationshipToAuthor: MastodonAccount.Relationship? = nil
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
        self.updateQuotedPostViewModel()
    }
    
    func update(from actionablePost: GenericMastodonPost) throws {
        self.fullPost = try fullPost?.byReplacingActionablePost(with: actionablePost)
        updateQuotedPostViewModel()
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
            let hashtagTimelineViewModel = HashtagTimelineViewModel(authenticationBox: currentUser, hashtag: hashtag.name)
            actionHandler?.presentScene(.hashtagTimeline(viewModel: hashtagTimelineViewModel), fromPost: initialDisplayInfo.id, transition: .show)
            return true
        } else {
            // fix non-ascii character URL link can not open issue
            actionHandler?.presentScene(.safari(url: url), fromPost: initialDisplayInfo.id, transition: .safariPresent(animated: true, completion: nil))
            return true
        }
    }
    
    func goToProfile(_ account: MastodonAccount) {
        guard let me = AuthenticationServiceProvider.shared.currentActiveUser.value?.cachedAccount else { return }
        if let myRelationshipToAuthor {
            switch myRelationshipToAuthor {
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

struct MastodonPostRowView: View {

    @Environment(MastodonPostViewModel.self) private var viewModel
    @Environment(ContentConcealViewModel.self) private var contentConcealModel

    let contentWidth: CGFloat
    
    let distanceFromAvatarLeadingEdgeToContentLeadingEdge: CGFloat = spacingBetweenGutterAndContent + AvatarSize.large
    
    var body: some View {
        let actionablePost = viewModel.fullPost?.actionablePost
        let author = actionablePost?.metaData.author ?? viewModel.fullPost?.metaData.author
        let instanceCanQuotePosts = AuthenticationServiceProvider.shared.currentActiveUser.value?.authentication.instanceConfiguration?.isAvailable(.quotePosts) ?? false
        
        VStack(alignment: .gutterAlign, spacing: 0) {  // gutterAlign keeps the content and social context headers properly aligned with the gap between avatar and content
            if let threadedContext = viewModel.threadedContext {
                // MARK: Conversation thread line decoration
                ZStack(alignment: Alignment(horizontal: .gutterAlign, vertical: .center)) {
                    if threadedContext.drawsLineAbove {
                        HStack(spacing: 0) {
                            threadingDecoration(withSpacerAtTop: false, withSpacerAtBottom: !threadedContext.isContiguous)
                                .frame(width: AvatarSize.large)
                            Spacer()
                                .frame(width: spacingBetweenGutterAndContent)
                        }
                        .alignmentGuide(.gutterAlign) { d in
                            return d[.trailing]
                        }
                    }
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: standardPadding)
                        viewModel.socialContextHeader
                            .frame(maxWidth: contentWidth, alignment: .leading)
                    }
                }
                .accessibilityHidden(true)
            } else {
                // MARK: Social context header
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: standardPadding)
                    viewModel.socialContextHeader
                        .frame(maxWidth: contentWidth, alignment: .leading)
                }
                .accessibilityHidden(true)
            }
            
            HStack(alignment: .top, spacing: spacingBetweenGutterAndContent) {
                // MARK: Avatar
                VStack(spacing: 0) {
                    AvatarView(size: .large, authorAvatarUrl: author?.avatarURL ?? viewModel.initialDisplayInfo.actionableAuthorStaticAvatar, goToProfile: {
                        goToProfile(author)
                    })
                    if let threadedContext = viewModel.threadedContext, threadedContext.drawsLineBelow {
                        threadingDecoration(withSpacerAtTop: !threadedContext.isContiguous, withSpacerAtBottom: false)
                            .frame(width: AvatarSize.large)
                    }
                }
                .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: spacingBetweenGutterAndContent) {
                    // MARK: Author info
                    AuthorHeaderView()
                        .onTapGesture {
                            goToProfile(author)
                        }
                   
                    // MARK: Content warned and/or filtered
                    contentConcealLozenge
                        .frame(width: contentWidth)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if contentConcealModel.currentMode.isShowingContent, let actionHandler = viewModel.actionHandler {
                        if viewModel.isShowingTranslation == true, let translatablePost = viewModel.fullPost?.actionablePost, let translation = actionHandler.translation(forContentPostId: translatablePost.id) {
                            // MARK: Translation info line
                            TranslationInfoView(translationInfo: translation, showOriginal: { actionHandler.doAction(.showOriginalLanguage, forPost: viewModel) }
                            )
                            .frame(width: contentWidth, alignment: .leading)
                        }
                        
                        // MARK: Text content
                        viewModel.textContentView(isInlinePreview: false)
                            .frame(width: contentWidth, alignment: .leading)
                            .onTapGesture {
                                viewModel.openThreadView()
                            }
                            .environment(\.openURL, OpenURLAction { url in
                                if viewModel.openURL(url) {
                                    return .handled
                                } else {
                                    return .systemAction(url)
                                }
                            })
                            .accessibilityElement(children: .combine)
                        
                        // MARK: Media attachment
                        if let attachment = viewModel.fullPost?.actionablePost?.content.attachment {
                            switch attachment {
                            case .media(let array):
                                MediaAttachment(array, altTextTranslations: viewModel.altTextTranslations).view(actionHandler: actionHandler)
                                    .frame(width: contentWidth)
                            case .poll(let poll):
                                let emojis = viewModel.fullPost?.actionablePost?.content.htmlWithEntities?.emojis
                                PollView(viewModel: PollViewModel(pollEntity: poll, emojis: emojis, optionTranslations: viewModel.isShowingTranslation == true ? viewModel.pollOptionTranslations : nil, containingPostID: viewModel.initialDisplayInfo.actionablePostID, actionHandler: actionHandler), contentWidth: contentWidth)
                                    .frame(width: contentWidth)
                            case .linkPreviewCard(let card):
                                LinkPreviewCard(cardEntity: card, fittingWidth: contentWidth, navigateToScene: { (scene, transition) in
                                    actionHandler.presentScene(scene, fromPost: viewModel.initialDisplayInfo.id, transition: transition)
                                })
                                .frame(width: contentWidth)
                            }
                        }
                        
                        // MARK: Quoted post
                        if let quotedPostViewModel = viewModel.fullQuotedPostViewModel {
                            if quotedPostViewModel.initialDisplayInfo.shouldFilterOut {
                                QuotedPostHiddenByFilterView()
                            } else {
                                EmbeddedPostView(layoutWidth: contentWidth, isSummary: false)
                                    .environment(quotedPostViewModel)
                                    .environment(contentConcealModel.nestedContentConcealModel)
                                    .onTapGesture {
                                        quotedPostViewModel.openThreadView()
                                    }
                            }
                        } else if let quotePlaceholder = viewModel.placeholderQuotedPost {
                            QuotedPostPlaceholderView()
                                .environment(QuotedPostPlaceholderViewModel(quotePlaceholder, authorName: nil))  // TODO: include author name if possible (will have to fetch from server)
                        }
                    }
                    
#if DEBUG && false
                    VStack {
                        Text(viewModel.post.id)
                        if let actionableID = viewModel.post.actionablePost?.id, actionableID != viewModel.post.id {
                            Text("(content: \(actionableID))")
                        }
                    }
                    .foregroundStyle(.red)
                    .font(.footnote)
#endif
                    
                    // MARK: Action Bar
                    if let actionablePost = viewModel.fullPost?.actionablePost {
                        Spacer()
                            .frame(height: 0)  // gives double spacing between bottom of post content and action bar
                        ActionBar(instanceCanQuotePosts: instanceCanQuotePosts)
                            .frame(width: contentWidth, alignment: .leading)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(viewModel.accessibilityActionBarLabel)
                    }
                    
                    // MARK: Thread view extra info for focused post
                    switch viewModel.threadedContext {
                    case .focused:
                        threadFocusDetailFooter
                    default:
                        EmptyView()
                    }
                    
                    Spacer()
                        .frame(height: standardPadding)
                }
            }
        }
        .environment(contentConcealModel)
        .background(.background.opacity(0.01)) // To allow tap in margin to open threadview. Opacity of 0 does not accept taps, nor does .clear.
        .onTapGesture {
            viewModel.openThreadView()
        }
        .onAppear() {
            //assert(viewModel.fullPost != nil)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L10n.Scene.Notification.Headers.status)
        .accessibilityActions {
            if let relationshipToAuthor = viewModel.myRelationshipToAuthor {
                // AUTHOR ACTIONS
                if let author {
                    Button(L10n.Common.Controls.Status.showUserProfile) {
                        goToProfile(author)
                    }
                }
                ForEach(MastodonPostMenuAction.authorA11yMenuItems(forPostBy: relationshipToAuthor, isQuotingMe: viewModel.isQuotingMe, isShowingTranslation: viewModel.isShowingTranslation), id: \.self.id) { action in
                    viewModel.accessibilityActionButton(action)
                }
                
                // REPLY
                viewModel.accessibilityActionButton(.reply)
                
                // QUOTE
                if instanceCanQuotePosts {
                    let (buttonTitle, buttonSubtitle, isEnabled) = viewModel.currentUserQuoteButton
                    let fullTitle = [buttonTitle, buttonSubtitle].compactMap { $0 }.joined(separator: ", ")
                    Button(fullTitle) {
                        if isEnabled {
                            guard let composeViewModel = viewModel.composeViewModelQuotingThisPost else { return }
                            viewModel.actionHandler?.presentScene(.compose(viewModel: composeViewModel), fromPost: nil, transition: .modal(animated: true, completion: nil))
                        }
                    }
                }
                
                // POST ACTIONS
                ForEach(MastodonPostMenuAction.postA11yMenuItemsOtherThanReply(forPostBy: relationshipToAuthor, myActions: viewModel.fullPost?.actionablePost?.content.myActions, isShowingTranslation: viewModel.isShowingTranslation), id: \.self.id) { action in
                    viewModel.accessibilityActionButton(action)
                }
            }
        }
    }
    
    func goToProfile(_ account: MastodonAccount?) {
        guard let account else { return }
        viewModel.goToProfile(account)
    }
}

extension MastodonPostViewModel {
    var a11yHeaderLabel: String {
        let visibilityString = initialDisplayInfo.actionableVisibility.a11yLabel
        let dateString = initialDisplayInfo.actionableCreatedAt.localizedShortTimeAgo(since: .now)
        let authorString = "\(visibilityString) post from \(initialDisplayInfo.actionableAuthorDisplayName)" + ", \(dateString)"
        if let socialContext {
            switch socialContext {
            case .boosted(let author, _):
                return "\(authorString), boosted by \(author)"
            case .mention(let isPrivate):
                return isPrivate ? "Private mention from \(initialDisplayInfo.actionableAuthorDisplayName), \(dateString)" : "\(authorString), mentions you"
            case .quoted(_, _):
                return "\(authorString), quotes you"
            case .reply(let replyTo, let isPrivate, _, _):
                return isPrivate ? "Private reply from \(initialDisplayInfo.actionableAuthorDisplayName), \(dateString)" : "\(authorString), in reply to \(replyTo)"
            }
        } else {
            return authorString
        }
    }
}

extension GenericMastodonPost.PrivacyLevel {
    var a11yLabel: String {
        switch self {
        case .loudPublic:
            return L10n.Scene.Compose.Visibility.public
        case .quietPublic:
            return L10n.Scene.Compose.Visibility.unlisted
        case .followersOnly:
            return L10n.Scene.Compose.Visibility.private
        case .mentionedOnly:
            return L10n.Scene.Compose.Visibility.direct
        }
    }
}

var staticTimestampFormatter = {
   let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

extension MastodonPostRowView {
    @ViewBuilder func threadingDecoration(withSpacerAtTop topSpacer: Bool, withSpacerAtBottom bottomSpacer: Bool) -> some View {
        VStack(alignment: .center, spacing: 0) {
            if topSpacer {
                Spacer()
                    .frame(height: tinySpacing)
            }
            Rectangle()
                .fill(.separator)
                .frame(width: 3)
            if bottomSpacer {
                Spacer()
                    .frame(height: tinySpacing)
            }
        }
    }
    
    @ViewBuilder var threadFocusDetailFooter: some View {
        VStack(alignment: .trailing, spacing: doublePadding) {
            if let fullPost = viewModel.fullPost as? MastodonContentPost {
                // date posted and application used
                let dateString = staticTimestampFormatter.string(from: viewModel.initialDisplayInfo.actionableCreatedAt)
                if let applicationName = fullPost.metaData.application?.name {
                    Text(L10n.Common.Controls.Status.postedViaApplication(dateString, applicationName))
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                } else {
                    Text(dateString)
                        .foregroundStyle(.secondary)
                }
                
                if let authBox = AuthenticationServiceProvider.shared.currentActiveUser.value {
                    
                    // edit history
                    if let lastEditDate = fullPost.content.editedAt {
                        let lastEditString = staticTimestampFormatter.string(from: lastEditDate)
                        Button {
                            Task {
                                do {
                                    let edits = try await APIService.shared.getHistory(forStatusID: fullPost.id, authenticationBox: authBox).value
                                    let editsViewModel = StatusEditHistoryViewModel(status: fullPost._legacyEntity, edits: edits, appContext: AppContext.shared, authenticationBox: authBox)
                                    viewModel.actionHandler?.presentScene(.editHistory(viewModel: editsViewModel), fromPost: nil, transition: .show)
                                } catch {
                                }
                            }
                        } label: {
                            HStack {
                                Text(L10n.Common.Controls.Status.Buttons.editHistoryDetail(lastEditString))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.borderless)
                    }
                    
                    // boosts and favorites
                    let boostCount = fullPost.content.metrics.boostCount
                    let favoriteCount = fullPost.content.metrics.favoriteCount
                    if boostCount > 0 {
                        Button {
                            let userListViewModel = UserListViewModel(
                                context: AppContext.shared,
                                authenticationBox: authBox,
                                kind: .rebloggedBy(status: MastodonStatus(entity: fullPost._legacyEntity, showDespiteContentWarning: false))
                            )
                            viewModel.actionHandler?.presentScene(.rebloggedBy(viewModel: userListViewModel), fromPost: nil, transition: .show)
                        } label: {
                            HStack {
                                Text(L10n.Plural.Count.reblog(boostCount))
                                    .foregroundStyle(.primary)
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.borderless)
                    }
                    if favoriteCount > 0 {
                        Button {
                            let userListViewModel = UserListViewModel(
                                context: AppContext.shared,
                                authenticationBox: authBox,
                                kind: .favoritedBy(status: MastodonStatus(entity: fullPost._legacyEntity, showDespiteContentWarning: false))
                            )
                            viewModel.actionHandler?.presentScene(.favoritedBy(viewModel: userListViewModel), fromPost: nil, transition: .show)
                        } label: {
                            HStack {
                                Text(L10n.Plural.Count.favorite(favoriteCount))
                                    .foregroundStyle(.primary)
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
        }
        .font(.footnote)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
    
    @ViewBuilder var contentConcealLozenge: some View {
        if let whenHiding = contentConcealModel.buttonText(whenHiding: true), let whenShowing = contentConcealModel.buttonText(whenHiding: false) {
            ShowMoreLozenge(buttonTextWhenHiding: whenHiding, buttonTextWhenShowing: whenShowing, viewModel: ShowMoreViewModel(isShowing: contentConcealModel.currentMode.isShowingContent, isFilter: contentConcealModel.currentModeIsFilter, reasons: contentConcealModel.currentMode.reasons ?? [], showMore: {
                show in
                if show {
                    contentConcealModel.showMore()
                } else {
                    contentConcealModel.hide()
                }
            }))
        }
    }
}

private struct ActionBar: View {
    
    @Environment(MastodonPostViewModel.self) private var viewModel
    let instanceCanQuotePosts: Bool
    
    var anyButtonHasNonZeroCount: Bool {
        guard let metrics = viewModel.fullPost?.actionablePost?.content.metrics else { return false }
        return metrics.boostCount + metrics.favoriteCount + metrics.replyCount > 0
    }

    var body: some View {
        ViewThatFits {
            HStack() {
                if let actionablePost = viewModel.fullPost?.actionablePost {
                    actionButton(forPost: actionablePost, action: .reply, layout: .adaptive)
                    Spacer()
                    actionButton(forPost: actionablePost, action: .boost, layout: .adaptive)
                    Spacer()
                    actionButton(forPost: actionablePost, action: .favourite, layout: .adaptive)
                    Spacer()
                    actionButton(forPost: actionablePost, action: .bookmark, layout: .adaptive)
                    Spacer()
                    ActionBarMenuButton(instanceCanQuotePosts: instanceCanQuotePosts)
                }
            }
            
            HStack() {
                if let actionablePost = viewModel.fullPost?.actionablePost {
                    actionButton(forPost: actionablePost, action: .reply, layout: .forceSmall)
                    Spacer()
                    actionButton(forPost: actionablePost, action: .boost, layout: .forceSmall)
                    Spacer()
                    actionButton(forPost: actionablePost, action: .favourite, layout: .forceSmall)
                    Spacer()
                    actionButton(forPost: actionablePost, action: .bookmark, layout: .forceSmall)
                    Spacer()
                    ActionBarMenuButton(instanceCanQuotePosts: instanceCanQuotePosts)
                }
            }
        }
    }
    
    struct ActionBarMenuButton: View {
        @Environment(MastodonPostViewModel.self) private var viewModel
        let instanceCanQuotePosts: Bool
        
        var body: some View {
            Menu {
                if let relationship = viewModel.myRelationshipToAuthor {
                    ForEach(submenus(forRelationshipToAuthor: relationship, isQuotingMe: viewModel.isQuotingMe, isShowingTranslation: viewModel.isShowingTranslation), id: \.self.id) { submenu in
                        ForEach(submenu.items, id: \.self) { menuAction in
                            if let actionablePost = viewModel.fullPost?.actionablePost {
                                Button(role: menuAction.isDestructive ? .destructive : nil) {
                                    
                                    viewModel.actionHandler?.doAction(menuAction, forPost: viewModel)
                                }
                                label: {
                                    Label(menuAction.labelText(username: actionablePost.metaData.author.displayInfo.displayName, postLanguage: actionablePost.content.language), systemImage: menuAction.iconSystemName)
                                }
                            }
                        }
                        Divider()
                    }
                }
            } label: {
                Label("", systemImage: "ellipsis")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 45)
                    .contentShape(Rectangle())
            }
        }
        
        func submenus(forRelationshipToAuthor relationship: MastodonAccount.Relationship, isQuotingMe: Bool,  isShowingTranslation: Bool?) -> [MastodonPostMenuAction.Submenu] {
            return MastodonPostMenuAction.menuItems(forPostBy: relationship, isQuotingMe: isQuotingMe, isShowingTranslation: isShowingTranslation)
        }
    }
    
    private func overrideState(for postAction: PostAction, of actionablePost: MastodonContentPost) -> AsyncBool? {
        switch (viewModel.isDoingAction, postAction) {
        case (nil, _):
            return nil
        case (.boost, .boost), (.favourite, .favourite), (.bookmark, .bookmark):
            return .settingToTrue
        case (.unboost, .boost), (.unfavourite, .favourite), (.unbookmark, .bookmark):
            return .settingToFalse
        default:
            return nil
        }
    }
    
    @ViewBuilder private func actionButton(forPost actionablePost: MastodonContentPost, action: PostAction, layout: StatefulCountedActionButton.LayoutSize) -> some View {
        let metrics = actionablePost.content.metrics
        let myActions = actionablePost.content.myActions
        let overrideState = overrideState(for: action, of: actionablePost)
        let showCountLabel = anyButtonHasNonZeroCount
        switch action {
        case .reply:
            StatefulCountedActionButton(type: .reply, layoutSize: layout, showCountLabel: showCountLabel, actionState: .init(count: metrics.replyCount, isSelected: .isFalse), doAction: {
                viewModel.actionHandler?.doAction(.reply, forPost: viewModel)
            })
        case .boost:
            let state = overrideState ?? AsyncBool.fromBool(myActions.boosted)
            let iHaveBoosted = {
                switch state {
                case .isFalse:
                    return false
                case .isTrue:
                    return true
                default:
                    return false
                }
            }()
            StatefulCountedActionButton(type: .boost, layoutSize: layout, showCountLabel: showCountLabel, actionState: .init(count: metrics.boostCount, isSelected: state), doAction: {
                guard actionablePost.isBoostable else { return }
                if instanceCanQuotePosts {
                    viewModel.actionHandler?.showSheet(.boostOrQuoteDialog(viewModel))
                } else {
                    if iHaveBoosted {
                        viewModel.actionHandler?.doAction(.unboost, forPost: viewModel)
                    } else {
                        viewModel.actionHandler?.doAction(.boost, forPost: viewModel)
                    }
                }
            })
            .opacity(actionablePost.isBoostable ? 1.0 : 0.3)
        case .favourite:
            let state = overrideState ?? AsyncBool.fromBool(myActions.favorited)
            StatefulCountedActionButton(type: .favourite, layoutSize: layout, showCountLabel: showCountLabel, actionState: .init(count: metrics.favoriteCount, isSelected: state), doAction: {
                switch state {
                case .isFalse:
                    viewModel.actionHandler?.doAction(.favourite, forPost: viewModel)
                case .isTrue:
                    viewModel.actionHandler?.doAction(.unfavourite, forPost: viewModel)
                default:
                    break
                }
            })
        case .bookmark:
            let state = overrideState ?? AsyncBool.fromBool(myActions.bookmarked)
            StatefulCountedActionButton(type: .bookmark, layoutSize: layout, showCountLabel: showCountLabel, actionState: .init(count: nil, isSelected: state), doAction: {
                switch state {
                case .isFalse:
                    viewModel.actionHandler?.doAction(.bookmark, forPost: viewModel)
                case .isTrue:
                    viewModel.actionHandler?.doAction(.unbookmark, forPost: viewModel)
                default:
                    break
                }
            })
        }
     }
}

extension ThreadedConversationModel.ThreadContext {
    var drawsLineAbove: Bool {
        switch self {
        case .focused(let connectedAbove, _):
            return connectedAbove
        case .rootWithChildBelow:
            return false
        case .fragmentBegin, .fragmentEnd, .fragmentContinuation:
            return true
        }
    }
    
    var drawsLineBelow: Bool {
        switch self {
        case .focused(_, let connectedBelow), .fragmentBegin(let connectedBelow):
            return connectedBelow
        case .rootWithChildBelow, .fragmentContinuation:
            return true
        case .fragmentEnd:
            return false
        }
    }
    
    var isContiguous: Bool {
        switch self {
        case .focused(let connectedAbove, let connectedBelow):
            return connectedAbove && connectedBelow
        case .rootWithChildBelow:
            return false
        case .fragmentBegin(let connectedBelow):
            return connectedBelow
        case .fragmentEnd:
            return false
        case .fragmentContinuation:
            return true
        }
    }
}

extension MastodonContentPost {
    
    @MainActor
    var isBoostable: Bool {
        let info = self.initialDisplayInfo(inContext: nil)
        switch info.actionableVisibility {
        case .mentionedOnly:
            return false
        case .followersOnly:
            return info.actionableAuthorId == AuthenticationServiceProvider.shared.currentActiveUser.value?.userID
        case .loudPublic, .quietPublic:
            return true
        }
    }
}
