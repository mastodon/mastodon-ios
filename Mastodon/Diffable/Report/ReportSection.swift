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
        let authContext: AuthContext
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
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ReportHeadlineTableViewCell.self), for: indexPath) as! ReportHeadlineTableViewCell
                cell.primaryLabel.text = headerContext.primaryLabelText
                cell.secondaryLabel.text = headerContext.secondaryLabelText
                return cell
            case .status(let status):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ReportStatusTableViewCell.self), for: indexPath) as! ReportStatusTableViewCell
                configure(
                    context: context,
                    tableView: tableView,
                    cell: cell,
                    status: status,
                    configuration: configuration
                )
                return cell
            case .comment(let commentContext):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ReportCommentTableViewCell.self), for: indexPath) as! ReportCommentTableViewCell
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
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as! TimelineBottomLoaderTableViewCell
                cell.activityIndicatorView.startAnimating()
                return cell
            }
        }
    }
}

extension ReportSection {
    
    static func configure(
        context: AppContext,
        tableView: UITableView,
        cell: ReportStatusTableViewCell,
        status: MastodonStatus,
        configuration: Configuration
    ) {
        StatusSection.setupStatusPollDataSource(
            context: context,
            authContext: configuration.authContext,
            statusView: cell.statusView
        )
        
        cell.statusView.viewModel.context = context
        cell.statusView.viewModel.authContext = configuration.authContext
        
        cell.configure(
            tableView: tableView,
            status: status
        )
    }
    
}
