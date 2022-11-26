//
//  AttachmentContainerView.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-17.
//

import UIKit
import SwiftUI
import MastodonUI

//final class AttachmentContainerView: UIView {
//
//    static let containerViewCornerRadius: CGFloat = 4
//
//    var descriptionBackgroundViewFrameObservation: NSKeyValueObservation?
//
//    let activityIndicatorView: UIActivityIndicatorView = {
//        let activityIndicatorView = UIActivityIndicatorView(style: .large)
//        activityIndicatorView.color = UIColor.white.withAlphaComponent(0.8)
//        return activityIndicatorView
//    }()
//
//    let previewImageView: UIImageView = {
//        let imageView = UIImageView()
//        imageView.contentMode = .scaleAspectFill
//        imageView.layer.cornerRadius = AttachmentContainerView.containerViewCornerRadius
//        imageView.layer.cornerCurve = .continuous
//        imageView.layer.masksToBounds = true
//        return imageView
//    }()
//
//    let emptyStateView = AttachmentContainerView.EmptyStateView()
//    let descriptionBackgroundView: UIView = {
//        let view = UIView()
//        view.layer.masksToBounds = true
//        view.layer.cornerRadius = AttachmentContainerView.containerViewCornerRadius
//        view.layer.cornerCurve = .continuous
//        view.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
//        view.layoutMargins = UIEdgeInsets(top: 0, left: 8, bottom: 5, right: 8)
//        return view
//    }()
//    let descriptionBackgroundGradientLayer: CAGradientLayer = {
//        let gradientLayer = CAGradientLayer()
//        gradientLayer.colors = [UIColor.black.withAlphaComponent(0.0).cgColor, UIColor.black.withAlphaComponent(0.69).cgColor]
//        gradientLayer.locations = [0.0, 1.0]
//        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
//        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
//        gradientLayer.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
//        return gradientLayer
//    }()
//    let descriptionTextView: UITextView = {
//        let textView = UITextView()
//        textView.showsVerticalScrollIndicator = false
//        textView.backgroundColor = .clear
//        textView.textColor = .white
//        textView.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: 15), maximumPointSize: 20)
//        textView.placeholder = L10n.Scene.Compose.Attachment.descriptionPhoto
//        textView.placeholderColor = UIColor.white.withAlphaComponent(0.6)   // force white with alpha for Light/Dark mode
//        textView.returnKeyType = .done
//        return textView
//    }()
//
//    private(set) lazy var contentView = AttachmentView(viewModel: viewModel)
//    public var viewModel: AttachmentView.ViewModel!
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        _init()
//    }
//
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        _init()
//    }
//
//}

//extension AttachmentContainerView {
//
//    private func _init() {
//        let hostingViewController = UIHostingController(rootView: contentView)
//        hostingViewController.view.translatesAutoresizingMaskIntoConstraints = false
//        addSubview(hostingViewController.view)
//        NSLayoutConstraint.activate([
//            hostingViewController.view.topAnchor.constraint(equalTo: topAnchor),
//            hostingViewController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
//            hostingViewController.view.trailingAnchor.constraint(equalTo: trailingAnchor),
//            hostingViewController.view.bottomAnchor.constraint(equalTo: bottomAnchor),
//        ])
//
//        previewImageView.translatesAutoresizingMaskIntoConstraints = false
//        addSubview(previewImageView)
//        NSLayoutConstraint.activate([
//            previewImageView.topAnchor.constraint(equalTo: topAnchor),
//            previewImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
//            previewImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
//            previewImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
//        ])
//
//        descriptionBackgroundView.translatesAutoresizingMaskIntoConstraints = false
//        addSubview(descriptionBackgroundView)
//        NSLayoutConstraint.activate([
//            descriptionBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
//            descriptionBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
//            descriptionBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
//            descriptionBackgroundView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.3),
//        ])
//        descriptionBackgroundView.layer.addSublayer(descriptionBackgroundGradientLayer)
//        descriptionBackgroundViewFrameObservation = descriptionBackgroundView.observe(\.bounds, options: [.initial, .new]) { [weak self] _, _ in
//            guard let self = self else { return }
//            self.descriptionBackgroundGradientLayer.frame = self.descriptionBackgroundView.bounds
//        }
//
//        descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
//        descriptionBackgroundView.addSubview(descriptionTextView)
//        NSLayoutConstraint.activate([
//            descriptionTextView.leadingAnchor.constraint(equalTo: descriptionBackgroundView.layoutMarginsGuide.leadingAnchor),
//            descriptionTextView.trailingAnchor.constraint(equalTo: descriptionBackgroundView.layoutMarginsGuide.trailingAnchor),
//            descriptionBackgroundView.layoutMarginsGuide.bottomAnchor.constraint(equalTo: descriptionTextView.bottomAnchor),
//            descriptionTextView.heightAnchor.constraint(lessThanOrEqualToConstant: 36),
//        ])
//
//        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
//        addSubview(emptyStateView)
//        NSLayoutConstraint.activate([
//            emptyStateView.topAnchor.constraint(equalTo: topAnchor),
//            emptyStateView.leadingAnchor.constraint(equalTo: leadingAnchor),
//            emptyStateView.trailingAnchor.constraint(equalTo: trailingAnchor),
//            emptyStateView.bottomAnchor.constraint(equalTo: bottomAnchor),
//        ])
//
//        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
//        addSubview(activityIndicatorView)
//        NSLayoutConstraint.activate([
//            activityIndicatorView.centerXAnchor.constraint(equalTo: previewImageView.centerXAnchor),
//            activityIndicatorView.centerYAnchor.constraint(equalTo: previewImageView.centerYAnchor),
//        ])
//
//        setupBroader()
//
//        emptyStateView.isHidden = true
//        activityIndicatorView.hidesWhenStopped = true
//        activityIndicatorView.startAnimating()
//
//        descriptionTextView.delegate = self
//    }
//
////    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
//        super.traitCollectionDidChange(previousTraitCollection)
//
//        setupBroader()
//    }
//
//}
//
//extension AttachmentContainerView {
//
//    private func setupBroader() {
//        emptyStateView.layer.borderWidth = 1
//        emptyStateView.layer.borderColor = traitCollection.userInterfaceStyle == .dark ? ThemeService.shared.currentTheme.value.tableViewCellSelectionBackgroundColor.cgColor : nil
//    }
//
//}

//// MARK: - UITextViewDelegate
//extension AttachmentContainerView: UITextViewDelegate {
//    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
//        // let keyboard dismiss when input description with "done" type return key
//        if textView === descriptionTextView, text == "\n" {
//            textView.resignFirstResponder()
//            return false
//        }
//
//        return true
//    }
//}
