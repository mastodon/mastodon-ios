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
        status: MastodonStatus
    ) async throws -> Mastodon.Entity.Translation? {
        FeedbackGenerator.shared.generate(.selectionChanged)

        do {
            let value = try await provider.context
                .apiService
                .translateStatus(
                    statusID: status.id,
                    authenticationBox: provider.authContext.mastodonAuthenticationBox
                ).value

            if value.content != nil {
                return value
            } else {
                return nil
            }

        } catch {
            throw TranslationFailure.emptyOrInvalidResponse
        }
    }
}
