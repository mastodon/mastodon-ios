//
//  ComposeContentViewModel.swift
//  
//
//  Created by MainasuK on 22/9/30.
//

import os.log
import Foundation
import Combine
import CoreDataStack
import MastodonCore
import Meta
import MastodonMeta

public final class ComposeContentViewModel: NSObject, ObservableObject {
    
    let logger = Logger(subsystem: "ComposeContentViewModel", category: "ViewModel")
    
    var disposeBag = Set<AnyCancellable>()
    
    // tableViewCell
    let composeReplyToTableViewCell = ComposeReplyToTableViewCell()
    let composeContentTableViewCell = ComposeContentTableViewCell()
    
    // input
    let context: AppContext
    let kind: Kind
    
    @Published var viewLayoutFrame = ViewLayoutFrame()
    @Published var authContext: AuthContext
    
    // output
    
    // content
    @Published public var initialContent = ""
    @Published public var content = ""
    @Published public var contentWeightedLength = 0
    @Published public var isContentEmpty = true
    @Published public var isContentValid = true
    @Published public var isContentEditing = false
    
    // author
    @Published var avatarURL: URL?
    @Published var name: MetaContent = PlaintextMetaContent(string: "")
    @Published var username: String = ""
    
    // UI & UX
    @Published var replyToCellFrame: CGRect = .zero
    @Published var contentCellFrame: CGRect = .zero
    @Published var scrollViewState: ScrollViewState = .fold


    public init(
        context: AppContext,
        authContext: AuthContext,
        kind: Kind
    ) {
        self.context = context
        self.authContext = authContext
        self.kind = kind
        super.init()
        // end init
        
        // bind author
        $authContext
            .sink { [weak self] authContext in
                guard let self = self else { return }
                guard let user = authContext.mastodonAuthenticationBox.authenticationRecord.object(in: self.context.managedObjectContext)?.user else { return }
                self.avatarURL = user.avatarImageURL()
                self.name = user.nameMetaContent ?? PlaintextMetaContent(string: user.displayNameWithFallback)
                self.username = user.acctWithDomain
            }
            .store(in: &disposeBag)
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }

}

extension ComposeContentViewModel {
    public enum Kind {
        case post
        case hashtag(hashtag: String)
        case mention(user: ManagedObjectRecord<MastodonUser>)
        case reply(status: ManagedObjectRecord<Status>)
    }

    public enum ScrollViewState {
        case fold       // snap to input
        case expand     // snap to reply
    }
}

