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

extension Instance {
    public var canFollowTags: Bool {
        guard let majorVersionString = version?.split(separator: ".").first else { return false }
        return Int(majorVersionString) == 4 // following Tags is support beginning with Mastodon v4.0.0
    }
}
