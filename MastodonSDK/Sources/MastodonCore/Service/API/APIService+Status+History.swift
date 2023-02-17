// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonSDK
import CoreDataStack

extension APIService {

    public func getStatusSource(
        forStatusID statusID: Status.ID,
        authenticationBox: MastodonAuthenticationBox) async throws -> Mastodon.Response.Content<Mastodon.Entity.StatusSource> {
            let domain = authenticationBox.domain
            let authorization = authenticationBox.userAuthorization

            let response = try await Mastodon.API.Statuses.statusSource(
                forStatusID: statusID,
                session: session,
                domain: domain,
                authorization: authorization).singleOutput()

            return response
        }

    public func getHistory(
        forStatusID statusID: Status.ID,
        authenticationBox: MastodonAuthenticationBox) async throws -> Mastodon.Response.Content<[Mastodon.Entity.StatusEdit]> {
            let domain = authenticationBox.domain
            let authorization = authenticationBox.userAuthorization

            let response = try await Mastodon.API.Statuses.editHistory(
                forStatusID: statusID,
                session: session,
                domain: domain,
                authorization: authorization).singleOutput()

            guard response.value.isEmpty == false else { return response }

            let managedObjectContext = self.backgroundManagedObjectContext

            try await managedObjectContext.performChanges {
                // get status
                guard let status = Status.fetch(in: managedObjectContext, configurationBlock: {
                    $0.predicate = Status.predicate(domain: domain, id: statusID)
                }).first else { return }

                Persistence.StatusEdit.createOrMerge(in: managedObjectContext,
                                                     statusEdits: response.value,
                                                     forStatus: status)
            }

            return response
        }
    
    public func publishStatusEdit(
        forStatusID statusID: Status.ID,
        editStatusQuery: Mastodon.API.Statuses.EditStatusQuery,
        authenticationBox: MastodonAuthenticationBox) async throws -> Mastodon.Response.Content<Mastodon.Entity.Status> {
            let domain = authenticationBox.domain
            let authorization = authenticationBox.userAuthorization
            
            let response = try await Mastodon.API.Statuses.editStatus(
                forStatusID: statusID,
                editStatusQuery: editStatusQuery,
                session: session,
                domain: domain,
                authorization: authorization).singleOutput()

            let responseHistory = try await Mastodon.API.Statuses.editHistory(
                forStatusID: statusID,
                session: session,
                domain: domain,
                authorization: authorization
            ).singleOutput()
            
            #if !APP_EXTENSION
            let managedObjectContext = self.backgroundManagedObjectContext

            try await managedObjectContext.performChanges {
                let me = authenticationBox.authenticationRecord.object(in: managedObjectContext)?.user
                let status = Persistence.Status.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.Status.PersistContext(
                        domain: domain,
                        entity: response.value,
                        me: me,
                        statusCache: nil,
                        userCache: nil,
                        networkDate: response.networkDate
                    )
                )
                
                Persistence.StatusEdit.createOrMerge(
                    in: managedObjectContext,
                    statusEdits: responseHistory.value,
                    forStatus: status.status
                )
            }
            #endif
            
            return response
        }
}
