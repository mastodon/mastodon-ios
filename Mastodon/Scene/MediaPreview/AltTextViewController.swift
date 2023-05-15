//
//  AltTextViewController.swift
//  Mastodon
//
//  Created by Jed Fox on 2022-11-26.
//

import SwiftUI

class AltTextViewController: UIViewController {
    let textView = {
        let textView: UITextView

        if #available(iOS 16, *) {
            // TODO: update code below to use TextKit 2 when dropping iOS 15 support
            textView = UITextView(usingTextLayoutManager: false)
        } else {
            textView = UITextView()
        }

        textView.textContainer.maximumNumberOfLines = 0
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.font = .preferredFont(forTextStyle: .callout)
        textView.isScrollEnabled = true
        textView.backgroundColor = .clear
        textView.isOpaque = false
        textView.isEditable = false
        textView.tintColor = .white
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 8, right: 8)
        textView.contentInsetAdjustmentBehavior = .always
        textView.verticalScrollIndicatorInsets.bottom = 4

        return textView
    }()

    init(alt: String, sourceView: UIView?) {
        textView.text = alt
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

        textView.translatesAutoresizingMaskIntoConstraints = false
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.addSubview(textView)

        textView.pinToParent()
        NSLayoutConstraint.activate([
            textView.widthAnchor.constraint(lessThanOrEqualToConstant: 400),
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        UIView.performWithoutAnimation {

            let size = textView.layoutManager.boundingRect(forGlyphRange: NSMakeRange(0, (textView.textStorage.string as NSString).length), in: textView.textContainer).size

            preferredContentSize = CGSize(
                width: size.width + (8 + textView.textContainer.lineFragmentPadding) * 2,
                height: size.height + 12 + (textView.textContainer.lineFragmentPadding) * 2
            )
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        textView.font = .preferredFont(forTextStyle: .callout)
    }
}

// MARK: UIPopoverPresentationControllerDelegate
extension AltTextViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        .none
    }
}
