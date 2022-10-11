//
//  ComposeContentViewController.swift
//  
//
//  Created by MainasuK on 22/9/30.
//

import os.log
import UIKit
import SwiftUI
import Combine

public final class ComposeContentViewController: UIViewController {
    
    let logger = Logger(subsystem: "ComposeContentViewController", category: "ViewController")
    
    var disposeBag = Set<AnyCancellable>()
    public var viewModel: ComposeContentViewModel!
    
    let tableView: ComposeTableView = {
        let tableView = ComposeTableView()
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.alwaysBounceVertical = true
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        return tableView
    }()

    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }

}

extension ComposeContentViewController {
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        tableView.delegate = self
        viewModel.setupDataSource(tableView: tableView)
        
        
        // setup snap behavior
        Publishers.CombineLatest(
            viewModel.$replyToCellFrame,
            viewModel.$scrollViewState
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] replyToCellFrame, scrollViewState in
            guard let self = self else { return }
            guard replyToCellFrame != .zero else { return }
            switch scrollViewState {
            case .fold:
                self.tableView.contentInset.top = -replyToCellFrame.height
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: set contentInset.top: -%s", ((#file as NSString).lastPathComponent), #line, #function, replyToCellFrame.height.description)
            case .expand:
                self.tableView.contentInset.top = 0
            }
        }
        .store(in: &disposeBag)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        viewModel.viewLayoutFrame.update(view: view)
    }
    
    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        
        viewModel.viewLayoutFrame.update(view: view)
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { [weak self] coordinatorContext in
            guard let self = self else { return }
            self.viewModel.viewLayoutFrame.update(view: self.view)
        }
    }
}

// MARK: - UIScrollViewDelegate
extension ComposeContentViewController {
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard scrollView === tableView else { return }

        let replyToCellFrame = viewModel.replyToCellFrame
        guard replyToCellFrame != .zero else { return }

        // try to find some patterns:
        // print("""
        // repliedToCellFrame: \(viewModel.repliedToCellFrame.value.height)
        // scrollView.contentOffset.y: \(scrollView.contentOffset.y)
        // scrollView.contentSize.height: \(scrollView.contentSize.height)
        // scrollView.frame: \(scrollView.frame)
        // scrollView.adjustedContentInset.top: \(scrollView.adjustedContentInset.top)
        // scrollView.adjustedContentInset.bottom: \(scrollView.adjustedContentInset.bottom)
        // """)

        switch viewModel.scrollViewState {
        case .fold:
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): fold")
            guard velocity.y < 0 else { return }
            let offsetY = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
            if offsetY < -44 {
                tableView.contentInset.top = 0
                targetContentOffset.pointee = CGPoint(x: 0, y: -scrollView.adjustedContentInset.top)
                viewModel.scrollViewState = .expand
            }

        case .expand:
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): expand")
            guard velocity.y > 0 else { return }
            // check if top across
            let topOffset = (scrollView.contentOffset.y + scrollView.adjustedContentInset.top) - replyToCellFrame.height

            // check if bottom bounce
            let bottomOffsetY = scrollView.contentOffset.y + (scrollView.frame.height - scrollView.adjustedContentInset.bottom)
            let bottomOffset = bottomOffsetY - scrollView.contentSize.height

            if topOffset > 44 {
                // do not interrupt user scrolling
                viewModel.scrollViewState = .fold
            } else if bottomOffset > 44 {
                tableView.contentInset.top = -replyToCellFrame.height
                targetContentOffset.pointee = CGPoint(x: 0, y: -replyToCellFrame.height)
                viewModel.scrollViewState = .fold
            }
        }
    }
}

// MARK: - UITableViewDelegate
extension ComposeContentViewController: UITableViewDelegate { }

