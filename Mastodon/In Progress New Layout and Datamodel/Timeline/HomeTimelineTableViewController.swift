// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import Combine
import SwiftUI
import UIKit

private enum Section {
    case main
}

private var avatarSize = AvatarSize.large

@MainActor
class HomeTimelineTableViewController: UITableViewController {

    var viewModel = HomeTimelineListViewModel(timeline: .following)
    fileprivate var datasource: TimelineDataSource?
    fileprivate var viewModelSubscriptions = Set<AnyCancellable>()
    
    init() {
        super.init(style: .plain)
        
        viewModel.$timelineItems.sink { [weak self] items in
            guard let self else { return }
            var replacementSnapshot = NSDiffableDataSourceSnapshot<Section, TimelineItem>()
            replacementSnapshot.appendSections([.main])
            replacementSnapshot.appendItems(items)
            datasource?.apply(replacementSnapshot)
            
            if items.count > 10 {
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                    self.tableView.scrollToRow(at: IndexPath(row: items.count / 2, section: 0), at: .top, animated: false)
                }
            }
        }.store(in: &viewModelSubscriptions)
    }
    
    override func viewDidLoad() {
        tableView.delegate = self
        tableView.register(MastodonPostRowHostingCell.self, forCellReuseIdentifier: "cell")
        datasource = TimelineDataSource(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, itemIdentifier in
            guard let self else { return UITableViewCell() }
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! MastodonPostRowHostingCell
            cell.contentWidth = self.postContentWidth(for: self.view.frame.size.width)
            switch itemIdentifier {
            case .loadingIndicator, .missingPosts:
                cell.configureToShowSomething()
            case .post(let viewModel):
                cell.viewModel = viewModel
            }
            return cell
        })
        tableView.dataSource = datasource
        
        var snapshot = datasource?.snapshot()
        snapshot?.appendSections([.main])
        datasource?.apply(snapshot!)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if let snapshot = datasource?.snapshot() {
            datasource?.applySnapshotUsingReloadData(snapshot)
        }
    }
    
    func postContentWidth(for viewWidth: CGFloat) -> CGFloat {
        let usableWidth = viewWidth
        let contentWidth = max(1, usableWidth - (spacingBetweenGutterAndContent * 3) - avatarSize)
        return contentWidth
    }
}

class MastodonPostRowHostingCell: UITableViewCell {
    var contentWidth: CGFloat = 10
    var widthConstraint: NSLayoutConstraint?
    
    var viewModel: MastodonPostViewModel? {
        didSet {
            self.contentView.backgroundColor = .clear
            self.contentConfiguration = UIHostingConfiguration(content: {
                HomeTimelinePostRowView(contentConcealModel: .alwaysShow,
                                        contentWidth: contentWidth)
                .environment(viewModel)
            })
        }
    }
    
    func configureToShowSomething() {
        self.contentView.backgroundColor = .yellow
        if self.widthConstraint == nil {
            widthConstraint = widthAnchor.constraint(equalToConstant: contentWidth)
            NSLayoutConstraint.activate([widthConstraint!])
        }
        widthConstraint?.constant = contentWidth
        setNeedsUpdateConstraints()
    }
}

fileprivate class TimelineDataSource: UITableViewDiffableDataSource<Section, TimelineItem> {
    var contentWidth: CGFloat = 10
}
