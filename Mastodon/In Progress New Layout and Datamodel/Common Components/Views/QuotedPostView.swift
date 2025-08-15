// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import MastodonSDK
import SwiftUI

struct FullQuotedPostView: View {
    @Environment(MastodonPostViewModel.self) private var viewModel
    @Environment(ContentConcealViewModel.self) private var contentConcealViewModel
    let layoutWidth: CGFloat
    
    var body: some View {
        if viewModel.fullPost != nil {
            if !contentConcealViewModel.currentMode.isShowingContent {
                QuotedPostContentConcealedView()
            } else {
                QuotedPostContentDisplayedView(layoutWidth: layoutWidth) // TODO: add blur content option for blur filters and hide-media-only CWs
            }
        }
    }
}

@MainActor
@Observable class QuotedPostPlaceholderViewModel {
    let quote: MastodonQuotedPost
    let authorName: String?
    var showOverlayTip: String? = nil
    
    init(_ quote: MastodonQuotedPost, authorName: String?) {
        self.quote = quote
        self.authorName = authorName
    }
}

struct QuotedPostPlaceholderView: View {
    @Environment(QuotedPostPlaceholderViewModel.self) var viewModel
    
    var body: some View {
        switch viewModel.quote.state {
        case .accepted:
            nestedQuotePlaceholder
        default:
            hiddenQuoteExplainerView
        }
    }
        
    @ViewBuilder var nestedQuotePlaceholder: some View {
        HStack {
            if let authorName = viewModel.authorName {
                Text("Quoted a post by \(authorName)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .background {
                        MastodonSecondaryBackground(fillInDarkModeOnly: true)
                    }
            } else {
                Text("Quoted a post")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .background {
                        MastodonSecondaryBackground(fillInDarkModeOnly: true)
                    }
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder var hiddenQuoteExplainerView: some View {
        if let message = viewModel.quote.state.displayText {
            HStack {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                if viewModel.quote.state.learnMoreMessage != nil {
                    Text("Learn more")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(standardPadding)
            .frame(maxWidth: .infinity)
            .background {
                MastodonSecondaryBackground(fillInDarkModeOnly: true)
            }
            .onTapGesture {
                if let additionalInfo = viewModel.quote.state.learnMoreMessage {
                    viewModel.showOverlayTip = additionalInfo
                }
            }
        }
    }
}

extension Mastodon.Entity.Quote.AcceptanceState {
    var displayText: String? {
        switch self {
        case .accepted:
            return nil
        case .pending:
            return "Post pending"
        case .revoked:
            return "Post removed by author"
        default:
            return "Post unavailable"
        }
    }
    
    var learnMoreMessage: String? {
        switch self {
        case .pending:
            "On Mastodon, you can control whether someone can quote you. This post is pending while we’re getting the original author’s approval."
        default:
            nil
        }
    }
}

struct QuotedPostContentDisplayedView: View {
    @Environment(MastodonPostViewModel.self) private var viewModel
    @Environment(ContentConcealViewModel.self) private var contentConcealViewModel
    @Environment(\.colorScheme) private var colorScheme
    let layoutWidth: CGFloat
    
    let padding: CGFloat = 12
    
    var body: some View {
        let contentWidth = layoutWidth - padding * 2
        HStack(spacing: 0) {
            VStack(alignment: .leading) {
                header()
                if viewModel.fullPost != nil {
                    viewModel.textContentView(isInlinePreview: true)
                        .font(.footnote)
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let attachmentInfo = viewModel.fullPost?.actionablePost?.content.attachment, let actionHandler = viewModel.actionHandler {
                    switch attachmentInfo {
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
                if let potentialQuotePost = viewModel.fullPost as? MastodonBasicPost, let furtherNestedQuote = potentialQuotePost.quotedPost {
                    QuotedPostPlaceholderView()
                        .environment(QuotedPostPlaceholderViewModel(furtherNestedQuote, authorName: nil))  // TODO: add author name
                }
            }
            Spacer(minLength: 0) // This pushes the VStack all the way to the left.
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(padding)
        .frame(maxWidth: .infinity)
        .background {
            MastodonSecondaryBackground(fillInDarkModeOnly: true)
        }
    }
    
    private let avatarShape = RoundedRectangle(cornerRadius: 4)
    
    @ViewBuilder func header() -> some View {
        HStack(spacing: 4) {
            if let url = viewModel.initialDisplayInfo.actionableAuthorStaticAvatar {
                AsyncImage(
                    url: url,
                    content: { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(avatarShape)
                    },
                    placeholder: {
                        avatarShape
                            .foregroundStyle(
                                Color(UIColor.secondarySystemFill))
                    }
                )
                .frame(width: AvatarSize.small, height: AvatarSize.small)
            }
            VStack() {
                HStack(spacing: 0) {
                    authorDisplayName
                    Spacer(minLength: doublePadding)
                    Text(viewModel.initialDisplayInfo.actionableCreatedAt.localizedExtremelyAbbreviatedTimeElapsedUntil(now: viewModel.timestamper.timestamp))
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 0) {
                    Text(viewModel.initialDisplayInfo.actionableAuthorHandle)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                }
            }
            .font(.caption)
        }
        .lineLimit(1)
        .font(.subheadline)
    }
    
    @ViewBuilder var authorDisplayName: some View {
        if let actionablePost = viewModel.fullPost?.actionablePost {
            let author = actionablePost.metaData.author
            MastodonContentView.header(html: author.displayInfo.displayName, emojis: author.displayInfo.emojis, style: .author(isInlinePreview: true))
        } else {
            EmptyView()
        }
    }
}

struct QuotedPostContentConcealedView: View {
    @Environment(ContentConcealViewModel.self) private var viewModel

    var body: some View {
        switch viewModel.currentMode {
        case .concealAll(let reasons, _):
            if let buttonTextWhenHiding = viewModel.buttonText(whenHiding: true), let buttonTextWhenShowing = viewModel.buttonText(whenHiding: false) {
                ShowMoreLozenge(buttonTextWhenHiding: buttonTextWhenHiding, buttonTextWhenShowing: buttonTextWhenShowing, viewModel: ShowMoreViewModel(isShowing: false, isFilter: viewModel.currentModeIsFilter, reasons: reasons, showMore: { show in
                    if show {
                        viewModel.showMore()
                    } else {
                        viewModel.hide()
                    }
                }))
            }
        default:
            EmptyView()
        }
    }
}
