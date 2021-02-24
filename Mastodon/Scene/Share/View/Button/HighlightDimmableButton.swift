//
//  HighlightDimmableButton.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-2-23.
//

import UIKit

final class HighlightDimmableButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    
    override var isHighlighted: Bool {
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
