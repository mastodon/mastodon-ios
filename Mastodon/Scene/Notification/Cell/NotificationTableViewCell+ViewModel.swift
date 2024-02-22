//
//  NotificationView+ViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-21.
//

import UIKit
import Combine
import CoreDataStack
import MastodonSDK
import MastodonCore

extension NotificationTableViewCell {
    final class ViewModel {
        let value: Value

        init(value: Value) {
            self.value = value
        }
        
        enum Value {
            case feed(MastodonFeed)
        }
    }
}

extension NotificationTableViewCell {

    func configure(
        tableView: UITableView,
        viewModel: ViewModel,
        delegate: NotificationTableViewCellDelegate?,
        authenticationBox: MastodonAuthenticationBox
    ) {
        if notificationView.frame == .zero {
            // set status view width
            notificationView.frame.size.width = tableView.frame.width - containerViewHorizontalMargin

            notificationView.statusView.frame.size.width = tableView.frame.width - containerViewHorizontalMargin
            notificationView.quoteStatusView.frame.size.width = tableView.frame.width - containerViewHorizontalMargin   // the as same width as statusView
        }

        switch viewModel.value {
        case .feed(let feed):
            notificationView.configure(feed: feed, authenticationBox: authenticationBox)
        }
        
        self.delegate = delegate

        Publishers.CombineLatest(
            notificationView.statusView.viewModel.$isContentReveal.removeDuplicates(),
            notificationView.quoteStatusView.viewModel.$isContentReveal.removeDuplicates()
        )
        .dropFirst()
        .receive(on: DispatchQueue.main)
        .sink { [weak tableView] _, _ in
            guard let tableView = tableView else { return }

            UIView.performWithoutAnimation {
                tableView.beginUpdates()
                tableView.endUpdates()
            }
        }
        .store(in: &disposeBag)
    }
    
}
