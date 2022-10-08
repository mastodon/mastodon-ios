//
//  Instance.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-10-9.
//

import UIKit
import CoreDataStack
import MastodonSDK

extension Instance {
    public var configuration: Mastodon.Entity.Instance.Configuration? {
        guard let configurationRaw = configurationRaw else { return nil }
        guard let configuration = try? JSONDecoder().decode(Mastodon.Entity.Instance.Configuration.self, from: configurationRaw) else {
            return nil
        }

        return configuration
    }
    
    static func encode(configuration: Mastodon.Entity.Instance.Configuration) -> Data? {
        return try? JSONEncoder().encode(configuration)
    }
}
