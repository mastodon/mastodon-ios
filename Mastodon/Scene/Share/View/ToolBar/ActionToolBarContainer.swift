//
//  ActionToolBarContainer.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/1.
//

import os.log
import UIKit

protocol ActionToolbarContainerDelegate: AnyObject {
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, replayButtonDidPressed sender: UIButton)
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, reblogButtonDidPressed sender: UIButton)
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, starButtonDidPressed sender: UIButton)
}


final class ActionToolbarContainer: UIView {
        
    let replyButton     = HighlightDimmableButton()
    let reblogButton    = HighlightDimmableButton()
    let favoriteButton  = HighlightDimmableButton()
    let moreButton      = HighlightDimmableButton()
    
    var isReblogButtonHighlight: Bool = false {
        didSet { isReblogButtonHighlightStateDidChange(to: isReblogButtonHighlight) }
    }
    
    var isFavoriteButtonHighlight: Bool = false {
        didSet { isFavoriteButtonHighlightStateDidChange(to: isFavoriteButtonHighlight) }
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
        reblogButton.addTarget(self, action: #selector(ActionToolbarContainer.reblogButtonDidPressed(_:)), for: .touchUpInside)
        favoriteButton.addTarget(self, action: #selector(ActionToolbarContainer.favoriteButtonDidPressed(_:)), for: .touchUpInside)
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
        
        let buttons = [replyButton, reblogButton, favoriteButton, moreButton]
        buttons.forEach { button in
            button.tintColor = Asset.Colors.Button.actionToolbar.color
            button.titleLabel?.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
            button.setTitle("", for: .normal)
            button.setTitleColor(.secondaryLabel, for: .normal)
            button.expandEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
            button.setInsets(forContentPadding: .zero, imageTitlePadding: style.buttonTitleImagePadding)
        }
        
        let replyImage = UIImage(systemName: "arrowshape.turn.up.left.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .ultraLight))!.withRenderingMode(.alwaysTemplate)
        let reblogImage = UIImage(systemName: "arrow.2.squarepath", withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .bold))!.withRenderingMode(.alwaysTemplate)
        let starImage = UIImage(systemName: "star.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .bold))!.withRenderingMode(.alwaysTemplate)
        let moreImage = UIImage(systemName: "ellipsis", withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .bold))!.withRenderingMode(.alwaysTemplate)
        
        replyButton.accessibilityLabel = L10n.Common.Controls.Status.Actions.reply
        reblogButton.accessibilityLabel = L10n.Common.Controls.Status.Actions.reblog    // needs update to follow state
        favoriteButton.accessibilityLabel = L10n.Common.Controls.Status.Actions.favorite    // needs update to follow state
        moreButton.accessibilityLabel = L10n.Common.Controls.Status.Actions.menu
        
        switch style {
        case .inline:
            buttons.forEach { button in
                button.contentHorizontalAlignment = .leading
            }
            replyButton.setImage(replyImage, for: .normal)
            reblogButton.setImage(reblogImage, for: .normal)
            favoriteButton.setImage(starImage, for: .normal)
            moreButton.setImage(moreImage, for: .normal)
            
            container.axis = .horizontal
            container.distribution = .fill
            
            replyButton.translatesAutoresizingMaskIntoConstraints = false
            reblogButton.translatesAutoresizingMaskIntoConstraints = false
            favoriteButton.translatesAutoresizingMaskIntoConstraints = false
            moreButton.translatesAutoresizingMaskIntoConstraints = false
            container.addArrangedSubview(replyButton)
            container.addArrangedSubview(reblogButton)
            container.addArrangedSubview(favoriteButton)
            container.addArrangedSubview(moreButton)
            NSLayoutConstraint.activate([
                replyButton.heightAnchor.constraint(equalToConstant: 44).priority(.defaultHigh),
                replyButton.heightAnchor.constraint(equalTo: reblogButton.heightAnchor).priority(.defaultHigh),
                replyButton.heightAnchor.constraint(equalTo: favoriteButton.heightAnchor).priority(.defaultHigh),
                replyButton.heightAnchor.constraint(equalTo: moreButton.heightAnchor).priority(.defaultHigh),
                replyButton.widthAnchor.constraint(equalTo: reblogButton.widthAnchor).priority(.defaultHigh),
                replyButton.widthAnchor.constraint(equalTo: favoriteButton.widthAnchor).priority(.defaultHigh),
            ])
            moreButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            moreButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            
        case .plain:
            buttons.forEach { button in
                button.contentHorizontalAlignment = .center
            }
            replyButton.setImage(replyImage, for: .normal)
            reblogButton.setImage(reblogImage, for: .normal)
            favoriteButton.setImage(starImage, for: .normal)
            
            container.axis = .horizontal
            container.spacing = 8
            container.distribution = .fillEqually
            
            container.addArrangedSubview(replyButton)
            container.addArrangedSubview(reblogButton)
            container.addArrangedSubview(favoriteButton)
        }
    }
    
    private func needsConfigure(for style: Style) -> Bool {
        guard let oldStyle = self.style else { return true }
        return oldStyle != style
    }
    
    private func isReblogButtonHighlightStateDidChange(to isHighlight: Bool) {
        let tintColor = isHighlight ? Asset.Colors.successGreen.color : Asset.Colors.Button.actionToolbar.color
        reblogButton.tintColor = tintColor
        reblogButton.setTitleColor(tintColor, for: .normal)
        reblogButton.setTitleColor(tintColor, for: .highlighted)
    }
    
    private func isFavoriteButtonHighlightStateDidChange(to isHighlight: Bool) {
        let tintColor = isHighlight ? Asset.Colors.systemOrange.color : Asset.Colors.Button.actionToolbar.color
        favoriteButton.tintColor = tintColor
        favoriteButton.setTitleColor(tintColor, for: .normal)
        favoriteButton.setTitleColor(tintColor, for: .highlighted)
    }
}

extension ActionToolbarContainer {
    
    @objc private func replyButtonDidPressed(_ sender: UIButton) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.actionToolbarContainer(self, replayButtonDidPressed: sender)
    }
    
    @objc private func reblogButtonDidPressed(_ sender: UIButton) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.actionToolbarContainer(self, reblogButtonDidPressed: sender)
    }
    
    @objc private func favoriteButtonDidPressed(_ sender: UIButton) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        delegate?.actionToolbarContainer(self, starButtonDidPressed: sender)
    }
    
}

extension ActionToolbarContainer {

    override var accessibilityElements: [Any]? {
        get { [replyButton, reblogButton, favoriteButton, moreButton] }
        set { }
    }
}

#if DEBUG
import SwiftUI

struct ActionToolbarContainer_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UIViewPreview(width: 300) {
                let toolbar = ActionToolbarContainer()
                toolbar.configure(for: .inline)
                return toolbar
            }
            .previewLayout(.fixed(width: 300, height: 44))
            .previewDisplayName("Inline")
        }
    }
}
#endif
