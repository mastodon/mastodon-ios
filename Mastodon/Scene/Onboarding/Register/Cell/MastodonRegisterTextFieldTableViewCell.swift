//
//  MastodonRegisterTextFieldTableViewCell.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-7.
//

import UIKit
import Combine
import MastodonUI
import MastodonAsset
import MastodonLocalization

//TODO: @zeitschlag Removefinal class MastodonRegisterTextFieldTableViewCell: UITableViewCell {
    
    static let textFieldHeight: CGFloat = 50
    static let textFieldLabelFont = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold), maximumPointSize: 22)

    var disposeBag = Set<AnyCancellable>()

    let textFieldShadowContainer = ShadowBackgroundContainer()
    let textField: UITextField = {
        let textField = UITextField()
        textField.font = MastodonRegisterTextFieldTableViewCell.textFieldLabelFont
        textField.backgroundColor = Asset.Scene.Onboarding.textFieldBackground.color
        textField.layer.masksToBounds = true
        textField.layer.cornerRadius = 10
        textField.layer.cornerCurve = .continuous
        return textField
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag.removeAll()
        textFieldShadowContainer.shadowColor = .black
        textFieldShadowContainer.shadowAlpha = 0.25
        resetTextField()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension MastodonRegisterTextFieldTableViewCell {
    
    private func _init() {
        selectionStyle = .none
        backgroundColor = .clear
        
        textFieldShadowContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textFieldShadowContainer)
        NSLayoutConstraint.activate([
            textFieldShadowContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            textFieldShadowContainer.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            textFieldShadowContainer.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: textFieldShadowContainer.bottomAnchor, constant: 6),
        ])
                
        textField.translatesAutoresizingMaskIntoConstraints = false
        textFieldShadowContainer.addSubview(textField)
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: textFieldShadowContainer.topAnchor),
            textField.leadingAnchor.constraint(equalTo: textFieldShadowContainer.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: textFieldShadowContainer.trailingAnchor),
            textField.bottomAnchor.constraint(equalTo: textFieldShadowContainer.bottomAnchor),
            textField.heightAnchor.constraint(equalToConstant: MastodonRegisterTextFieldTableViewCell.textFieldHeight).priority(.required - 1),
        ])
        
        resetTextField()
    }
    
}

extension MastodonRegisterTextFieldTableViewCell {
    func resetTextField() {
        textField.keyboardType = .default
        textField.autocorrectionType = .default
        textField.autocapitalizationType = .none
        textField.attributedPlaceholder = nil
        textField.isSecureTextEntry = false
        textField.textAlignment = .natural
        textField.semanticContentAttribute = .unspecified
        
        let paddingRect = CGRect(x: 0, y: 0, width: 16, height: 10)
        textField.leftView = UIView(frame: paddingRect)
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: paddingRect)
        textField.rightViewMode = .always
    }
    
    func setupTextViewRightView(text: String) {
        textField.rightView = {
            let containerView = UIView()
            
            let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: MastodonRegisterTextFieldTableViewCell.textFieldHeight))
            paddingView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(paddingView)
            NSLayoutConstraint.activate([
                paddingView.topAnchor.constraint(equalTo: containerView.topAnchor),
                paddingView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                paddingView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                paddingView.widthAnchor.constraint(equalToConstant: 8).priority(.defaultHigh),
            ])

            let label = UILabel()
            label.font = MastodonRegisterTextFieldTableViewCell.textFieldLabelFont
            label.textColor = Asset.Colors.Label.primary.color
            label.text = text
            label.lineBreakMode = .byTruncatingMiddle
            
            label.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(label)
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: containerView.topAnchor),
                label.leadingAnchor.constraint(equalTo: paddingView.trailingAnchor),
                containerView.trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: 16),
                label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                label.widthAnchor.constraint(lessThanOrEqualToConstant: 180).priority(.required - 1),
            ])
            return containerView
        }()
    }
    
    func setupTextViewPlaceholder(text: String) {
        textField.attributedPlaceholder = NSAttributedString(
            string: text,
            attributes: [
                .foregroundColor: Asset.Colors.Label.secondary.color,
                .font: MastodonRegisterTextFieldTableViewCell.textFieldLabelFont
            ]
        )
    }
}
