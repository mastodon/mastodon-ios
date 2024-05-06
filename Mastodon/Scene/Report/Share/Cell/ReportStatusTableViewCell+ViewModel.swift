//
//  ReportStatusTableViewCell+ViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-2-7.
//

import UIKit
import MastodonSDK

extension ReportStatusTableViewCell {

    func configure(
        tableView: UITableView,
        status: MastodonStatus
    ) {
        if statusView.frame == .zero {
            // set status view width
            statusView.frame.size.width = tableView.frame.width - ReportStatusTableViewCell.checkboxLeadingMargin - ReportStatusTableViewCell.checkboxSize.width - ReportStatusTableViewCell.statusViewLeadingSpacing
        }
        
        statusView.configure(status: status)
        
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
