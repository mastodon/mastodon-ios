//
//  ContentSizedTableView.swift
//  Mastodon
//
//  Created by Nathan Mattes on 13.11.22.
//

import UIKit

// Source: https://stackoverflow.com/a/48623673
public final class ContentSizedTableView: UITableView {
    override public var contentSize: CGSize {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override public var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
}
