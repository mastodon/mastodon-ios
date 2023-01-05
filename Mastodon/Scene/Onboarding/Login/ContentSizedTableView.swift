//
//  MastodonLoginTableView.swift
//  Mastodon
//
//  Created by Nathan Mattes on 13.11.22.
//

import UIKit

// Source: https://stackoverflow.com/a/48623673
final class ContentSizedTableView: UITableView {
  override var contentSize:CGSize {
    didSet {
      invalidateIntrinsicContentSize()
    }
  }

  override var intrinsicContentSize: CGSize {
    layoutIfNeeded()
    return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
  }
}
