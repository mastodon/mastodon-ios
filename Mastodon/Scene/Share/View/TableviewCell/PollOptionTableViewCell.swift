//
//  PollOptionTableViewCell.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-2-25.
//

import UIKit

final class PollOptionTableViewCell: UITableViewCell {
    
    static let height: CGFloat = optionHeight + 2 * verticalMargin
    static let optionHeight: CGFloat = 44
    static let verticalMargin: CGFloat = 5
    static let checkmarkImageSize = CGSize(width: 26, height: 26)
    
    let roundedBackgroundView = UIView()
    
    let checkmarkBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        return view
    }()
    
    let checkmarkImageView: UIView = {
        let imageView = UIImageView()
        let image = UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .bold))!
        imageView.image = image.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = Asset.Colors.Button.highlight.color
        return imageView
    }()
    
    let optionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = Asset.Colors.Label.primary.color
        label.text = "Option"
        label.textAlignment = UIApplication.shared.userInterfaceLayoutDirection == .leftToRight ? .left : .right
        return label
    }()
    
    let optionPercentageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = Asset.Colors.Label.primary.color
        label.text = "50%"
        label.textAlignment = UIApplication.shared.userInterfaceLayoutDirection == .leftToRight ? .right : .left
        return label
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

extension PollOptionTableViewCell {
    
    private func _init() {
        selectionStyle = .none
        backgroundColor = .clear
        roundedBackgroundView.backgroundColor = Asset.Colors.Background.systemGroupedBackground.color
        
        roundedBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(roundedBackgroundView)
        NSLayoutConstraint.activate([
            roundedBackgroundView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            roundedBackgroundView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            roundedBackgroundView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: roundedBackgroundView.bottomAnchor, constant: 5),
            roundedBackgroundView.heightAnchor.constraint(equalToConstant: PollOptionTableViewCell.optionHeight).priority(.defaultHigh),
        ])
        
        checkmarkBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        roundedBackgroundView.addSubview(checkmarkBackgroundView)
        NSLayoutConstraint.activate([
            checkmarkBackgroundView.topAnchor.constraint(equalTo: roundedBackgroundView.topAnchor, constant: 9),
            checkmarkBackgroundView.leadingAnchor.constraint(equalTo: roundedBackgroundView.leadingAnchor, constant: 9),
            roundedBackgroundView.bottomAnchor.constraint(equalTo: checkmarkBackgroundView.bottomAnchor, constant: 9),
            checkmarkBackgroundView.widthAnchor.constraint(equalToConstant: PollOptionTableViewCell.checkmarkImageSize.width).priority(.defaultHigh),
            checkmarkBackgroundView.heightAnchor.constraint(equalToConstant: PollOptionTableViewCell.checkmarkImageSize.height).priority(.defaultHigh),
        ])
        
        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false
        checkmarkBackgroundView.addSubview(checkmarkImageView)
        NSLayoutConstraint.activate([
            checkmarkImageView.topAnchor.constraint(equalTo: checkmarkBackgroundView.topAnchor, constant: 5),
            checkmarkImageView.leadingAnchor.constraint(equalTo: checkmarkBackgroundView.leadingAnchor, constant: 5),
            checkmarkBackgroundView.trailingAnchor.constraint(equalTo: checkmarkImageView.trailingAnchor, constant: 5),
            checkmarkBackgroundView.bottomAnchor.constraint(equalTo: checkmarkImageView.bottomAnchor, constant: 5),
        ])
        
        optionLabel.translatesAutoresizingMaskIntoConstraints = false
        roundedBackgroundView.addSubview(optionLabel)
        NSLayoutConstraint.activate([
            optionLabel.leadingAnchor.constraint(equalTo: checkmarkBackgroundView.trailingAnchor, constant: 14),
            optionLabel.centerYAnchor.constraint(equalTo: roundedBackgroundView.centerYAnchor),
        ])
        
        optionPercentageLabel.translatesAutoresizingMaskIntoConstraints = false
        roundedBackgroundView.addSubview(optionPercentageLabel)
        NSLayoutConstraint.activate([
            optionPercentageLabel.leadingAnchor.constraint(equalTo: optionLabel.trailingAnchor, constant: 8),
            roundedBackgroundView.trailingAnchor.constraint(equalTo: optionPercentageLabel.trailingAnchor, constant: 18),
            optionPercentageLabel.centerYAnchor.constraint(equalTo: roundedBackgroundView.centerYAnchor),
        ])
        optionPercentageLabel.setContentHuggingPriority(.required - 1, for: .horizontal)
        optionPercentageLabel.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
            
        configureCheckmark(state: .none)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        updateCornerRadius()
    }
    
    private func updateCornerRadius() {
        roundedBackgroundView.layer.masksToBounds = true
        roundedBackgroundView.layer.cornerRadius = PollOptionTableViewCell.optionHeight * 0.5
        roundedBackgroundView.layer.cornerCurve = .circular
        
        checkmarkBackgroundView.layer.masksToBounds = true
        checkmarkBackgroundView.layer.cornerRadius = checkmarkBackgroundView.bounds.height * 0.5
        checkmarkBackgroundView.layer.cornerCurve = .circular
    }
    
}

extension PollOptionTableViewCell {
    
    enum CheckmarkState {
        case none
        case off
        case on
    }
    
    func configureCheckmark(state: CheckmarkState) {
        switch state {
        case .none:
            checkmarkBackgroundView.backgroundColor = .clear
            checkmarkImageView.isHidden = true
            optionPercentageLabel.isHidden = true
            optionLabel.textColor = Asset.Colors.Label.primary.color
            optionLabel.layer.removeShadow()
        case .off:
            checkmarkBackgroundView.backgroundColor = .systemBackground
            checkmarkBackgroundView.layer.borderColor = UIColor.systemGray3.cgColor
            checkmarkBackgroundView.layer.borderWidth = 1
            checkmarkImageView.isHidden = true
            optionPercentageLabel.isHidden = true
            optionLabel.textColor = Asset.Colors.Label.primary.color
            optionLabel.layer.removeShadow()
        case .on:
            checkmarkBackgroundView.backgroundColor = .systemBackground
            checkmarkBackgroundView.layer.borderColor = UIColor.clear.cgColor
            checkmarkBackgroundView.layer.borderWidth = 0
            checkmarkImageView.isHidden = false
            optionPercentageLabel.isHidden = false
            optionLabel.textColor = .white
            optionLabel.layer.setupShadow(x: 0, y: 0, blur: 4, spread: 0)
        }
    }
    
}


#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct PollTableViewCell_Previews: PreviewProvider {
    
    static var controls: some View {
        Group {
            UIViewPreview() {
                PollOptionTableViewCell()
            }
            .previewLayout(.fixed(width: 375, height: 44 + 10))
            UIViewPreview() {
                let cell = PollOptionTableViewCell()
                cell.configureCheckmark(state: .off)
                return cell
            }
            .previewLayout(.fixed(width: 375, height: 44 + 10))
            UIViewPreview() {
                let cell = PollOptionTableViewCell()
                cell.configureCheckmark(state: .on)
                return cell
            }
            .previewLayout(.fixed(width: 375, height: 44 + 10))
        }
    }
    
    static var previews: some View {
        Group {
            controls.colorScheme(.light)
            controls.colorScheme(.dark)
        }
        .background(Color.gray)
    }
    
}

#endif

