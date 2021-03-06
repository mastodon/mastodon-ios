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
    case category
    case search
    case servers
}

extension PickServerSection {
    static func tableViewDiffableDataSource(
        for tableView: UITableView,
        dependency: NeedsDependency,
        pickServerCategoriesCellDelegate: PickServerCategoriesCellDelegate,
        pickServerSearchCellDelegate: PickServerSearchCellDelegate,
        pickServerCellDelegate: PickServerCellDelegate
    ) -> UITableViewDiffableDataSource<PickServerSection, PickServerItem> {
        UITableViewDiffableDataSource(tableView: tableView) { [weak pickServerCategoriesCellDelegate, weak pickServerSearchCellDelegate, weak pickServerCellDelegate] tableView, indexPath, item -> UITableViewCell? in
            switch item {
            case .header:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PickServerTitleCell.self), for: indexPath) as! PickServerTitleCell
                return cell
            case .categoryPicker(let items):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PickServerCategoriesCell.self), for: indexPath) as! PickServerCategoriesCell
                cell.delegate = pickServerCategoriesCellDelegate
                cell.diffableDataSource = CategoryPickerSection.collectionViewDiffableDataSource(
                    for: cell.collectionView,
                    dependency: dependency
                )
                var snapshot = NSDiffableDataSourceSnapshot<CategoryPickerSection, CategoryPickerItem>()
                snapshot.appendSections([.main])
                snapshot.appendItems(items, toSection: .main)
                cell.diffableDataSource?.apply(snapshot, animatingDifferences: false, completion: nil)
                return cell
            case .search:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PickServerSearchCell.self), for: indexPath) as! PickServerSearchCell
                cell.delegate = pickServerSearchCellDelegate
                return cell
            case .server(let server, let attribute):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PickServerCell.self), for: indexPath) as! PickServerCell
                PickServerSection.configure(cell: cell, server: server, attribute: attribute)
                cell.delegate = pickServerCellDelegate
                return cell
            }
        }
    }
}

extension PickServerSection {
    
    static func configure(cell: PickServerCell, server: Mastodon.Entity.Server, attribute: PickServerItem.ServerItemAttribute) {
        cell.domainLabel.text = server.domain
        cell.descriptionLabel.text = {
            guard let html = try? HTML(html: server.description, encoding: .utf8) else {
                return server.description
            }
            
            return html.text ?? server.description
        }()
        cell.langValueLabel.text = server.language.uppercased()
        cell.usersValueLabel.text = parseUsersCount(server.totalUsers)
        cell.categoryValueLabel.text = server.category.uppercased()
        
        cell.updateExpandMode(mode: attribute.isExpand ? .expand : .collapse)
        
        if attribute.isLast {
            cell.containerView.layer.maskedCorners = [
                .layerMinXMaxYCorner,
                .layerMaxXMaxYCorner
            ]
            cell.containerView.layer.cornerCurve = .continuous
            cell.containerView.layer.cornerRadius = MastodonPickServerAppearance.tableViewCornerRadius
        } else {
            cell.containerView.layer.cornerRadius = 0
        }
        
        cell.expandMode
            .receive(on: DispatchQueue.main)
            .sink { mode in
                switch mode {
                case .collapse:
                    // do nothing
                    break
                case .expand:
                    let placeholderImage = UIImage.placeholder(size: cell.thumbnailImageView.frame.size, color: .systemFill)
                        .af.imageRounded(withCornerRadius: 3.0, divideRadiusByImageScale: false)
                    guard let proxiedThumbnail = server.proxiedThumbnail,
                          let url = URL(string: proxiedThumbnail) else {
                        cell.thumbnailImageView.image = placeholderImage
                        cell.thumbnailActivityIdicator.stopAnimating()
                        return
                    }
                    cell.thumbnailImageView.isHidden = false
                    cell.thumbnailActivityIdicator.startAnimating()
            
                    cell.thumbnailImageView.af.setImage(
                        withURL: url,
                        placeholderImage: placeholderImage,
                        filter: AspectScaledToFillSizeWithRoundedCornersFilter(size: cell.thumbnailImageView.frame.size, radius: 3),
                        imageTransition: .crossDissolve(0.33),
                        completion: { [weak cell] response in
                            switch response.result {
                            case .success, .failure:
                                cell?.thumbnailActivityIdicator.stopAnimating()
                            }
                        }
                    )
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
