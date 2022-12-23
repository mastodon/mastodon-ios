//
//  AltViewController.swift
//  Mastodon
//
//  Created by Jed Fox on 2022-11-26.
//

import SwiftUI

class AltViewController: UIViewController {
    private var alt: String
    let label = {
        if #available(iOS 16, *) {
            // TODO: update code below to use TextKit 2 when dropping iOS 15 support
            return UITextView(usingTextLayoutManager: false)
        } else {
            return UITextView()
        }
    }()

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
    
    override func loadView() {
        super.loadView()
        view.translatesAutoresizingMaskIntoConstraints = false
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
        label.isScrollEnabled = true
        label.backgroundColor = .clear
        label.isOpaque = false
        label.isEditable = false
        label.tintColor = .white
        label.text = alt
        label.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 8, right: 8)
        label.contentInsetAdjustmentBehavior = .always
        label.verticalScrollIndicatorInsets.bottom = 4

        view.backgroundColor = .systemBackground
        view.addSubview(label)

        label.pinToParent()
        NSLayoutConstraint.activate([
            label.widthAnchor.constraint(lessThanOrEqualToConstant: 400),
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        UIView.performWithoutAnimation {
            let size = label.layoutManager.boundingRect(forGlyphRange: NSMakeRange(0, (label.textStorage.string as NSString).length), in: label.textContainer).size
            preferredContentSize = CGSize(
                width: size.width + (8 + label.textContainer.lineFragmentPadding) * 2,
                height: size.height + 12 + (label.textContainer.lineFragmentPadding * 2)
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
