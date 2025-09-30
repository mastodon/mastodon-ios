// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import MastodonSDK
import SwiftUI
import MastodonLocalization
import SDWebImageSwiftUI

struct EmbeddedPostView: View {
    @Environment(MastodonPostViewModel.self) private var viewModel
    @Environment(ContentConcealViewModel.self) private var contentConcealViewModel
    let layoutWidth: CGFloat
    let isSummary: Bool
    
    var body: some View {
        if viewModel.fullPost != nil {
            if !contentConcealViewModel.currentMode.isShowingContent {
                EmbeddedPostContentConcealedView()
            } else {
                EmbeddedPostContentDisplayedView(layoutWidth: layoutWidth, isSummary: isSummary) // TODO: add blur content option for blur filters and hide-media-only CWs
            }
        }
    }
}

@MainActor
@Observable class QuotedPostPlaceholderViewModel {
    let quote: MastodonQuotedPost
    let authorName: String?
    
    init(_ quote: MastodonQuotedPost, authorName: String?) {
        self.quote = quote
        self.authorName = authorName
    }
}

struct QuotedPostPlaceholderView: View {
    @Environment(QuotedPostPlaceholderViewModel.self) var viewModel
    @State var isPresentingLearnMore: Bool = false
    
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
            } else {
                Text("Quoted a post")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(standardPadding)
        .frame(maxWidth: .infinity)
        .background {
            MastodonSecondaryBackground(fillInDarkModeOnly: true)
        }
    }

    @ViewBuilder var hiddenQuoteExplainerView: some View {
        if let message = viewModel.quote.state.displayText {
            VStack {
                HStack {
                    Text(message)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    if viewModel.quote.state.learnMoreMessage != nil && !isPresentingLearnMore {
                        Text("Learn more")
                            .fontWeight(.semibold)
                    }
                }
                .foregroundStyle(.secondary)
                
                if isPresentingLearnMore, let message = viewModel.quote.state.learnMoreMessage {
                    Text(message)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .font(.footnote)
            .padding(standardPadding)
            .frame(maxWidth: .infinity)
            .background {
                MastodonSecondaryBackground(fillInDarkModeOnly: true)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if viewModel.quote.state.learnMoreMessage != nil {
                    isPresentingLearnMore = !isPresentingLearnMore
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityText ?? "")
        }
    }
    
    var accessibilityText: String? {
        let (shortExplanation, moreInfo) = (viewModel.quote.state.displayText, viewModel.quote.state.learnMoreMessage)
        if let shortExplanation, let moreInfo {
            return "\(shortExplanation). \(moreInfo)"
        }
        if let shortExplanation {
            return "\(shortExplanation)"
        }
        else {
            return nil
        }
    }
}

struct QuotedPostHiddenByFilterView: View {
    var body: some View {
        HStack {
            Text(L10n.Common.Controls.Status.Quote.hiddenByFilter)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(standardPadding)
        .frame(maxWidth: .infinity)
        .background {
            MastodonSecondaryBackground(fillInDarkModeOnly: true)
        }
    }
}

extension Mastodon.Entity.Quote.AcceptanceState {
    var displayText: String? {
        switch self {
        case .accepted:
            return nil
        case .pending:
            return L10n.Common.Controls.Status.Quote.pending
        case .revoked:
            return L10n.Common.Controls.Status.Quote.removedByAuthor
        default:
            return L10n.Common.Controls.Status.Quote.unavailable
        }
    }
    
    var learnMoreMessage: String? {
        switch self {
        case .pending:
            L10n.Common.Controls.Status.Quote.pendingExplanationMessage
        default:
            nil
        }
    }
}

struct EmbeddedPostContentDisplayedView: View {
    @Environment(MastodonPostViewModel.self) private var viewModel
    @Environment(TimestampUpdater.self) private var timestamper
    @Environment(ContentConcealViewModel.self) private var contentConcealViewModel
    @Environment(\.colorScheme) private var colorScheme
    let layoutWidth: CGFloat
    let isSummary: Bool
    
    let padding: CGFloat = 12
    
    var body: some View {
        let contentWidth = max(0, layoutWidth - padding * 2)
        HStack(spacing: 0) {
            VStack(alignment: .leading) {
                header
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(viewModel.a11yHeaderLabel)
                if viewModel.fullPost != nil {
                    viewModel.textContentView(isInlinePreview: true)
                        .font(.footnote)
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityElement(children: .combine)
                }
                if let attachmentInfo = viewModel.fullPost?.actionablePost?.content.attachment, let actionHandler = viewModel.actionHandler {
                    if isSummary {
                        if let iconName = attachmentInfo.iconName, let labelText = attachmentInfo.labelText {
                            HStack {
                                Image(systemName: iconName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: AvatarSize.tiny)
                                Text(labelText)
                            }
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                            .lineLimit(1)
                        }
                    } else {
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
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L10n.Common.Controls.Status.Quote.a11yLabel)
    }
    
    private let avatarShape = RoundedRectangle(cornerRadius: 4)
    
    @ViewBuilder var header: some View {
        HStack(spacing: 4) {
            if let url = viewModel.initialDisplayInfo.actionableAuthorStaticAvatar {
                WebImage(
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
                .frame(width: isSummary ? AvatarSize.tiny : AvatarSize.small, height: isSummary ? AvatarSize.tiny : AvatarSize.small)
                .accessibilityHidden(true)
            }
            VStack() {
                HStack(spacing: 0) {
                    authorDisplayName
                    if isSummary {
                        Spacer()
                            .frame(width: tinySpacing)
                        Text(viewModel.initialDisplayInfo.actionableAuthorHandle)
                            .foregroundStyle(.secondary)
                    } else {
                        Spacer(minLength: doublePadding)
                        Text(viewModel.initialDisplayInfo.actionableCreatedAt.localizedExtremelyAbbreviatedTimeElapsedUntil(now: timestamper.timestamp))
                            .foregroundStyle(.secondary)
                    }
                }
                if !isSummary {
                    HStack(spacing: 0) {
                        Text(viewModel.initialDisplayInfo.actionableAuthorHandle)
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                    }
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

struct EmbeddedPostContentConcealedView: View {
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

extension GenericMastodonPost.PostAttachment {
    var iconName: String? {
        switch self {
        case .media(let array):
            switch array.first?.type {
            case .image:
                switch array.count {
                case 0: return nil
                case 1: return "photo"
                case 2: return "photo.on.rectangle"
                default: return "photo.stack"
                }
            case .audio:
                return "speaker.wave.2"
            case .gifv, .video:
                return "play.tv"
            default:
                switch array.count {
                case 0: return nil
                case 1:
                    return "rectangle"
                case 2:
                    return "rectangle.on.rectangle"
                default:
                    return "rectangle.stack"
                }
            }
        case .poll:
            return "chart.bar.yaxis"
        case .linkPreviewCard:
            return nil
        }
    }

    var labelText: String? {
        switch self {
        case .media(let array):
            switch array.first?.type {
            case .image:
                return L10n.Plural.Count.image(array.count)
            case .audio:
                return L10n.Plural.Count.audio(array.count)
            case .gifv:
                return L10n.Plural.Count.gif(array.count)
            case .video:
                return L10n.Plural.Count.video(array.count)
            default:
                return L10n.Plural.Count.attachment(array.count)
            }
        case .poll:
            return L10n.Plural.Count.poll(1)
        case .linkPreviewCard:
            return nil
        }
    }
}
