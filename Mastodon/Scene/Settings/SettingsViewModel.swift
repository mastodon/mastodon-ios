//
//  SettingsViewModel.swift
//  Mastodon
//
//  Created by ihugo on 2021/4/7.
//

import Combine
import CoreData
import CoreDataStack
import Foundation
import MastodonSDK
import UIKit
import os.log

class SettingsViewModel: NSObject, NeedsDependency {
    // confirm set only once
    weak var context: AppContext! { willSet { precondition(context == nil) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(coordinator == nil) } }
    
    var dataSource: UITableViewDiffableDataSource<SettingsSection, SettingsItem>!
    var disposeBag = Set<AnyCancellable>()
    let viewDidLoad = PassthroughSubject<Void, Never>()
    lazy var fetchResultsController: NSFetchedResultsController<Setting> = {
        let fetchRequest = Setting.sortedFetchRequest
        if let box =
            self.context.authenticationService.activeMastodonAuthenticationBox.value {
            let domain = box.domain
            fetchRequest.predicate = Setting.predicate(domain: domain)
        }
        
        fetchRequest.fetchLimit = 1
        fetchRequest.returnsObjectsAsFaults = false
        let controller = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        controller.delegate = self
        return controller
    }()
    let setting = CurrentValueSubject<Setting?, Never>(nil)
    
    /// trigger when
    /// - init alerts
    /// - change subscription status everytime
    let alertUpdate = PassthroughSubject<(triggerBy: String, values: [Bool?]), Never>()
    
    lazy var notificationDefaultValue: [String: [Bool?]] = {
        let followerSwitchItems: [Bool?] = [true, nil, true, true]
        let anyoneSwitchItems: [Bool?] = [true, true, true, true]
        let noOneSwitchItems: [Bool?] = [nil, nil, nil, nil]
        let followSwitchItems: [Bool?] = [true, true, true, true]
        
        let anyone = L10n.Scene.Settings.Section.Notifications.Trigger.anyone
        let follower = L10n.Scene.Settings.Section.Notifications.Trigger.follower
        let follow = L10n.Scene.Settings.Section.Notifications.Trigger.follow
        let noOne = L10n.Scene.Settings.Section.Notifications.Trigger.noOne
        return [anyone: anyoneSwitchItems,
                follower: followerSwitchItems,
                follow: followSwitchItems,
                noOne: noOneSwitchItems]
    }()
    
    struct Input {
    }

    struct Output {
    }
    
    init(context: AppContext, coordinator: SceneCoordinator) {
        self.context = context
        self.coordinator = coordinator
        
        super.init()
    }
    
    func transform(input: Input?) -> Output? {
        //guard let input = input else { return nil }
        
        // build data for table view
        buildDataSource()
        
        // request subsription data for updating or initialization
        requestSubscription()
        
        typealias SubscriptionResponse = Mastodon.Response.Content<Mastodon.Entity.Subscription>
        alertUpdate
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .flatMap { [weak self] (arg) -> AnyPublisher<SubscriptionResponse, Error> in
                let (triggerBy, values) = arg
                guard let self = self else {
                    return Empty<SubscriptionResponse, Error>().eraseToAnyPublisher()
                }
                guard let activeMastodonAuthenticationBox =
                        self.context.authenticationService.activeMastodonAuthenticationBox.value else {
                    return Empty<SubscriptionResponse, Error>().eraseToAnyPublisher()
                }
                guard values.count >= 4 else {
                    return Empty<SubscriptionResponse, Error>().eraseToAnyPublisher()
                }
                
                typealias Query = Mastodon.API.Notification.CreateSubscriptionQuery
                let domain = activeMastodonAuthenticationBox.domain
                return self.context.apiService.changeSubscription(
                    domain: domain,
                    mastodonAuthenticationBox: activeMastodonAuthenticationBox,
                    query: Query(favourite: values[0], follow: values[1],  reblog: values[2], mention: values[3], poll: nil),
                    triggerBy: triggerBy)
            }
            .sink { _ in
            } receiveValue: { (subscription) in
            }
            .store(in: &disposeBag)
        
        
        do {
            try fetchResultsController.performFetch()
            setting.value = fetchResultsController.fetchedObjects?.first
        } catch {
            assertionFailure(error.localizedDescription)
        }
        return nil
    }
    
    // MARK: - Private methods
    fileprivate func processDataSource(_ settings: Setting?) {
        var snapshot = NSDiffableDataSourceSnapshot<SettingsSection, SettingsItem>()
        
        // appearance
        let appearnceMode = SettingsItem.AppearanceMode(rawValue: settings?.appearance ?? "") ?? .automatic
        let appearanceItem = SettingsItem.apperance(item: appearnceMode)
        let appearance = SettingsSection.apperance(title: L10n.Scene.Settings.Section.Appearance.title, selectedMode:appearanceItem)
        snapshot.appendSections([appearance])
        snapshot.appendItems([appearanceItem])
        
        // notifications
        var switches: [Bool?]?
        if let alerts = settings?.subscription?.first(where: { (s) -> Bool in
            return s.type == settings?.triggerBy
        })?.alert {
            var items = [Bool?]()
            items.append(alerts.favourite)
            items.append(alerts.follow)
            items.append(alerts.reblog)
            items.append(alerts.mention)
            switches = items
        } else if let triggerBy = settings?.triggerBy,
                  let values = self.notificationDefaultValue[triggerBy] {
            switches = values
            self.alertUpdate.send((triggerBy: triggerBy, values: values))
        } else {
            // fallback a default value
            let anyone = L10n.Scene.Settings.Section.Notifications.Trigger.anyone
            switches = self.notificationDefaultValue[anyone]
        }
        let notifications = [L10n.Scene.Settings.Section.Notifications.favorites,
                             L10n.Scene.Settings.Section.Notifications.follows,
                             L10n.Scene.Settings.Section.Notifications.boosts,
                             L10n.Scene.Settings.Section.Notifications.mentions,]
        var notificationItems = [SettingsItem]()
        for (i, noti) in notifications.enumerated() {
            var value: Bool? = nil
            if let switches = switches, i < switches.count {
                value = switches[i]
            }
            
            let item = SettingsItem.notification(item: SettingsItem.NotificationSwitch(title: noti, isOn: value == true, enable: value != nil))
            notificationItems.append(item)
        }
        let notificationSection = SettingsSection.notifications(title: L10n.Scene.Settings.Section.Notifications.title, items: notificationItems)
        snapshot.appendSections([notificationSection])
        snapshot.appendItems(notificationItems)
        
        // boring zone
        let boringLinks = [L10n.Scene.Settings.Section.BoringZone.terms,
                           L10n.Scene.Settings.Section.BoringZone.privacy]
        var boringLinkItems = [SettingsItem]()
        for l in boringLinks {
            // FIXME: update color in both light and dark mode
            let item = SettingsItem.boringZone(item: SettingsItem.Link(title: l, color: .systemBlue))
            boringLinkItems.append(item)
        }
        let boringSection = SettingsSection.boringZone(title: L10n.Scene.Settings.Section.BoringZone.title, items: boringLinkItems)
        snapshot.appendSections([boringSection])
        snapshot.appendItems(boringLinkItems)
        
        // spicy zone
        let spicyLinks = [L10n.Scene.Settings.Section.SpicyZone.clear,
                          L10n.Scene.Settings.Section.SpicyZone.signOut]
        var spicyLinkItems = [SettingsItem]()
        for l in spicyLinks {
            // FIXME: update color in both light and dark mode
            let item = SettingsItem.boringZone(item: SettingsItem.Link(title: l, color: .systemRed))
            spicyLinkItems.append(item)
        }
        let spicySection = SettingsSection.boringZone(title: L10n.Scene.Settings.Section.SpicyZone.title, items: spicyLinkItems)
        snapshot.appendSections([spicySection])
        snapshot.appendItems(spicyLinkItems)
        
        self.dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    private func buildDataSource() {
        setting.filter({ $0 != nil }).sink { [weak self] (settings) in
            guard let self = self else { return }
            self.processDataSource(settings)
        }
        .store(in: &disposeBag)
        
        // init with no subscription for notification
        let settings: Setting? = nil
        self.processDataSource(settings)
    }
    
    private func requestSubscription() {
        // request subscription of notifications
        typealias SubscriptionResponse = Mastodon.Response.Content<Mastodon.Entity.Subscription>
        viewDidLoad.flatMap { [weak self] (_) -> AnyPublisher<SubscriptionResponse, Error> in
            guard let self = self,
                  let activeMastodonAuthenticationBox =
                    self.context.authenticationService.activeMastodonAuthenticationBox.value else {
                return Empty<SubscriptionResponse, Error>().eraseToAnyPublisher()
            }
            
            let domain = activeMastodonAuthenticationBox.domain
            return self.context.apiService.subscription(
                domain: domain,
                mastodonAuthenticationBox: activeMastodonAuthenticationBox)
        }
        .sink { _ in
        } receiveValue: { (subscription) in
        }
        .store(in: &disposeBag)
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension SettingsViewModel: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
         os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard controller === fetchResultsController else {
            return
        }
        
        setting.value = fetchResultsController.fetchedObjects?.first
    }
    
}

enum SettingsSection: Hashable {
    case apperance(title: String, selectedMode: SettingsItem)
    case notifications(title: String, items: [SettingsItem])
    case boringZone(title: String, items: [SettingsItem])
    case spicyZone(tilte: String, items: [SettingsItem])
    
    var title: String {
        switch self {
        case .apperance(let title, _),
             .notifications(let title, _),
             .boringZone(let title, _),
             .spicyZone(let title, _):
            return title
        }
    }
}

enum SettingsItem: Hashable {
    enum AppearanceMode: String {
        case automatic
        case light
        case dark
    }
    
    struct NotificationSwitch: Hashable {
        let title: String
        let isOn: Bool
        let enable: Bool
    }
    
    struct Link: Hashable {
        let title: String
        let color: UIColor
    }
    
    case apperance(item: AppearanceMode)
    case notification(item: NotificationSwitch)
    case boringZone(item: Link)
    case spicyZone(item: Link)
}
