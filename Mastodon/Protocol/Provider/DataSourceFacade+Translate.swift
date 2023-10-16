//
//  DataSourceFacade+Translate.swift
//  Mastodon
//
//  Created by Marcus Kida on 29.11.22.
//

import UIKit
import CoreData
import CoreDataStack
import MastodonCore
import MastodonSDK

typealias Provider = UIViewController & NeedsDependency & AuthContextProvider

extension DataSourceFacade {
    enum TranslationFailure: Error {
        case emptyOrInvalidResponse
    }
    
    public static func translateStatus(
        provider: Provider,
        status: ManagedObjectRecord<Status>
    ) async throws -> Mastodon.Entity.Translation? {
        let selectionFeedbackGenerator = await UISelectionFeedbackGenerator()
        await selectionFeedbackGenerator.selectionChanged()

        guard
            let status = status.object(in: provider.context.managedObjectContext)
        else {
            return nil
        }
        
        if let reblog = status.reblog {
            return try await translateStatus(provider: provider, status: reblog)
        } else {
            return try await translateStatus(provider: provider, status: status)
        }
    }
}

private extension DataSourceFacade {
    static func translateStatus(provider: Provider, status: Status) async throws -> Mastodon.Entity.Translation? {
        do {
            let value = try await provider.context
                .apiService
                .translateStatus(
                    statusID: status.id,
                    authenticationBox: provider.authContext.mastodonAuthenticationBox
                ).value

            guard let content = value.content else {
                return nil
            }
            
            return value
        } catch {
            throw TranslationFailure.emptyOrInvalidResponse
        }
    }
}
