//
//  ReportFooterView.swift
//  Mastodon
//
//  Created by ihugo on 2021/4/22.
//

import UIKit
import MastodonAsset
import MastodonLocalization

final class ReportFooterView: UIView {
    enum Step: Int {
        case one
        case two
    }
    
    lazy var stackview: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.alignment = .fill
        view.spacing = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var nextStepButton: PrimaryActionButton = {
        let button = PrimaryActionButton()
        button.setTitle(L10n.Common.Controls.Actions.continue, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy var skipButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = Asset.Colors.brandBlue.color
        button.setTitle(L10n.Common.Controls.Actions.skip, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    var step: Step = .one {
        didSet {
            switch step {
            case .one:
                nextStepButton.setTitle(L10n.Common.Controls.Actions.continue, for: .normal)
                skipButton.setTitle(L10n.Common.Controls.Actions.skip, for: .normal)
            case .two:
                nextStepButton.setTitle(L10n.Scene.Report.send, for: .normal)
                skipButton.setTitle(L10n.Scene.Report.skipToSend, for: .normal)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = ThemeService.shared.currentTheme.value.systemElevatedBackgroundColor

        stackview.addArrangedSubview(nextStepButton)
        stackview.addArrangedSubview(skipButton)
        addSubview(stackview)
        
        NSLayoutConstraint.activate([
            stackview.topAnchor.constraint(
                equalTo: self.topAnchor,
                constant: ReportView.continuTopMargin
            ),
            stackview.leadingAnchor.constraint(
                equalTo: self.readableContentGuide.leadingAnchor,
                constant: ReportView.horizontalMargin
            ),
            stackview.bottomAnchor.constraint(
                equalTo: self.safeAreaLayoutGuide.bottomAnchor,
                constant: -1 * ReportView.skipBottomMargin
            ),
            stackview.trailingAnchor.constraint(
                equalTo: self.readableContentGuide.trailingAnchor,
                constant: -1 * ReportView.horizontalMargin
            ),
            nextStepButton.heightAnchor.constraint(
                equalToConstant: ReportView.buttonHeight
            ),
            skipButton.heightAnchor.constraint(
                equalTo: nextStepButton.heightAnchor
            )
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct ReportFooterView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UIViewPreview(width: 375) { () -> UIView in
                return ReportFooterView(frame: CGRect(origin: .zero, size: CGSize(width: 375, height: 164)))
            }
            .previewLayout(.fixed(width: 375, height: 164))
        }
    }
    
}

#endif
