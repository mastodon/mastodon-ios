//
//  NSKeyValueObservation.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-2-24.
//

import Foundation

extension NSKeyValueObservation {
    func store(in set: inout Set<NSKeyValueObservation>) {
        set.insert(self)
    }
}
