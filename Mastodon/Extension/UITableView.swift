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
    
    func blinkRow(at indexPath: IndexPath) {
        DispatchQueue.main.asyncAfter(wallDeadline: .now() + 1) { [weak self] in
            guard let self = self else { return }
            guard let cell = self.cellForRow(at: indexPath) else { return }
            let backgroundColor = cell.backgroundColor
            
            UIView.animate(withDuration: 0.3) {
                cell.backgroundColor = Asset.Colors.brand.color.withAlphaComponent(0.5)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    UIView.animate(withDuration: 0.3) {
                        cell.backgroundColor = backgroundColor
                    }
                }
            }
        }
    }
    
}
