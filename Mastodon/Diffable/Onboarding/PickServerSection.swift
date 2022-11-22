//
//  PickServerSection.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021/3/5.
//

import UIKit
import MastodonSDK
import Kanna
import AlamofireImage

enum PickServerSection: Equatable, Hashable {
    case header
    case servers
}

extension PickServerSection {
    static func tableViewDiffableDataSource(
        for tableView: UITableView,
        dependency: NeedsDependency
    ) -> UITableViewDiffableDataSource<PickServerSection, PickServerItem> {
        tableView.register(OnboardingHeadlineTableViewCell.self, forCellReuseIdentifier: String(describing: OnboardingHeadlineTableViewCell.self))
        tableView.register(PickServerCell.self, forCellReuseIdentifier: String(describing: PickServerCell.self))
        tableView.register(PickServerLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: PickServerLoaderTableViewCell.self))
        
        return UITableViewDiffableDataSource(tableView: tableView) { [
            weak dependency
        ] tableView, indexPath, item -> UITableViewCell? in
            guard let _ = dependency else { return nil }
            switch item {
            case .header:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: OnboardingHeadlineTableViewCell.self), for: indexPath) as! OnboardingHeadlineTableViewCell
                return cell
            case .server(let server, let attribute):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PickServerCell.self), for: indexPath) as! PickServerCell
                PickServerSection.configure(cell: cell, server: server, attribute: attribute)
                return cell
            case .loader(let attribute):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PickServerLoaderTableViewCell.self), for: indexPath) as! PickServerLoaderTableViewCell
                PickServerSection.configure(cell: cell, attribute: attribute)
                return cell
            }
        }
    }
}

extension PickServerSection {
    
    static func configure(cell: PickServerCell, server: Mastodon.Entity.Server, attribute: PickServerItem.ServerItemAttribute) {
        cell.domainLabel.text = server.domain
        cell.descriptionLabel.attributedText = {
            let content: String = {
                guard let html = try? HTML(html: server.description, encoding: .utf8) else {
                    return server.description
                }
                return html.text ?? server.description
            }()
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineHeightMultiple = 1.16
            
            return NSAttributedString(
                string: content,
                attributes: [
                    .paragraphStyle: paragraphStyle
                ]
            )
        }()
        cell.usersValueLabel.attributedText = {
            let attributedString = NSMutableAttributedString()
            let attachment = NSTextAttachment(image: UIImage(systemName: "person.2.fill")!)
            let attachmentAttributedString = NSAttributedString(attachment: attachment)
            attributedString.append(attachmentAttributedString)
            attributedString.append(NSAttributedString(string: " "))
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineHeightMultiple = 1.12
            let valueAttributedString = NSAttributedString(
                string: parseUsersCount(server.totalUsers),
                attributes: [
                    .paragraphStyle: paragraphStyle
                ]
            )
            attributedString.append(valueAttributedString)
            
            return attributedString
        }()
        cell.langValueLabel.attributedText = {
            let attributedString = NSMutableAttributedString()
            let attachment = NSTextAttachment(image: UIImage(systemName: "text.bubble.fill")!)
            let attachmentAttributedString = NSAttributedString(attachment: attachment)
            attributedString.append(attachmentAttributedString)
            attributedString.append(NSAttributedString(string: " "))
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineHeightMultiple = 1.12
            let valueAttributedString = NSAttributedString(
                string: server.language.uppercased(),
                attributes: [
                    .paragraphStyle: paragraphStyle
                ]
            )
            attributedString.append(valueAttributedString)

            return attributedString
        }()
      
        attribute.isLast
            .receive(on: DispatchQueue.main)
            .sink { [weak cell] isLast in
                guard let cell = cell else { return }
                if isLast {
                    cell.containerView.layer.maskedCorners = [
                        .layerMinXMaxYCorner,
                        .layerMaxXMaxYCorner
                    ]
                    cell.containerView.layer.cornerCurve = .continuous
                    cell.containerView.layer.cornerRadius = MastodonPickServerAppearance.tableViewCornerRadius
                    cell.containerView.layer.masksToBounds = true
                } else {
                    cell.containerView.layer.cornerRadius = 0
                    cell.containerView.layer.masksToBounds = false
                }
            }
            .store(in: &cell.disposeBag)
    }
    
    private static func parseUsersCount(_ usersCount: Int) -> String {
        switch usersCount {
        case 0..<1000:
            return "\(usersCount)"
        default:
            let usersCountInThousand = Float(usersCount) / 1000.0
            return String(format: "%.1fK", usersCountInThousand)
        }
    }
    
}

extension PickServerSection {
    
    static func configure(cell: PickServerLoaderTableViewCell, attribute: PickServerItem.LoaderItemAttribute) {
        if attribute.isLast {
            cell.containerView.layer.maskedCorners = [
                .layerMinXMaxYCorner,
                .layerMaxXMaxYCorner
            ]
            cell.containerView.layer.cornerCurve = .continuous
            cell.containerView.layer.cornerRadius = MastodonPickServerAppearance.tableViewCornerRadius
            cell.containerView.layer.masksToBounds = true
        } else {
            cell.containerView.layer.cornerRadius = 0
            cell.containerView.layer.masksToBounds = false
        }
        
        attribute.isNoResult ? cell.stopAnimating() : cell.startAnimating()
        cell.emptyStatusLabel.isHidden = !attribute.isNoResult
    }
    
}
