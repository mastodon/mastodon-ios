//
//  NSLayoutConstraint.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/1/28.
//

import UIKit

extension NSLayoutConstraint {
    func priority(_ priority: UILayoutPriority) -> Self {
        self.priority = priority
        return self
    }
    
    func identifier(_ identifier: String?) -> Self {
        self.identifier = identifier
        return self
    }
}
