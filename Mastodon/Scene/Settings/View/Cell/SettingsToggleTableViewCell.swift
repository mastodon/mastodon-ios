//
//  SettingsToggleTableViewCell.swift
//  Mastodon
//
//  Created by ihugo on 2021/4/8.
//

import UIKit
import Combine

protocol SettingsToggleCellDelegate: AnyObject {
    func settingsToggleCell(_ cell: SettingsToggleTableViewCell, switchValueDidChange switch: UISwitch)
}

class SettingsToggleTableViewCell: UITableViewCell {
    
    var disposeBag = Set<AnyCancellable>()
    
    private(set) lazy var switchButton: UISwitch = {
        let view = UISwitch(frame:.zero)
        return view
    }()
    
    weak var delegate: SettingsToggleCellDelegate?
    
    // MARK: - Methods
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: Private methods
    private func setupUI() {
        selectionStyle = .none
        accessoryView = switchButton
        backgroundColor = Asset.Colors.Background.secondaryGroupedSystemBackground.color
        
        switchButton.addTarget(self, action: #selector(switchValueDidChange(sender:)), for: .valueChanged)
    }

}

// MARK: - Actions
extension SettingsToggleTableViewCell {
    
    @objc private func switchValueDidChange(sender: UISwitch) {
        guard let delegate = delegate else { return }
        delegate.settingsToggleCell(self, switchValueDidChange: sender)
    }
    
}

extension SettingsToggleTableViewCell {
    
    func update(enabled: Bool?) {
        switchButton.isEnabled = enabled != nil
        textLabel?.textColor = enabled != nil ? Asset.Colors.Label.primary.color : Asset.Colors.Label.secondary.color
        switchButton.isOn = enabled ?? false
    }
    
}
