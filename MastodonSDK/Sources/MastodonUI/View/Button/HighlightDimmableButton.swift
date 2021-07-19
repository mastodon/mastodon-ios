//
//  HighlightDimmableButton.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-2-23.
//

import UIKit

final public class HighlightDimmableButton: UIButton {
    
    public var expandEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.inset(by: expandEdgeInsets).contains(point)
    }
    
    public override var isHighlighted: Bool {
        didSet {
            alpha = isHighlighted ? 0.6 : 1
        }
    }
    
}

extension HighlightDimmableButton {
    private func _init() {
        adjustsImageWhenHighlighted = false
    }
}
