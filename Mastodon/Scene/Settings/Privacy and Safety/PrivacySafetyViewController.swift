// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import UIKit
import SwiftUI
import MastodonSDK
import MastodonCore
import MastodonLocalization
import MastodonAsset

final class PrivacySafetyViewController: UIHostingController<PrivacySafetyView>, NeedsDependency {
    weak var context: AppContext!
    weak var coordinator: SceneCoordinator!
        
    init(context: AppContext, coordinator: SceneCoordinator) {
        self.context = context
        self.coordinator = coordinator
        super.init(rootView: PrivacySafetyView(viewModel: PrivacySafetyViewModel()))
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
        Form {
            Section(L10n.Scene.Settings.PrivacySafety.Preset.title) {
                CheckableButton(text: L10n.Scene.Settings.PrivacySafety.Preset.openAndPublic, isChecked: viewModel.preset == .openPublic, action: {
                    viewModel.preset = .openPublic
                })
                CheckableButton(text: L10n.Scene.Settings.PrivacySafety.Preset.privateAndRestricted, isChecked: viewModel.preset == .privateRestricted, action: {
                    viewModel.preset = .privateRestricted
                })
                CheckableButton(text: L10n.Scene.Settings.PrivacySafety.Preset.custom, isChecked: viewModel.preset == .custom, action: {
                    viewModel.preset = .custom
                })
            }
        }
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
