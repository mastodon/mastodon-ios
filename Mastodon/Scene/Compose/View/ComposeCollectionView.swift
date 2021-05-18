//
//  ComposeCollectionView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-17.
//

import UIKit

final class ComposeCollectionView: UICollectionView {
    
    weak var autoCompleteViewController: AutoCompleteViewController?
    
    // adjust hitTest for auto-complete
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let autoCompleteViewController = autoCompleteViewController else {
            return super.hitTest(point, with: event)
        }
        
        let thePoint = convert(point, to: autoCompleteViewController.view)
        if let hitView = autoCompleteViewController.view.hitTest(thePoint, with: event) {
            return hitView
        } else {
            return super.hitTest(point, with: event)
        }
    }
    
}
