//
//  ActionRequestHandler.swift
//  OpenInActionExtension
//
//  Created by Marcus Kida on 03.01.23.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

class ActionRequestHandler: NSObject, NSExtensionRequestHandling {

    var extensionContext: NSExtensionContext?
    
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
            return doneWithResults(nil)
        }
        
        itemProvider.loadItem(forTypeIdentifier: UTType.propertyList.identifier, options: nil, completionHandler: { [weak self] item, error in
            DispatchQueue.main.async {
                guard
                    let dictionary = item as? NSDictionary,
                    let results = dictionary[NSExtensionJavaScriptPreprocessingResultsKey] as? NSDictionary
                else {
                    self?.doneWithResults(nil)
                    return
                }
                
                if let username = results["username"] as? String {
                    self?.completeWithOpenUserProfile(username)
                } else if let url = results["url"] as? String {
                    self?.completeWithSearch(url)
                } else {
                    self?.doneWithResults(nil)
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
    
    func completeWithSearch(_ query: String) {
        guard let query = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return doneWithResults(nil)
        }
        doneWithResults(
            ["openURL": "mastodon://search?query=\(query)"]
        )
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
