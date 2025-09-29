// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import MastodonAsset
import MastodonLocalization
import MastodonSDK
import SwiftUI
import MastodonCore
import SDWebImageSwiftUI

struct LinkPreviewCard: View {
    
    private let compactPreviewHeight: CGFloat = 96
    
    enum Layout: Equatable {
        case noPreviewVisual
        case compact
        case large(aspectRatio: CGFloat)
    }
    
    let cardEntity: Mastodon.Entity.Card
    let fittingWidth: CGFloat
    let navigateToScene: (SceneCoordinator.Scene, SceneCoordinator.Transition)->()
    
    @State var blurhash: UIImage?
    @State var couldShowImage = true
    @State var loadingEmbeddedContent = false
    
    var body: some View {
        let previewFrame = previewFrameSize(fittingWidth: fittingWidth)
        VStack(spacing: 0) {
            switch cardEntity.layout {
            case .large:
                VStack(alignment: .leading, spacing: 0) {
                    previewVisual
                        .frame(width: previewFrame.width, height: previewFrame.height)
                    Divider()
                    textContentStack
                }
            case .compact:
                HStack(spacing: 0) {
                    previewVisual
                        .frame(width: previewFrame.width, height: previewFrame.height)
                    Divider()
                    textContentStack
                        .frame(width: max(0, fittingWidth - previewFrame.width))
                }
            case .noPreviewVisual:
                textContentStack
                    .frame(width: fittingWidth)
            }
            
            Divider()
            authorMolecule
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.standard))
        .background {
            RoundedRectangle(cornerRadius: CornerRadius.standard)
                .fill(.clear)
                .stroke(.separator, lineWidth: 0.3)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L10n.Common.Controls.Status.linkA11yLabel)
        .onTapGesture {
            guard let url = URL(string: cardEntity.url) else { return }
            navigateToScene(.safari(url: url), .safariPresent(animated: true, completion: nil))
        }
    }
    
    func previewFrameSize(fittingWidth: CGFloat) -> CGSize {
        guard couldShowImage else { return .zero }
        
        switch cardEntity.layout {
        case .noPreviewVisual:
                return .zero
        case .compact:
            guard let previewWidth = cardEntity.width, let previewHeight = cardEntity.height, previewHeight > 0 else { return .zero }
            let height: CGFloat = compactPreviewHeight
            let aspectRatio = CGFloat(previewWidth) / CGFloat(previewHeight)
            let width = floor(height * aspectRatio)
            return CGSize(width: width, height: height)
        case .large(let aspectRatio):
            guard aspectRatio > 0 else { return .zero }
            return CGSize(width: fittingWidth, height: fittingWidth / aspectRatio)
        }
    }
    
    @ViewBuilder var previewVisual: some View {
            if couldShowImage, let imageUrl = cardEntity.image {
                WebImage(url: URL(string: imageUrl))
                { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            if let blurhash {
                                Image(uiImage: blurhash)
                                    .resizable()
                                    .scaledToFill()
                                    .accessibilityHidden(true)
                                ProgressView()
                            } else {
                                if cardEntity.html == nil || cardEntity.html?.isEmpty == true {
                                    ProgressView()
                                }
                            }
                        }
                    case .success(let image):
                        ZStack {
                            if let blurhash {
                                // use the blurhash as a backdrop because the preview image is often the wrong aspect ratio
                                Image(uiImage: blurhash)
                                    .resizable()
                                    .scaledToFill()
                                    .accessibilityHidden(true)
                            }
                            image
                                .resizable()
                                .scaledToFit()
                                .accessibilityHidden(true)
                            
                            if let html = cardEntity.html, !html.isEmpty {
                                if loadingEmbeddedContent {
                                    ZStack {
                                        ProgressView()
                                            .progressViewStyle(.circular)
                                        WebContentView(style: .linkPreviewCard, html: html)
                                    }
                                } else {
                                    Button {
                                        loadingEmbeddedContent = true
                                    } label: {
                                        HStack {
                                            Image(systemName: "play.fill")
                                                .font(.title2)
                                            Text(L10n.Common.Controls.Status.loadEmbed)
                                        }
                                        .foregroundStyle(.primary)
                                        .padding(EdgeInsets(top: standardPadding, leading: ButtonPadding.capsuleHorizontal, bottom: standardPadding, trailing: ButtonPadding.capsuleHorizontal))
                                        .background {
                                            Capsule()
                                                .fill(.ultraThinMaterial)
                                        }
                                    }
                                    .buttonStyle(.borderless)
                                }
                            }
                        }
                    case .failure:
                        Color.clear.frame(height: 0)
                            .onAppear {
                                switch cardEntity.type {
                                case .link, .photo:
                                    couldShowImage = false
                                default:
                                    break
                                }
                            }
                            .accessibilityHidden(true)
                    @unknown default:
                        EmptyView()
                    }
                }
                .onAppear() {
                    loadBlurhash()
                }
            }
    }
    
    func loadBlurhash() {
        Task {
            if let blurhashString = cardEntity.blurhash, let width = cardEntity.width, let height = cardEntity.height {
                blurhash = try? await BlurhashImageCacheService.shared.image(
                    blurhash: blurhashString,
                    size: CGSize(width: max(1, width), height: max(1, height)),
                    url: cardEntity.url
                ).singleOutput()
            }
        }
    }
    
    @ViewBuilder var authorMolecule: some View {
        // avatar button if the author has an account, otherwise shows author information as text
        HStack {
            if let author = cardEntity.authors?.first, let account = author.account {
                // Author has an account; show Mastodon logo and avatar button
                Image(uiImage: Asset.Scene.Sidebar.logo.image.withRenderingMode(.alwaysTemplate))
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
                    .frame(width: 17, height: 17)
                
                Text(L10n.Common.Controls.Status.Card.by)
                    .foregroundStyle(.secondary)
                
                Button { // author account button
                    guard let currentUser = AuthenticationServiceProvider.shared.currentActiveUser.value?.cachedAccount else { return }
                    let profileType: ProfileViewController.ProfileType
                    if currentUser.id == account.id {
                        profileType = .me(currentUser)
                    } else {
                        profileType = .notMe(me: currentUser, displayAccount: account, relationship: nil)
                    }
                    navigateToScene(.profile(profileType), .show)
                } label: {
                    HStack(spacing: tinySpacing) {
                        AvatarView(size: .tiny, authorAvatarUrl: account.avatarURL, goToProfile: nil)
                        MastodonContentView.header(html: account.displayNameWithFallback, emojis: account.emojis, style: .linkPreviewCardAuthorButton)
                            .lineLimit(1)
                    }
                    .padding(EdgeInsets(top: tinySpacing, leading: 6, bottom: tinySpacing, trailing: 6))
                    .background {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Asset.Colors.Button.userFollowing.swiftUIColor)
                    }
                }
                .buttonStyle(.borderless)
            } else {
                // No account, show author label
                if let author = cardEntity.authors?.first, let authorName = author.name, authorName.isEmpty == false {
                    Text(L10n.Common.Controls.Status.Card.byAuthor(authorName))
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                } else if let authorName = cardEntity.authorName, authorName.isNotEmpty {  // deprecated since 4.3.0
                    Text(L10n.Common.Controls.Status.Card.byAuthor(authorName))
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                } else if let linkHost = URL(string: cardEntity.url)?.host {
                    Text(linkHost)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(EdgeInsets(top: standardPadding, leading: doublePadding, bottom: standardPadding, trailing: doublePadding))
    }
    
    @ViewBuilder var publisherAttributionMolecule: some View {
        if let providerName = cardEntity.providerName, !providerName.isEmpty {
            HStack(spacing: 2) {
                Text(providerName)
                    .lineLimit(1)
                if let formattedPublishedDate = cardEntity.publishedAt?.abbreviatedDate {
                    Text("·")
                    Text(formattedPublishedDate)
                        .lineLimit(1)
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder var textContentStack: some View {
        VStack(alignment: .leading, spacing: 0) {
            publisherAttributionMolecule
            Text(cardEntity.title)
                .font(.body)
                .fontWeight(.semibold)
                .multilineTextAlignment(.leading)
            switch cardEntity.layout {
            case .noPreviewVisual, .large:
                if !cardEntity.description.isEmpty {
                    Spacer()
                        .frame(maxHeight: tinySpacing)
                    Text(cardEntity.description)
                        .font(.subheadline)
                        .lineLimit(2)
                }
            case .compact:
                EmptyView()
            }
        }
        .padding(EdgeInsets(top: standardPadding, leading: doublePadding, bottom: standardPadding, trailing: doublePadding))
    }
}

private extension Mastodon.Entity.Card {
    var layout: LinkPreviewCard.Layout {
        if (image == nil || image!.isEmpty) && (html == nil || html!.isEmpty) {
            return .noPreviewVisual
        }
        var aspectRatio = CGFloat(width ?? 1) / CGFloat(height ?? 1)
        if !aspectRatio.isFinite {
            aspectRatio = 1
        }
        
        if (abs(aspectRatio - 1) < 0.05 || image == nil) && (html == nil || html!.isEmpty) {
            return .compact
        } else {
            return .large(aspectRatio: aspectRatio)
        }
    }
}
