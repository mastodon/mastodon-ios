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

extension DataSourceFacade {
    enum TranslationFailure: Error {
        case emptyOrInvalidResponse
    }
    
    public static func translateStatus(
        provider: UIViewController & NeedsDependency & AuthContextProvider,
        status: ManagedObjectRecord<Status>
    ) async throws {
        let selectionFeedbackGenerator = await UISelectionFeedbackGenerator()
        await selectionFeedbackGenerator.selectionChanged()

        guard
            let status = status.object(in: provider.context.managedObjectContext)
        else {
            return
        }
        
        func translate(status: Status) async throws -> String? {
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
                
                return content
            } catch {
                throw TranslationFailure.emptyOrInvalidResponse
            }
        }
        
        func translateAndApply(to status: Status) async throws {
            do {
                status.translatedContent = try await translate(status: status)
            } catch {
                status.translatedContent = nil
                throw TranslationFailure.emptyOrInvalidResponse
            }
        }
        
        if let reblog = status.reblog {
            try await translateAndApply(to: reblog)
        } else {
            try await translateAndApply(to: status)
        }
    }
}
