//
//  ReportStatusTableViewCell+ViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-2-7.
//

import UIKit
import CoreDataStack

extension ReportStatusTableViewCell {
    final class ViewModel {
        let value: Status

        init(value: Status) {
            self.value = value
        }
    }
}

extension ReportStatusTableViewCell {

    func configure(
        tableView: UITableView,
        viewModel: ViewModel
    ) {
        if statusView.frame == .zero {
            // set status view width
            statusView.frame.size.width = tableView.frame.width - ReportStatusTableViewCell.checkboxLeadingMargin - ReportStatusTableViewCell.checkboxSize.width - ReportStatusTableViewCell.statusViewLeadingSpacing
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): did layout for new cell")
        }
        
        statusView.configure(status: viewModel.value)
        
        statusView.viewModel.$isContentReveal
            .removeDuplicates()
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak tableView, weak self] isContentReveal in
                guard let tableView = tableView else { return }
                guard let _ = self else { return }
                
                tableView.beginUpdates()
                tableView.endUpdates()
            }
            .store(in: &disposeBag)
    }
    
}
