//
//  MetaTextView.swift
//  Mastodon
//
//  Created by jinsu kim on 12/28/22.
//

import UIKit
import MetaTextKit

extension MetaTextView {

    override public func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(selectAll) {
            if let range = selectedTextRange, range.start == beginningOfDocument, range.end == endOfDocument {
                return false // already selected all text
            }
            return !text.isEmpty
        }
        return super.canPerformAction(action, withSender: sender)
    }
}
