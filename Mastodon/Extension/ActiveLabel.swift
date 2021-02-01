//
//  ActiveLabel.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/1/29.
//

import UIKit
import Foundation
import ActiveLabel
import os.log

extension ActiveLabel {
    
    enum Style {
        case `default`
        case timelineHeaderView
    }
    
    convenience init(style: Style) {
        self.init()
    
        switch style {
        case .default:
//            urlMaximumLength = 30
            font = .preferredFont(forTextStyle: .body)
            textColor = .white
        case .timelineHeaderView:
            font = .preferredFont(forTextStyle: .footnote)
            textColor = .secondaryLabel
        }
        
        numberOfLines = 0
        mentionColor = UIColor.yellow
        hashtagColor = UIColor.blue
        URLColor = UIColor.red
        text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
    }
    
}

extension ActiveLabel {
    func config(content: String) {
        if let parseResult = try? TootContent.parse(toot: content) {
            activeEntities.removeAll()
            numberOfLines = 0
            font = UIFont(name: "SFProText-Regular", size: 16)
            textColor = .white
            URLColor = .systemRed
            mentionColor = .systemGreen
            hashtagColor = .systemBlue
            text = parseResult.trimmed
            activeEntities = parseResult.activeEntities
        }
    }
}

