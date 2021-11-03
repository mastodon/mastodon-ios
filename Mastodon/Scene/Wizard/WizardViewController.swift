//
//  WizardViewController.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-11-2.
//

import os.log
import UIKit
import Combine

protocol WizardViewControllerDelegate: AnyObject {
    func readyToLayoutItem(_ wizardViewController: WizardViewController, item: WizardViewController.Item) -> Bool
    func layoutSpotlight(_ wizardViewController: WizardViewController, item: WizardViewController.Item) -> UIBezierPath
    func layoutWizardCard(_ wizardViewController: WizardViewController, item: WizardViewController.Item)
}

class WizardViewController: UIViewController {
    
    let logger = Logger(subsystem: "Wizard", category: "UI")
    
    var disposeBag = Set<AnyCancellable>()
    weak var delegate: WizardViewControllerDelegate?
    
    private(set) var items: [Item] = {
        var items: [Item] = []
        if !UserDefaults.shared.didShowMultipleAccountSwitchWizard {
            items.append(.multipleAccountSwitch)
        }
        return items
    }()
    
    let pendingItem = CurrentValueSubject<Item?, Never>(nil)
    let currentItem = CurrentValueSubject<Item?, Never>(nil)
    
    let backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        return view
    }()
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension WizardViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        
        let backgroundTapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
        backgroundTapGestureRecognizer.addTarget(self, action: #selector(WizardViewController.backgroundTapGestureRecognizerHandler(_:)))
        backgroundView.addGestureRecognizer(backgroundTapGestureRecognizer)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Create a timer to consume pending item
        Timer.publish(every: 0.5, on: .main, in: .default)
            .autoconnect()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                guard self.pendingItem.value != nil else { return }
                self.consume()
            }
            .store(in: &disposeBag)
        
        consume()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        invalidLayoutForCurrentItem()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate { context in
            
        } completion: { [weak self] context in
            guard let self = self else { return }
            self.invalidLayoutForCurrentItem()
        }

    }

}

extension WizardViewController {
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

extension WizardViewController {
    
    func setup() {
        assert(delegate != nil, "need set delegate before use")
        
        guard !items.isEmpty else { return }
        
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundView.frame = view.bounds
        view.addSubview(backgroundView)
    }
    
    func destroy() {
        view.removeFromSuperview()
    }
    
    func consume() {
        guard !items.isEmpty else {
            destroy()
            return
        }
        
        guard let first = items.first else { return }
        guard delegate?.readyToLayoutItem(self, item: first) == true else {
            pendingItem.value = first
            return
        }
        pendingItem.value = nil
        currentItem.value = nil
        
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
        let spotlight = delegate.layoutSpotlight(self, item: item)
        let maskLayer = CAShapeLayer()
        // expand rect to make sure view always fill the screen when device rotate 
        let expandRect: CGRect = {
            var rect = backgroundView.bounds
            rect.size.width *= 2
            rect.size.height *= 2
            return rect
        }()
        let path = UIBezierPath(rect: expandRect)
        path.append(spotlight)
        maskLayer.fillRule = .evenOdd
        maskLayer.path = path.cgPath
        backgroundView.layer.mask = maskLayer
        
        // layout wizard card
        delegate.layoutWizardCard(self, item: item)
        
        currentItem.value = item
    }
    
    private func prepareForReuse() {
        backgroundView.subviews.forEach { subview in
            subview.removeFromSuperview()
        }
        backgroundView.mask = nil
        backgroundView.layer.mask = nil
    }
    
    private func invalidLayoutForCurrentItem() {
        if let item = currentItem.value {
            perform(item: item)
        }
    }
    
}

extension WizardViewController {
    @objc private func backgroundTapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public)")
        
        consume()
    }
}
