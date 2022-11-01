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

public protocol TimelineMiddleLoaderTableViewCellDelegate: AnyObject {
    func timelineMiddleLoaderTableViewCell(_ cell: TimelineMiddleLoaderTableViewCell, loadMoreButtonDidPressed button: UIButton)
}

public final class TimelineMiddleLoaderTableViewCell: TimelineLoaderTableViewCell {
    
    weak var delegate: TimelineMiddleLoaderTableViewCellDelegate?
    
    private(set) lazy var viewModel: ViewModel = {
        let viewModel = ViewModel()
        viewModel.bind(cell: self)
        return viewModel
    }()
    
    let topSawToothView = SawToothView()
    let bottomSawToothView = SawToothView()
    
    public override func _init() {
        super._init()
        
        loadMoreButton.isHidden = false
        loadMoreLabel.isHidden = false
        activityIndicatorView.isHidden = false
        
        loadMoreButton.setInsets(forContentPadding: .zero, imageTitlePadding: 4)
        loadMoreButton.addTarget(self, action: #selector(TimelineMiddleLoaderTableViewCell.loadMoreButtonDidPressed(_:)), for: .touchUpInside)
        
        topSawToothView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(topSawToothView)
        NSLayoutConstraint.activate([
            topSawToothView.topAnchor.constraint(equalTo: contentView.topAnchor),
            topSawToothView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            topSawToothView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            topSawToothView.heightAnchor.constraint(equalToConstant: 3),
        ])
        topSawToothView.transform = CGAffineTransform(scaleX: 1, y: -1) // upside down
        
        bottomSawToothView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bottomSawToothView)
        NSLayoutConstraint.activate([
            bottomSawToothView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bottomSawToothView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomSawToothView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            bottomSawToothView.heightAnchor.constraint(equalToConstant: 3),
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

