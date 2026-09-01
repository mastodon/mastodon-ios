// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonAsset
import MastodonSDK
import MastodonUI
import MastodonCore
import MastodonLocalization

struct MastodonPostRowView: View {
    @Environment(MastodonNavigationRouter.self) private var navigator
    @Environment(MastodonPostViewModel.self) private var viewModel
    @Environment(ContentConcealViewModel.self) private var contentConcealModel

    let contentWidth: CGFloat
    let precalculatedHeight: CGFloat?
    let isPinned: Bool
    let actionHandler: MastodonPostMenuActionHandler?
    let threadedContext: ThreadedConversationModel.ThreadContext?
    let filterContext: Mastodon.Entity.FilterContext?
    
    let distanceFromAvatarLeadingEdgeToContentLeadingEdge: CGFloat = spacingBetweenGutterAndContent + AvatarSize.large
    
    var body: some View {
        let actionablePost = viewModel.fullPost?.actionablePost
        let author = actionablePost?.metaData.author ?? viewModel.fullPost?.metaData.author
        let instanceCanQuotePosts = AuthenticationServiceProvider.shared.currentActiveUser.value?.authentication.instanceConfiguration?.isAvailable(.quotePosts) ?? false
        
        VStack(alignment: .gutterAlign, spacing: 0) {  // gutterAlign keeps the content and social context headers properly aligned with the gap between avatar and content
            if let threadedContext {
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
                        viewModel.socialContextHeader(inThreadContext: threadedContext, getAccount: { accountID in actionHandler?.account(accountID) })
                            .frame(maxWidth: contentWidth, alignment: .leading)
                    }
                }
                .accessibilityHidden(true)
            } else {
                // MARK: Social context header
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: standardPadding)
                    viewModel.socialContextHeader(inThreadContext: threadedContext, getAccount: { accountID in actionHandler?.account(accountID) })
                        .frame(maxWidth: contentWidth, alignment: .leading)
                }
                .accessibilityHidden(true)
            }
            
            HStack(alignment: .top, spacing: spacingBetweenGutterAndContent) {
                // MARK: Avatar
                VStack(spacing: 0) {
                    AvatarView(style: .roundedRect, size: .large, avatarSource: .url(author?.avatarURL ?? viewModel.initialDisplayInfo.actionableAuthorStaticAvatar))
                        .onAsyncTap {
                            if let author {
                                navigator.push(.profile(account: author._legacyEntity, relationship: viewModel.myRelationshipToAuthor))
                            }
                        } onError: { error in
                            navigator.didReceiveError(error)
                        }

                    if let threadedContext, threadedContext.drawsLineBelow {
                        let lowerThreadDecorationHeight: CGFloat? = {
                            if let precalculatedHeight {
                                return precalculatedHeight - standardPadding - AvatarSize.large
                            } else {
                                return nil
                            }
                        }()
                        threadingDecoration(withSpacerAtTop: !threadedContext.isContiguous, withSpacerAtBottom: false)
                            .frame(width: AvatarSize.large, height: lowerThreadDecorationHeight)
                    }
                }
                .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: spacingBetweenGutterAndContent) {
                    // MARK: Author info
                    AuthorHeaderView(threadedContext: threadedContext, isPinned: isPinned, getAccount: { accountID in actionHandler?.account(accountID) })
                        .onTapGesture {
                            goToProfile(author)
                        }
#if DEBUG
                    Text(viewModel.initialDisplayInfo.id)
                        .font(.footnote)
                        .border(.red)
                    if viewModel.initialDisplayInfo.id != viewModel.initialDisplayInfo.actionablePostID {
                        Text("actionable: \(viewModel.initialDisplayInfo.actionablePostID)")
                            .font(.footnote)
                            .border(.red)
                    }
#endif
                   
                    // MARK: Content warned and/or filtered
                    contentConcealLozenge
                        .frame(width: contentWidth)
                        .fixedSize(horizontal: false, vertical: true)
                    if contentConcealModel.currentMode.isShowingContent {
                        MastodonPostContentStackView(contentWidth: contentWidth, actionHandler: actionHandler, navigator: navigator, filterContext: filterContext)
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
                    if viewModel.displayType == .standard, let actionablePost = viewModel.fullPost?.actionablePost {
                        Spacer()
                            .frame(height: 0)  // gives double spacing between bottom of post content and action bar
                        ActionBar(instanceCanQuotePosts: instanceCanQuotePosts, actionHandler: actionHandler)
                            .frame(width: contentWidth, alignment: .leading)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(viewModel.accessibilityActionBarLabel)
                    }
                    
                    // MARK: Thread view extra info for focused post
                    switch threadedContext {
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
                    viewModel.accessibilityActionButton(action, actionHandler: actionHandler, navigator: navigator)
                }
                
                // REPLY
                viewModel.accessibilityActionButton(.reply, actionHandler: actionHandler, navigator: navigator)
                
                // QUOTE
                if instanceCanQuotePosts {
                    let (buttonTitle, buttonSubtitle, isEnabled) = viewModel.currentUserQuoteButton
                    let fullTitle = [buttonTitle, buttonSubtitle].compactMap { $0 }.joined(separator: ", ")
                    Button(fullTitle) {
                        if isEnabled {
                            guard let composeViewModel = viewModel.composeViewModelQuotingThisPost else { return }
                            navigator.presentSheet(.modalCompose(composeViewModel, nil), afterDeconflictionDelay: false)
                        }
                    }
                }
                
                // POST ACTIONS
                ForEach(MastodonPostMenuAction.postA11yMenuItemsOtherThanReply(forPostBy: relationshipToAuthor, myActions: viewModel.fullPost?.actionablePost?.content.myActions, isShowingTranslation: viewModel.isShowingTranslation), id: \.self.id) { action in
                    viewModel.accessibilityActionButton(action, actionHandler: actionHandler, navigator: navigator)
                }
            }
        }
    }
    
    func goToProfile(_ account: MastodonAccount?) {
        guard let account else { return }
        viewModel.goToProfile(account, navigator: navigator)
    }
}

extension MastodonPostViewModel {
    func a11yHeaderLabel(inThreadedContext threadedContext: ThreadedConversationModel.ThreadContext?, getAccount: (Mastodon.Entity.Account.ID)->(MastodonAccount?)) -> String {
        let visibilityString = initialDisplayInfo.actionableVisibility.a11yLabel
        let dateString = initialDisplayInfo.actionableCreatedAt.localizedShortTimeAgo(since: .now)
        let authorString = "\(visibilityString) post from \(initialDisplayInfo.actionableAuthorDisplayName)" + ", \(dateString)"
        if let socialContext = socialContext(inThreadContext: threadedContext, getAccount: getAccount) {
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
                            navigator.push(.timeline(.postHistory(fullPost)))
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
                            guard let statusID = fullPost.actionablePost?.id else { return }
                            navigator.push(.timeline(.whoBoosted(actionableStatusID: statusID)))
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
                            guard let statusID = fullPost.actionablePost?.id else { return }
                            navigator.push(.timeline(.whoFavourited(actionableStatusID: statusID)))
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

struct MastodonPostContentStackView: View {
    @Environment(MastodonPostViewModel.self) var viewModel
    @Environment(ContentConcealViewModel.self) var contentConcealModel
    
    let contentWidth: CGFloat
    let actionHandler: MastodonPostMenuActionHandler?
    let navigator: MastodonNavigationRouter?
    let filterContext: Mastodon.Entity.FilterContext?
    
    var linkTapPolicy: LinkTapPolicy {
        guard let navigator else { return .inert }
        return .navigate(navigator, viewModel)
    }
    
    func linkTapPolicy(forQuotedPost quotedViewModel: MastodonPostViewModel) -> LinkTapPolicy {
        guard let navigator else { return .inert }
        return .navigate(navigator, quotedViewModel)
    }
    
    var body: some View {
        if viewModel.isShowingTranslation == true, let translatablePost = viewModel.fullPost?.actionablePost, let translation = actionHandler?.translation(forContentPostId: translatablePost.id) {
            // MARK: Translation info line
            TranslationInfoView(translationInfo: translation, showOriginal: {
                if let actionHandler, let navigator { actionHandler.doAction(.showOriginalLanguage, forPost: viewModel, navigator: navigator)
                }
            })
            .frame(width: contentWidth, alignment: .leading)
        }
        
        // MARK: Text content
        viewModel.textContentView(isInlinePreview: false, actionHandler: actionHandler)
            .frame(width: contentWidth, alignment: .leading)
            .environment(\.openURL, OpenURLAction { url in
                return linkTapPolicy.openUrlResult(url)
            })
            .accessibilityElement(children: .combine)
        
        // MARK: Media attachment
        if let attachment = viewModel.fullPost?.actionablePost?.content.attachment {
            switch attachment {
            case .media(let array):
                MediaAttachmentView(
                    mediaAttachment: MediaAttachment(array, altTextTranslations: viewModel.altTextTranslations),
                    containerOverlayBinding:
                        actionHandler?.containerOverlayBinding,
                    linkTapPolicy: linkTapPolicy)
                .frame(width: contentWidth)
            case .pollOptions(let pollEdit):
                let options = pollEdit.options.enumerated().map { (index, option) in
                    PollViewModel.Option(index: index, text: option.title, emojis: (viewModel.fullPost as? MastodonContentPost)?.content.htmlWithEntities?.emojis ?? [])
                }
                PollOptionsView(options: options, contentWidth: contentWidth)
            case .poll(let poll):
                let emojis = viewModel.fullPost?.actionablePost?.content.htmlWithEntities?.emojis
                PollView(viewModel: PollViewModel(pollEntity: poll, emojis: emojis, optionTranslations: viewModel.isShowingTranslation == true ? viewModel.pollOptionTranslations : nil, containingPostID: viewModel.initialDisplayInfo.actionablePostID, actionHandler: actionHandler), contentWidth: contentWidth)
                    .frame(width: contentWidth)
            case .linkPreviewCard(let card):
                if viewModel.collectionViewModel == nil { // do not show both a link preview and a collection preview
                    LinkPreviewCard(cardEntity: card, fittingWidth: contentWidth, accountLinkHandler: navigator, linkTapPolicy: linkTapPolicy)
                        .frame(width: contentWidth)
                }
            }
        }
        
        // MARK: Quoted post
        if let quotedPostViewModel = viewModel.fullQuotedPostViewModel {
            if let filterContext, quotedPostViewModel.initialDisplayInfo.filterOutInContexts.contains(filterContext) {
                QuotedPostHiddenByFilterView()
            } else {
                EmbeddedPostView(layoutWidth: contentWidth, isSummary: false, actionHandler: actionHandler, accountLinkHandler: navigator, linkTapPolicy: linkTapPolicy(forQuotedPost: quotedPostViewModel))
                    .environment(quotedPostViewModel)
                    .environment(contentConcealModel.nestedContentConcealModel ?? .alwaysShow)
                    .onTapGesture {
                        if let navigator {
                            quotedPostViewModel.openThreadView(navigator: navigator)
                        }
                    }
                    .allowsHitTesting(navigator != nil)
            }
        } else if let quotePlaceholder = viewModel.placeholderQuotedPost {
            QuotedPostPlaceholderView()
                .environment(QuotedPostPlaceholderViewModel(quotePlaceholder, authorName: nil))  // TODO: include author name if possible (will have to fetch from server)
        }
        
        // MARK: Tagged collections
        if let collectionViewModel = viewModel.collectionViewModel {
            EmbeddedCollectionView(layoutWidth: contentWidth, isSummary: true, actionHandler: actionHandler)
                .environment(collectionViewModel)
                .onTapGesture {
                    navigator?.push(.timeline(.collection(collectionViewModel)))
                }
                .allowsHitTesting(navigator != nil)
        }
    }
}

private struct ActionBar: View {
    @Environment(MastodonNavigationRouter.self) private var navigator
    @Environment(MastodonPostViewModel.self) private var viewModel
    let instanceCanQuotePosts: Bool
    let actionHandler: MastodonPostMenuActionHandler?
    
    var anyButtonHasNonZeroCount: Bool {
        guard let metrics = viewModel.fullPost?.actionablePost?.content.metrics else { return false }
        return metrics.boostCount + metrics.favoriteCount + metrics.replyCount > 0
    }

    var body: some View {
        ViewThatFits {
            HStack() {
                if let actionablePost = viewModel.fullPost?.actionablePost {
                    ForEach([PostAction.reply, .boost, .favourite, .bookmark], id: \.self) { action in
                        actionButton(forPost: actionablePost, action: action, layout: .adaptive)
                        Spacer()
                    }
                    ActionBarMenuButton(instanceCanQuotePosts: instanceCanQuotePosts, actionHandler: actionHandler)
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
                    ActionBarMenuButton(instanceCanQuotePosts: instanceCanQuotePosts, actionHandler: actionHandler)
                }
            }
        }
    }
    
    struct ActionBarMenuButton: View {
        @Environment(MastodonNavigationRouter.self) private var navigator
        @Environment(MastodonPostViewModel.self) private var viewModel
        let instanceCanQuotePosts: Bool
        let actionHandler: MastodonPostMenuActionHandler?
        
        var body: some View {
            Menu {
                if let relationship = viewModel.myRelationshipToAuthor {
                    ForEach(submenus(forRelationshipToAuthor: relationship, isQuotingMe: viewModel.isQuotingMe, isShowingTranslation: viewModel.isShowingTranslation), id: \.self.id) { submenu in
                        ForEach(submenu.items, id: \.self) { menuAction in
                            if let actionablePost = viewModel.fullPost?.actionablePost {
                                switch menuAction {
                                case .sharePost:
                                    let urlString = actionablePost.metaData.url ?? actionablePost.metaData.uriForFediverse
                                    if let url = URL(string: urlString) {
                                        ShareLink(item: url) {
                                            menuActionLabel(menuAction, forPost: actionablePost)
                                        }
                                    }
                                default:
                                    Button(role: menuAction.isDestructive ? .destructive : nil) {
                                        actionHandler?.doAction(menuAction, forPost: viewModel, navigator: navigator)
                                    }
                                    label: {
                                        menuActionLabel(menuAction, forPost: actionablePost)
                                    }
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
                    .frame(minWidth: 45, minHeight: 45)
                    .contentShape(Rectangle())
            }
        }
        
        @ViewBuilder func menuActionLabel(_ menuAction: MastodonPostMenuAction, forPost actionablePost: MastodonContentPost) -> some View {
            Label(menuAction.labelText(username: actionablePost.metaData.author.displayInfo.displayName, postLanguage: actionablePost.content.language), systemImage: menuAction.iconSystemName)
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
                actionHandler?.doAction(.reply, forPost: viewModel, navigator: navigator)
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
                    navigator.presentedSheet = .timelineSheet(.boostOrQuoteDialog(viewModel))
                } else {
                    if iHaveBoosted {
                        actionHandler?.doAction(.unboost, forPost: viewModel, navigator: navigator)
                    } else {
                        actionHandler?.doAction(.boost, forPost: viewModel, navigator: navigator)
                    }
                }
            })
            .opacity(actionablePost.isBoostable ? 1.0 : 0.3)
        case .favourite:
            let state = overrideState ?? AsyncBool.fromBool(myActions.favorited)
            StatefulCountedActionButton(type: .favourite, layoutSize: layout, showCountLabel: showCountLabel, actionState: .init(count: metrics.favoriteCount, isSelected: state), doAction: {
                switch state {
                case .isFalse:
                    actionHandler?.doAction(.favourite, forPost: viewModel, navigator: navigator)
                case .isTrue:
                    actionHandler?.doAction(.unfavourite, forPost: viewModel, navigator: navigator)
                default:
                    break
                }
            })
        case .bookmark:
            let state = overrideState ?? AsyncBool.fromBool(myActions.bookmarked)
            StatefulCountedActionButton(type: .bookmark, layoutSize: layout, showCountLabel: showCountLabel, actionState: .init(count: nil, isSelected: state), doAction: {
                switch state {
                case .isFalse:
                    actionHandler?.doAction(.bookmark, forPost: viewModel, navigator: navigator)
                case .isTrue:
                    actionHandler?.doAction(.unbookmark, forPost: viewModel, navigator: navigator)
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
        let info = self.initialDisplayInfo()
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
