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
            
            let _leadingLayoutConstraint = contentView.leadingAnchor.constraint(equalTo: leadingAnchor)
            let _trailingLayoutConstraint = trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
            
            NSLayoutConstraint.activate([
                contentView.topAnchor.constraint(equalTo: topAnchor),
                _leadingLayoutConstraint,
                _trailingLayoutConstraint,
                contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
            
            leadingLayoutConstraint = _leadingLayoutConstraint
            trailingLayoutConstraint = _trailingLayoutConstraint
            
            updateConstraints()
        }
    }

    var leadingLayoutConstraint: NSLayoutConstraint?
    var trailingLayoutConstraint: NSLayoutConstraint?
    
}

extension AdaptiveMarginContainerView {
    
    public override func updateConstraints() {
        super.updateConstraints()
        
        leadingLayoutConstraint?.constant = margin
        trailingLayoutConstraint?.constant = margin
    }
    
}
