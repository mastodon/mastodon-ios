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

typealias Provider = UIViewController & NeedsDependency & AuthContextProvider

extension DataSourceFacade {
    enum TranslationFailure: Error {
        case emptyOrInvalidResponse
    }
    
    public static func translateStatus(
        provider: Provider,
        status: ManagedObjectRecord<Status>
    ) async throws {
        let selectionFeedbackGenerator = await UISelectionFeedbackGenerator()
        await selectionFeedbackGenerator.selectionChanged()

        guard
            let status = status.object(in: provider.context.managedObjectContext)
        else {
            return
        }
        
        if let reblog = status.reblog {
            try await translateAndApply(provider: provider, status: reblog)
        } else {
            try await translateAndApply(provider: provider, status: status)
        }
    }
}

private extension DataSourceFacade {
    static func translateStatus(provider: Provider, status: Status) async throws -> Status.TranslatedContent? {
        do {
            let value = try await provider.context
                .apiService
                .translateStatus(
                    statusID: status.id,
                    authenticationBox: provider.authContext.mastodonAuthenticationBox
                ).value

            guard let content = value.content else {
                throw TranslationFailure.emptyOrInvalidResponse
            }
            
            return Status.TranslatedContent(content: content, provider: value.provider)
        } catch {
            throw TranslationFailure.emptyOrInvalidResponse
        }
    }
    
    static func translateAndApply(provider: Provider, status: Status) async throws {
        do {
            let translated = try await translateStatus(provider: provider, status: status)
            status.update(translatedContent: translated)
        } catch {
            status.update(translatedContent: nil)
            throw TranslationFailure.emptyOrInvalidResponse
        }
    }
}
