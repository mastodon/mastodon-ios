//
//  MainTabBarController+Wizard.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-9-15.
//

import os.log
import UIKit

protocol WizardDelegate: AnyObject {
    func spotlight(item: MainTabBarController.Wizard.Item) -> UIBezierPath
    func layoutWizardCard(_ wizard: MainTabBarController.Wizard, item: MainTabBarController.Wizard.Item)
}

extension MainTabBarController {
    class Wizard {
        
        let logger = Logger(subsystem: "Wizard", category: "UI")
        
        weak var delegate: WizardDelegate?
        
        private(set) var items: [Item]
        
        let backgroundView: UIView = {
            let view = UIView()
            view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            return view
        }()
        
        init() {
            var items: [Item] = []
            if !UserDefaults.shared.didShowMultipleAccountSwitchWizard {
                items.append(.multipleAccountSwitch)
            }
            self.items = items
            
            let backgroundTapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
            backgroundTapGestureRecognizer.addTarget(self, action: #selector(MainTabBarController.Wizard.backgroundTapGestureRecognizerHandler(_:)))
            backgroundView.addGestureRecognizer(backgroundTapGestureRecognizer)
        }
    }
}

extension MainTabBarController.Wizard {
    enum Item {
        case multipleAccountSwitch
        
        var title: String {
            return L10n.Scene.Wizard.newInMastodon
        }
        
        var description: String {
            switch self {
            case .multipleAccountSwitch:
                return L10n.Scene.Wizard.multipleAccountSwitchIntroDescription
            }
        }
        
        func markAsRead() {
            switch self {
            case .multipleAccountSwitch:
                UserDefaults.shared.didShowMultipleAccountSwitchWizard = true
            }
        }
    }
}

extension MainTabBarController.Wizard {
    
    func setup(in view: UIView) {
        assert(delegate != nil, "need set delegate before use")
        
        guard !items.isEmpty else { return }
        
        backgroundView.frame = view.bounds
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundView)
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    func consume() {
        guard !items.isEmpty else {
            backgroundView.removeFromSuperview()
            return
        }
        let item = items.removeFirst()
        perform(item: item)
    }
    
    private func perform(item: Item) {
        guard let delegate = delegate else {
            assertionFailure()
            return
        }
        
        // prepare for reuse
        prepareForReuse()
        
        // set wizard item read
        item.markAsRead()
        
        // add spotlight
        let spotlight = delegate.spotlight(item: item)
        let maskLayer = CAShapeLayer()
        let path = UIBezierPath(rect: backgroundView.bounds)
        path.append(spotlight)
        maskLayer.fillRule = .evenOdd
        maskLayer.path = path.cgPath
        backgroundView.layer.mask = maskLayer
        
        // layout wizard card
        delegate.layoutWizardCard(self, item: item)
    }
    
    private func prepareForReuse() {
        backgroundView.subviews.forEach { subview in
            subview.removeFromSuperview()
        }
        backgroundView.mask = nil
        backgroundView.layer.mask = nil
    }
    
}

extension MainTabBarController.Wizard {
    @objc private func backgroundTapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        consume()
    }
}
