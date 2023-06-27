// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonCore

struct AboutSettingsSection: Hashable {
    let entries: [AboutSettingsEntry]
}

enum AboutSettingsEntry: Hashable {
    case evenMoreSettings
    case contributeToMastodon
    case privacyPolicy
    case clearMediaCache(Int)

    var text: String {
        switch self {
            //TODO: @zeitschlag Add Localization
        case .evenMoreSettings:
            return "Even More Settings"
        case .contributeToMastodon:
            return "Contribute to Mastodon"
        case .privacyPolicy:
            return "Privacy Policy"
        case .clearMediaCache(_):
            return "Clear Media Storage"
        }
    }

    var secondaryText: String? {
        switch self {
        case .evenMoreSettings, .contributeToMastodon, .privacyPolicy:
            return nil
        case .clearMediaCache(let mediaStorage):
            return AppContext.byteCountFormatter.string(fromByteCount: Int64(mediaStorage))
        }
    }
}
