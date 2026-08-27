//
//  ActionRequestHandler.swift
//  OpenInActionExtension
//
//  Created by Marcus Kida on 03.01.23.
//

import Combine
import UIKit
import MobileCoreServices
import UniformTypeIdentifiers
import MastodonCore
import MastodonSDK
import MastodonLocalization

class ActionRequestHandler: NSObject, NSExtensionRequestHandling {
    var extensionContext: NSExtensionContext?
    var cancellables = [AnyCancellable]()
        
    func beginRequest(with context: NSExtensionContext) {
        // Do not call super in an Action extension with no user interface
        self.extensionContext = context
              
        let itemProvider = context.inputItems
            .compactMap({ $0 as? NSExtensionItem })
            .reduce([NSItemProvider](), { partialResult, acc in
                var nextResult = partialResult
                nextResult += acc.attachments ?? []
                return nextResult
            })
            .filter({ $0.hasItemConformingToTypeIdentifier(UTType.propertyList.identifier) })
            .first
        
        guard let itemProvider = itemProvider else {
            return doneWithInvalidLink()
        }
        
        itemProvider.loadItem(forTypeIdentifier: UTType.propertyList.identifier, options: nil, completionHandler: { [weak self] item, error in
            DispatchQueue.main.async {
                guard
                    let dictionary = item as? NSDictionary,
                    let results = dictionary[NSExtensionJavaScriptPreprocessingResultsKey] as? NSDictionary
                else {
                    self?.doneWithInvalidLink()
                    return
                }
                
                if let url = results["url"] as? String {
                    Task {
                        await self?.performSearch(for: url)
                    }
                } else {
                    self?.doneWithInvalidLink()
                }
            }
        })
    }
}

// Search API
private extension ActionRequestHandler {
    func performSearch(for url: String) async {
        guard
            let activeAuthenticationBox = await AuthenticationServiceProvider.shared.currentActiveUser.value
        else {
            return doneWithResults(nil)
        }
        
        Mastodon.API
            .V2
            .Search
            .search(
                session: .shared,
                domain: activeAuthenticationBox.domain,
                query: .init(q: url, resolve: true),
                authorization: activeAuthenticationBox.userAuthorization
            )
            .receive(on: DispatchQueue.main)
            .sink { completion in
                // no-op
            } receiveValue: { [weak self] result in
                let value = result.value
                if let foundAccount = value.accounts.first {
                    self?.doneWithResults([
                        "openURL": "mastodon://profile/\(foundAccount.acct)"
                    ])
                } else if let foundStatus = value.statuses.first {
                    self?.doneWithResults([
                        "openURL": "mastodon://status/\(foundStatus.id)"
                    ])
                } else if let foundHashtag = value.hashtags.first {
                    self?.continueWithSearch(foundHashtag.name)
                } else {
                    self?.doneWithInvalidLink()
                }
            }
            .store(in: &cancellables)

    }
}

// Fallback to In-App Search
private extension ActionRequestHandler {
    func continueWithSearch(_ query: String) {
        guard let query = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            doneWithInvalidLink()
            return
        }
        doneWithResults(
            ["openURL": "mastodon://search?query=\(query)"]
        )
    }
}

// Action response handling
private extension ActionRequestHandler {
    func doneWithInvalidLink() {
        doneWithResults(["alert": L10n.Extension.OpenIn.invalidLinkError])
    }
    
    func doneWithResults(_ resultsForJavaScriptFinalizeArg: [String: Any]?) {
        if let resultsForJavaScriptFinalize = resultsForJavaScriptFinalizeArg {
            let resultsDictionary = [NSExtensionJavaScriptFinalizeArgumentKey: resultsForJavaScriptFinalize]
            let resultsProvider = NSItemProvider(item: resultsDictionary as NSDictionary, typeIdentifier: UTType.propertyList.identifier)
            let resultsItem = NSExtensionItem()
            resultsItem.attachments = [resultsProvider]
            self.extensionContext!.completeRequest(returningItems: [resultsItem], completionHandler: nil)
        } else {
            self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
        }
        self.extensionContext = nil
    }
}
