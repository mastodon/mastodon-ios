//
//  PollSection.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-2.
//

import UIKit
import CoreData
import CoreDataStack

import MastodonSDK

extension Mastodon.Entity.Attachment: Hashable {
    public static func == (lhs: Mastodon.Entity.Attachment, rhs: Mastodon.Entity.Attachment) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

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
                    PollSection.configure(cell: cell, pollOption: option, pollItemAttribute: attribute)
                }
                return cell
            }
       }
    }
}

extension PollSection {
    static func configure(
        cell: PollOptionTableViewCell,
        pollOption option: PollOption,
        pollItemAttribute attribute: PollItem.Attribute
    ) {
        cell.pollOptionView.optionTextField.text = option.title
        configure(cell: cell, selectState: attribute.selectState)
        configure(cell: cell, voteState: attribute.voteState)
        cell.attribute = attribute
        cell.layoutIfNeeded()
        cell.updateTextAppearance()
    }
}

extension PollSection {
    
    static func configure(cell: PollOptionTableViewCell, selectState state: PollItem.Attribute.SelectState) {
        switch state {
        case .none:
            cell.pollOptionView.checkmarkBackgroundView.isHidden = true
            cell.pollOptionView.checkmarkImageView.isHidden = true
        case .off:
            cell.pollOptionView.checkmarkBackgroundView.backgroundColor = .systemBackground
            cell.pollOptionView.checkmarkBackgroundView.layer.borderColor = UIColor.systemGray3.cgColor
            cell.pollOptionView.checkmarkBackgroundView.layer.borderWidth = 1
            cell.pollOptionView.checkmarkBackgroundView.isHidden = false
            cell.pollOptionView.checkmarkImageView.isHidden = true
        case .on:
            cell.pollOptionView.checkmarkBackgroundView.backgroundColor = .systemBackground
            cell.pollOptionView.checkmarkBackgroundView.layer.borderColor = UIColor.clear.cgColor
            cell.pollOptionView.checkmarkBackgroundView.layer.borderWidth = 0
            cell.pollOptionView.checkmarkBackgroundView.isHidden = false
            cell.pollOptionView.checkmarkImageView.isHidden = false
        }
    }

    static func configure(cell: PollOptionTableViewCell, voteState state: PollItem.Attribute.VoteState) {
        switch state {
        case .hidden:
            cell.pollOptionView.optionPercentageLabel.isHidden = true
            cell.pollOptionView.voteProgressStripView.isHidden = true
            cell.pollOptionView.voteProgressStripView.setProgress(0.0, animated: false)
        case .reveal(let voted, let percentage, let animated):
            cell.pollOptionView.optionPercentageLabel.isHidden = false
            cell.pollOptionView.optionPercentageLabel.text = String(Int(100 * percentage)) + "%"
            cell.pollOptionView.voteProgressStripView.isHidden = false
            cell.pollOptionView.voteProgressStripView.tintColor = voted ? Asset.Colors.brandBlue.color : Asset.Colors.Background.Poll.disabled.color
            cell.pollOptionView.voteProgressStripView.setProgress(CGFloat(percentage), animated: animated)
        }
    }
    
}
