// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonAsset
import MastodonLocalization
import MastodonCore

struct BoostOrQuoteDialog: View {
    @Environment(MastodonPostViewModel.self) var viewModel
    
    var body: some View {
        if let actionablePost = viewModel.fullPost?.actionablePost {
            ZStack {
                Color(.secondarySystemBackground)
                    .ignoresSafeArea(edges: .bottom)
                
                VStack(spacing: 0) {
                    if actionablePost.content.myActions.boosted {
                        Button {
                            viewModel.actionHandler?.doAction(.unboost, forPost: viewModel)
                        } label: {
                            Text(L10n.Common.Alerts.BoostAPost.unboost)
                                .padding()
                        }
                        .foregroundStyle(Asset.Colors.accent.swiftUIColor)
                    } else {
                        Button {
                            viewModel.actionHandler?.doAction(.boost, forPost: viewModel)
                        } label: {
                            Text(L10n.Common.Alerts.BoostAPost.boost)
                                .padding()
                        }
                        .foregroundStyle(Asset.Colors.accent.swiftUIColor)
                    }
                    
                    Divider()
                    
                    let quoteButtonInfo = viewModel.currentUserQuoteButton
                    
                    if let buttonTitle = quoteButtonInfo.title {
                        Button {
                            guard let composeViewModel = viewModel.composeViewModelQuotingThisPost else { return }
                            viewModel.actionHandler?.presentScene(.compose(viewModel: composeViewModel), fromPost: nil, transition: .modal(animated: true, completion: nil))
                        } label: {
                            VStack {
                                Text(buttonTitle)
                                    .foregroundStyle(Asset.Colors.accent.swiftUIColor)
                                if let subtitle = quoteButtonInfo.subtitle {
                                    Text(subtitle)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding()
                        }
                    } else if let subtitle = quoteButtonInfo.subtitle {
                        Text(subtitle)
                            .padding()
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .background() {
                    RoundedRectangle(cornerRadius: 14, style: .circular)
                        .fill(.background)
                }
                .padding(16)
            }
        } else {
            EmptyView()
        }
    }
}
