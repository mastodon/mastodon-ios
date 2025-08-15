// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonSDK
import MastodonCore

@MainActor
@Observable class MastodonPostViewModel {
    
    var quotedPostViewModel: QuotedPostViewModel?
    
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
        if let potentialQuotePost = fullPost?.actionablePost as? MastodonBasicPost, let quoted = potentialQuotePost.quotedPost {
            self.quotedPostViewModel = QuotedPostViewModel(quoted, filterContext: self.filterContext, myAccountID: "", myDomain: "", navigateToStatus: {  // TODO: fill in accountID and domain
                // TODO: use the actionHandler to accomplish this
            })
        }
    }
    
    var myRelationshipToAuthor: MastodonAccount.Relationship? = nil

    var displayPrepStatus: DisplayPrepStatus = .unprepared
    var isShowingTranslation: Bool? = nil
    var isDoingAction: MastodonPostMenuAction? = nil
    
    var actionHandler: MastodonPostMenuActionHandler? = nil
    let timestamper: TimestampUpdater = TimestampUpdater.timestamper(withInterval: 30)
    let filterContext: Mastodon.Entity.FilterContext
    
    private(set) var translation: Mastodon.Entity.Translation? = nil
    
    nonisolated
    init(_ initialDisplay: GenericMastodonPost.InitialDisplayInfo, context: Mastodon.Entity.FilterContext) {
        self.initialDisplayInfo = initialDisplay
        self.filterContext = context
    }
    
    private init(_ initialDisplay: GenericMastodonPost.InitialDisplayInfo, fullPost: GenericMastodonPost? = nil, isShowingTranslation: Bool? = nil, isDoingAction: MastodonPostMenuAction? = nil, myRelationshipToAuthor: MastodonAccount.Relationship? = nil, actionHandler: MastodonPostMenuActionHandler? = nil, translation: Mastodon.Entity.Translation? = nil, filterContext: Mastodon.Entity.FilterContext) {
        self.initialDisplayInfo = initialDisplay
        self.fullPost = fullPost
        self.filterContext = filterContext
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
        guard let myRelationshipToAuthor else { return }
        switch myRelationshipToAuthor {
        case .isMe:
            let profile: ProfileViewController.ProfileType = .me(account._legacyEntity)
            actionHandler?.presentScene(.profile(profile), fromPost: initialDisplayInfo.id, transition: .show)
        case .isNotMe(let info):
            if let info, let me = AuthenticationServiceProvider.shared.currentActiveUser.value?.cachedAccount {
                let profile: ProfileViewController.ProfileType = .notMe(me: me, displayAccount: account._legacyEntity, relationship: info._legacyEntity)
                actionHandler?.presentScene(.profile(profile), fromPost: initialDisplayInfo.id, transition: .show)
            }
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

fileprivate extension MastodonPostViewModel {
    
    var socialContextHeader: SocialContextHeader? {
        guard let fullPost else { return nil }
        if fullPost is MastodonBoostPost {
            // BOOSTED BY
            return .boosted(by: fullPost.metaData.author.displayInfo.displayName, emojis: fullPost.metaData.author.displayInfo.emojis)
        } else if let basicPost = fullPost as? MastodonBasicPost {
            // REPLIED and/or PRIVATE MENTION
            let isPrivate = basicPost.metaData.privacyLevel == .mentionedOnly
            let replyInfo = basicPost.inReplyTo
            if let replyInfo {
                let replyToAccount = actionHandler?.account(replyInfo.accountID)
                return .reply(to: replyToAccount?.displayInfo.displayName ?? "unknown", isPrivate: isPrivate, isNotification: false, emojis: replyToAccount?.displayInfo.emojis ?? [])
            } else if isPrivate {
                return .mention(isPrivate: true)
            }
        }
        return nil
    }

    func textContentView() -> MastodonContentView {
        let emptyTextContent: MastodonContentView = .timelinePost(heightCacheID: "empty", html: "", emojis: MastodonContentView.Emojis(), isInlinePreview: false)
        
        guard let actionablePost = fullPost?.actionablePost, let untranslatedContent = actionablePost.content.htmlWithEntities?.html else { return emptyTextContent }
        let emojis = actionablePost.content.htmlWithEntities?.emojis ?? MastodonContentView.Emojis()
        
        if isShowingTranslation == true, let translation = actionHandler?.translation(forContentPostId: actionablePost.id)?.content {
            return .timelinePost(heightCacheID: actionablePost.id+"translated", html: translation, emojis: emojis, isInlinePreview: false)
        } else {
            return .timelinePost(heightCacheID: actionablePost.id, html: untranslatedContent, emojis: emojis, isInlinePreview: false)
        }
    }
}

struct HomeTimelinePostRowView: View {

    @Environment(MastodonPostViewModel.self) private var viewModel
    @Environment(ContentConcealViewModel.self) private var contentConcealModel

    let contentWidth: CGFloat
    
    let distanceFromAvatarLeadingEdgeToContentLeadingEdge: CGFloat = spacingBetweenGutterAndContent + AvatarSize.large
    
    var body: some View {
        let actionablePost = viewModel.fullPost?.actionablePost
        let author = actionablePost?.metaData.author ?? viewModel.fullPost?.metaData.author
        
        VStack(alignment: .gutterAlign, spacing: tinySpacing) {
            
            viewModel.socialContextHeader
            
            HStack(alignment: .top) {
            
                AvatarView(size: .large, authorAvatarUrl: author?.avatarURL ?? viewModel.initialDisplayInfo.actionableAuthorStaticAvatar, goToProfile: {
                    goToProfile(author)
                })
                
                VStack(spacing: spacingBetweenGutterAndContent) {
                    AuthorHeaderView(timestamper: viewModel.timestamper)
                    
                    contentConcealLozenge
                        .frame(width: contentWidth)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if contentConcealModel.currentMode.isShowingContent, let actionHandler = viewModel.actionHandler {
                        if viewModel.isShowingTranslation == true, let translatablePost = viewModel.fullPost?.actionablePost, let translation = actionHandler.translation(forContentPostId: translatablePost.id) {
                            TranslationInfoView(translationInfo: translation, showOriginal: { actionHandler.doAction(.showOriginalLanguage, forPost: translatablePost) }
                            )
                            .frame(width: contentWidth, alignment: .leading)
                        }
                        viewModel.textContentView()
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
                        
                        if let quotedPostViewModel = viewModel.quotedPostViewModel {
                            QuotedPostView()
                                .environment(quotedPostViewModel)
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
                    
                    if let actionablePost = viewModel.fullPost?.actionablePost {
                        Spacer()
                            .frame(height: 0)  // gives double spacing between bottom of post content and action bar
                        ActionBar()
                            .frame(width: contentWidth, alignment: .leading)
                    }
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
    }
    
    func goToProfile(_ account: MastodonAccount?) {
        guard let account else { return }
        viewModel.goToProfile(account)
    }
}

extension HomeTimelinePostRowView {
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

    var body: some View {
        HStack() {
            if let actionablePost = viewModel.fullPost?.actionablePost {
                actionButton(forPost: actionablePost, action: .reply)
                Spacer()
                actionButton(forPost: actionablePost, action: .boost)
                Spacer()
                actionButton(forPost: actionablePost, action: .favourite)
                Spacer()
                actionButton(forPost: actionablePost, action: .bookmark)
                Spacer()
                ActionBarMenuButton()
                Spacer()
            }
        }
    }
    
    struct ActionBarMenuButton: View {
        @Environment(MastodonPostViewModel.self) private var viewModel
        
        var body: some View {
            Menu {
                if let relationship = viewModel.myRelationshipToAuthor {
                    ForEach(submenus(forRelationshipToAuthor: relationship, isShowingTranslation: viewModel.isShowingTranslation), id: \.self.id) { submenu in
                        ForEach(submenu.items, id: \.self) { menuAction in
                            if let actionablePost = viewModel.fullPost?.actionablePost {
                                Button(role: menuAction.isDestructive ? .destructive : nil) {
                                    
                                    viewModel.actionHandler?.doAction(menuAction, forPost: actionablePost)
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
            }
        }
        
        func submenus(forRelationshipToAuthor relationship: MastodonAccount.Relationship, isShowingTranslation: Bool?) -> [MastodonPostMenuAction.Submenu] {
            return MastodonPostMenuAction.menuItems(forPostBy: relationship, isShowingTranslation: isShowingTranslation)
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
    
    private func actionButton(forPost actionablePost: MastodonContentPost, action: PostAction) -> StatefulCountedActionButton {
        let metrics = actionablePost.content.metrics
        let myActions = actionablePost.content.myActions
        let overrideState = overrideState(for: .reply, of: actionablePost)
        switch action {
        case .reply:
            let state = overrideState ?? AsyncBool.fromBool(myActions.boosted)
            return StatefulCountedActionButton(type: .reply, actionState: .init(count: metrics.replyCount, isSelected: state), doAction: {
                switch state {
                case .isFalse:
                    viewModel.actionHandler?.doAction(.reply, forPost: actionablePost)
                default:
                    break
                }
            })
        case .boost:
            let state = overrideState ?? AsyncBool.fromBool(myActions.boosted)
            return StatefulCountedActionButton(type: .boost, actionState: .init(count: metrics.boostCount, isSelected: state), doAction: {
                switch state {
                case .isFalse:
                    viewModel.actionHandler?.doAction(.boost, forPost: actionablePost)
                case .isTrue:
                    viewModel.actionHandler?.doAction(.unboost, forPost: actionablePost)
                default:
                    break
                }
            })
        case .favourite:
            let state = overrideState ?? AsyncBool.fromBool(myActions.favorited)
            return StatefulCountedActionButton(type: .favourite, actionState: .init(count: metrics.favoriteCount, isSelected: state), doAction: {
                switch state {
                case .isFalse:
                    viewModel.actionHandler?.doAction(.favourite, forPost: actionablePost)
                case .isTrue:
                    viewModel.actionHandler?.doAction(.unfavourite, forPost: actionablePost)
                default:
                    break
                }
            })
        case .bookmark:
            let state = overrideState ?? AsyncBool.fromBool(myActions.bookmarked)
            return StatefulCountedActionButton(type: .bookmark, actionState: .init(count: nil, isSelected: state), doAction: {
                switch state {
                case .isFalse:
                    viewModel.actionHandler?.doAction(.bookmark, forPost: actionablePost)
                case .isTrue:
                    viewModel.actionHandler?.doAction(.unbookmark, forPost: actionablePost)
                default:
                    break
                }
            })
        }
     }
}
