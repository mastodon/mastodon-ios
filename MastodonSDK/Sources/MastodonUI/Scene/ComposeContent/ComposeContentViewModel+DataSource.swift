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
        
        switch kind {
        case .post:
            break
        case .reply(let status):
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
        case .hashtag(let hashtag):
            break
        case .mention(let user):
            break
        }
    }
}

extension ComposeContentViewModel: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section.allCases[section] {
        case .replyTo:
            switch kind {
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
