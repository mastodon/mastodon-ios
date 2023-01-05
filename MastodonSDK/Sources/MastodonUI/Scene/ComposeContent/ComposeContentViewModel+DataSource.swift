//
//  ComposeContentViewModel+DataSource.swift
//  
//
//  Created by MainasuK on 22/10/10.
//

import UIKit
import MastodonCore
import CoreDataStack
import UIHostingConfigurationBackport

extension ComposeContentViewModel {
    
    func setupDataSource(
        tableView: UITableView
    ) {
        tableView.dataSource = self
        
        setupTableViewCell(tableView: tableView)
    }
    
}

extension ComposeContentViewModel {
    enum Section: CaseIterable {
        case replyTo
        case status
    }

    private func setupTableViewCell(tableView: UITableView) {        
        composeContentTableViewCell.contentConfiguration = UIHostingConfigurationBackport {
            ComposeContentView(viewModel: self)
        }
        
        $contentCellFrame
            .map { $0.height }
            .removeDuplicates()
            .sink { [weak self] height in
                guard let self = self else { return }
                guard !tableView.visibleCells.isEmpty else { return }
                UIView.performWithoutAnimation {
                    tableView.beginUpdates()
                    self.composeContentTableViewCell.frame.size.height = height
                    tableView.endUpdates()                    
                }
            }
            .store(in: &disposeBag)
        
        if case .reply(let status) = destination {
            let cell = composeReplyToTableViewCell
            // bind frame publisher
            cell.$framePublisher
                .receive(on: DispatchQueue.main)
                .assign(to: \.replyToCellFrame, on: self)
                .store(in: &cell.disposeBag)

            // set initial width
            cell.statusView.frame.size.width = tableView.frame.width

            // configure status
            context.managedObjectContext.performAndWait {
                guard let replyTo = status.object(in: context.managedObjectContext) else { return }
                cell.statusView.configure(status: replyTo)
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension ComposeContentViewModel: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section.allCases[section] {
        case .replyTo:
            switch destination {
            case .reply:        return 1
            default:            return 0
            }
        case .status:           return 1
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section.allCases[indexPath.section] {
        case .replyTo:
            return composeReplyToTableViewCell
        case .status:
            return composeContentTableViewCell
        }
    }
}

extension ComposeContentViewModel {
    
    func setupCustomEmojiPickerDiffableDataSource(
        collectionView: UICollectionView
    ) {
        let diffableDataSource = CustomEmojiPickerSection.collectionViewDiffableDataSource(
            collectionView: collectionView,
            context: context
        )
        self.customEmojiPickerDiffableDataSource = diffableDataSource
        
        let domain = authContext.mastodonAuthenticationBox.domain.uppercased()
        customEmojiViewModel?.emojis
            .receive(on: DispatchQueue.main)
            .sink { [weak self, weak diffableDataSource] emojis in
                guard let _ = self else { return }
                guard let diffableDataSource = diffableDataSource else { return }
                
                var snapshot = NSDiffableDataSourceSnapshot<CustomEmojiPickerSection, CustomEmojiPickerItem>()
                let customEmojiSection = CustomEmojiPickerSection.emoji(name: domain)
                snapshot.appendSections([customEmojiSection])
                let items: [CustomEmojiPickerItem] = {
                    var items = [CustomEmojiPickerItem]()
                    for emoji in emojis where emoji.visibleInPicker {
                        let attribute = CustomEmojiPickerItem.CustomEmojiAttribute(emoji: emoji)
                        let item = CustomEmojiPickerItem.emoji(attribute: attribute)
                        items.append(item)
                    }
                    return items
                }()
                snapshot.appendItems(items, toSection: customEmojiSection)
                
                diffableDataSource.apply(snapshot)
            }
            .store(in: &disposeBag)
    }
    
}
