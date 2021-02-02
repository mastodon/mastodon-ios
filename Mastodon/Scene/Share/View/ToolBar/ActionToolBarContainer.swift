//
//  ActionToolBarContainer.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/1.
//

import os.log
import UIKit

protocol ActionToolbarContainerDelegate: class {
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, replayButtonDidPressed sender: UIButton)
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, retootButtonDidPressed sender: UIButton)
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, starButtonDidPressed sender: UIButton)
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, bookmarkButtonDidPressed sender: UIButton)
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, moreButtonDidPressed sender: UIButton)
    
}


final class ActionToolbarContainer: UIView {
        
    let replyButton     = HitTestExpandedButton()
    let retootButton    = HitTestExpandedButton()
    let starButton      = HitTestExpandedButton()
    let bookmartButton  = HitTestExpandedButton()
    let moreButton      = HitTestExpandedButton()
    
    var isstarButtonHighlight: Bool = false {
        didSet { isstarButtonHighlightStateDidChange(to: isstarButtonHighlight) }
    }
    
    weak var delegate: ActionToolbarContainerDelegate?
    
    private let container = UIStackView()
    private var style: Style?
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ActionToolbarContainer {

    private func _init() {
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: container.trailingAnchor),
            bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        
        replyButton.addTarget(self, action: #selector(ActionToolbarContainer.replyButtonDidPressed(_:)), for: .touchUpInside)
        retootButton.addTarget(self, action: #selector(ActionToolbarContainer.retootButtonDidPressed(_:)), for: .touchUpInside)
        starButton.addTarget(self, action: #selector(ActionToolbarContainer.starButtonDidPressed(_:)), for: .touchUpInside)
        bookmartButton.addTarget(self, action: #selector(ActionToolbarContainer.bookmarkButtonDidPressed(_:)), for: .touchUpInside)
        moreButton.addTarget(self, action: #selector(ActionToolbarContainer.moreButtonDidPressed(_:)), for: .touchUpInside)
    }
    
}

extension ActionToolbarContainer {
    
    enum Style {
        case inline
        case plain
        
        var buttonTitleImagePadding: CGFloat {
            switch self {
            case .inline:       return 4.0
            case .plain:        return 0
            }
        }
    }
    
    func configure(for style: Style) {
        guard needsConfigure(for: style) else {
            return
        }
        
        self.style = style
        container.arrangedSubviews.forEach { subview in
            container.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        
        let buttons = [replyButton, retootButton, starButton,bookmartButton, moreButton]
        buttons.forEach { button in
            button.tintColor = Asset.Colors.tootGray.color
            button.titleLabel?.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
            button.setTitle("", for: .normal)
            button.setTitleColor(.secondaryLabel, for: .normal)
            button.setInsets(forContentPadding: .zero, imageTitlePadding: style.buttonTitleImagePadding)
        }
        
        switch style {
        case .inline:
            buttons.forEach { button in
                button.contentHorizontalAlignment = .leading
            }
            replyButton.setImage(Asset.ToolBar.reply.image.withRenderingMode(.alwaysTemplate), for: .normal)
            retootButton.setImage(Asset.ToolBar.retoot.image.withRenderingMode(.alwaysTemplate), for: .normal)
            starButton.setImage(Asset.ToolBar.star.image.withRenderingMode(.alwaysTemplate), for: .normal)
            bookmartButton.setImage(Asset.ToolBar.bookmark.image.withRenderingMode(.alwaysTemplate), for: .normal)
            moreButton.setImage(Asset.ToolBar.more.image.withRenderingMode(.alwaysTemplate), for: .normal)
            
            container.axis = .horizontal
            container.distribution = .fill
            
            replyButton.translatesAutoresizingMaskIntoConstraints = false
            retootButton.translatesAutoresizingMaskIntoConstraints = false
            starButton.translatesAutoresizingMaskIntoConstraints = false
            bookmartButton.translatesAutoresizingMaskIntoConstraints = false
            moreButton.translatesAutoresizingMaskIntoConstraints = false
            container.addArrangedSubview(replyButton)
            container.addArrangedSubview(retootButton)
            container.addArrangedSubview(starButton)
            container.addArrangedSubview(bookmartButton)
            container.addArrangedSubview(moreButton)
            NSLayoutConstraint.activate([
                replyButton.heightAnchor.constraint(equalToConstant: 40).priority(.defaultHigh),
                replyButton.heightAnchor.constraint(equalTo: retootButton.heightAnchor).priority(.defaultHigh),
                replyButton.heightAnchor.constraint(equalTo: starButton.heightAnchor).priority(.defaultHigh),
                replyButton.heightAnchor.constraint(equalTo: moreButton.heightAnchor).priority(.defaultHigh),
                replyButton.heightAnchor.constraint(equalTo: bookmartButton.heightAnchor).priority(.defaultHigh),
                replyButton.widthAnchor.constraint(equalTo: retootButton.widthAnchor).priority(.defaultHigh),
                replyButton.widthAnchor.constraint(equalTo: starButton.widthAnchor).priority(.defaultHigh),
                replyButton.widthAnchor.constraint(equalTo: bookmartButton.widthAnchor).priority(.defaultHigh),
            ])
            moreButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            moreButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            
        case .plain:
            buttons.forEach { button in
                button.contentHorizontalAlignment = .center
            }
            replyButton.setImage(Asset.ToolBar.reply.image.withRenderingMode(.alwaysTemplate), for: .normal)
            retootButton.setImage(Asset.ToolBar.retoot.image.withRenderingMode(.alwaysTemplate), for: .normal)
            starButton.setImage(Asset.ToolBar.bookmark.image.withRenderingMode(.alwaysTemplate), for: .normal)
            bookmartButton.setImage(Asset.ToolBar.bookmark.image.withRenderingMode(.alwaysTemplate), for: .normal)
            
            container.axis = .horizontal
            container.spacing = 8
            container.distribution = .fillEqually
            
            container.addArrangedSubview(replyButton)
            container.addArrangedSubview(retootButton)
            container.addArrangedSubview(starButton)
            container.addArrangedSubview(bookmartButton)
        }
    }
    
    private func needsConfigure(for style: Style) -> Bool {
        guard let oldStyle = self.style else { return true }
        return oldStyle != style
    }
    
    private func isstarButtonHighlightStateDidChange(to isHighlight: Bool) {
        let tintColor = isHighlight ? Asset.Colors.likeOrange.color : Asset.Colors.tootGray.color
        starButton.tintColor = tintColor
        starButton.setTitleColor(tintColor, for: .normal)
        starButton.setTitleColor(tintColor, for: .highlighted)
    }
}

extension ActionToolbarContainer {
    
    @objc private func replyButtonDidPressed(_ sender: UIButton) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.actionToolbarContainer(self, replayButtonDidPressed: sender)
    }
    
    @objc private func retootButtonDidPressed(_ sender: UIButton) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.actionToolbarContainer(self, retootButtonDidPressed: sender)
    }
    
    @objc private func starButtonDidPressed(_ sender: UIButton) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.actionToolbarContainer(self, starButtonDidPressed: sender)
    }
    
    @objc private func moreButtonDidPressed(_ sender: UIButton) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.actionToolbarContainer(self, moreButtonDidPressed: sender)
    }
    @objc private func bookmarkButtonDidPressed(_ sender: UIButton) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.actionToolbarContainer(self, bookmarkButtonDidPressed: sender)
    }
    
}
