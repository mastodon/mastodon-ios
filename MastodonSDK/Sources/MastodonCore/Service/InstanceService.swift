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
//            .flatMap { [unowned self] response -> AnyPublisher<Void, Error> in
//                return
//            }
            .sink { _ in
            } receiveValue: { [weak self] response in
                guard let _ = self else { return }
                // do nothing
            }
            .store(in: &disposeBag)
    }
    
    private func updateInstance(domain: String, response: Mastodon.Response.Content<Mastodon.Entity.Instance>) -> AnyPublisher<Void, Error> {
        let managedObjectContext = self.backgroundManagedObjectContext
        return managedObjectContext.performChanges {
            // get instance
            let (instance, _) = APIService.CoreData.createOrMergeInstance(
                into: managedObjectContext,
                domain: domain,
                entity: response.value,
                networkDate: response.networkDate
            )
            
            // update instance
            AuthenticationServiceProvider.shared.update(instance: instance, where: domain)
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
        return managedObjectContext.performChanges {
            // get instance
            let (instance, _) = APIService.CoreData.createOrMergeInstance(
                in: managedObjectContext,
                context: .init(
                    domain: domain,
                    entity: response.value,
                    networkDate: response.networkDate
                )
            )
            
            // update instance
            AuthenticationServiceProvider.shared.update(instance: instance, where: domain)
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
