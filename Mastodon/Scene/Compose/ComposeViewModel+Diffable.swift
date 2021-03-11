//
//  ComposeViewModel+Diffable.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-11.
//

import UIKit

extension ComposeViewModel {
    
    func setupDiffableDataSource(for tableView: UITableView) {
        diffableDataSource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, item -> UITableViewCell? in
            guard let self = self else { return nil }
            
            switch item {
            case .replyTo(let tootObjectID):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ComposeRepliedToTootContentTableViewCell.self), for: indexPath) as! ComposeRepliedToTootContentTableViewCell
                // TODO:
                return cell
            case .toot(let attribute):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ComposeTootContentTableViewCell.self), for: indexPath) as! ComposeTootContentTableViewCell
                // TODO:
                return cell
            }
        }
        
        var snapshot = NSDiffableDataSourceSnapshot<ComposeStatusSection, ComposeStatusItem>()
        snapshot.appendSections([.repliedTo, .status])
        switch composeKind {
        case .replyToot(let tootObjectID):
            snapshot.appendItems([.replyTo(tootObjectID: tootObjectID)], toSection: .repliedTo)
            snapshot.appendItems([.toot(attribute: ComposeStatusItem.InputAttribute(hasReplyTo: true))], toSection: .status)
        case .toot:
            snapshot.appendItems([.toot(attribute: ComposeStatusItem.InputAttribute(hasReplyTo: false))], toSection: .status)
        }
        diffableDataSource.apply(snapshot, animatingDifferences: false)
    }
    
}
