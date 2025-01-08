//
//  ReportSection.swift
//  Mastodon
//
//  Created by ihugo on 2021/4/20.
//

import Combine
import CoreData
import CoreDataStack
import Foundation
import MastodonSDK
import UIKit
import MastodonAsset
import MastodonCore
import MastodonUI
import MastodonLocalization

enum ReportSection: Equatable, Hashable {
    case main
}

extension ReportSection {
    
    struct Configuration {
        let authenticationBox: MastodonAuthenticationBox
    }
    
    static func diffableDataSource(
        tableView: UITableView,
        context: AppContext,
        configuration: Configuration
    ) -> UITableViewDiffableDataSource<ReportSection, ReportItem> {
        
        tableView.register(ReportHeadlineTableViewCell.self, forCellReuseIdentifier: String(describing: ReportHeadlineTableViewCell.self))
        tableView.register(ReportStatusTableViewCell.self, forCellReuseIdentifier: String(describing: ReportStatusTableViewCell.self))
        tableView.register(ReportCommentTableViewCell.self, forCellReuseIdentifier: String(describing: ReportCommentTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))

        return UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item -> UITableViewCell? in
            switch item {
            case .header(let headerContext):
                guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ReportHeadlineTableViewCell.self), for: indexPath) as? ReportHeadlineTableViewCell else {
                    assertionFailure("unexpected cell dequeued")
                    return nil
                }
                cell.primaryLabel.text = headerContext.primaryLabelText
                cell.secondaryLabel.text = headerContext.secondaryLabelText
                return cell
            case .status(let status):
                guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ReportStatusTableViewCell.self), for: indexPath) as? ReportStatusTableViewCell else {
                    assertionFailure("unexpected cell dequeued")
                    return nil
                }
                configure(
                    tableView: tableView,
                    cell: cell,
                    viewModel: .init(value: status),
                    configuration: configuration
                )
                return cell
            case .comment(let commentContext):
                guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ReportCommentTableViewCell.self), for: indexPath) as? ReportCommentTableViewCell else {
                    assertionFailure("unexpected cell dequeued")
                    return nil
                }
                cell.commentTextView.text = commentContext.comment
                NotificationCenter.default.publisher(for: UITextView.textDidChangeNotification, object: cell.commentTextView)
                    .receive(on: DispatchQueue.main)
                    .sink { [weak cell] notification in
                        guard let cell = cell else { return }
                        commentContext.comment = cell.commentTextView.text
                        
                        // fix shadow get animation issue when cell height changes
                        UIView.performWithoutAnimation {
                            tableView.beginUpdates()
                            tableView.endUpdates()
                        }
                    }
                    .store(in: &cell.disposeBag)
                return cell
            case .bottomLoader:
                guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as? TimelineBottomLoaderTableViewCell else { assertionFailure("unexpected cell dequeued")
                    return nil
                }
                cell.activityIndicatorView.startAnimating()
                return cell
            }
        }
    }
}

extension ReportSection {
    
    static func configure(
        tableView: UITableView,
        cell: ReportStatusTableViewCell,
        viewModel: ReportStatusTableViewCell.ViewModel,
        configuration: Configuration
    ) {
        StatusSection.setupStatusPollDataSource(
            authenticationBox: configuration.authenticationBox,
            statusView: cell.statusView
        )
        
        cell.statusView.viewModel.authenticationBox = configuration.authenticationBox
        
        cell.configure(
            tableView: tableView,
            viewModel: viewModel
        )
    }
    
}
