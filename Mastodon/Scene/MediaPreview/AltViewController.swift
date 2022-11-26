//
//  AltViewController.swift
//  Mastodon
//
//  Created by Jed Fox on 2022-11-26.
//

import SwiftUI

class AltViewController: UIViewController {
    private var alt: String
    let label = UILabel()

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
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.lineBreakStrategy = .standard
        label.font = .preferredFont(forTextStyle: .callout)
        label.text = alt

        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "V:|-[label]-|", metrics: nil, views: ["label": label])
        )
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "H:|-[label]-|", metrics: nil, views: ["label": label])
        )
        NSLayoutConstraint.activate([
            label.widthAnchor.constraint(lessThanOrEqualToConstant: 400),
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        UIView.performWithoutAnimation {
            preferredContentSize = CGSize(
                width: label.intrinsicContentSize.width + view.layoutMargins.left + view.layoutMargins.right,
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
