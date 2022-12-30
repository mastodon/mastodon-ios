//
//  InstanceService.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-10-9.
//

import os.log
import Foundation
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

public final class InstanceService {
    
    var disposeBag = Set<AnyCancellable>()
    
    let logger = Logger(subsystem: "InstanceService", category: "Logic")
    
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
        guard let apiService = self.apiService else { return }
        apiService.instance(domain: domain)
            .flatMap { [unowned self] response -> AnyPublisher<Void, Error> in
                if response.value.version?.majorServerVersion(greaterThanOrEquals: 4) == true {
                    return apiService.instanceV2(domain: domain)
                        .flatMap { return self.updateInstanceV2(domain: domain, response: $0) }
                        .eraseToAnyPublisher()
                } else {
                    return self.updateInstance(domain: domain, response: response)
                }
            }
//            .flatMap { [unowned self] response -> AnyPublisher<Void, Error> in
//                return
//            }
            .sink { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .failure(let error):
                    self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Instance] update instance failure: \(error.localizedDescription)")
                case .finished:
                    self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Instance] update instance for domain: \(domain)")
                }
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
                networkDate: response.networkDate,
                log: Logger(subsystem: "Update", category: "InstanceService")
            )
            
            // update relationship
            let request = MastodonAuthentication.sortedFetchRequest
            request.predicate = MastodonAuthentication.predicate(domain: domain)
            request.returnsObjectsAsFaults = false
            do {
                let authentications = try managedObjectContext.fetch(request)
                for authentication in authentications {
                    authentication.update(instance: instance)
                }
            } catch {
                assertionFailure(error.localizedDescription)
            }
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
                    networkDate: response.networkDate,
                    log: Logger(subsystem: "Update", category: "InstanceService")
                )
            )
            
            // update relationship
            let request = MastodonAuthentication.sortedFetchRequest
            request.predicate = MastodonAuthentication.predicate(domain: domain)
            request.returnsObjectsAsFaults = false
            do {
                let authentications = try managedObjectContext.fetch(request)
                for authentication in authentications {
                    authentication.update(instance: instance)
                }
            } catch {
                assertionFailure(error.localizedDescription)
            }
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

public extension InstanceService {
    func updateMutesAndBlocks() {
        Task {
            for authBox in authenticationService?.mastodonAuthenticationBoxes ?? [] {
                do {
                    try await apiService?.getMutes(
                        authenticationBox: authBox
                    )
                    
                    try await apiService?.getBlocked(
                        authenticationBox: authBox
                    )
                    
                    self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Instance] update mutes and blocks succeeded")
                } catch {
                    self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [Instance] update mutes and blocks failure: \(error.localizedDescription)")
                }
            }
        }
    }
}
