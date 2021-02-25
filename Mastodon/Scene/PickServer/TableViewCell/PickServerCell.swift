//
//  PickServerCell.swift
//  Mastodon
//
//  Created by BradGao on 2021/2/24.
//

import UIKit
import MastodonSDK
import Kingfisher

protocol PickServerCellDelegate: class {
    func pickServerCell(modeChange server: Mastodon.Entity.Server, newMode: PickServerCell.Mode, updates: (() -> Void))
}

class PickServerCell: UITableViewCell {
    
    weak var delegate: PickServerCellDelegate?
    
    enum Mode {
        case collapse
        case expand
    }
    
    private var bgView: UIView = {
        let view = UIView()
        view.backgroundColor = Asset.Colors.lightWhite.color
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var domainLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = Asset.Colors.lightDarkGray.color
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var checkbox: UIImageView = {
        let imageView = UIImageView()
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .body)
        imageView.tintColor = Asset.Colors.lightSecondaryText.color
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 0
        label.textColor = Asset.Colors.lightDarkGray.color
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var thumbImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private var infoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private var expandBox: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var expandButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(L10n.Scene.ServerPicker.Button.seemore, for: .normal)
        button.setTitle(L10n.Scene.ServerPicker.Button.seeless, for: .selected)
        button.setTitleColor(Asset.Colors.lightBrandBlue.color, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var seperator: UIView = {
        let view = UIView()
        view.backgroundColor = Asset.Colors.lightBackground.color
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var langValueLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.lightDarkGray.color
        label.font = UIFontMetrics(forTextStyle: .title2).scaledFont(for: UIFont.systemFont(ofSize: 22, weight: .semibold))
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var usersValueLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.lightDarkGray.color
        label.font = UIFontMetrics(forTextStyle: .title2).scaledFont(for: UIFont.systemFont(ofSize: 22, weight: .semibold))
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var categoryValueLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.lightDarkGray.color
        label.font = UIFontMetrics(forTextStyle: .title2).scaledFont(for: UIFont.systemFont(ofSize: 22, weight: .semibold))
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var langTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.lightDarkGray.color
        label.font = .preferredFont(forTextStyle: .caption2)
        label.text = L10n.Scene.ServerPicker.Label.language
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var usersTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.lightDarkGray.color
        label.font = .preferredFont(forTextStyle: .caption2)
        label.text = L10n.Scene.ServerPicker.Label.users
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var categoryTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = Asset.Colors.lightDarkGray.color
        label.font = .preferredFont(forTextStyle: .caption2)
        label.text = L10n.Scene.ServerPicker.Label.category
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var collapseConstraints: [NSLayoutConstraint] = []
    private var expandConstraints: [NSLayoutConstraint] = []
    
    var mode: PickServerCell.Mode = .collapse {
        didSet {
            updateMode()
        }
    }
    
    var server: Mastodon.Entity.Server? {
        didSet {
            updateServerInfo()
        }
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

// MARK: - Methods to configure appearance
extension PickServerCell {
    private func _init() {
        selectionStyle = .none
        backgroundColor = .clear
        
        contentView.addSubview(bgView)
        contentView.addSubview(domainLabel)
        contentView.addSubview(checkbox)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(seperator)
        
        contentView.addSubview(expandButton)
        
        // Always add the expandbox which contains elements only visible in expand mode
        contentView.addSubview(expandBox)
        expandBox.addSubview(thumbImageView)
        expandBox.addSubview(infoStackView)
        expandBox.isHidden = true
        
        let verticalInfoStackViewLang = makeVerticalInfoStackView(arrangedView: langValueLabel, langTitleLabel)
        let verticalInfoStackViewUsers = makeVerticalInfoStackView(arrangedView: usersValueLabel, usersTitleLabel)
        let verticalInfoStackViewCategory = makeVerticalInfoStackView(arrangedView: categoryValueLabel, categoryTitleLabel)
        infoStackView.addArrangedSubview(verticalInfoStackViewLang)
        infoStackView.addArrangedSubview(verticalInfoStackViewUsers)
        infoStackView.addArrangedSubview(verticalInfoStackViewCategory)
        
        let expandButtonTopConstraintInCollapse = expandButton.topAnchor.constraint(equalTo: descriptionLabel.lastBaselineAnchor, constant: 12)
        collapseConstraints.append(expandButtonTopConstraintInCollapse)
        
        let expandButtonTopConstraintInExpand = expandButton.topAnchor.constraint(equalTo: expandBox.bottomAnchor, constant: 8).priority(.defaultHigh)
        expandConstraints.append(expandButtonTopConstraintInExpand)
        
        NSLayoutConstraint.activate([
            // Set background view
            bgView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            bgView.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentView.readableContentGuide.trailingAnchor.constraint(equalTo: bgView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bgView.bottomAnchor, constant: 1),
            
            // Set bottom separator
            seperator.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            contentView.readableContentGuide.trailingAnchor.constraint(equalTo: seperator.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: seperator.bottomAnchor),
            seperator.heightAnchor.constraint(equalToConstant: 1),
            
            domainLabel.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            domainLabel.topAnchor.constraint(equalTo: bgView.topAnchor, constant: 16),
            
            checkbox.widthAnchor.constraint(equalToConstant: 23),
            checkbox.heightAnchor.constraint(equalToConstant: 22),
            bgView.trailingAnchor.constraint(equalTo: checkbox.trailingAnchor, constant: 16),
            checkbox.leadingAnchor.constraint(equalTo: domainLabel.trailingAnchor, constant: 16),
            checkbox.centerYAnchor.constraint(equalTo: domainLabel.centerYAnchor),
            
            descriptionLabel.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            descriptionLabel.topAnchor.constraint(equalTo: domainLabel.firstBaselineAnchor, constant: 8).priority(.defaultHigh),
            bgView.trailingAnchor.constraint(equalTo: descriptionLabel.trailingAnchor, constant: 16),
            
            // Set expandBox constraints
            expandBox.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            bgView.trailingAnchor.constraint(equalTo: expandBox.trailingAnchor, constant: 16),
            expandBox.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 8),
            expandBox.bottomAnchor.constraint(equalTo: infoStackView.bottomAnchor),
            
            thumbImageView.leadingAnchor.constraint(equalTo: expandBox.leadingAnchor),
            expandBox.trailingAnchor.constraint(equalTo: thumbImageView.trailingAnchor),
            thumbImageView.topAnchor.constraint(equalTo: expandBox.topAnchor),
            thumbImageView.heightAnchor.constraint(equalTo: thumbImageView.widthAnchor, multiplier: 151.0 / 303.0).priority(.defaultHigh),
            
            infoStackView.leadingAnchor.constraint(equalTo: expandBox.leadingAnchor),
            expandBox.trailingAnchor.constraint(equalTo: infoStackView.trailingAnchor),
            infoStackView.topAnchor.constraint(equalTo: thumbImageView.bottomAnchor, constant: 16),
            
            expandButton.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            bgView.trailingAnchor.constraint(equalTo: expandButton.trailingAnchor, constant: 16),
            bgView.bottomAnchor.constraint(equalTo: expandButton.bottomAnchor, constant: 8),
        ])
        
        NSLayoutConstraint.activate(collapseConstraints)
        
        expandButton.addTarget(self, action: #selector(expandButtonDidClicked(_:)), for: .touchUpInside)
        
    }
    
    private func makeVerticalInfoStackView(arrangedView: UIView...) -> UIStackView {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .equalCentering
        stackView.spacing = 2
        arrangedView.forEach { stackView.addArrangedSubview($0) }
        return stackView
    }
    
    private func updateMode() {
        switch mode {
        case .collapse:
            expandBox.isHidden = true
            expandButton.isSelected = false
            NSLayoutConstraint.deactivate(expandConstraints)
            NSLayoutConstraint.activate(collapseConstraints)
        case .expand:
            expandBox.isHidden = false
            expandButton.isSelected = true
            NSLayoutConstraint.activate(expandConstraints)
            NSLayoutConstraint.deactivate(collapseConstraints)
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            checkbox.image = UIImage(systemName: "checkmark.circle.fill")
        } else {
            checkbox.image = UIImage(systemName: "circle")
        }
    }
    
    @objc
    private func expandButtonDidClicked(_ sender: UIButton) {
        let newMode: Mode = mode == .collapse ? .expand : .collapse
        delegate?.pickServerCell(modeChange: server!, newMode: newMode, updates: { [weak self] in
            self?.mode = newMode
        })
    }
}

// MARK: - Methods to update data
extension PickServerCell {
    private func updateServerInfo() {
        guard let serverInfo = server else { return }
        domainLabel.text = serverInfo.domain
        descriptionLabel.text = serverInfo.description
        let processor =  RoundCornerImageProcessor(cornerRadius: 3)
        thumbImageView.kf.indicatorType = .activity
        thumbImageView.kf.setImage(with: URL(string: serverInfo.proxiedThumbnail ?? "")!, placeholder: UIImage.placeholder(color: Asset.Colors.lightBackground.color), options: [
            .processor(processor),
            .scaleFactor(UIScreen.main.scale),
            .transition(.fade(1))
        ])
        langValueLabel.text = serverInfo.language.uppercased()
        usersValueLabel.text = parseUsersCount(serverInfo.totalUsers)
        categoryValueLabel.text = serverInfo.category.uppercased()
    }
    
    private func parseUsersCount(_ usersCount: Int) -> String {
        switch usersCount {
        case 0..<1000:
            return "\(usersCount)"
        default:
            let usersCountInThousand = Float(usersCount) / 1000.0
            return String(format: "%.1fK", usersCountInThousand)
        }
    }
}
