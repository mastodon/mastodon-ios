// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import Combine
import UIKit
import SwiftUI
import MastodonSDK
import MastodonCore
import MastodonLocalization
import MastodonAsset
import MastodonUI

final class PrivacySafetyViewController: UIHostingController<AnyView> {
    private let viewModel: PrivacySafetyViewModel
    private var disposeBag = [AnyCancellable]()
    
    init(appContext: AppContext, authenticationBox: MastodonAuthenticationBox, coordinator: SceneCoordinator) {
        self.viewModel = PrivacySafetyViewModel(
            appContext: appContext, authenticationBox: authenticationBox, coordinator: coordinator
        )
        let interactionSettingsDefaults = PostInteractionSettingsViewModel.InitialSettings.fresh(replyingToVisibility: nil)
        let rootView = PrivacySafetyView(
            viewModel: self.viewModel
        )
            .environment(PostInteractionSettingsViewModel(account: authenticationBox.cachedAccount, initialSettings: interactionSettingsDefaults))
        super.init(
            rootView: AnyView(rootView)
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
