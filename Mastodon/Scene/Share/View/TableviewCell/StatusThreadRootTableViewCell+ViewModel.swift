//
//  StatusThreadRootTableViewCell+ViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-17.
//

import UIKit
import CoreDataStack

extension StatusThreadRootTableViewCell {
    final class ViewModel {
        let value: Value

        init(value: Value) {
            self.value = value
        }
        
        enum Value {
            case status(Status)
        }
    }
}

extension StatusThreadRootTableViewCell {

    func configure(
        tableView: UITableView,
        viewModel: ViewModel,
        delegate: StatusTableViewCellDelegate?
    ) {
        if statusView.frame == .zero {
            // set status view width
            statusView.frame.size.width = tableView.frame.width - containerViewHorizontalMargin
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): did layout for new cell")
        }

        switch viewModel.value {
        case .status(let status):
            statusView.configure(status: status)
        }
        
        self.delegate = delegate
        
        statusView.viewModel.$isContentReveal
            .removeDuplicates()
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak tableView, weak self] isContentReveal in
                guard let tableView = tableView else { return }
                guard let self = self else { return }
                
                guard self.contentView.window != nil else { return }
                
                tableView.beginUpdates()
                tableView.endUpdates()
            }
            .store(in: &disposeBag)
    }
    
}
