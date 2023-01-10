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
                
        guard
            let itemProvider = context.inputItems
                .compactMap({ $0 as? NSExtensionItem })
                .reduce([NSItemProvider](), { partialResult, acc in
                    var nextResult = partialResult
                    nextResult += acc.attachments ?? []
                    return nextResult
                })
                .filter({ $0.hasItemConformingToTypeIdentifier(UTType.propertyList.identifier) })
                .first
        else {
            return self.completeWithNotFoundError()
        }
        
        itemProvider.loadItem(forTypeIdentifier: UTType.propertyList.identifier, options: nil, completionHandler: { (item, error) in
            guard
                let dictionary = item as? [String: Any],
                let results = dictionary[NSExtensionJavaScriptPreprocessingResultsKey] as? [String: Any]? ?? [:]
            else {
                return self.completeWithNotFoundError()
            }
            
            DispatchQueue.main.async {
                self.completeWithOpenUserProfile(results)
            }
        })
    }
}

private extension ActionRequestHandler {
    func completeWithOpenUserProfile(_ results: [String: Any]) {
        guard let username = results["username"] as? String else { return }
        doneWithResults([
            "openURL": "mastodon://profile/\(username)"
        ])
    }
    
    func completeWithNotFoundError() {
        doneWithResults(
            ["error": "Failed to find username. Are you sure this is a Mastodon Profile page?"]
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
