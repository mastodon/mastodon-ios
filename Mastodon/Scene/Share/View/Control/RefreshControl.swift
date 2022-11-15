//
//  RefreshControl.swift
//  Mastodon
//
//  Created by Kyle Bashour on 11/14/22.
//

import UIKit

/// RefreshControl subclass that properly displays itself behind table view contents.
class RefreshControl: UIRefreshControl {
    override init() {
        super.init()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        layer.zPosition = -1
    }
}
