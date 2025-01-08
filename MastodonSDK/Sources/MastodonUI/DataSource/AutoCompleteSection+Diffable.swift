//
//  AutoCompleteSection+Diffable.swift
//  
//
//  Created by MainasuK on 22/10/10.
//

import UIKit
import MastodonCore
import MastodonSDK
import MastodonLocalization
import MastodonMeta

extension AutoCompleteSection {
    
    public static func tableViewDiffableDataSource(
        tableView: UITableView
    ) -> UITableViewDiffableDataSource<AutoCompleteSection, AutoCompleteItem> {
        UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item in
            switch item {
            case .hashtag(let hashtag):
                guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: AutoCompleteTableViewCell.self), for: indexPath) as? AutoCompleteTableViewCell else {
                    assertionFailure("unexpected cell dequeued")
                    return nil
                }
                configureHashtag(cell: cell, hashtag: hashtag)
                return cell
            case .hashtagV1(let hashtagName):
                guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: AutoCompleteTableViewCell.self), for: indexPath) as? AutoCompleteTableViewCell else {
                    assertionFailure("unexpected cell dequeued")
                    return nil
                }
                configureHashtag(cell: cell, hashtagName: hashtagName)
                return cell
            case .account(let account):
                guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: AutoCompleteTableViewCell.self), for: indexPath) as? AutoCompleteTableViewCell else {
                    assertionFailure("unexpected cell dequeued")
                    return nil
                }
                configureAccount(cell: cell, account: account)
                return cell
            case .emoji(let emoji):
                guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: AutoCompleteTableViewCell.self), for: indexPath) as? AutoCompleteTableViewCell else {
                    assertionFailure("unexpected cell dequeued")
                    return nil
                }
                configureEmoji(cell: cell, emoji: emoji, isFirst: indexPath.row == 0)
                return cell
            case .bottomLoader:
                guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as? TimelineBottomLoaderTableViewCell else { assertionFailure("unexpected cell dequeued")
                    return nil
                }
                cell.startAnimating()
                return cell
            }
        }
    }

}

extension AutoCompleteSection {

    private static func configureHashtag(cell: AutoCompleteTableViewCell, hashtag: Mastodon.Entity.Tag) {
        let metaContent = PlaintextMetaContent(string: "#" + hashtag.name)
        cell.titleLabel.configure(content: metaContent)
        cell.subtitleLabel.text = {
            let count = (hashtag.history ?? [])
                .sorted(by: { $0.day > $1.day })
                .prefix(2)
                .compactMap { Int($0.accounts) }
                .reduce(0, +)
            return L10n.Plural.peopleTalking(count)
        }()
        cell.avatarImageView.isHidden = true
    }
    
    private static func configureHashtag(cell: AutoCompleteTableViewCell, hashtagName: String) {
        let metaContent = PlaintextMetaContent(string: "#" + hashtagName)
        cell.titleLabel.configure(content: metaContent)
        cell.subtitleLabel.text = " "
        cell.avatarImageView.isHidden = true
    }
    
    private static func configureAccount(cell: AutoCompleteTableViewCell, account: Mastodon.Entity.Account) {
        let mastodonContent = MastodonContent(content: account.displayNameWithFallback, emojis: account.emojiMeta)
        do {
            let metaContent = try MastodonMetaContent.convert(document: mastodonContent)
            cell.titleLabel.configure(content: metaContent)
        } catch {
            let metaContent = PlaintextMetaContent(string: account.displayNameWithFallback)
            cell.titleLabel.configure(content: metaContent)
        }
        cell.subtitleLabel.text = "@" + account.acct
        cell.avatarImageView.isHidden = false
        cell.avatarImageView.configure(with: URL(string: account.avatar))
    }
    
    private static func configureEmoji(cell: AutoCompleteTableViewCell, emoji: Mastodon.Entity.Emoji, isFirst: Bool) {
        let metaContent = PlaintextMetaContent(string: ":" + emoji.shortcode + ":")
        cell.titleLabel.configure(content: metaContent)
        // FIXME: handle spacer enter to complete emoji
        // cell.subtitleLabel.text = isFirst ? L10n.Scene.Compose.AutoComplete.spaceToAdd : " "
        cell.subtitleLabel.text = " "
        cell.avatarImageView.isHidden = false
        cell.avatarImageView.configure(with: URL(string: emoji.url))
    }
    
}
