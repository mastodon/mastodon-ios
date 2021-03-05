//
//  PollOptionTableViewCell.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-2-25.
//

import UIKit
import Combine

final class PollOptionTableViewCell: UITableViewCell {
    
    static let height: CGFloat = optionHeight + 2 * verticalMargin
    static let optionHeight: CGFloat = 44
    static let verticalMargin: CGFloat = 5
    static let checkmarkImageSize = CGSize(width: 26, height: 26)
    
    private var viewStateDisposeBag = Set<AnyCancellable>()
    var selectState: PollItem.Attribute.SelectState = .off
    var voteState: PollItem.Attribute.VoteState?
        
    let roundedBackgroundView = UIView()
    let voteProgressStripView: StripProgressView = {
        let view = StripProgressView()
        view.tintColor = Asset.Colors.Background.Poll.highlight.color
        return view
    }()
    
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
    
    let optionLabelMiddlePaddingView = UIView()
    
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
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        guard let voteState = voteState else { return }
        switch voteState {
        case .hidden:
            let color = Asset.Colors.Background.systemGroupedBackground.color
            self.roundedBackgroundView.backgroundColor = isHighlighted ? color.withAlphaComponent(0.8) : color
        case .reveal:
            break
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        guard let voteState = voteState else { return }
        switch voteState {
        case .hidden:
            let color = Asset.Colors.Background.systemGroupedBackground.color
            self.roundedBackgroundView.backgroundColor = isHighlighted ? color.withAlphaComponent(0.8) : color
        case .reveal:
            break
        }
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
        
        voteProgressStripView.translatesAutoresizingMaskIntoConstraints = false
        roundedBackgroundView.addSubview(voteProgressStripView)
        NSLayoutConstraint.activate([
            voteProgressStripView.topAnchor.constraint(equalTo: roundedBackgroundView.topAnchor),
            voteProgressStripView.leadingAnchor.constraint(equalTo: roundedBackgroundView.leadingAnchor),
            voteProgressStripView.trailingAnchor.constraint(equalTo: roundedBackgroundView.trailingAnchor),
            voteProgressStripView.bottomAnchor.constraint(equalTo: roundedBackgroundView.bottomAnchor),
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
        
        optionLabelMiddlePaddingView.translatesAutoresizingMaskIntoConstraints = false
        roundedBackgroundView.addSubview(optionLabelMiddlePaddingView)
        NSLayoutConstraint.activate([
            optionLabelMiddlePaddingView.leadingAnchor.constraint(equalTo: optionLabel.trailingAnchor),
            optionLabelMiddlePaddingView.centerYAnchor.constraint(equalTo: roundedBackgroundView.centerYAnchor),
            optionLabelMiddlePaddingView.heightAnchor.constraint(equalToConstant: 4).priority(.defaultHigh),
            optionLabelMiddlePaddingView.widthAnchor.constraint(greaterThanOrEqualToConstant: 8).priority(.defaultLow),
        ])
        optionLabelMiddlePaddingView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        optionPercentageLabel.translatesAutoresizingMaskIntoConstraints = false
        roundedBackgroundView.addSubview(optionPercentageLabel)
        NSLayoutConstraint.activate([
            optionPercentageLabel.leadingAnchor.constraint(equalTo: optionLabelMiddlePaddingView.trailingAnchor),
            roundedBackgroundView.trailingAnchor.constraint(equalTo: optionPercentageLabel.trailingAnchor, constant: 18),
            optionPercentageLabel.centerYAnchor.constraint(equalTo: roundedBackgroundView.centerYAnchor),
        ])
        optionPercentageLabel.setContentHuggingPriority(.required - 1, for: .horizontal)
        optionPercentageLabel.setContentCompressionResistancePriority(.required - 1, for: .horizontal)            
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        updateCornerRadius()
        updateTextAppearance()
    }
    
    private func updateCornerRadius() {
        roundedBackgroundView.layer.masksToBounds = true
        roundedBackgroundView.layer.cornerRadius = PollOptionTableViewCell.optionHeight * 0.5
        roundedBackgroundView.layer.cornerCurve = .circular
        
        checkmarkBackgroundView.layer.masksToBounds = true
        checkmarkBackgroundView.layer.cornerRadius = PollOptionTableViewCell.checkmarkImageSize.width * 0.5
        checkmarkBackgroundView.layer.cornerCurve = .circular
    }
    
    func updateTextAppearance() {
        guard let voteState = voteState else {
            optionLabel.textColor = Asset.Colors.Label.primary.color
            optionLabel.layer.removeShadow()
            return
        }
        
        switch voteState {
        case .hidden:
            optionLabel.textColor = Asset.Colors.Label.primary.color
            optionLabel.layer.removeShadow()
        case .reveal(_, let percentage):
            if CGFloat(percentage) * voteProgressStripView.frame.width > optionLabelMiddlePaddingView.frame.minX {
                optionLabel.textColor = .white
                optionLabel.layer.setupShadow(x: 0, y: 0, blur: 4, spread: 0)
            } else {
                optionLabel.textColor = Asset.Colors.Label.primary.color
                optionLabel.layer.removeShadow()
            }
            
            if CGFloat(percentage) * voteProgressStripView.frame.width > optionLabelMiddlePaddingView.frame.maxX {
                optionPercentageLabel.textColor = .white
                optionPercentageLabel.layer.setupShadow(x: 0, y: 0, blur: 4, spread: 0)
            } else {
                optionPercentageLabel.textColor = Asset.Colors.Label.primary.color
                optionPercentageLabel.layer.removeShadow()
            }
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
                PollSection.configure(cell: cell, selectState: .off)
                return cell
            }
            .previewLayout(.fixed(width: 375, height: 44 + 10))
            UIViewPreview() {
                let cell = PollOptionTableViewCell()
                PollSection.configure(cell: cell, selectState: .on)
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

