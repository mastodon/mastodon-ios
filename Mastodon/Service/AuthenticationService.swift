//
//  AuthenticationService.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021/2/3.
//

import os.log
import Foundation
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

final class AuthenticationService: NSObject {

    var disposeBag = Set<AnyCancellable>()
    
    // input
    weak var apiService: APIService?
    let managedObjectContext: NSManagedObjectContext    // read-only
    let backgroundManagedObjectContext: NSManagedObjectContext
    let mastodonAuthenticationFetchedResultsController: NSFetchedResultsController<MastodonAuthentication>

    // output
    let mastodonAuthentications = CurrentValueSubject<[MastodonAuthentication], Never>([])
    let mastodonAuthenticationBoxes = CurrentValueSubject<[AuthenticationService.MastodonAuthenticationBox], Never>([])
    let activeMastodonAuthentication = CurrentValueSubject<MastodonAuthentication?, Never>(nil)
    let activeMastodonAuthenticationBox = CurrentValueSubject<AuthenticationService.MastodonAuthenticationBox?, Never>(nil)

    init(
        managedObjectContext: NSManagedObjectContext,
        backgroundManagedObjectContext: NSManagedObjectContext,
        apiService: APIService
    ) {
        self.managedObjectContext = managedObjectContext
        self.backgroundManagedObjectContext = backgroundManagedObjectContext
        self.apiService = apiService
        self.mastodonAuthenticationFetchedResultsController = {
            let fetchRequest = MastodonAuthentication.sortedFetchRequest
            fetchRequest.returnsObjectsAsFaults = false
            fetchRequest.fetchBatchSize = 20
            let controller = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: managedObjectContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            return controller
        }()
        super.init()

        mastodonAuthenticationFetchedResultsController.delegate = self

        // TODO: verify credentials for active authentication
    
        // bind data
        mastodonAuthentications
            .map { $0.sorted(by: { $0.activedAt > $1.activedAt }).first }
            .assign(to: \.value, on: activeMastodonAuthentication)
            .store(in: &disposeBag)
        
        mastodonAuthentications
            .map { authentications -> [AuthenticationService.MastodonAuthenticationBox] in
                return authentications
                    .sorted(by: { $0.activedAt > $1.activedAt })
                    .compactMap { authentication -> AuthenticationService.MastodonAuthenticationBox? in
                        return AuthenticationService.MastodonAuthenticationBox(
                            domain: authentication.domain,
                            userID: authentication.userID,
                            appAuthorization: Mastodon.API.OAuth.Authorization(accessToken: authentication.appAccessToken),
                            userAuthorization: Mastodon.API.OAuth.Authorization(accessToken: authentication.userAccessToken)
                        )
                    }
            }
            .assign(to: \.value, on: mastodonAuthenticationBoxes)
            .store(in: &disposeBag)
        
        mastodonAuthenticationBoxes
            .map { $0.first }
            .assign(to: \.value, on: activeMastodonAuthenticationBox)
            .store(in: &disposeBag)

        do {
            try mastodonAuthenticationFetchedResultsController.performFetch()
            mastodonAuthentications.value = mastodonAuthenticationFetchedResultsController.fetchedObjects ?? []
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }

}

extension AuthenticationService {
    struct MastodonAuthenticationBox {
        let domain: String
        let userID: MastodonUser.ID
        let appAuthorization: Mastodon.API.OAuth.Authorization
        let userAuthorization: Mastodon.API.OAuth.Authorization
    }
}

extension AuthenticationService {
    
    func activeMastodonUser(domain: String, userID: MastodonUser.ID) -> AnyPublisher<Result<Bool, Error>, Never> {
        var isActived = false
        
        return backgroundManagedObjectContext.performChanges {
            let request = MastodonAuthentication.sortedFetchRequest
            request.predicate = MastodonAuthentication.predicate(domain: domain, userID: userID)
            request.fetchLimit = 1
            guard let mastodonAutentication = try? self.backgroundManagedObjectContext.fetch(request).first else {
                return
            }
            mastodonAutentication.update(activedAt: Date())
            isActived = true
        }
        .map { result in
            return result.map { isActived }
        }
        .eraseToAnyPublisher()
    }
    
    func signOutMastodonUser(domain: String, userID: MastodonUser.ID) -> AnyPublisher<Result<Bool, Error>, Never> {
        var isSignOut = false
        
        var _mastodonAutenticationBox: MastodonAuthenticationBox?
        let managedObjectContext = backgroundManagedObjectContext
        return managedObjectContext.performChanges {
            let request = MastodonAuthentication.sortedFetchRequest
            request.predicate = MastodonAuthentication.predicate(domain: domain, userID: userID)
            request.fetchLimit = 1
            guard let mastodonAutentication = try? managedObjectContext.fetch(request).first else {
                return
            }
            _mastodonAutenticationBox = AuthenticationService.MastodonAuthenticationBox(
                domain: mastodonAutentication.domain,
                userID: mastodonAutentication.userID,
                appAuthorization: Mastodon.API.OAuth.Authorization(accessToken: mastodonAutentication.appAccessToken),
                userAuthorization: Mastodon.API.OAuth.Authorization(accessToken: mastodonAutentication.userAccessToken)
            )
            managedObjectContext.delete(mastodonAutentication)
            isSignOut = true
        }
        .flatMap { result -> AnyPublisher<Result<Void, Error>, Never> in
            guard let apiService = self.apiService,
                  let mastodonAuthenticationBox = _mastodonAutenticationBox else {
                return Just(result).eraseToAnyPublisher()
            }
            
            return apiService.cancelSubscription(
                mastodonAuthenticationBox: mastodonAuthenticationBox
            )
            .map { _ in result }
            .catch { _ in Just(result).eraseToAnyPublisher() }
            .eraseToAnyPublisher()
        }
        .map { result in
            return result.map { isSignOut }
        }
        .eraseToAnyPublisher()
    }
    
}


// MARK: - NSFetchedResultsControllerDelegate
extension AuthenticationService: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
         os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if controller === mastodonAuthenticationFetchedResultsController {
            mastodonAuthentications.value = mastodonAuthenticationFetchedResultsController.fetchedObjects ?? []
        }
    }
    
}
    
