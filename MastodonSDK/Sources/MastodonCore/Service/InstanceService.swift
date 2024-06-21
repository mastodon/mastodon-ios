//
//  InstanceService.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-10-9.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

public final class InstanceService {
    
    var disposeBag = Set<AnyCancellable>()

    // input
    let backgroundManagedObjectContext: NSManagedObjectContext
    weak var apiService: APIService?
    weak var authenticationService: AuthenticationService?
    
    // output

    init(
        apiService: APIService,
        authenticationService: AuthenticationService
    ) {
        self.backgroundManagedObjectContext = apiService.backgroundManagedObjectContext
        self.apiService = apiService
        self.authenticationService = authenticationService
        
        authenticationService.$mastodonAuthenticationBoxes
            .receive(on: DispatchQueue.main)
            .compactMap { $0.first?.domain }
            .removeDuplicates()     // prevent infinity loop
            .sink { [weak self] domain in
                guard let self = self else { return }
                self.updateInstance(domain: domain)
            }
            .store(in: &disposeBag)
    }
    
}

extension InstanceService {
    func updateInstance(domain: String) {
        guard let apiService else { return }
        apiService.instance(domain: domain, authenticationBox: authenticationService?.mastodonAuthenticationBoxes.first)
            .flatMap { [unowned self] response -> AnyPublisher<Void, Error> in
                if response.value.version?.majorServerVersion(greaterThanOrEquals: 4) == true {
                    return apiService.instanceV2(domain: domain, authenticationBox: authenticationService?.mastodonAuthenticationBoxes.first)
                        .flatMap { return self.updateInstanceV2(domain: domain, response: $0) }
                        .eraseToAnyPublisher()
                } else {
                    return self.updateInstance(domain: domain, response: response)
                }
            }
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    self?.updateTranslationLanguages(domain: domain)
                case .failure:
                    break
                }
            } receiveValue: { [weak self] response in
                guard let _ = self else { return }
                // do nothing
            }
            .store(in: &disposeBag)
    }
    
    func updateTranslationLanguages(domain: String) {
        apiService?.translationLanguages(domain: domain, authenticationBox: authenticationService?.mastodonAuthenticationBoxes.first)
            .sink(receiveCompletion: { completion in
                // no-op
            }, receiveValue: { [weak self] response in
                self?.updateTranslationLanguages(domain: domain, response: response)
            })
            .store(in: &disposeBag)
    }
    
    private func updateTranslationLanguages(domain: String, response: Mastodon.Response.Content<TranslationLanguages>) {
        AuthenticationServiceProvider.shared
            .updating(translationLanguages: response.value, for: domain)
    }
    
    private func updateInstance(domain: String, response: Mastodon.Response.Content<Mastodon.Entity.Instance>) -> AnyPublisher<Void, Error> {
        let managedObjectContext = self.backgroundManagedObjectContext
        let instanceEntity = response.value
        return managedObjectContext.performChanges {
            // get instance
            let (instance, _) = APIService.CoreData.createOrMergeInstance(
                into: managedObjectContext,
                domain: domain,
                entity: instanceEntity,
                networkDate: response.networkDate
            )
            
            // update instance
            AuthenticationServiceProvider.shared
                .updating(instance: instance, where: domain)
                .updating(instanceV1: instanceEntity, for: domain)
        }
        .setFailureType(to: Error.self)
        .tryMap { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                throw error
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func updateInstanceV2(domain: String, response: Mastodon.Response.Content<Mastodon.Entity.V2.Instance>) -> AnyPublisher<Void, Error> {
        let managedObjectContext = self.backgroundManagedObjectContext
        let instanceEntity = response.value
        return managedObjectContext.performChanges {
            // get instance
            let (instance, _) = APIService.CoreData.createOrMergeInstance(
                in: managedObjectContext,
                context: .init(
                    domain: domain,
                    entity: instanceEntity,
                    networkDate: response.networkDate
                )
            )
            
            // update instance
            AuthenticationServiceProvider.shared
                .updating(instance: instance, where: domain)
                .updating(instanceV2: instanceEntity, for: domain)
        }
        .setFailureType(to: Error.self)
        .tryMap { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                throw error
            }
        }
        .eraseToAnyPublisher()
    }
}
