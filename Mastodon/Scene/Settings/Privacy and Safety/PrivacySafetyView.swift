// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonLocalization

struct PrivacySafetyView: View {
    @StateObject var viewModel: PrivacySafetyViewModel
    
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
                        Picker(selection: $viewModel.visibility) {
                            ForEach(PrivacySafetyViewModel.Visibility.allCases, id: \.self) {
                                Text($0.title)
                            }
                        } label: {
                            Text(L10n.Scene.Settings.PrivacySafety.DefaultPostVisibility.title)
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
        .onAppear(perform: viewModel.viewDidAppear)
        .onDisappear(perform: viewModel.saveSettings)
    }
}
