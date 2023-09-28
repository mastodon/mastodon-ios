//
//  SettingService.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-25.
//

import UIKit
import Combine
import CoreDataStack
import MastodonSDK
import MastodonAsset
import MastodonLocalization
import MastodonCommon

public final class SettingService {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    weak var apiService: APIService?
    weak var authenticationService: AuthenticationService?
    weak var notificationService: NotificationService?
    
    // output
    let settingFetchedResultController: SettingFetchedResultController
    public let currentSetting = CurrentValueSubject<Setting?, Never>(nil)
    
    init(
        apiService: APIService,
        authenticationService: AuthenticationService,
        notificationService: NotificationService
    ) {
        self.apiService = apiService
        self.authenticationService = authenticationService
        self.notificationService = notificationService
        self.settingFetchedResultController = SettingFetchedResultController(
            managedObjectContext: authenticationService.managedObjectContext,
            additionalPredicate: nil
        )

        // create setting (if non-exist) for authenticated users
        authenticationService.$mastodonAuthenticationBoxes
            .compactMap { [weak self] mastodonAuthenticationBoxes -> AnyPublisher<[MastodonAuthenticationBox], Never>? in
                guard let self = self else { return nil }
                guard let authenticationService = self.authenticationService else { return nil }
                
                let managedObjectContext = authenticationService.backgroundManagedObjectContext
                return managedObjectContext.performChanges {
                    for authenticationBox in mastodonAuthenticationBoxes {
                        let domain = authenticationBox.domain
                        let userID = authenticationBox.userID
                        _ = APIService.CoreData.createOrMergeSetting(
                            into: managedObjectContext,
                            property: Setting.Property(
                                domain: domain,
                                userID: userID
                            )
                        )
                    }   // end for
                }
                .map { _ in mastodonAuthenticationBoxes }
                .eraseToAnyPublisher()
            }
            .sink { _ in
                // do nothing
            }
            .store(in: &disposeBag)
        
        // bind current setting
        Publishers.CombineLatest(
            authenticationService.$mastodonAuthenticationBoxes,
            settingFetchedResultController.settings
        )
        .sink { [weak self] mastodonAuthenticationBoxes, settings in
            guard let self = self else { return }
            guard let activeMastodonAuthenticationBox = mastodonAuthenticationBoxes.first else { return }
            let currentSetting = settings.first(where: { setting in
                return setting.domain == activeMastodonAuthenticationBox.domain
                    && setting.userID == activeMastodonAuthenticationBox.userID
            })
            self.currentSetting.value = currentSetting
        }
        .store(in: &disposeBag)
        
        Publishers.CombineLatest3(
            notificationService.deviceToken,
            currentSetting.eraseToAnyPublisher(),
            authenticationService.$mastodonAuthenticationBoxes
        )
        .compactMap { [weak self] deviceToken, setting, mastodonAuthenticationBoxes -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Subscription>, Error>? in
            guard let self = self else { return nil }
            guard let deviceToken = deviceToken else { return nil }
            guard let setting = setting else { return nil }
            guard let authenticationBox = mastodonAuthenticationBoxes.first else { return nil }
            
            guard let subscription = setting.activeSubscription else { return nil }
            
            guard setting.domain == authenticationBox.domain,
                  setting.userID == authenticationBox.userID else { return nil }
            
            let _viewModel = self.notificationService?.dequeueNotificationViewModel(
                mastodonAuthenticationBox: authenticationBox
            )
            guard let viewModel = _viewModel else { return nil }
            let queryData = Mastodon.API.Subscriptions.QueryData(
                policy: subscription.policy,
                alerts: Mastodon.API.Subscriptions.QueryData.Alerts(
                    favourite: subscription.alert.favourite,
                    follow: subscription.alert.follow,
                    reblog: subscription.alert.reblog,
                    mention: subscription.alert.mention,
                    poll: subscription.alert.poll
                )
            )
            let query = viewModel.createSubscribeQuery(
                deviceToken: deviceToken,
                queryData: queryData,
                mastodonAuthenticationBox: authenticationBox
            )
    
            return apiService.createSubscription(
                subscriptionObjectID: subscription.objectID,
                query: query,
                mastodonAuthenticationBox: authenticationBox
            )
        }
        .debounce(for: .seconds(3), scheduler: DispatchQueue.main)      // limit subscribe request emit time interval
        .sink(receiveValue: { _ in
        })
        .store(in: &disposeBag)
    }
    
}

extension SettingService {
    
    public static func openSettingsAlertController(title: String, message: String) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let settingAction = UIAlertAction(title: L10n.Common.Controls.Actions.settings, style: .default) { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        alertController.addAction(settingAction)
        let cancelAction = UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        return alertController
    }
}
