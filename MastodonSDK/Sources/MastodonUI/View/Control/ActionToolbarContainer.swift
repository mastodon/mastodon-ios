//
//  ActionToolBarContainer.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/1.
//

import os.log
import UIKit
import MastodonAsset
import MastodonLocalization

public protocol ActionToolbarContainerDelegate: AnyObject {
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, buttonDidPressed button: UIButton, action: ActionToolbarContainer.Action)
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, showReblogs action: UIAccessibilityCustomAction)
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, showFavorites action: UIAccessibilityCustomAction)
}

public final class ActionToolbarContainer: UIView {
    
    let logger = Logger(subsystem: "ActionToolbarContainer", category: "Control")
    
    static let replyImage = Asset.Communication.bubbleLeftAndBubbleRight.image.withRenderingMode(.alwaysTemplate)
    static let reblogImage = Asset.Arrow.repeat.image.withRenderingMode(.alwaysTemplate)
    static let starImage = Asset.ObjectsAndTools.star.image.withRenderingMode(.alwaysTemplate)
    static let starFillImage = Asset.ObjectsAndTools.starFill.image.withRenderingMode(.alwaysTemplate)
    static let shareImage = Asset.Arrow.squareAndArrowUp.image.withRenderingMode(.alwaysTemplate)
        
    public let replyButton     = HighlightDimmableButton()
    public let reblogButton    = HighlightDimmableButton()
    public let favoriteButton  = HighlightDimmableButton()
    public let shareButton     = HighlightDimmableButton()
    
    public weak var delegate: ActionToolbarContainerDelegate?
    
    private let container = UIStackView()
    private var style: Style?
        
    public override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    public required init?(coder: NSCoder) {
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
        
        replyButton.addTarget(self, action: #selector(ActionToolbarContainer.buttonDidPressed(_:)), for: .touchUpInside)
        reblogButton.addTarget(self, action: #selector(ActionToolbarContainer.buttonDidPressed(_:)), for: .touchUpInside)
        favoriteButton.addTarget(self, action: #selector(ActionToolbarContainer.buttonDidPressed(_:)), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(ActionToolbarContainer.buttonDidPressed(_:)), for: .touchUpInside)
    }
    
    public func configure(for style: Style) {
        guard needsConfigure(for: style) else {
            return
        }
        
        self.style = style
        container.arrangedSubviews.forEach { subview in
            container.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        
        let buttons = [replyButton, reblogButton, favoriteButton, shareButton]
        buttons.forEach { button in
            button.tintColor = Asset.Colors.Button.actionToolbar.color
            button.titleLabel?.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
            button.setTitle("", for: .normal)
            button.setTitleColor(.secondaryLabel, for: .normal)
            button.expandEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
            button.setInsets(forContentPadding: .zero, imageTitlePadding: style.buttonTitleImagePadding)
        }
        // add more expand for menu button
        shareButton.expandEdgeInsets = UIEdgeInsets(top: -10, left: -20, bottom: -10, right: -20)
        
        replyButton.accessibilityLabel = L10n.Common.Controls.Status.Actions.reply
        reblogButton.accessibilityLabel = L10n.Common.Controls.Status.Actions.reblog    // needs update to follow state
        favoriteButton.accessibilityLabel = L10n.Common.Controls.Status.Actions.favorite    // needs update to follow state
        shareButton.accessibilityLabel = L10n.Common.Controls.Actions.share
        
        switch style {
        case .inline:
            buttons.forEach { button in
                button.contentHorizontalAlignment = .leading
            }
            replyButton.setImage(ActionToolbarContainer.replyImage, for: .normal)
            reblogButton.setImage(ActionToolbarContainer.reblogImage, for: .normal)
            favoriteButton.setImage(ActionToolbarContainer.starImage, for: .normal)
            shareButton.setImage(ActionToolbarContainer.shareImage, for: .normal)
            
            container.axis = .horizontal
            container.distribution = .equalSpacing
            
            replyButton.translatesAutoresizingMaskIntoConstraints = false
            reblogButton.translatesAutoresizingMaskIntoConstraints = false
            favoriteButton.translatesAutoresizingMaskIntoConstraints = false
            shareButton.translatesAutoresizingMaskIntoConstraints = false
            container.addArrangedSubview(replyButton)
            container.addArrangedSubview(reblogButton)
            container.addArrangedSubview(favoriteButton)
            container.addArrangedSubview(shareButton)
            NSLayoutConstraint.activate([
                replyButton.heightAnchor.constraint(equalToConstant: 36).priority(.defaultHigh),
                replyButton.heightAnchor.constraint(equalTo: reblogButton.heightAnchor).priority(.defaultHigh),
                replyButton.heightAnchor.constraint(equalTo: favoriteButton.heightAnchor).priority(.defaultHigh),
                replyButton.heightAnchor.constraint(equalTo: shareButton.heightAnchor).priority(.defaultHigh),
                replyButton.widthAnchor.constraint(equalTo: reblogButton.widthAnchor).priority(.defaultHigh),
                replyButton.widthAnchor.constraint(equalTo: favoriteButton.widthAnchor).priority(.defaultHigh),
            ])
            shareButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            shareButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            
        case .plain:
            buttons.forEach { button in
                button.contentHorizontalAlignment = .center
            }
            replyButton.setImage(ActionToolbarContainer.replyImage, for: .normal)
            reblogButton.setImage(ActionToolbarContainer.reblogImage, for: .normal)
            favoriteButton.setImage(ActionToolbarContainer.starImage, for: .normal)
            
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
    
}

extension ActionToolbarContainer {
    
    public enum Action: String, CaseIterable {
        case reply
        case reblog
        case like
        case bookmark
        case share
    }
    
    public enum Style {
        case inline
        case plain
        
        var buttonTitleImagePadding: CGFloat {
            switch self {
            case .inline:       return 4.0
            case .plain:        return 0
            }
        }
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
    
    @objc private func buttonDidPressed(_ sender: UIButton) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        let _action: Action?
        switch sender {
        case replyButton:       _action = .reply
        case reblogButton:      _action = .reblog
        case favoriteButton:    _action = .like
        case shareButton:       _action = .share
        default:                _action = nil
        }
        
        guard let action = _action else {
            assertionFailure()
            return
        }
        
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): \(action.rawValue) button pressed")
        delegate?.actionToolbarContainer(self, buttonDidPressed: sender, action: action)
    }
    
}

extension ActionToolbarContainer {
 
    public func configureReply(count: Int, isEnabled: Bool) {
        let title = ActionToolbarContainer.title(from: count)
        replyButton.setTitle(title, for: .normal)
        replyButton.accessibilityLabel = L10n.Common.Controls.Actions.reply
        replyButton.accessibilityValue = L10n.Plural.Count.reply(count)
    }
    
    public func configureReblog(count: Int, isEnabled: Bool, isHighlighted: Bool) {
        let title = ActionToolbarContainer.title(from: count)
        reblogButton.setTitle(title, for: .normal)
        reblogButton.accessibilityValue = L10n.Plural.Count.reblog(count)
        reblogButton.isEnabled = isEnabled
        reblogButton.setImage(ActionToolbarContainer.reblogImage, for: .normal)
        let tintColor = isHighlighted ? Asset.Colors.successGreen.color : Asset.Colors.Button.actionToolbar.color
        reblogButton.tintColor = tintColor
        reblogButton.setTitleColor(tintColor, for: .normal)
        reblogButton.setTitleColor(tintColor, for: .highlighted)
        
        if isHighlighted {
            reblogButton.accessibilityTraits.insert(.selected)
            reblogButton.accessibilityLabel = L10n.Common.Controls.Status.Actions.unreblog
        } else {
            reblogButton.accessibilityTraits.remove(.selected)
            reblogButton.accessibilityLabel = L10n.Common.Controls.Status.Actions.reblog
        }
        reblogButton.accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: "Show All Reblogs") { [weak self] action in
                guard let self = self else { return false }
                self.delegate?.actionToolbarContainer(self, showReblogs: action)
                return true
            }
        ]
    }
    
    public func configureFavorite(count: Int, isEnabled: Bool, isHighlighted: Bool) {
        let title = ActionToolbarContainer.title(from: count)
        favoriteButton.setTitle(title, for: .normal)
        favoriteButton.accessibilityValue = L10n.Plural.Count.favorite(count)
        favoriteButton.isEnabled = isEnabled
        let image = isHighlighted ? ActionToolbarContainer.starFillImage : ActionToolbarContainer.starImage
        favoriteButton.setImage(image, for: .normal)
        let tintColor = isHighlighted ? Asset.Colors.systemOrange.color : Asset.Colors.Button.actionToolbar.color
        favoriteButton.tintColor = tintColor
        favoriteButton.setTitleColor(tintColor, for: .normal)
        favoriteButton.setTitleColor(tintColor, for: .highlighted)
        
        if isHighlighted {
            favoriteButton.accessibilityTraits.insert(.selected)
            favoriteButton.accessibilityLabel = L10n.Common.Controls.Status.Actions.unfavorite
        } else {
            favoriteButton.accessibilityTraits.remove(.selected)
            favoriteButton.accessibilityLabel = L10n.Common.Controls.Status.Actions.favorite
        }
        favoriteButton.accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: "Show All Favorites") { [weak self] action in
                guard let self = self else { return false }
                self.delegate?.actionToolbarContainer(self, showFavorites: action)
                return true
            }
        ]
    }
    
}

extension ActionToolbarContainer {
    private static func title(from number: Int?) -> String {
        guard let number = number, number > 0 else { return "" }
        return String(number)
    }
}

extension ActionToolbarContainer {
    public override var accessibilityElements: [Any]? {
        get { [replyButton, reblogButton, favoriteButton, shareButton] }
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
