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
