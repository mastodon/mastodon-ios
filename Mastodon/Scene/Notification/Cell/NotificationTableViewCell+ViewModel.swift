//
//  NotificationView+ViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-21.
//

import UIKit
import Combine
import CoreDataStack

extension NotificationTableViewCell {
    final class ViewModel {
        let value: Value

        init(value: Value) {
            self.value = value
        }
        
        enum Value {
            case feed(Feed)
        }
    }
}

extension NotificationTableViewCell {

    func configure(
        tableView: UITableView,
        viewModel: ViewModel,
        delegate: NotificationTableViewCellDelegate?
    ) {
        if notificationView.frame == .zero {
            // set status view width
            notificationView.frame.size.width = tableView.frame.width - containerViewHorizontalMargin
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): did layout for new cell")
            
            notificationView.statusView.frame.size.width = tableView.frame.width - containerViewHorizontalMargin
            notificationView.quoteStatusView.frame.size.width = tableView.frame.width - containerViewHorizontalMargin   // the as same width as statusView
        }

        switch viewModel.value {
        case .feed(let feed):
            notificationView.configure(feed: feed)
        }
        
        self.delegate = delegate

        Publishers.CombineLatest(
            notificationView.statusView.viewModel.$isContentReveal.removeDuplicates(),
            notificationView.quoteStatusView.viewModel.$isContentReveal.removeDuplicates()
        )
        .dropFirst()
        .receive(on: DispatchQueue.main)
        .sink { [weak tableView, weak self] _, _ in
            guard let tableView = tableView else { return }
            guard let self = self else { return }
            self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): tableView updates")

            UIView.performWithoutAnimation {
                tableView.beginUpdates()
                tableView.endUpdates()                
            }
        }
        .store(in: &disposeBag)
    }
    
}
