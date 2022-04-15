//
//  TrendView+Configuration.swift
//  
//
//  Created by MainasuK on 2022-4-13.
//

import UIKit
import MastodonSDK
import MastodonLocalization

extension TrendView {
    public func configure(tag: Mastodon.Entity.Tag) {
        let primaryLabelText = "#" + tag.name
        let secondaryLabelText = L10n.Plural.peopleTalking(tag.talkingPeopleCount ?? 0)
        
        primaryLabel.text = primaryLabelText
        secondaryLabel.text = secondaryLabelText
        
        lineChartView.data = (tag.history ?? [])
            .sorted(by: { $0.day < $1.day })        // latest last
            .map { entry in
                guard let point = Int(entry.accounts) else {
                    return .zero
                }
                return CGFloat(point)
            }
        
        isAccessibilityElement = true
        accessibilityLabel = [
            primaryLabelText,
            secondaryLabelText
        ].joined(separator: ", ")
    }
}
