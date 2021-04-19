//
//  SettingsToggleTableViewCell.swift
//  Mastodon
//
//  Created by ihugo on 2021/4/8.
//

import UIKit

protocol SettingsToggleCellDelegate: class {
    func settingsToggleCell(_ cell: SettingsToggleTableViewCell, didChangeStatus: Bool)
}

class SettingsToggleTableViewCell: UITableViewCell {
    lazy var switchButton: UISwitch = {
        let view = UISwitch(frame:.zero)
        return view
    }()
    
    var data: SettingsItem.NotificationSwitch?
    weak var delegate: SettingsToggleCellDelegate?
    
    // MARK: - Methods
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(with data: SettingsItem.NotificationSwitch, delegate: SettingsToggleCellDelegate?) {
        self.delegate = delegate
        self.data = data
        textLabel?.text = data.title
        switchButton.isOn = data.isOn
        setup(enable: data.enable)
    }
    
    // MARK: Actions
    @objc func valueDidChange(sender: UISwitch) {
        guard let delegate = delegate else { return }
        delegate.settingsToggleCell(self, didChangeStatus: sender.isOn)
    }
    
    // MARK: Private methods
    private func setupUI() {
        selectionStyle = .none
        accessoryView = switchButton
        
        switchButton.addTarget(self, action: #selector(valueDidChange(sender:)), for: .valueChanged)
    }
    
    private func setup(enable: Bool) {
        if enable {
            textLabel?.textColor = Asset.Colors.Label.primary.color
        } else {
            textLabel?.textColor = Asset.Colors.Label.secondary.color
        }
        switchButton.isEnabled = enable
    }
}
