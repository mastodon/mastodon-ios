//
//  ComposeContentViewModel.swift
//  
//
//  Created by MainasuK on 22/9/30.
//

import Foundation
import CoreDataStack
import MastodonCore

public final class ComposeContentViewModel: NSObject, ObservableObject {
    
    // tableViewCell
    let composeReplyToTableViewCell = ComposeReplyToTableViewCell()
    
    // input
    let context: AppContext
    let kind: Kind

    public init(
        context: AppContext,
        kind: Kind
    ) {
        self.context = context
        self.kind = kind
        super.init()
        // end init
    }
    
}

extension ComposeContentViewModel {
    public enum Kind {
        case post
        case hashtag(hashtag: String)
        case mention(user: ManagedObjectRecord<MastodonUser>)
        case reply(status: ManagedObjectRecord<Status>)
    }

    public enum ViewState {
        case fold       // snap to input
        case expand     // snap to reply
    }
}

