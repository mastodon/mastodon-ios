//
//  AdaptiveMarginContainerView.swift
//  
//
//  Created by MainasuK on 2022-2-18.
//

import UIKit

public final class AdaptiveMarginContainerView: UIView {
    
    public var margin: CGFloat = 0 {
        didSet { updateConstraints() }
    }
    
    public var contentView: UIView? {
        didSet {
            guard let contentView = contentView else { return }
            guard contentView.superview == nil else { return }
            
            contentView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(contentView)
            
            let _topLayoutConstraint = contentView.topAnchor.constraint(equalTo: topAnchor)
            let _leadingLayoutConstraint = contentView.leadingAnchor.constraint(equalTo: leadingAnchor)
            let _trailingLayoutConstraint = trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
            let _bottomLayoutConstraint = bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            
            NSLayoutConstraint.activate([
                _topLayoutConstraint,
                _leadingLayoutConstraint,
                _trailingLayoutConstraint,
                _bottomLayoutConstraint
            ])
            
            topLayoutConstraint = _topLayoutConstraint
            leadingLayoutConstraint = _leadingLayoutConstraint
            trailingLayoutConstraint = _trailingLayoutConstraint
            bottomLayoutConstraint = _bottomLayoutConstraint
            
            updateConstraints()
        }
    }

    private(set) var topLayoutConstraint: NSLayoutConstraint?
    private(set) var leadingLayoutConstraint: NSLayoutConstraint?
    private(set) var trailingLayoutConstraint: NSLayoutConstraint?
    private(set) var bottomLayoutConstraint: NSLayoutConstraint?
    
}

extension AdaptiveMarginContainerView {
    
    public override func updateConstraints() {
        super.updateConstraints()
        
        leadingLayoutConstraint?.constant = margin
        trailingLayoutConstraint?.constant = margin
    }
    
}
