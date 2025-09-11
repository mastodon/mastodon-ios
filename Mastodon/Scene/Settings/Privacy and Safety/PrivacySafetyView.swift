// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonSDK
import MastodonLocalization
import MastodonUI

struct PrivacySafetyView: View {
    @StateObject var viewModel: PrivacySafetyViewModel
    @Environment(PostInteractionSettingsViewModel.self) var visibilityAndQuotabilityViewModel
    
    var body: some View {
        Group {
            if !viewModel.isUserInteractionEnabled {
                ProgressView()
            } else {
                Form {
                    Section(L10n.Scene.Settings.PrivacySafety.Preset.title) {
                        CheckableButton(
                            text: L10n.Scene.Settings.PrivacySafety.Preset.openAndPublic,
                            isChecked: viewModel.preset == .openPublic,
                            action: {
                                viewModel.preset = .openPublic
                            }
                        )
                        CheckableButton(
                            text: L10n.Scene.Settings.PrivacySafety.Preset.privateAndRestricted,
                            isChecked: viewModel.preset == .privateRestricted,
                            action: {
                                viewModel.preset = .privateRestricted
                            }
                        )
                        
                        if viewModel.preset == .custom {
                            CheckableButton(
                                text: L10n.Scene.Settings.PrivacySafety.Preset.custom,
                                isChecked: viewModel.preset == .custom,
                                action: {
                                    viewModel.preset = .custom
                                }
                            )
                        }
                    }
                    
                    Section {
                        Picker(selection: Binding<Mastodon.Entity.Status.Visibility>(
                            get: {
                                return visibilityAndQuotabilityViewModel.interactionSettings.visibility
                            },
                            set: { newValue in
                                visibilityAndQuotabilityViewModel.setInteractionSettings(visibility: newValue, quotability: nil)
                                viewModel.visibility = visibilityAndQuotabilityViewModel.interactionSettings.visibility.toModelVisibility
                            }
                        )) {
                            ForEach(visibilityAndQuotabilityViewModel.availableVisibilities, id: \.self) {
                                Text($0.title)
                            }
                        } label: {
                            Text(L10n.Scene.Settings.PrivacySafety.DefaultPostVisibility.title)
                        }
                        
                        if viewModel.canSetQuotability {
                            Picker(selection: Binding<Mastodon.Entity.Source.QuotePolicy>(
                                get: {
                                    visibilityAndQuotabilityViewModel.interactionSettings.quotability
                                },
                                set: { newValue in
                                    visibilityAndQuotabilityViewModel.setInteractionSettings(visibility: nil, quotability: newValue)
                                    viewModel.quotability = visibilityAndQuotabilityViewModel.interactionSettings.quotability
                                }
                            ) ) {
                                ForEach(visibilityAndQuotabilityViewModel.interactionSettings.visibility.allowableQuotePolicies, id: \.self) {
                                    Text($0.title)
                                }
                            } label: {
                                Text(L10n.Scene.Compose.QuotePermissionPolicy.title)
                            }
                        }
                    }
                    
                    Section {
                        Toggle(L10n.Scene.Settings.PrivacySafety.manuallyApproveFollowRequests, isOn: $viewModel.manuallyApproveFollowRequests)
                        Toggle(L10n.Scene.Settings.PrivacySafety.showFollowersAndFollowing, isOn: $viewModel.showFollowersAndFollowing)
                        Toggle(L10n.Scene.Settings.PrivacySafety.suggestMyAccountToOthers, isOn: $viewModel.suggestMyAccountToOthers)
                        Toggle(L10n.Scene.Settings.PrivacySafety.appearInSearchEngines, isOn: $viewModel.appearInSearches)
                    }
                }
            }
        }
        .onChange(of: viewModel.preset) {
            let newVisibility = viewModel.visibility.toEntityVisibility
            let newQuotability: Mastodon.Entity.Source.QuotePolicy?
            switch viewModel.preset {
            case .custom:
                newQuotability = nil
            case .openPublic:
                newQuotability = .anyone
            case .privateRestricted:
                newQuotability = .nobody
            }
            visibilityAndQuotabilityViewModel.setInteractionSettings(visibility: newVisibility, quotability: newQuotability)
        }
        .onAppear(perform: viewModel.viewDidAppear)
        .onDisappear(){
            viewModel.visibility = visibilityAndQuotabilityViewModel.interactionSettings.visibility.toModelVisibility
            viewModel.quotability = visibilityAndQuotabilityViewModel.interactionSettings.quotability
            viewModel.saveSettings()
        }
    }
}

fileprivate extension Mastodon.Entity.Status.Visibility {
    var toModelVisibility: PrivacySafetyViewModel.Visibility {
        switch self {
        case .public:
            return .public
        case .unlisted:
            return .unlisted
        case .private:
            return .followersOnly
        case .direct:
            return .onlyPeopleMentioned
        case ._other:
            assertionFailure("unexpected visibility setting")
            return .onlyPeopleMentioned
        }
    }
}

fileprivate extension PrivacySafetyViewModel.Visibility {
    var toEntityVisibility: Mastodon.Entity.Status.Visibility {
        switch self {
        case .public:
            Mastodon.Entity.Status.Visibility.public
        case .unlisted:
            Mastodon.Entity.Status.Visibility.unlisted
        case .followersOnly:
            Mastodon.Entity.Status.Visibility.private
        case .onlyPeopleMentioned:
            Mastodon.Entity.Status.Visibility.direct
        }
    }
}

fileprivate extension Mastodon.Entity.Source.QuotePolicy {
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
