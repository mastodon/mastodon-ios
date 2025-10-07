// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonAsset
import MastodonSDK
import MastodonCore
import MastodonLocalization

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
                                    .environment(contentConcealModel.nestedContentConcealModel ?? .alwaysShow)
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
                    .frame(minWidth: 45, minHeight: 45)
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
