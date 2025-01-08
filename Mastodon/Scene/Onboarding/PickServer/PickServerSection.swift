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
        dependency: UIViewController
    ) -> UITableViewDiffableDataSource<PickServerSection, PickServerItem> {
        tableView.register(PickServerCell.self, forCellReuseIdentifier: String(describing: PickServerCell.self))
        tableView.register(PickServerLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: PickServerLoaderTableViewCell.self))
        
        return UITableViewDiffableDataSource(tableView: tableView) { [
            weak dependency
        ] tableView, indexPath, item -> UITableViewCell? in
            guard let _ = dependency else { return nil }
            switch item {
            case .server(let server, let attribute):
                guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PickServerCell.self), for: indexPath) as? PickServerCell else {
                    assertionFailure("unexpected cell dequeued")
                    return nil
                }
                PickServerSection.configure(cell: cell, server: server, attribute: attribute)
                return cell
            case .loader(let attribute):
                guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PickServerLoaderTableViewCell.self), for: indexPath) as? PickServerLoaderTableViewCell else {
                    assertionFailure("unexpected cell dequeued")
                    return nil
                }
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
        if let proxiedThumbnail = server.proxiedThumbnail, let thumbnailUrl = URL(string: proxiedThumbnail) {
            cell.thumbnailImageView.af.setImage(withURL: thumbnailUrl, completion: { _ in
                DispatchQueue.main.async {
                    cell.thumbnailImageView.isHidden = false
                }
            })
        }
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
