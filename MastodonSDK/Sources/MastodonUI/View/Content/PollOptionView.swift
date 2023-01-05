//
//  PollOptionView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-23.
//

import UIKit
import Combine
import MastodonAsset
import MastodonLocalization

public final class PollOptionView: UIView {
    
    public static let height: CGFloat = optionHeight + 2 * verticalMargin
    public static let optionHeight: CGFloat = 44
    public static let verticalMargin: CGFloat = 5
    public static let checkmarkImageSize = CGSize(width: 26, height: 26)
    public static let checkmarkBackgroundLeadingMargin: CGFloat = 9
    
    private var viewStateDisposeBag = Set<AnyCancellable>()

    public var disposeBag = Set<AnyCancellable>()
    public private(set) lazy var viewModel: ViewModel = {
        let viewModel = ViewModel()
        viewModel.bind(view: self)
        return viewModel
    }()
    
    public private(set) var style: Style?
    
    public let roundedBackgroundView = UIView()
    public let voteProgressStripView: StripProgressView = {
        let view = StripProgressView()
        view.tintColor = Asset.Colors.brand.color
        return view
    }()
    
    public let checkmarkBackgroundView: UIView = {
        let view = UIView()
        return view
    }()
    
    public let checkmarkImageView: UIImageView = {
        let imageView = UIImageView()
        let image = UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .bold))!
        imageView.image = image.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = Asset.Colors.brand.color
        return imageView
    }()
    
    public let plusCircleImageView: UIImageView = {
        let imageView = UIImageView()
        let image = Asset.Circles.plusCircle.image
        imageView.image = image.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = Asset.Colors.brand.color
        return imageView
    }()
    
    public let optionTextField: DeleteBackwardResponseTextField = {
        let textField = DeleteBackwardResponseTextField()
        textField.font = .systemFont(ofSize: 15, weight: .medium)
        textField.textColor = Asset.Colors.Label.primary.color
        textField.text = "Option"
        textField.textAlignment = UIApplication.shared.userInterfaceLayoutDirection == .leftToRight ? .left : .right
        return textField
    }()
    
    public let optionLabelMiddlePaddingView = UIView()
    
    public let optionPercentageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = Asset.Colors.Label.primary.color
        label.text = "50%"
        label.textAlignment = UIApplication.shared.userInterfaceLayoutDirection == .leftToRight ? .right : .left
        return label
    }()
    
    public func prepareForReuse() {
        disposeBag.removeAll()
        viewModel.objects.removeAll()
        viewModel.percentage = nil
        voteProgressStripView.setProgress(0, animated: false)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension PollOptionView {
    private func _init() {
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
        voteProgressStripView.pinToParent()
        
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
        plusCircleImageView.pinTo(to: checkmarkBackgroundView)
        
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
        
        updateCornerRadius()
        
        isAccessibilityElement = true
    }
    
    public override var accessibilityLabel: String? {
        get {
            switch viewModel.voteState {
            case .reveal:
                return [
                    optionTextField,
                    optionPercentageLabel
                ]
                .compactMap { $0.accessibilityLabel }
                .joined(separator: ", ")
                
            case .hidden:
                return optionTextField.accessibilityLabel
            }
        }
        set { }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        updateCornerRadius()
        viewModel.layoutDidUpdate.send()
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        viewModel.layoutDidUpdate.send()
    }
    
}

extension PollOptionView {
    public enum Style {
        case plain
        case edit
    }
    
    public func setup(style: Style) {
        guard self.style == nil else {
            assertionFailure("Should only setup once")
            return
        }
        self.style = style
        self.viewModel.style = style
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

