// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import MastodonSDK
import SwiftUI

@MainActor
@Observable
class QuotedPostViewModel {
    let quote: MastodonQuotedPost
    let myAccountID: String
    let myDomain: String
    let navigateToStatus: ()->()
    var contentConcealViewModel: ContentConcealViewModel?
    
    var showOverlayTip: String? = nil
    
    init(_ quote: MastodonQuotedPost, filterContext: Mastodon.Entity.FilterContext?, myAccountID: String, myDomain: String, navigateToStatus: @escaping ()->()) {
        self.quote = quote
        if let fullPost = quote.fullPost {
            contentConcealViewModel = ContentConcealViewModel(contentPost: fullPost, context: filterContext)
        } else {
            contentConcealViewModel = nil
        }
        self.myAccountID = myAccountID
        self.myDomain = myDomain
        self.navigateToStatus = navigateToStatus
    }
}

struct QuotedPostView: View {
    @Environment(QuotedPostViewModel.self) private var viewModel
    
    var body: some View {
        if let fullPost = viewModel.quote.fullPost {
            if let contentConcealModel = viewModel.contentConcealViewModel, !contentConcealModel.currentMode.isShowingContent {
                QuotedPostContentConcealedView()
            } else {
                let postViewModel = fullPost._legacyEntity.viewModel(myAccountID: viewModel.myAccountID, myDomain: viewModel.myDomain, navigateToStatus: viewModel.navigateToStatus)
                QuotedPostContentDisplayedView(viewModel: postViewModel) // TODO: add blur content option for blur filters and hide-media-only CWs
            }
        } else {
            switch viewModel.quote.state {
            case .accepted:
                nestedQuotePlaceholder
            default:
                quoteHiddenExplainerView
            }
        }
        // TODO: show tip if viewModel.showOverlayTip is not nil
    }
    
    @ViewBuilder var nestedQuotePlaceholder: some View {
        Text("Quoted a post by @author")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .background {
                MastodonSecondaryBackground(fillInDarkModeOnly: true)
            }
    }
    
    @ViewBuilder var quoteHiddenExplainerView: some View {
        if let message = viewModel.quote.state.displayText {
            HStack {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if viewModel.quote.state.learnMoreMessage != nil {
                    Spacer()
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
    let viewModel: Mastodon.Entity.Status.ViewModel
    @Environment(ContentConcealViewModel.self) private var contentConcealViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading) {
                header()
                if let content = viewModel.content {
                    Text(String(content.characters[...]))
                        .font(.subheadline)
                        .lineLimit(9)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let attachmentInfo = viewModel.attachmentInfo {
                    HStack {
                        Image(systemName: attachmentInfo.iconName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: AvatarSize.tiny)
                        Text(attachmentInfo.labelText)
                    }
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                    .lineLimit(1)
                }
            }
            Spacer(minLength: 0) // This pushes the VStack all the way to the left.
        }
        .padding(standardPadding)
        .frame(maxWidth: .infinity)
        .background {
            MastodonSecondaryBackground(fillInDarkModeOnly: true)
        }
    }
    
    private let avatarShape = RoundedRectangle(cornerRadius: 4)
    
    @ViewBuilder func header() -> some View {
        HStack(spacing: 4) {
            if let url = viewModel.accountAvatarUrl {
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
                .frame(width: AvatarSize.tiny, height: AvatarSize.tiny)
            }
            Text(viewModel.accountDisplayName ?? "")
                .bold()
            Text(viewModel.accountFullName ?? "")
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .lineLimit(1)
        .font(.subheadline)
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
