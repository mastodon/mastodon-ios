//
//  WizardPreference.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-15.
//

import UIKit

extension UserDefaults {
    @objc public dynamic var didShowMultipleAccountSwitchWizard: Bool {
        get { return bool(forKey: #function) }
        set { self[#function] = newValue }
    }
}
