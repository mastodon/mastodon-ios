// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonLocalization
import MastodonCore
import MastodonSDK

public struct PostInteractionSettingsView: View {
    private let closeAndSave: (Bool) -> ()
    
    @Environment(PostInteractionSettingsViewModel.self) private var viewModel
    
    public init(closeAndSave: @escaping (Bool) -> Void) {
        self.closeAndSave = closeAndSave
    }
    
    public var body: some View {
            VStack {
                Spacer()
                    .frame(height: 4)
                // header and save/cancel buttons
                HStack {
                    Button(L10n.Common.Controls.Actions.cancel, role: .cancel) {
                       closeAndSave(false)
                    }
                    .tint(.blue)
                    Spacer()
                    Text(L10n.Scene.Compose.VisibilityAndQuotability.title)
                        .fontWeight(.semibold)
                    Spacer()
                    Button(L10n.Common.Controls.Actions.save, role: .none) {
                        closeAndSave(true)
                    }
                    .fontWeight(.semibold)
                    .tint(.blue)
                }
                Spacer()
                    .frame(height: 16)
                
                
                ScrollView {
                    
                Text(L10n.Scene.Compose.VisibilityAndQuotability.subtitle)
                    .font(.caption)
                Spacer()
                
                // visibility
                HStack {
                    Text(L10n.Scene.Compose.Visibility.title)
                        .accessibilityHidden(true)
                    Spacer()
                    validatingVisibilityPicker()
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(19)
                .background {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.background)
                }
                .accessibilityElement(children: .combine)
                
                Spacer()
                
                // quotability
                HStack {
                    Text(L10n.Scene.Compose.QuotePermissionPolicy.title)
                        .accessibilityHidden(true)
                    Spacer()
                    quotabilityPicker(viewModel.interactionSettings.visibility.allowableQuotePolicies)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(19)
                .background {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.background)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(EdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16))
        .background(Color(.secondarySystemBackground))
        .ignoresSafeArea(edges: .bottom)
    }
    
    @ViewBuilder
    func validatingVisibilityPicker() -> some View {
        Picker(selection: Binding<Mastodon.Entity.Status.Visibility>(
            get: {
                viewModel.interactionSettings.visibility
            },
            set: { newValue in
                viewModel.setInteractionSettings(visibility: newValue, quotability: nil)
            }
        )) {
            ForEach(viewModel.availableVisibilities, id: \.self) { visibility in
                Text(visibility.title)
            }
        } label: {
            Text(L10n.Scene.Compose.Visibility.title)
        }
        .disabled(!viewModel.canEditVisibility)
        .tint(.secondary)
    }
    
    @ViewBuilder
    func quotabilityPicker(_ options: [Mastodon.Entity.Source.QuotePolicy]) -> some View {
        Picker(selection: Binding<Mastodon.Entity.Source.QuotePolicy>(
            get: {
                viewModel.interactionSettings.quotability
            },
            set: { newValue in
                viewModel.setInteractionSettings(visibility: nil, quotability: newValue)
            }
        )) {
            ForEach(viewModel.interactionSettings.visibility.allowableQuotePolicies, id: \.self) { quotability in
                Label {
                    Text(quotability.title)
                } icon: {
                    EmptyView()
                }
            }
        } label: {
            Text(L10n.Scene.Compose.QuotePermissionPolicy.title)
        }
        .disabled(options.count < 2)
        .tint(.secondary)
    }
}

extension Mastodon.Entity.Source.QuotePolicy {
    var title: String {
        switch self {
        case .anyone:
            L10n.Scene.Compose.QuotePermissionPolicy.anyone
        case .followers:
            L10n.Scene.Compose.QuotePermissionPolicy.followers
        case .nobody:
            L10n.Scene.Compose.QuotePermissionPolicy.onlyMe
        case ._other(let string):
            string
        }
    }
}
