//
//  Instance.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-10-9.
//

import UIKit
import MastodonSDK

extension String {
    public func majorServerVersion(greaterThanOrEquals comparedVersion: Int) -> Bool {
        guard
            let majorVersionString = split(separator: ".").first,
            let majorVersionInt = Int(majorVersionString)
        else { return false }
        
        return majorVersionInt >= comparedVersion
    }
}
