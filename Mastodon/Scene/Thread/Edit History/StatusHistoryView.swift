// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonUI

class StatusHistoryView: UIView {
    let statusView = StatusView()
    
    private var statusViewLeadingConstraint: NSLayoutConstraint!
    private var statusViewTrailingConstraint: NSLayoutConstraint!

    init() {
        super.init(frame: .zero)
        statusView.translatesAutoresizingMaskIntoConstraints = false
        statusView.setup(style: .editHistory)
        addSubview(statusView)
        
        statusViewLeadingConstraint = statusView.leadingAnchor.constraint(equalTo: leadingAnchor)
        statusViewTrailingConstraint = statusView.trailingAnchor.constraint(equalTo: trailingAnchor)
        
        NSLayoutConstraint.activate([
            statusView.topAnchor.constraint(equalTo: topAnchor),
            statusView.bottomAnchor.constraint(equalTo: bottomAnchor),
            statusViewLeadingConstraint,
            statusViewTrailingConstraint
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func prepareForReuse() {
        statusView.prepareForReuse()
    }
}

extension StatusHistoryView: AdaptiveContainerView {
    func updateContainerViewComponentsLayoutMarginsRelativeArrangementBehavior(isEnabled: Bool) {
        statusView.updateContainerViewComponentsLayoutMarginsRelativeArrangementBehavior(isEnabled: isEnabled)
        statusViewLeadingConstraint.constant = isEnabled ? 0 : StatusEditHistoryTableViewCell.horizontalMargin
        statusViewTrailingConstraint.constant = isEnabled ? 0 : -StatusEditHistoryTableViewCell.horizontalMargin
    }
}
