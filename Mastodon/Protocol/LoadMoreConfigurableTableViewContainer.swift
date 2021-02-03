//
//  LoadMoreConfigurableTableViewContainer.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/3.
//

import UIKit
import GameplayKit

/// The tableView container driven by state machines with "LoadMore" logic
protocol LoadMoreConfigurableTableViewContainer: UIViewController {
    
    associatedtype BottomLoaderTableViewCell: UITableViewCell
    associatedtype LoadingState: GKState
    
    var loadMoreConfigurableTableView: UITableView { get }
    var loadMoreConfigurableStateMachine: GKStateMachine { get }
    func handleScrollViewDidScroll(_ scrollView: UIScrollView)
}

extension LoadMoreConfigurableTableViewContainer {
    func handleScrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === loadMoreConfigurableTableView else { return }

        let cells = loadMoreConfigurableTableView.visibleCells.compactMap { $0 as? BottomLoaderTableViewCell }
        guard let loaderTableViewCell = cells.first else { return }
        
        if let tabBar = tabBarController?.tabBar, let window = view.window {
            let loaderTableViewCellFrameInWindow = loadMoreConfigurableTableView.convert(loaderTableViewCell.frame, to: nil)
            let windowHeight = window.frame.height
            let loaderAppear = (loaderTableViewCellFrameInWindow.origin.y + 0.8 * loaderTableViewCell.frame.height) < (windowHeight - tabBar.frame.height)
            if loaderAppear {
                loadMoreConfigurableStateMachine.enter(LoadingState.self)
            } else {
                // do nothing
            }
        } else {
            loadMoreConfigurableStateMachine.enter(LoadingState.self)
        }
    }
}
