//
//  PickServerSearchCell.swift
//  Mastodon
//
//  Created by BradGao on 2021/2/24.
//

import UIKit

protocol PickServerSearchCellDelegate: class {
    func pickServerSearchCell(didChange searchText: String?)
}

class PickServerSearchCell: UITableViewCell {
    
    weak var delegate: PickServerSearchCellDelegate?
    
    private var bgView: UIView = {
        let view = UIView()
        view.backgroundColor = Asset.Colors.lightWhite.color
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.maskedCorners = [
            .layerMinXMinYCorner,
            .layerMaxXMinYCorner
        ]
        view.layer.cornerCurve = .continuous
        view.layer.cornerRadius = 10
        return view
    }()
    
    private var textFieldBgView: UIView = {
        let view = UIView()
        view.backgroundColor = Asset.Colors.lightBackground.color.withAlphaComponent(0.6)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 6
        view.layer.cornerCurve = .continuous
        return view
    }()
    
    private var searchTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.font = .preferredFont(forTextStyle: .headline)
        textField.tintColor = Asset.Colors.lightDarkGray.color
        textField.textColor = Asset.Colors.lightDarkGray.color
        textField.adjustsFontForContentSizeCategory = true
        textField.attributedPlaceholder =
            NSAttributedString(string: L10n.Scene.ServerPicker.Input.placeholder,
                               attributes: [.font: UIFont.preferredFont(forTextStyle: .headline),
                                            .foregroundColor: Asset.Colors.lightSecondaryText.color.withAlphaComponent(0.6)])
        textField.clearButtonMode = .whileEditing
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        return textField
    }()
    
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
        self.selectionStyle = .none
        backgroundColor = .clear
        
        searchTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
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
    @objc func textFieldDidChange(_ textField: UITextField) {
        delegate?.pickServerSearchCell(didChange: textField.text)
    }
}
