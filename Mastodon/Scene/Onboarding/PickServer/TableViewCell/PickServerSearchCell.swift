//
//  PickServerSearchCell.swift
//  Mastodon
//
//  Created by BradGao on 2021/2/24.
//

import UIKit

protocol PickServerSearchCellDelegate: AnyObject {
    func pickServerSearchCell(_ cell: PickServerSearchCell, searchTextDidChange searchText: String?)
}

class PickServerSearchCell: UITableViewCell {
    
    weak var delegate: PickServerSearchCellDelegate?
    
    private var bgView: UIView = {
        let view = UIView()
        view.backgroundColor = Asset.Theme.Mastodon.secondaryGroupedSystemBackground.color
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.maskedCorners = [
            .layerMinXMinYCorner,
            .layerMaxXMinYCorner
        ]
        view.layer.cornerCurve = .continuous
        view.layer.cornerRadius = MastodonPickServerAppearance.tableViewCornerRadius
        return view
    }()
    
    private var textFieldBgView: UIView = {
        let view = UIView()
        view.backgroundColor = Asset.Colors.TextField.background.color
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 6
        view.layer.cornerCurve = .continuous
        return view
    }()
    
    let searchTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.leftView = {
            let imageView = UIImageView(
                image: UIImage(
                    systemName: "magnifyingglass",
                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .regular)
                )
            )
            imageView.tintColor = Asset.Colors.Label.secondary.color.withAlphaComponent(0.6)
            
            let containerView = UIView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(imageView)
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            ])
            
            let paddingView = UIView()
            paddingView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(paddingView)
            NSLayoutConstraint.activate([
                paddingView.topAnchor.constraint(equalTo: containerView.topAnchor),
                paddingView.leadingAnchor.constraint(equalTo: imageView.trailingAnchor),
                paddingView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                paddingView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                paddingView.widthAnchor.constraint(equalToConstant: 4).priority(.defaultHigh),
            ])
            return containerView
        }()
        textField.leftViewMode = .always
        textField.font = .systemFont(ofSize: 15, weight: .regular)
        textField.tintColor = Asset.Colors.Label.primary.color
        textField.textColor = Asset.Colors.Label.primary.color
        textField.adjustsFontForContentSizeCategory = true
        textField.attributedPlaceholder =
            NSAttributedString(string: L10n.Scene.ServerPicker.Input.placeholder,
                               attributes: [.font: UIFont.systemFont(ofSize: 15, weight: .regular),
                                            .foregroundColor: Asset.Colors.Label.secondary.color.withAlphaComponent(0.6)])
        textField.clearButtonMode = .whileEditing
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .done
        textField.keyboardType = .URL
        return textField
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        delegate = nil
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

extension PickServerSearchCell {
    private func _init() {
        selectionStyle = .none
        backgroundColor = Asset.Theme.Mastodon.systemGroupedBackground.color
        
        searchTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        searchTextField.delegate = self
        
        contentView.addSubview(bgView)
        contentView.addSubview(textFieldBgView)
        contentView.addSubview(searchTextField)
        
        NSLayoutConstraint.activate([
            bgView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            bgView.topAnchor.constraint(equalTo: contentView.topAnchor),
            bgView.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            bgView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            textFieldBgView.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 14),
            textFieldBgView.topAnchor.constraint(equalTo: bgView.topAnchor, constant: 12),
            bgView.trailingAnchor.constraint(equalTo: textFieldBgView.trailingAnchor, constant: 14),
            bgView.bottomAnchor.constraint(equalTo: textFieldBgView.bottomAnchor, constant: 13),
            
            searchTextField.leadingAnchor.constraint(equalTo: textFieldBgView.leadingAnchor, constant: 11),
            searchTextField.topAnchor.constraint(equalTo: textFieldBgView.topAnchor, constant: 4),
            textFieldBgView.trailingAnchor.constraint(equalTo: searchTextField.trailingAnchor, constant: 11),
            textFieldBgView.bottomAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 4),
        ])
    }
}

extension PickServerSearchCell {
    @objc private func textFieldDidChange(_ textField: UITextField) {
        delegate?.pickServerSearchCell(self, searchTextDidChange: textField.text)
    }
}

// MARK: - UITextFieldDelegate
extension PickServerSearchCell: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}
