//
//  StatusTableViewCell.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/1/27.
//

import os.log
import UIKit
import AVKit
import Combine


protocol StatusTableViewCellDelegate: class {
    func statusTableViewCell(_ cell: StatusTableViewCell, actionToolbarContainer: ActionToolbarContainer, likeButtonDidPressed sender: UIButton)
    func statusTableViewCell(_ cell: StatusTableViewCell, statusView: StatusView, contentWarningActionButtonPressed button: UIButton)
}

final class StatusTableViewCell: UITableViewCell {
    
    static let bottomPaddingHeight: CGFloat = 10
    
    weak var delegate: StatusTableViewCellDelegate?
    
    var disposeBag = Set<AnyCancellable>()
    var observations = Set<NSKeyValueObservation>()
    
    let statusView = StatusView()
        
    override func prepareForReuse() {
        super.prepareForReuse()
        statusView.isStatusTextSensitive = false
        statusView.cleanUpContentWarning()
        disposeBag.removeAll()
        observations.removeAll()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        DispatchQueue.main.async {
            self.statusView.drawContentWarningImageView()            
        }
    }
    
}

extension StatusTableViewCell {
    
    private func _init() {
        selectionStyle = .none
        backgroundColor = Asset.Colors.Background.secondaryGroupedSystemBackground.color
        statusView.contentWarningBlurContentImageView.backgroundColor = Asset.Colors.Background.secondaryGroupedSystemBackground.color
        
        statusView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(statusView)
        NSLayoutConstraint.activate([
            statusView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            statusView.leadingAnchor.constraint(equalTo:  contentView.readableContentGuide.leadingAnchor),
            contentView.readableContentGuide.trailingAnchor.constraint(equalTo: statusView.trailingAnchor),
        ])
        
        let bottomPaddingView = UIView()
        bottomPaddingView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bottomPaddingView)
        NSLayoutConstraint.activate([
            bottomPaddingView.topAnchor.constraint(equalTo: statusView.bottomAnchor, constant: 10),
            bottomPaddingView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bottomPaddingView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomPaddingView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            bottomPaddingView.heightAnchor.constraint(equalToConstant: StatusTableViewCell.bottomPaddingHeight).priority(.defaultHigh),
        ])
                
        statusView.delegate = self
        statusView.actionToolbarContainer.delegate = self
        bottomPaddingView.backgroundColor = Asset.Colors.Background.systemGroupedBackground.color
    }
    
}

// MARK: - StatusViewDelegate
extension StatusTableViewCell: StatusViewDelegate {
    func statusView(_ statusView: StatusView, contentWarningActionButtonPressed button: UIButton) {
        delegate?.statusTableViewCell(self, statusView: statusView, contentWarningActionButtonPressed: button)
    }
}

// MARK: - ActionToolbarContainerDelegate
extension StatusTableViewCell: ActionToolbarContainerDelegate {
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, replayButtonDidPressed sender: UIButton) {
        
    }
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, retootButtonDidPressed sender: UIButton) {
        
    }
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, starButtonDidPressed sender: UIButton) {
        delegate?.statusTableViewCell(self, actionToolbarContainer: actionToolbarContainer, likeButtonDidPressed: sender)
    }
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, bookmarkButtonDidPressed sender: UIButton) {
        
    }
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, moreButtonDidPressed sender: UIButton) {
        
    }
}
