//
//  ComposeViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-11.
//

import UIKit
import Combine
import CoreData
import CoreDataStack

final class ComposeViewModel {
    
    // input
    let context: AppContext
    let composeKind: ComposeKind
    
    // output
    var diffableDataSource: UITableViewDiffableDataSource<ComposeStatusSection, ComposeStatusItem>!
    let title: CurrentValueSubject<String, Never>
    let shouldDismiss = CurrentValueSubject<Bool, Never>(true)
    
    init(
        context: AppContext,
        composeKind: ComposeKind
    ) {
        self.context = context
        self.composeKind = composeKind
        switch composeKind {
        case .toot:         self.title = CurrentValueSubject(L10n.Scene.Compose.Title.newToot)
        case .replyToot:    self.title = CurrentValueSubject(L10n.Scene.Compose.Title.newReply)
        }
        // end init
    }
    
}

extension ComposeViewModel {
    enum ComposeKind {
        case toot
        case replyToot(tootObjectID: NSManagedObjectID)
    }
}
