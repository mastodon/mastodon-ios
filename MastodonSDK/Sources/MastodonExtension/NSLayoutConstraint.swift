//
//  NSLayoutConstraint.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/1/28.
//

import UIKit

extension NSLayoutConstraint {
    public func priority(_ priority: UILayoutPriority) -> Self {
        self.priority = priority
        return self
    }
    
    public func identifier(_ identifier: String?) -> Self {
        self.identifier = identifier
        return self
    }

    @discardableResult
    public func activate() -> Self {
        self.isActive = true
        return self
    }

    @discardableResult
    public func deactivate() -> Self {
        self.isActive = false
        return self
    }
}
