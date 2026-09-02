//
//  ReportSection.swift
//  Mastodon
//
//  Created by ihugo on 2021/4/20.
//

import Combine
import Foundation
import MastodonSDK
import UIKit
import MastodonUI
import SwiftUI

enum ReportSection: Equatable, Hashable, Sendable {
    case main
}

extension ReportSection {
    
    struct StatusRowSupport {
        let postViewModel: @MainActor (MastodonStatus) -> MastodonPostViewModel?
        let canChangeSelection: @MainActor (MastodonStatus) -> Bool
        let isSelected: @MainActor (MastodonStatus) -> Binding<Bool> // for now the binding is never actually exercised, because the tableview is handling the selection
    }
    
    @MainActor
    static func diffableDataSource(
        tableView: UITableView,
        statusRowSupport: StatusRowSupport?
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
                guard let statusRowSupport = statusRowSupport else { return cell }
                guard let postViewModel = statusRowSupport.postViewModel(status) else { return cell }
                cell.configure(
                    postViewModel: postViewModel,
                    layoutWidth: tableView.bounds.inset(by: tableView.safeAreaInsets).width,
                    canChangeSelection: statusRowSupport.canChangeSelection(status),
                    isSelected: statusRowSupport.isSelected(status)
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
