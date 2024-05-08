// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import Foundation

extension Mastodon.API {
    public static func disputesEndpoint(domain: String, strikeId: String) -> URL {
        return Mastodon.API.webURL(domain: domain).appendingPathComponent("disputes/strikes/\(strikeId)")
    }
}
