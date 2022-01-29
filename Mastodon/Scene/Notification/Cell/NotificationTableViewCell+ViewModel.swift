//
//  NotificationView+ViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-21.
//

import UIKit
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
            notificationView.frame.size.width = tableView.frame.width
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): did layout for new cell")
            
            notificationView.statusView.frame.size.width = tableView.frame.width
            notificationView.quoteStatusView.frame.size.width = tableView.frame.width - StatusView.containerLayoutMargin.left - StatusView.containerLayoutMargin.right
        }

        switch viewModel.value {
        case .feed(let feed):
            notificationView.configure(feed: feed)
        }
//
         self.delegate = delegate
    }
    
}
