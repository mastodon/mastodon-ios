//
//  StatusTableViewCell+ViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-12.
//

import UIKit
import CoreDataStack

extension StatusTableViewCell {
    final class ViewModel {
        let value: Value

        init(value: Value) {
            self.value = value
        }
        
        enum Value {
            case feed(Feed)
            case status(Status)
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
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): did layout for new cell")
        }
        
        switch viewModel.value {
        case .feed(let feed):
            statusView.configure(feed: feed)
            
            feed.publisher(for: \.hasMore)
                .sink { [weak self] hasMore in
                    guard let self = self else { return }
                    self.separatorLine.isHidden = hasMore
                }
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
