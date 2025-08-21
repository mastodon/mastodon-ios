// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import MastodonSDK

class ThreadedConversationModel {
    
    enum ThreadContext {
        case rootWithChildBelow
        case focused(connectedAbove: Bool, connectedBelow: Bool)
        case fragmentStart
        case fragmentContinuation
        case fragmentEnd
    }
    
    var hasScrolledToFocusedPost = false
    let focusedID: Mastodon.Entity.Status.ID
    let fullThread: [ Mastodon.Entity.Status ]
    let threadContextInfos: [ Mastodon.Entity.Status.ID : ThreadContext]
    
    init(threadContext: Mastodon.Entity.Context, focusedPost: GenericMastodonPost) {
        focusedID = focusedPost.id
        
        // Ancestors form a single reply chain
        let anscestors = replyToThread(chainingUpFrom: focusedPost, from: threadContext.ancestors)
        
        // Descendants can form a multiply branching tree. We rely on the server to have given the descendents to us in an appropriate display order
        let descendants = threadContext.descendants
        
        fullThread = anscestors + [focusedPost._legacyEntity] + descendants

        var contextInfos = [ Mastodon.Entity.Status.ID : ThreadContext]()
        
        contextInfos[focusedPost.id] = .focused(connectedAbove: !anscestors.isEmpty, connectedBelow: !descendants.isEmpty)
        
        let allNonFocusedItems = anscestors + descendants
        let finalIndex = allNonFocusedItems.endIndex - 1
        for (index, item) in allNonFocusedItems.enumerated() {
            switch index {
            case 0:
                if anscestors.isEmpty {
                    // we are starting with a direct reply to the focused post
                    let nextIndex = index + 1
                    if allNonFocusedItems.endIndex > nextIndex {
                        let connectedBelow = index != finalIndex && allNonFocusedItems[nextIndex].inReplyToID == item.id
                        contextInfos[item.id] = connectedBelow ? .fragmentContinuation : .fragmentEnd
                    }
                } else {
                    contextInfos[item.id] = .rootWithChildBelow
                }
            default:
                let previous = allNonFocusedItems[index - 1]
                let connectedBelow = index != finalIndex && allNonFocusedItems[index + 1].inReplyToID == item.id
                let connectedAbove = previous.id == item.inReplyToID || !connectedBelow // this isn't the focused item, so if it isn't connected to something here and it isn't the root of the thread, then it must be a single disconnected reply to the focused post and should show the broken off connecting line to indicate that it is a reply
                switch (connectedAbove, connectedBelow) {
                case (true, true):
                    contextInfos[item.id] = .fragmentContinuation
                case (false, true):
                    contextInfos[item.id] = .fragmentStart
                case (true, false):
                    contextInfos[item.id] = .fragmentEnd
                case (false, false):
                    assertionFailure("only the focused item in a thread should have the possibility of being completely unconnected")
                }
            }
        }
        threadContextInfos = contextInfos
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
