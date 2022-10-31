//
//  NSKeyValueObservation.swift
//  Twidere
//
//  Created by Cirno MainasuK on 2020-7-20.
//  Copyright © 2020 Twidere. All rights reserved.
//

import Foundation

extension NSKeyValueObservation {
    public func store(in set: inout Set<NSKeyValueObservation>) {
        set.insert(self)
    }
}
