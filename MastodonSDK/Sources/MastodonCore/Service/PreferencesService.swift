//
//  PreferencesService.swift
//  
//
//  Created by Jed Fox on 2022-11-28.
//

import os.log
import Combine
import CoreDataStack
import MastodonSDK

public final class PreferencesService {

    var disposeBag = Set<AnyCancellable>()

    private var currentSettingUpdateSubscription: AnyCancellable?

    // input
    weak var apiService: APIService?
    weak var authenticationService: AuthenticationService?

    // output
    public let currentPreferences = CurrentValueSubject<Mastodon.Entity.Preferences, Never>(.default)

    static let logger = Logger(subsystem: "PreferencesService", category: "Service")


    init(
        apiService: APIService,
        authenticationService: AuthenticationService
    ) {
        self.apiService = apiService
        self.authenticationService = authenticationService

        // bind current setting
        Publishers.CombineLatest(
            authenticationService.$mastodonAuthenticationBoxes,
            authenticationService.updateActiveUserAccountPublisher
        )
        .compactMap { [weak self] (mastodonAuthenticationBoxes, _) -> AnyPublisher<(Mastodon.Response.Content<Mastodon.Entity.Preferences>, ManagedObjectRecord<MastodonAuthentication>, APIService), Error>? in
            guard let self = self, let apiService = self.apiService else { return nil }
            guard let activeMastodonAuthenticationBox = mastodonAuthenticationBoxes.first else { return nil }
            return apiService.preferences(authenticationBox: activeMastodonAuthenticationBox)
                .combineLatest(
                    Just(activeMastodonAuthenticationBox.authenticationRecord).setFailureType(to: Error.self),
                    Just(apiService).setFailureType(to: Error.self)
                )
                .eraseToAnyPublisher()
        }
        .flatMap { $0 }
        .asyncMap { [weak self] prefs, authenticationRecord, apiService in
            guard let self = self, let apiService = self.apiService else { return }
            await MainActor.run {
                self.currentPreferences.send(prefs.value)
            }
            try await apiService.backgroundManagedObjectContext.perform {
                let authentication = authenticationRecord.object(in: apiService.backgroundManagedObjectContext)
                authentication?.update(preferences: prefs.value)
            }
        }
        .sink { completion in
            if case .failure(let error) = completion {
                // NOTE: this should be changed to .sensitive or .private if we ever allow
                // user input in preferences beyond simple boolean/enum options.
                Self.logger.warning("Error parsing preferences: \(error, privacy: .public)")
            }
        } receiveValue: { _ in }
        .store(in: &disposeBag)

        authenticationService.$mastodonAuthenticationBoxes
            .compactMap { $0.first?.authenticationRecord }
            .sink { [weak self] authenticationRecord in
                guard let self = self, let apiService = self.apiService else { return }
                self.currentPreferences.send(
                    authenticationRecord.object(in: apiService.backgroundManagedObjectContext)?.preferences ?? .default
                )
            }
            .store(in: &disposeBag)
    }

}
