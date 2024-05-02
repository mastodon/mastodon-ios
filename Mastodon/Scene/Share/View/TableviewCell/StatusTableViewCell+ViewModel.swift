//
//  StatusTableViewCell+ViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-12.
//

import UIKit
import MastodonSDK

extension StatusTableViewCell {
    final class ViewModel {
        let value: Value

        init(value: Value) {
            self.value = value
        }
        
        enum Value {
            case feed(MastodonFeed)
            case status(MastodonStatus)
        }
    }
}

extension StatusTableViewCell {

    func configure(
        tableView: UITableView,
        viewModel: ViewModel,
        delegate: StatusTableViewCellDelegate?
    ) {
        if statusView.frame == .zero {
            // set status view width
            statusView.frame.size.width = tableView.frame.width - containerViewHorizontalMargin
        }
        
        switch viewModel.value {
        case .feed(let feed):
            statusView.configure(feed: feed)
            self.separatorLine.isHidden = feed.hasMore
            feed.$hasMore.sink(receiveValue: { [weak self] hasMore in
                self?.separatorLine.isHidden = hasMore
            })
            .store(in: &disposeBag)
            
        case .status(let status):
            statusView.configure(status: status)
        }
        
        self.delegate = delegate
        
        statusView.viewModel.$isContentReveal
            .removeDuplicates()
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak tableView, weak self] _ in
                guard let tableView = tableView else { return }
                guard let _ = self else { return }

                UIView.performWithoutAnimation {
                    tableView.beginUpdates()
                    tableView.endUpdates()
                }
            }
            .store(in: &disposeBag)

        statusView.viewModel.$card
            .removeDuplicates()
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak tableView, weak self] _ in
                guard let tableView = tableView else { return }
                guard let _ = self else { return }

                UIView.performWithoutAnimation {
                    tableView.beginUpdates()
                    tableView.endUpdates()
                }
            }
            .store(in: &disposeBag)
    }
    
}
