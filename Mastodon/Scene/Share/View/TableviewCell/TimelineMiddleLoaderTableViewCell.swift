//
//  TimelineMiddleLoaderTableViewCell.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/4.
//

import Combine
import CoreData
import os.log
import UIKit

protocol TimelineMiddleLoaderTableViewCellDelegate: class {
    func configure(cell: TimelineMiddleLoaderTableViewCell, upperTimelineStatusID: String?, timelineIndexobjectID:NSManagedObjectID?)
    func timelineMiddleLoaderTableViewCell(_ cell: TimelineMiddleLoaderTableViewCell, loadMoreButtonDidPressed button: UIButton)
}

final class TimelineMiddleLoaderTableViewCell: TimelineLoaderTableViewCell {
    weak var delegate: TimelineMiddleLoaderTableViewCellDelegate?
    
    let sawToothView: SawToothView = {
        let sawToothView = SawToothView()
        sawToothView.translatesAutoresizingMaskIntoConstraints = false
        return sawToothView
    }()
    
    override func _init() {
        super._init()
        
        loadMoreButton.isHidden = false
        loadMoreLabel.isHidden = false
        activityIndicatorView.isHidden = false
        
        loadMoreButton.setInsets(forContentPadding: .zero, imageTitlePadding: 4)
        loadMoreButton.addTarget(self, action: #selector(TimelineMiddleLoaderTableViewCell.loadMoreButtonDidPressed(_:)), for: .touchUpInside)
        
        contentView.addSubview(sawToothView)
        NSLayoutConstraint.activate([
            sawToothView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            sawToothView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            sawToothView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            sawToothView.heightAnchor.constraint(equalToConstant: 3),
        ])
    }
}

extension TimelineMiddleLoaderTableViewCell {
    @objc private func loadMoreButtonDidPressed(_ sender: UIButton) {
        os_log("%{public}s[%{public}ld], %{public}s", (#file as NSString).lastPathComponent, #line, #function)
        delegate?.timelineMiddleLoaderTableViewCell(self, loadMoreButtonDidPressed: sender)
    }
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct TimelineMiddleLoaderTableViewCell_Previews: PreviewProvider {
    
    static var previews: some View {
        UIViewPreview(width: 375) {
            TimelineMiddleLoaderTableViewCell()
        }
        .previewLayout(.fixed(width: 375, height: 100))
    }
    
}

#endif

