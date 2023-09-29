//
//  ComposeStatusPollOptionCollectionViewCell.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-23.
//

import UIKit
import Combine
import MastodonAsset
import MastodonCore
import MastodonLocalization
import MastodonUI

protocol ComposeStatusPollOptionCollectionViewCellDelegate: AnyObject {
    func composeStatusPollOptionCollectionViewCell(_ cell: ComposeStatusPollOptionCollectionViewCell, textFieldDidBeginEditing textField: UITextField)
    func composeStatusPollOptionCollectionViewCell(_ cell: ComposeStatusPollOptionCollectionViewCell, textBeforeDeleteBackward text: String?)
    func composeStatusPollOptionCollectionViewCell(_ cell: ComposeStatusPollOptionCollectionViewCell, pollOptionTextFieldDidReturn: UITextField)
}

final class ComposeStatusPollOptionCollectionViewCell: UICollectionViewCell {
    
    static let reorderHandlerImageLeadingMargin: CGFloat = 11
    
    var disposeBag = Set<AnyCancellable>()
    weak var delegate: ComposeStatusPollOptionCollectionViewCellDelegate?
    
    let pollOptionView = PollOptionView()
    let reorderBarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "line.horizontal.3")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)).withRenderingMode(.alwaysTemplate)
        imageView.tintColor = Asset.Colors.Label.secondary.color
        return imageView
    }()
    
    let singleTagGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
    
    private var pollOptionSubscription: AnyCancellable?
    let pollOption = PassthroughSubject<String, Never>()
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return pollOptionView.frame.contains(point)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        delegate = nil
        disposeBag.removeAll()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _init()
    }
    
}

extension ComposeStatusPollOptionCollectionViewCell {
    
    private func _init() {
        pollOptionView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(pollOptionView)
        NSLayoutConstraint.activate([
            pollOptionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            pollOptionView.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            pollOptionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        
        reorderBarImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(reorderBarImageView)
        NSLayoutConstraint.activate([
            reorderBarImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            reorderBarImageView.leadingAnchor.constraint(equalTo: pollOptionView.trailingAnchor, constant: ComposeStatusPollOptionCollectionViewCell.reorderHandlerImageLeadingMargin),
            reorderBarImageView.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            reorderBarImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        reorderBarImageView.setContentCompressionResistancePriority(.defaultHigh + 10, for: .horizontal)
        
        pollOptionView.checkmarkImageView.isHidden = true
        pollOptionView.optionPercentageLabel.isHidden = true
        pollOptionView.optionTextField.text = nil

        pollOptionView.roundedBackgroundView.backgroundColor = .tertiarySystemGroupedBackground
        pollOptionView.checkmarkBackgroundView.backgroundColor = UIColor(dynamicProvider: { traitCollection in
            return traitCollection.userInterfaceStyle == .light ? .white : SystemTheme.tableViewCellSelectionBackgroundColor
        })
        setupBorderColor()
        
        pollOptionView.addGestureRecognizer(singleTagGestureRecognizer)
        singleTagGestureRecognizer.addTarget(self, action: #selector(ComposeStatusPollOptionCollectionViewCell.singleTagGestureRecognizerHandler(_:)))
        
        pollOptionSubscription = NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification, object: pollOptionView.optionTextField)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self = self else { return }
                guard let textField = notification.object as? UITextField else { return }
                self.pollOption.send(textField.text ?? "")
            }
        pollOptionView.optionTextField.deleteBackwardDelegate = self
        pollOptionView.optionTextField.delegate = self
    }
    
    private func setupBorderColor() {
        pollOptionView.roundedBackgroundView.layer.borderWidth = 1
        pollOptionView.roundedBackgroundView.layer.borderColor = SystemTheme.tableViewCellSelectionBackgroundColor.withAlphaComponent(0.3).cgColor

        pollOptionView.checkmarkBackgroundView.layer.borderColor = SystemTheme.tableViewCellSelectionBackgroundColor.withAlphaComponent(0.3).cgColor
        pollOptionView.checkmarkBackgroundView.layer.borderWidth = 1
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        setupBorderColor()
    }
    
}

extension ComposeStatusPollOptionCollectionViewCell {

    @objc private func singleTagGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        pollOptionView.optionTextField.becomeFirstResponder()
    }
    
}

// MARK: - DeleteBackwardResponseTextFieldDelegate
extension ComposeStatusPollOptionCollectionViewCell: DeleteBackwardResponseTextFieldDelegate {
    func deleteBackwardResponseTextField(_ textField: DeleteBackwardResponseTextField, textBeforeDelete: String?) {
        delegate?.composeStatusPollOptionCollectionViewCell(self, textBeforeDeleteBackward: textBeforeDelete)
    }
}

// MARK: - UITextFieldDelegate
extension ComposeStatusPollOptionCollectionViewCell: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.composeStatusPollOptionCollectionViewCell(self, textFieldDidBeginEditing: textField)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === pollOptionView.optionTextField {
            delegate?.composeStatusPollOptionCollectionViewCell(self, pollOptionTextFieldDidReturn: textField)
        }
        return true
    }
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct ComposeStatusPollOptionCollectionViewCell_Previews: PreviewProvider {
    
    static var controls: some View {
        Group {
            UIViewPreview() {
                let cell = ComposeStatusPollOptionCollectionViewCell()
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
