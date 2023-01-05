//
//  StatusTableViewCell.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/1/27.
//

import os.log
import UIKit
import Combine
import MastodonAsset
import MastodonLocalization
import MastodonUI

final class StatusTableViewCell: UITableViewCell {
    
    static let marginForRegularHorizontalSizeClass: CGFloat = 64
    
    let logger = Logger(subsystem: "StatusTableViewCell", category: "View")
        
    weak var delegate: StatusTableViewCellDelegate?
    var disposeBag = Set<AnyCancellable>()
    var _disposeBag = Set<AnyCancellable>()

    let statusView = StatusView()
    let separatorLine = UIView.separatorLine
    
    var containerViewLeadingLayoutConstraint: NSLayoutConstraint!
    var containerViewTrailingLayoutConstraint: NSLayoutConstraint!

    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag.removeAll()
        statusView.prepareForReuse()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension StatusTableViewCell {
    
    private func _init() {
        statusView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(statusView)
        setupContainerViewMarginConstraints()
        NSLayoutConstraint.activate([
            statusView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            containerViewLeadingLayoutConstraint,
            containerViewTrailingLayoutConstraint,
            contentView.bottomAnchor.constraint(equalTo: statusView.bottomAnchor, constant: 10),
        ])
        statusView.setup(style: .inline)
        updateContainerViewMarginConstraints()
        
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separatorLine)
        NSLayoutConstraint.activate([
            separatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: UIView.separatorLineHeight(of: contentView)).priority(.required - 1),
        ])
        
        statusView.delegate = self
        
        isAccessibilityElement = true
        accessibilityElements = [statusView]
        statusView.viewModel.$groupedAccessibilityLabel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] accessibilityLabel in
                guard let self = self else { return }
                self.accessibilityLabel = accessibilityLabel
            }
            .store(in: &_disposeBag)
        
        statusView.viewModel
            .$translatedFromLanguage
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                self?.invalidateIntrinsicContentSize()
            })
            .store(in: &_disposeBag)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        updateContainerViewMarginConstraints()
    }
    
    override func accessibilityActivate() -> Bool {
        delegate?.tableViewCell(self, statusView: statusView, accessibilityActivate: Void())
        return true
    }

    override var accessibilityCustomActions: [UIAccessibilityCustomAction]? {
        get { statusView.accessibilityCustomActions }
        set { }
    }
}

// MARK: - AdaptiveContainerMarginTableViewCell
extension StatusTableViewCell: AdaptiveContainerMarginTableViewCell {
    var containerView: StatusView {
        statusView
    }
}

// MARK: - StatusViewContainerTableViewCell
extension StatusTableViewCell: StatusViewContainerTableViewCell { }

// MARK: - StatusViewDelegate
extension StatusTableViewCell: StatusViewDelegate { }
