//
//  ReportView.swift
//  Mastodon
//
//  Created by ihugo on 2021/4/20.
//

import UIKit

struct ReportView {
    static var horizontalMargin: CGFloat { return 12 }
    static var verticalMargin: CGFloat { return 22 }
    static var buttonHeight: CGFloat { return 46 }
    static var skipBottomMargin: CGFloat { return 8 }
    static var continuTopMargin: CGFloat { return 22 }
}

final class ReportViewHeader: UIView {
    enum Step: Int {
        case one
        case two
    }
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.Label.secondary.color
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 0
        return label
    }()
    
    lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.Label.primary.color
        label.font = UIFont.preferredFont(forTextStyle: .title3)
        label.numberOfLines = 0
        return label
    }()
    
    lazy var stackview: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.alignment = .leading
        view.spacing = 2
        return view
    }()
    
    var step: Step = .one {
        didSet {
            switch step {
            case .one:
                titleLabel.text = L10n.Scene.Report.step1
                contentLabel.text = L10n.Scene.Report.content1
            case .two:
                titleLabel.text = L10n.Scene.Report.step2
                contentLabel.text = L10n.Scene.Report.content2
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = Asset.Colors.Background.elevatedPrimary.color
        stackview.addArrangedSubview(titleLabel)
        stackview.addArrangedSubview(contentLabel)
        addSubview(stackview)
        
        stackview.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackview.safeAreaLayoutGuide.topAnchor.constraint(
                equalTo: self.topAnchor,
                constant: ReportView.verticalMargin
            ),
            stackview.leadingAnchor.constraint(
                equalTo: self.readableContentGuide.leadingAnchor,
                constant: ReportView.horizontalMargin
            ),
            stackview.bottomAnchor.constraint(
                equalTo: self.bottomAnchor,
                constant: -1 * ReportView.verticalMargin
            ),
            stackview.trailingAnchor.constraint(
                equalTo: self.readableContentGuide.trailingAnchor,
                constant: -1 * ReportView.horizontalMargin
            )
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ReportViewFooter: UIView {
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
                skipButton.setTitle(L10n.Scene.Report.skiptosend, for: .normal)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = Asset.Colors.Background.elevatedPrimary.color
        
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

struct ReportView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UIViewPreview { () -> UIView in
                let view = ReportViewHeader()
                view.step = .one
                view.contentLabel.preferredMaxLayoutWidth = 335
                return view
            }
            .previewLayout(.fixed(width: 375, height: 110))
            
            UIViewPreview(width: 375) { () -> UIView in
                return ReportViewFooter(frame: CGRect(origin: .zero, size: CGSize(width: 375, height: 164)))
            }
            .previewLayout(.fixed(width: 375, height: 164))
        }
    }
    
}

#endif
