//
//  AltViewController.swift
//  Mastodon
//
//  Created by Jed Fox on 2022-11-26.
//

import SwiftUI

class AltViewController: UIViewController {
    private var alt: String
    let label = UITextView()

    init(alt: String, sourceView: UIView?) {
        self.alt = alt
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .popover
        self.popoverPresentationController?.delegate = self
        self.popoverPresentationController?.permittedArrowDirections = .up
        self.popoverPresentationController?.sourceView = sourceView
        self.overrideUserInterfaceStyle = .dark
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        label.translatesAutoresizingMaskIntoConstraints = false
        label.textContainer.maximumNumberOfLines = 0
        label.textContainer.lineBreakMode = .byWordWrapping
        label.textContainerInset = UIEdgeInsets(
            top: 8,
            left: 0,
            bottom: -label.textContainer.lineFragmentPadding,
            right: 0
        )
        label.font = .preferredFont(forTextStyle: .callout)
        label.isScrollEnabled = false
        label.backgroundColor = .clear
        label.isOpaque = false
        label.isEditable = false
        label.tintColor = .white
        label.text = alt

        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "V:|-[label]-|", metrics: nil, views: ["label": label])
        )
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "H:|-(8)-[label]-(8)-|", metrics: nil, views: ["label": label])
        )
        NSLayoutConstraint.activate([
            label.widthAnchor.constraint(lessThanOrEqualToConstant: 400),
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        UIView.performWithoutAnimation {
            preferredContentSize = CGSize(
                width: label.intrinsicContentSize.width + 16,
                height: label.intrinsicContentSize.height + view.layoutMargins.top + view.layoutMargins.bottom
            )
        }
    }
}

// MARK: UIPopoverPresentationControllerDelegate
extension AltViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        .none
    }
}
