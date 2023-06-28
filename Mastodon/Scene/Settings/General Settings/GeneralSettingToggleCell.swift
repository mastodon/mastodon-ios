// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit

protocol GeneralSettingToggleCellDelegate: AnyObject {
    
}

class GeneralSettingToggleCell: UITableViewCell {
    static let reuseIdentifier = "GeneralSettingToggleCell"

    // add title label
    // add switch

    func configure(with setting: GeneralSetting, viewModel: GeneralSettingsViewModel) {
        switch setting {
        case .appearance(_), .openLinksIn(_):
            assertionFailure("Only for Design")
        case .design(let designSetting):
            textLabel?.text = designSetting.title

            switch designSetting {
            case .showAnimations:
                //TODO: Implement
                if viewModel.playAnimations == true {
                    print("play animations")
                }
            }
        }
    }
}
