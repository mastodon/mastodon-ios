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
    public var configurationV2: Mastodon.Entity.V2.Instance.Configuration? {
        guard
            let configurationRaw = configurationV2Raw,
            let configuration = try? JSONDecoder().decode(
                Mastodon.Entity.V2.Instance.Configuration.self,
                from: configurationRaw
            )
        else {
            return nil
        }

        return configuration
    }
    
    static func encodeV2(configuration: Mastodon.Entity.V2.Instance.Configuration) -> Data? {
        return try? JSONEncoder().encode(configuration)
    }
}

extension String {
    public func majorServerVersion(greaterThanOrEquals comparedVersion: Int) -> Bool {
        guard
            let majorVersionString = split(separator: ".").first,
            let majorVersionInt = Int(majorVersionString)
        else { return false }
        
        return majorVersionInt >= comparedVersion
    }
}
