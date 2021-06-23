//
//  PollOptionView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-23.
//

import UIKit
import Combine

final class PollOptionView: UIView {
    
    static let height: CGFloat = optionHeight + 2 * verticalMargin
    static let optionHeight: CGFloat = 44
    static let verticalMargin: CGFloat = 5
    static let checkmarkImageSize = CGSize(width: 26, height: 26)
    static let checkmarkBackgroundLeadingMargin: CGFloat = 9
    
    private var viewStateDisposeBag = Set<AnyCancellable>()
    
    let roundedBackgroundView = UIView()
    let voteProgressStripView: StripProgressView = {
        let view = StripProgressView()
        view.tintColor = Asset.Colors.brandBlue.color
        return view
    }()
    
    let checkmarkBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = Asset.Colors.Background.tertiarySystemBackground.color
        return view
    }()
    
    let checkmarkImageView: UIImageView = {
        let imageView = UIImageView()
        let image = UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .bold))!
        imageView.image = image.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = Asset.Colors.brandBlue.color
        return imageView
    }()
    
    let plusCircleImageView: UIImageView = {
        let imageView = UIImageView()
        let image = Asset.Circles.plusCircle.image
        imageView.image = image.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = Asset.Colors.brandBlue.color
        return imageView
    }()
    
    let optionTextField: DeleteBackwardResponseTextField = {
        let textField = DeleteBackwardResponseTextField()
        textField.font = .systemFont(ofSize: 15, weight: .medium)
        textField.textColor = Asset.Colors.Label.primary.color
        textField.text = "Option"
        textField.textAlignment = UIApplication.shared.userInterfaceLayoutDirection == .leftToRight ? .left : .right
        return textField
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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension PollOptionView {
    private func _init() {
        // default color in the timeline
        roundedBackgroundView.backgroundColor = Asset.Colors.Background.secondarySystemBackground.color
        
        roundedBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(roundedBackgroundView)
        NSLayoutConstraint.activate([
            roundedBackgroundView.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            roundedBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            roundedBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomAnchor.constraint(equalTo: roundedBackgroundView.bottomAnchor, constant: 5),
            roundedBackgroundView.heightAnchor.constraint(equalToConstant: PollOptionView.optionHeight).priority(.defaultHigh),
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
            checkmarkBackgroundView.leadingAnchor.constraint(equalTo: roundedBackgroundView.leadingAnchor, constant: PollOptionView.checkmarkBackgroundLeadingMargin),
            roundedBackgroundView.bottomAnchor.constraint(equalTo: checkmarkBackgroundView.bottomAnchor, constant: 9),
            checkmarkBackgroundView.widthAnchor.constraint(equalToConstant: PollOptionView.checkmarkImageSize.width).priority(.required - 1),
            checkmarkBackgroundView.heightAnchor.constraint(equalToConstant: PollOptionView.checkmarkImageSize.height).priority(.required - 1),
        ])
        
        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false
        checkmarkBackgroundView.addSubview(checkmarkImageView)
        NSLayoutConstraint.activate([
            checkmarkImageView.topAnchor.constraint(equalTo: checkmarkBackgroundView.topAnchor, constant: 5),
            checkmarkImageView.leadingAnchor.constraint(equalTo: checkmarkBackgroundView.leadingAnchor, constant: 5),
            checkmarkBackgroundView.trailingAnchor.constraint(equalTo: checkmarkImageView.trailingAnchor, constant: 5),
            checkmarkBackgroundView.bottomAnchor.constraint(equalTo: checkmarkImageView.bottomAnchor, constant: 5),
        ])
        
        plusCircleImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(plusCircleImageView)
        NSLayoutConstraint.activate([
            plusCircleImageView.topAnchor.constraint(equalTo: checkmarkBackgroundView.topAnchor),
            plusCircleImageView.leadingAnchor.constraint(equalTo: checkmarkBackgroundView.leadingAnchor),
            plusCircleImageView.trailingAnchor.constraint(equalTo: checkmarkBackgroundView.trailingAnchor),
            plusCircleImageView.bottomAnchor.constraint(equalTo: checkmarkBackgroundView.bottomAnchor),
        ])
        
        optionTextField.translatesAutoresizingMaskIntoConstraints = false
        roundedBackgroundView.addSubview(optionTextField)
        NSLayoutConstraint.activate([
            optionTextField.leadingAnchor.constraint(equalTo: checkmarkBackgroundView.trailingAnchor, constant: 14),
            optionTextField.centerYAnchor.constraint(equalTo: roundedBackgroundView.centerYAnchor),
            optionTextField.widthAnchor.constraint(greaterThanOrEqualToConstant: 44).priority(.defaultHigh),
        ])
        
        optionLabelMiddlePaddingView.translatesAutoresizingMaskIntoConstraints = false
        roundedBackgroundView.addSubview(optionLabelMiddlePaddingView)
        NSLayoutConstraint.activate([
            optionLabelMiddlePaddingView.leadingAnchor.constraint(equalTo: optionTextField.trailingAnchor),
            optionLabelMiddlePaddingView.centerYAnchor.constraint(equalTo: roundedBackgroundView.centerYAnchor),
            optionLabelMiddlePaddingView.heightAnchor.constraint(equalToConstant: 4).priority(.defaultHigh),
            optionLabelMiddlePaddingView.widthAnchor.constraint(greaterThanOrEqualToConstant: 8).priority(.defaultLow),
        ])
        optionLabelMiddlePaddingView.setContentHuggingPriority(.required - 1, for: .horizontal)
        optionLabelMiddlePaddingView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        optionPercentageLabel.translatesAutoresizingMaskIntoConstraints = false
        roundedBackgroundView.addSubview(optionPercentageLabel)
        NSLayoutConstraint.activate([
            optionPercentageLabel.leadingAnchor.constraint(equalTo: optionLabelMiddlePaddingView.trailingAnchor),
            roundedBackgroundView.trailingAnchor.constraint(equalTo: optionPercentageLabel.trailingAnchor, constant: 18),
            optionPercentageLabel.centerYAnchor.constraint(equalTo: roundedBackgroundView.centerYAnchor),
        ])
        optionPercentageLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        optionPercentageLabel.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
        
        plusCircleImageView.isHidden = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateCornerRadius()
    }
    
}

extension PollOptionView {
    private func updateCornerRadius() {
        roundedBackgroundView.layer.masksToBounds = true
        roundedBackgroundView.layer.cornerRadius = PollOptionView.optionHeight * 0.5
        roundedBackgroundView.layer.cornerCurve = .circular
        
        checkmarkBackgroundView.layer.masksToBounds = true
        checkmarkBackgroundView.layer.cornerRadius = PollOptionView.checkmarkImageSize.width * 0.5
        checkmarkBackgroundView.layer.cornerCurve = .circular
    }
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct PollOptionView_Previews: PreviewProvider {
    
    static var previews: some View {
        Group {
            UIViewPreview(width: 375) {
                PollOptionView()
            }
            .previewLayout(.fixed(width: 375, height: 100))
            UIViewPreview(width: 375) {
                PollOptionView()
            }
            .preferredColorScheme(.dark)
            .previewLayout(.fixed(width: 375, height: 100))
        }
    }
    
}

#endif

