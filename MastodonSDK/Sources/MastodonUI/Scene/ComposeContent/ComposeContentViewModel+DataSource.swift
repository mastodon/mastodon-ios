//
//  ComposeContentViewModel+DataSource.swift
//  
//
//  Created by MainasuK on 22/10/10.
//

import UIKit
import MastodonCore
import MastodonSDK
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
            .throttle(for: 0.5, scheduler: RunLoop.main, latest: true)
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
            cell.statusView.configure(status: status)

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
            authContext: authContext,
            context: context
        )
        self.customEmojiPickerDiffableDataSource = diffableDataSource

        customEmojiViewModel?.emojis
            // Don't block the main queue
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            // Sort emojis
            .compactMap({ (emojis) -> [Mastodon.Entity.Emoji]? in
                guard let emojis else { return nil }

                return emojis.sorted { a, b in
                    a.shortcode.lowercased() < b.shortcode.lowercased()
                }
            })
            // Collate emojis into categories
            .map({ (emojis) -> (noCategory: [Mastodon.Entity.Emoji], categorised: [String:[Mastodon.Entity.Emoji]]) in
                let emojiMap: (noCategory: [Mastodon.Entity.Emoji], categorised: [String:[Mastodon.Entity.Emoji]]) = {
                    var noCategory = [Mastodon.Entity.Emoji]()
                    var categorised = [String:[Mastodon.Entity.Emoji]]()
                    
                    for emoji in emojis where emoji.visibleInPicker {
                        if let category = emoji.category {
                            var categoryArray = categorised[category] ?? [Mastodon.Entity.Emoji]()
                            categoryArray.append(emoji)
                            categorised[category] = categoryArray
                        } else {
                            noCategory.append(emoji)
                        }
                    }
                    
                    return (
                        noCategory,
                        categorised
                    )
                }()
                
                return emojiMap
            })
            // Build snapshot from emoji map
            .map({ (emojiMap) -> NSDiffableDataSourceSnapshot<CustomEmojiPickerSection, CustomEmojiPickerItem> in

                var snapshot = NSDiffableDataSourceSnapshot<CustomEmojiPickerSection, CustomEmojiPickerItem>()
                if !emojiMap.noCategory.isEmpty {
                    let customEmojiSection = CustomEmojiPickerSection.uncategorized
                    snapshot.appendSections([customEmojiSection])
                    snapshot.appendItems(emojiMap.noCategory.map({ emoji in
                        CustomEmojiPickerItem.emoji(attribute: CustomEmojiPickerItem.CustomEmojiAttribute(emoji: emoji))
                    }), toSection: customEmojiSection)
                }
                emojiMap.categorised.keys.sorted().forEach { category in
                    let section = CustomEmojiPickerSection.emoji(name: category)
                    snapshot.appendSections([section])
                    if let items = emojiMap.categorised[category] {
                        snapshot.appendItems(items.map({ emoji in
                            CustomEmojiPickerItem.emoji(attribute: CustomEmojiPickerItem.CustomEmojiAttribute(emoji: emoji))
                        }), toSection: section)
                    }
                }

                return snapshot
            })
            // Apply snapshot
            .receive(on: DispatchQueue.main)
            .sink { [weak self, weak diffableDataSource] snapshot in
                guard let _ = self else { return }
                guard let diffableDataSource = diffableDataSource else { return }

                diffableDataSource.apply(snapshot)
            }
            .store(in: &disposeBag)
    }
    
}
