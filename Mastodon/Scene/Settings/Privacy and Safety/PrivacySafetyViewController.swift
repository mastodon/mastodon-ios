// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import Combine
import UIKit
import SwiftUI
import MastodonSDK
import MastodonCore
import MastodonLocalization
import MastodonAsset

final class PrivacySafetyViewController: UIHostingController<PrivacySafetyView> {
    private let viewModel: PrivacySafetyViewModel
    private var disposeBag = [AnyCancellable]()
    
    init(appContext: AppContext, authContext: AuthContext, coordinator: SceneCoordinator) {
        self.viewModel = PrivacySafetyViewModel(
            appContext: appContext, authContext: authContext, coordinator: coordinator
        )
        super.init(
            rootView: PrivacySafetyView(
                viewModel: self.viewModel
            )
        )
        self.viewModel.onDismiss.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.dismiss(animated: true)
            }
            .store(in: &disposeBag)
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.Scene.Settings.PrivacySafety.title
    }
}

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

private struct CheckableButton: View {
    let text: String
    let isChecked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                Spacer()
                if isChecked {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Asset.Colors.Brand.blurple.swiftUIColor)
                }
            }
        }
    }
}
