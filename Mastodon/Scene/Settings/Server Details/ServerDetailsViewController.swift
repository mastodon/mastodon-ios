// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonSDK

enum ServerDetailsTab: Int, CaseIterable {
    case about = 0
    case rules = 1

    var title: String {
        switch self {
                //TODO: Add localization @zeitschlag
            case .about: return "About"
            case .rules: return "Rules"
        }
    }
}

protocol ServerDetailsViewControllerDelegate: AnyObject {

}

class ServerDetailsViewController: UIViewController {

    weak var delegate: (ServerDetailsViewControllerDelegate & AboutInstanceViewControllerDelegate & InstanceRulesViewControllerDelegate)? {
        didSet {
            aboutInstanceViewController.delegate = delegate
            instanceRulesViewController.delegate = delegate
        }
    }
    let pageController: UIPageViewController

    private let segmentedControlWrapper: UIView
    let segmentedControl: UISegmentedControl
    let aboutInstanceViewController: AboutInstanceViewController
    let instanceRulesViewController: InstanceRulesViewController
    let containerView: UIView

    init(domain: String) {
        segmentedControl = UISegmentedControl()
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false

        segmentedControlWrapper = UIView()
        segmentedControlWrapper.translatesAutoresizingMaskIntoConstraints = false
        segmentedControlWrapper.addSubview(segmentedControl)

        containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        aboutInstanceViewController = AboutInstanceViewController()
        instanceRulesViewController = InstanceRulesViewController()

        pageController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        pageController.setViewControllers([aboutInstanceViewController], direction: .forward, animated: false)

        super.init(nibName: nil, bundle: nil)

        view.addSubview(segmentedControlWrapper)
        view.addSubview(containerView)
        view.backgroundColor = .systemGroupedBackground

        containerView.addSubview(pageController.view)
        addChild(pageController)
        pageController.didMove(toParent: self)
        pageController.delegate = self
        pageController.dataSource = self

        ServerDetailsTab.allCases.forEach {
            segmentedControl.insertSegment(withTitle: $0.title, at: $0.rawValue, animated: false)
        }
        segmentedControl.selectedSegmentIndex = ServerDetailsTab.about.rawValue
        segmentedControl.addTarget(self, action: #selector(ServerDetailsViewController.segmentedControlValueChanged(_:)), for: .valueChanged)

        setupConstraints()

        title = domain
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupConstraints() {
        let constraints = [
            segmentedControlWrapper.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            segmentedControlWrapper.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: segmentedControlWrapper.trailingAnchor),

            containerView.topAnchor.constraint(equalTo: segmentedControlWrapper.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            segmentedControl.topAnchor.constraint(equalTo: segmentedControlWrapper.topAnchor, constant: 4),
            segmentedControl.leadingAnchor.constraint(equalTo: segmentedControlWrapper.leadingAnchor, constant: 16),
            segmentedControlWrapper.trailingAnchor.constraint(equalTo: segmentedControl.trailingAnchor, constant: 16),
            segmentedControlWrapper.bottomAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 8),
        ]

        NSLayoutConstraint.activate(constraints)
    }

    //MARK: - Actions
    @objc
    func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        guard let selectedTab = ServerDetailsTab(rawValue: sender.selectedSegmentIndex) else { return }

        switch selectedTab {
            case .about:
                pageController.setViewControllers([aboutInstanceViewController], direction: .reverse, animated: true)
            case .rules:
                pageController.setViewControllers([instanceRulesViewController], direction: .forward, animated: true)
        }
    }

    func update(with instance: Mastodon.Entity.V2.Instance) {
        aboutInstanceViewController.update(with: instance)
        instanceRulesViewController.update(with: instance)
    }
}

//MARK: - UIPageViewControllerDataSource
extension ServerDetailsViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if viewController == instanceRulesViewController {
            return aboutInstanceViewController
        } else {
            return nil
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if viewController == aboutInstanceViewController {
            return instanceRulesViewController
        } else {
            return nil
        }
    }
}

//MARK: - UIPageViewControllerDelegate
extension ServerDetailsViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let currentViewController = pageViewController.viewControllers?.first else { return }

        if currentViewController == aboutInstanceViewController {
            segmentedControl.selectedSegmentIndex = ServerDetailsTab.about.rawValue
        } else if currentViewController == instanceRulesViewController {
            segmentedControl.selectedSegmentIndex = ServerDetailsTab.rules.rawValue
        }
    }
}
