// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonCore
import MastodonLocalization

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
            return L10n.Scene.Settings.AboutMastodon.moreSettings
        case .contributeToMastodon:
            return L10n.Scene.Settings.AboutMastodon.contributeToMastodon
        case .privacyPolicy:
            return L10n.Scene.Settings.AboutMastodon.privacyPolicy
        case .clearMediaCache(_):
            return L10n.Scene.Settings.AboutMastodon.cleaerMediaStorage
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
