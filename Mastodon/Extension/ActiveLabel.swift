//
//  ActiveLabel.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/1/29.
//

import UIKit
import Foundation
import ActiveLabel


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
            textColor = UIColor.label.withAlphaComponent(0.8)
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
    func config(content:String) {
        let html = content.replacingOccurrences(of: "</p><p>", with: "<br /><br />").replacingOccurrences(of: "<p>", with: "").replacingOccurrences(of: "</p>", with: "")
        text = html.toPlainText()
    }
}

