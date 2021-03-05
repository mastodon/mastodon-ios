//
//  PollSection.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-2.
//

import UIKit
import CoreData
import CoreDataStack

enum PollSection: Equatable, Hashable {
    case main
}

extension PollSection {
    static func tableViewDiffableDataSource(
        for tableView: UITableView,
        managedObjectContext: NSManagedObjectContext
    ) -> UITableViewDiffableDataSource<PollSection, PollItem> {
        return UITableViewDiffableDataSource<PollSection, PollItem>(tableView: tableView) { tableView, indexPath, item -> UITableViewCell? in
            switch item {
            case .opion(let objectID, let attribute):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PollOptionTableViewCell.self), for: indexPath) as! PollOptionTableViewCell
                managedObjectContext.performAndWait {
                    let option = managedObjectContext.object(with: objectID) as! PollOption
                    PollSection.configure(cell: cell, pollOption: option, itemAttribute: attribute)
                }
                return cell
            }
       }
    }
}

extension PollSection {
    static func configure(
        cell: PollOptionTableViewCell,
        pollOption: PollOption,
        itemAttribute: PollItem.Attribute
    ) {
        cell.optionLabel.text = pollOption.title
        configure(cell: cell, selectState: itemAttribute.selectState)
        configure(cell: cell, voteState: itemAttribute.voteState)
    }
}

extension PollSection {
    
    static func configure(cell: PollOptionTableViewCell, selectState state: PollItem.Attribute.SelectState) {
        switch state {
        case .none:
            cell.checkmarkBackgroundView.isHidden = true
            cell.checkmarkImageView.isHidden = true
        case .off:
            cell.checkmarkBackgroundView.backgroundColor = .systemBackground
            cell.checkmarkBackgroundView.layer.borderColor = UIColor.systemGray3.cgColor
            cell.checkmarkBackgroundView.layer.borderWidth = 1
            cell.checkmarkBackgroundView.isHidden = false
            cell.checkmarkImageView.isHidden = true
        case .on:
            cell.checkmarkBackgroundView.backgroundColor = .systemBackground
            cell.checkmarkBackgroundView.layer.borderColor = UIColor.clear.cgColor
            cell.checkmarkBackgroundView.layer.borderWidth = 0
            cell.checkmarkBackgroundView.isHidden = false
            cell.checkmarkImageView.isHidden = false
        }
        
        cell.selectState = state
    }

    static func configure(cell: PollOptionTableViewCell, voteState state: PollItem.Attribute.VoteState) {
        switch state {
        case .hidden:
            cell.optionPercentageLabel.isHidden = true
        case .reveal(let voted, let percentage):
            cell.optionPercentageLabel.isHidden = false
            cell.optionPercentageLabel.text = String(Int(100 * percentage)) + "%"
            cell.voteProgressStripView.tintColor = voted ? Asset.Colors.Background.Poll.highlight.color : Asset.Colors.Background.Poll.disabled.color
            cell.voteProgressStripView.setProgress(CGFloat(percentage), animated: true)
        }
        cell.voteState = state
        
        cell.layoutIfNeeded()
        cell.updateTextAppearance()
    }
    
}
