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
                
                if let username = results["username"] as? String {
                    self?.completeWithOpenUserProfile(username)
                } else if let url = results["url"] as? String {
                    self?.continueWithSearch(url)
                } else {
                    self?.doneWithInvalidLink()
                }
            }
        })
    }
}

private extension ActionRequestHandler {
    func completeWithOpenUserProfile(_ username: String) {
        doneWithResults([
            "openURL": "mastodon://profile/\(username)"
        ])
    }
    
    func continueWithSearch(_ query: String) {
        guard
            let url = URL(string: query),
            let host = url.host
        else {
            return doneWithInvalidLink()
        }
        
        Mastodon.API
            .Instance
            .instance(
                session: .shared,
                domain: host
            )
            .receive(on: DispatchQueue.main)
            .sink { _ in
                // no-op
            } receiveValue: { [weak self] response in
                guard response.value.version != nil else {
                    self?.doneWithInvalidLink()
                    return
                }
                guard let query = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                    self?.doneWithInvalidLink()
                    return
                }
                self?.doneWithResults(
                    ["openURL": "mastodon://search?query=\(query)"]
                )
            }
            .store(in: &cancellables)
    }
    
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
