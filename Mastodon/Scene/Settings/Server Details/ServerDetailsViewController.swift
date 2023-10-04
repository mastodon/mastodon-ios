// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit

protocol ServerDetailsViewControllerDelegate: AnyObject {

}

class ServerDetailsViewController: UIViewController {

    weak var delegate: ServerDetailsViewControllerDelegate?
    // PageController

    let segmentedControl: UISegmentedControl
    let containerView: UIView

    init() {
        segmentedControl = UISegmentedControl()
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false

        containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .green

        super.init(nibName: nil, bundle: nil)

        view.addSubview(segmentedControl)
        view.addSubview(containerView)

        view.backgroundColor = .systemGroupedBackground

        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupConstraints() {
        let constraints = [
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: segmentedControl.trailingAnchor),

            containerView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ]

        NSLayoutConstraint.activate(constraints)
    }
}

