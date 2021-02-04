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

class AuthenticationService: NSObject {

    var disposeBag = Set<AnyCancellable>()
    // input
    weak var apiService: APIService?
    let managedObjectContext: NSManagedObjectContext    // read-only
    let backgroundManagedObjectContext: NSManagedObjectContext
    let mastodonAuthenticationFetchedResultsController: NSFetchedResultsController<MastodonAuthentication>

    // output
    let mastodonAuthentications = CurrentValueSubject<[MastodonAuthentication], Never>([])
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
        
        activeMastodonAuthentication
            .map { authentication -> AuthenticationService.MastodonAuthenticationBox? in
                guard let authentication = authentication else { return nil }
                return AuthenticationService.MastodonAuthenticationBox(
                    domain: authentication.domain,
                    userID: authentication.userID,
                    appAuthorization: Mastodon.API.OAuth.Authorization(accessToken: authentication.appAccessToken),
                    userAuthorization: Mastodon.API.OAuth.Authorization(accessToken: authentication.userAccessToken)
                )
            }
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
        
        return backgroundManagedObjectContext.performChanges {
            let request = MastodonAuthentication.sortedFetchRequest
            request.predicate = MastodonAuthentication.predicate(domain: domain, userID: userID)
            request.fetchLimit = 1
            guard let mastodonAutentication = try? self.backgroundManagedObjectContext.fetch(request).first else {
                return
            }
            self.backgroundManagedObjectContext.delete(mastodonAutentication)
            isSignOut = true
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
    
