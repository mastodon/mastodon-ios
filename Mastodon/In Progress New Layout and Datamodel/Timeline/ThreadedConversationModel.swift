// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import MastodonSDK

class ThreadedConversationModel {
    
    enum ThreadContext {
        case rootWithChildBelow
        case focused(connectedAbove: Bool, connectedBelow: Bool)
        case fragmentBegin(connectedBelow: Bool)
        case fragmentContinuation
        case fragmentEnd
    }
    
    var hasScrolledToFocusedPost = false
    let focusedID: Mastodon.Entity.Status.ID
    let fullThread: [ Mastodon.Entity.Status ]
    let threadContextInfos: [ Mastodon.Entity.Status.ID : ThreadContext]
    
    init(threadContext: Mastodon.Entity.Context, focusedPost: GenericMastodonPost) {
        focusedID = focusedPost.id
        
        var contextInfos = [ Mastodon.Entity.Status.ID : ThreadContext]()
        
        
        let ancestors = replyToThread(chainingUpFrom: focusedPost, from: threadContext.ancestors)
        let descendants = threadContext.descendants
        
        // Handle the focused post
        contextInfos[focusedPost.id] = .focused(connectedAbove: !ancestors.isEmpty, connectedBelow: !descendants.isEmpty)

        // Ancestors form a single reply chain
        for (index, item) in ancestors.enumerated() {
            switch index {
            case 0:
                contextInfos[item.id] = .rootWithChildBelow
            default:
                contextInfos[item.id] = .fragmentContinuation
            }
        }
        
        // Descendants can form a multiply branching tree; we rely on the server to have given the descendents to us in an appropriate display order
        let finalIndex = descendants.endIndex - 1
        var isReplyToPrevious = true // the first item in descendents ought to be a reply to the focused post
        for (index, item) in descendants.enumerated() {
            
            let nextItem = index == finalIndex ? nil : descendants[index + 1]
            let hasReplyBelow = nextItem?.inReplyToID == item.id
           
            switch (isReplyToPrevious, hasReplyBelow){
            case (true, true):
                contextInfos[item.id] = .fragmentContinuation
            case (true, false):
                contextInfos[item.id] = .fragmentEnd
            case (false, _):
                contextInfos[item.id] = .fragmentBegin(connectedBelow: hasReplyBelow)
            }

            isReplyToPrevious = hasReplyBelow
        }

        threadContextInfos = contextInfos
        fullThread = ancestors + [focusedPost._legacyEntity] + descendants
    }
    
    func context(for postID: Mastodon.Entity.Status.ID) -> ThreadContext? {
        return threadContextInfos[postID]
    }
}

struct MastodonReplyTree {
    let root: Mastodon.Entity.Status.ID
    let children: [MastodonReplyTree]
}

private func replyToThread(
    chainingUpFrom focusedPost: GenericMastodonPost,
    from statuses: [Mastodon.Entity.Status]
) -> [Mastodon.Entity.Status] {
    guard let post = focusedPost as? MastodonBasicPost, let replyToID = post.inReplyTo?.postID else { return [] }
    
    var dict: [Mastodon.Entity.Status.ID: Mastodon.Entity.Status] = [:]
    for status in statuses {
        dict[status.id] = status
    }
    
    var nextID: Mastodon.Entity.Status.ID? = replyToID
    var replies: [Mastodon.Entity.Status] = []
    while let _nextID = nextID {
        guard let status = dict[_nextID] else { break }
        replies.insert(status, at: 0)
        nextID = status.inReplyToID
    }
    
    return replies
}
