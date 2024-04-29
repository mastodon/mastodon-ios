//
//  UITableView.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-3-2.
//

import UIKit
import MastodonAsset
import MastodonLocalization

extension UITableView {
    
    func deselectRow(with transitionCoordinator: UIViewControllerTransitionCoordinator?, animated: Bool) {
        guard let indexPathForSelectedRow = indexPathForSelectedRow else { return }
        
        guard let transitionCoordinator = transitionCoordinator else {
            deselectRow(at: indexPathForSelectedRow, animated: animated)
            return
        }
        
        transitionCoordinator.animate(alongsideTransition: { _ in
            self.deselectRow(at: indexPathForSelectedRow, animated: animated)
        }, completion: { context in
            if context.isCancelled {
                self.selectRow(at: indexPathForSelectedRow, animated: animated, scrollPosition: .none)
            }
        })
    }
}
