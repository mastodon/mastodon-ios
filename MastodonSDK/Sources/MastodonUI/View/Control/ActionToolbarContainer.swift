//
//  ActionToolBarContainer.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/1.
//

import UIKit
import MastodonAsset
import MastodonLocalization
import MastodonExtension

public protocol ActionToolbarContainerDelegate: AnyObject {
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, buttonDidPressed button: UIButton, action: ActionToolbarContainer.Action)
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, showReblogs action: UIAccessibilityCustomAction)
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, showFavorites action: UIAccessibilityCustomAction)
}

public final class ActionToolbarContainer: UIView {

    static let replyImage = UIImage(systemName: "arrowshape.turn.up.left")!.withRenderingMode(.alwaysTemplate)
    static let reblogImage = UIImage(systemName: "arrow.2.squarepath")!.withRenderingMode(.alwaysTemplate)
    static let starImage = UIImage(systemName: "star")!.withRenderingMode(.alwaysTemplate)
    static let starFillImage = UIImage(systemName: "star.fill")!.withRenderingMode(.alwaysTemplate)
    static let shareImage = UIImage(systemName: "square.and.arrow.up")!.withRenderingMode(.alwaysTemplate)

    public let replyButton     = HighlightDimmableButton()
    public let reblogButton    = HighlightDimmableButton()
    public let favoriteButton  = HighlightDimmableButton()
    public let shareButton     = HighlightDimmableButton()
    
    public weak var delegate: ActionToolbarContainerDelegate?
    
    private let container = UIStackView()
    private let firstContainer = UIStackView()
    private let secondContainer = UIStackView()

    private var isAccessibilityCategory: Bool?
    private var shareButtonWidthConstraint: NSLayoutConstraint?

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

        let buttons = [replyButton, reblogButton, favoriteButton, shareButton]
        buttons.forEach { button in
            button.tintColor = Asset.Colors.Button.actionToolbar.color
            button.titleLabel?.font = UIFontMetrics(forTextStyle: .caption1)
                .scaledFont(for: .monospacedDigitSystemFont(ofSize: 12, weight: .regular))
            button.titleLabel?.adjustsFontForContentSizeCategory = true
            button.setTitle("", for: .normal)
            button.setTitleColor(.secondaryLabel, for: .normal)
            button.expandEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
            button.setInsets(forContentPadding: .zero, imageTitlePadding: 4)
            button.adjustsImageSizeForAccessibilityContentSizeCategory = true
            button.setContentCompressionResistancePriority(.defaultHigh + 100, for: .horizontal)
        }
        // add more expand for menu button
        shareButton.expandEdgeInsets = UIEdgeInsets(top: -10, left: -20, bottom: -10, right: -20)
        
        replyButton.accessibilityLabel = L10n.Common.Controls.Status.Actions.reply
        reblogButton.accessibilityLabel = L10n.Common.Controls.Status.Actions.reblog    // needs update to follow state
        favoriteButton.accessibilityLabel = L10n.Common.Controls.Status.Actions.favorite    // needs update to follow state
        shareButton.accessibilityLabel = L10n.Common.Controls.Actions.share
        
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

        firstContainer.translatesAutoresizingMaskIntoConstraints = false
        firstContainer.axis = .horizontal
        firstContainer.distribution = .equalSpacing

        secondContainer.translatesAutoresizingMaskIntoConstraints = false
        secondContainer.axis = .horizontal
        secondContainer.distribution = .equalSpacing

        shareButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        shareButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        shareButtonWidthConstraint = replyButton.widthAnchor.constraint(equalTo: shareButton.widthAnchor)

        traitCollectionDidChange(nil)

        NSLayoutConstraint.activate([
            replyButton.heightAnchor.constraint(equalToConstant: 36).priority(.defaultHigh),
            replyButton.heightAnchor.constraint(equalTo: reblogButton.heightAnchor).priority(.defaultHigh),
            replyButton.heightAnchor.constraint(equalTo: favoriteButton.heightAnchor).priority(.defaultHigh),
            replyButton.heightAnchor.constraint(equalTo: shareButton.heightAnchor).priority(.defaultHigh),
            replyButton.widthAnchor.constraint(equalTo: reblogButton.widthAnchor).priority(.defaultHigh),
            replyButton.widthAnchor.constraint(equalTo: favoriteButton.widthAnchor).priority(.defaultHigh),
        ])
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        let isAccessibilityCategory = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        guard isAccessibilityCategory != self.isAccessibilityCategory else { return }
        self.isAccessibilityCategory = isAccessibilityCategory

        if isAccessibilityCategory {
            container.axis = .vertical
            container.spacing = 12

            firstContainer.addArrangedSubview(replyButton)
            firstContainer.addArrangedSubview(reblogButton)
            container.addArrangedSubview(firstContainer)

            secondContainer.addArrangedSubview(favoriteButton)
            secondContainer.addArrangedSubview(shareButton)
            container.addArrangedSubview(secondContainer)
        } else {
            container.axis = .horizontal
            container.spacing = 0

            container.addArrangedSubview(replyButton)
            container.addArrangedSubview(reblogButton)
            container.addArrangedSubview(favoriteButton)
            container.addArrangedSubview(shareButton)

            firstContainer.removeFromSuperview()
            secondContainer.removeFromSuperview()
        }
        shareButtonWidthConstraint!.isActive = isAccessibilityCategory
    }
}

extension ActionToolbarContainer {
    
    public enum Action: String, CaseIterable {
        case reply
        case reblog
        case like
        case share
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
        reblogButton.accessibilityValue = L10n.Plural.Count.reblogA11y(count)
        reblogButton.isEnabled = isEnabled
        reblogButton.setImage(ActionToolbarContainer.reblogImage, for: .normal)
        let tintColor = isHighlighted ? Asset.Colors.successGreen.color : Asset.Colors.Button.actionToolbar.color
        reblogButton.tintColor = tintColor
        reblogButton.setTitleColor(tintColor, for: .normal)
        reblogButton.setTitleColor(tintColor, for: .highlighted)
        
        if isHighlighted {
            reblogButton.accessibilityTraits.insert(.selected)
            reblogButton.accessibilityLabel = L10n.Common.Controls.Status.Actions.A11YLabels.unreblog
        } else {
            reblogButton.accessibilityTraits.remove(.selected)
            reblogButton.accessibilityLabel = L10n.Common.Controls.Status.Actions.A11YLabels.reblog
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
        return number.asAbbreviatedCountString()
    }
}

extension ActionToolbarContainer {
    public override var accessibilityElements: [Any]? {
        get { [replyButton, reblogButton, favoriteButton, shareButton] }
        set { }
    }
}
