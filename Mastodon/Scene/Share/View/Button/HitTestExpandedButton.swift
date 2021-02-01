//
//  HitTestExpandedButton.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/1.
//

import UIKit

final class HitTestExpandedButton: UIButton {
    
    var expandEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.inset(by: expandEdgeInsets).contains(point)
    }
    
}
