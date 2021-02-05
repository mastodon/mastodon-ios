//
//  TimelineBottomLoaderTableViewCell.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/3.
//

import UIKit
import Combine

final class TimelineBottomLoaderTableViewCell: TimelineLoaderTableViewCell {
    override func _init() {
        super._init()
        backgroundColor = .clear

        activityIndicatorView.isHidden = false
        activityIndicatorView.startAnimating()
    }
}
