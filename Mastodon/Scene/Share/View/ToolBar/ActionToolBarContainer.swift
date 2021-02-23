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
    func actionToolbarContainer(_ actionToolbarContainer: ActionToolbarContainer, moreButtonDidPressed sender: UIButton)
    
}


final class ActionToolbarContainer: UIView {
        
    let replyButton     = HitTestExpandedButton()
    let retootButton    = HitTestExpandedButton()
    let starButton      = HitTestExpandedButton()
    let moreButton      = HitTestExpandedButton()
    
    var isStarButtonHighlight: Bool = false {
        didSet { isStarButtonHighlightStateDidChange(to: isStarButtonHighlight) }
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
        
        let buttons = [replyButton, retootButton, starButton, moreButton]
        buttons.forEach { button in
            button.tintColor = UIColor.black.withAlphaComponent(0.6)
            button.titleLabel?.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
            button.setTitle("", for: .normal)
            button.setTitleColor(.secondaryLabel, for: .normal)
            button.setInsets(forContentPadding: .zero, imageTitlePadding: style.buttonTitleImagePadding)
        }
        
        let replyImage = UIImage(systemName: "arrowshape.turn.up.left.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .ultraLight))!.withRenderingMode(.alwaysTemplate)
        let reblogImage = UIImage(systemName: "arrow.2.squarepath", withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .bold))!.withRenderingMode(.alwaysTemplate)
        let starImage = UIImage(systemName: "star.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .bold))!.withRenderingMode(.alwaysTemplate)
        let moreImage = UIImage(systemName: "ellipsis", withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .bold))!.withRenderingMode(.alwaysTemplate)
        
        switch style {
        case .inline:
            buttons.forEach { button in
                button.contentHorizontalAlignment = .leading
            }
            replyButton.setImage(replyImage, for: .normal)
            retootButton.setImage(reblogImage, for: .normal)
            starButton.setImage(starImage, for: .normal)
            moreButton.setImage(moreImage, for: .normal)
            
            container.axis = .horizontal
            container.distribution = .fill
            
            replyButton.translatesAutoresizingMaskIntoConstraints = false
            retootButton.translatesAutoresizingMaskIntoConstraints = false
            starButton.translatesAutoresizingMaskIntoConstraints = false
            moreButton.translatesAutoresizingMaskIntoConstraints = false
            container.addArrangedSubview(replyButton)
            container.addArrangedSubview(retootButton)
            container.addArrangedSubview(starButton)
            container.addArrangedSubview(moreButton)
            NSLayoutConstraint.activate([
                replyButton.heightAnchor.constraint(equalToConstant: 44).priority(.defaultHigh),
                replyButton.heightAnchor.constraint(equalTo: retootButton.heightAnchor).priority(.defaultHigh),
                replyButton.heightAnchor.constraint(equalTo: starButton.heightAnchor).priority(.defaultHigh),
                replyButton.heightAnchor.constraint(equalTo: moreButton.heightAnchor).priority(.defaultHigh),
                replyButton.widthAnchor.constraint(equalTo: retootButton.widthAnchor).priority(.defaultHigh),
                replyButton.widthAnchor.constraint(equalTo: starButton.widthAnchor).priority(.defaultHigh),
            ])
            moreButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            moreButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
            
        case .plain:
            buttons.forEach { button in
                button.contentHorizontalAlignment = .center
            }
            replyButton.setImage(replyImage, for: .normal)
            retootButton.setImage(reblogImage, for: .normal)
            starButton.setImage(starImage, for: .normal)
            
            container.axis = .horizontal
            container.spacing = 8
            container.distribution = .fillEqually
            
            container.addArrangedSubview(replyButton)
            container.addArrangedSubview(retootButton)
            container.addArrangedSubview(starButton)
        }
    }
    
    private func needsConfigure(for style: Style) -> Bool {
        guard let oldStyle = self.style else { return true }
        return oldStyle != style
    }
    
    private func isStarButtonHighlightStateDidChange(to isHighlight: Bool) {
        let tintColor = isHighlight ? Asset.Colors.systemOrange.color : UIColor.black.withAlphaComponent(0.6)
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
