// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonCore
import MastodonLocalization
import MastodonSDK

extension GenericMastodonPost.PostContent.ContentWarned {
    func displayMode(withShowTextAnyway showTextAnyway: Bool, showMediaAnyway: Bool?) -> ContentConcealViewModel.ContentDisplayMode {
        let showMedia = showMediaAnyway ?? true
        switch self {
        case .nothingToWarn:
            return .neverConceal
        case .warnAll(let reasons):
            return .concealAll(reasons: reasons, showTextAnyway: showTextAnyway, showMediaAnyway: showMedia)
        case .warnMediaAttachmentOnly:
            return .concealMediaOnly(showAnyway: showMedia)
        }
    }
}

/// Posts can have no concealment, or be content warned (either full post or media only) or filtered, or both.
/// For a post that carries both a content warning and filter hits, we treat this as a layered reveal, with the actual content at the bottom, a layer of contentWarned protection on top of it, and a layer of filtered on top of that.
/// Revealing content removes the filtered layer first, then the contentWarned layer. Concealing content replaces both layers at once.
/// Media is treated separately, requiring its own tap to reveal.
/// User preferences (set on the web) can override contentWarned behavior (defaulting to show all content, even in warned posts, or to hide all images, even when the post has no warning).
@MainActor
@Observable
class ContentConcealViewModel {
    
    static let alwaysShow = ContentConcealViewModel(contentPost: nil, context: nil)
    
    public var nestedContentConcealModel: ContentConcealViewModel?
    
    public enum ContentDisplayMode {
        case neverConceal
        case concealAll(reasons: [String], showTextAnyway: Bool, showMediaAnyway: Bool)
        case concealMediaOnly(showAnyway: Bool)
        
        var isShowingMedia: Bool {
            switch self {
            case .neverConceal, .concealMediaOnly(showAnyway: true), .concealAll(_, _, showMediaAnyway: true):
                return true
            default:
                return false
            }
        }
        
        var isShowingTextContent: Bool {
            switch self {
            case .neverConceal, .concealMediaOnly, .concealAll(_, showTextAnyway: true, _):
                return true
            default:
                return false
            }
        }
        
        var reasons: [String]? {
            switch self {
            case .neverConceal, .concealMediaOnly:
                return nil
            case .concealAll(let reasons, _, _):
                return reasons
            }
        }
    }
    
    private let filtered: GenericMastodonPost.PostContent.ContentWarned
    private let contentWarned: GenericMastodonPost.PostContent.ContentWarned
    
    private var showTextAnyway: (despiteFiltered: Bool?, despiteContentWarning: Bool?)
    private var showMedia: Bool?
    private let initialShowMedia: Bool?
    let blurFilterReasons: [String]
    
    private(set) var currentModeIsFilter: Bool
    
    private(set) var currentMode: ContentDisplayMode
    
    init(initialHideText: Bool, initialHideMedia: Bool) {
        filtered = .nothingToWarn
        contentWarned = .warnAll(reasons: [])
        showTextAnyway = (nil, !initialHideText)
        showMedia = !initialHideMedia
        initialShowMedia = !initialHideMedia
        blurFilterReasons = []
        currentModeIsFilter = false
        currentMode = .concealAll(reasons: [], showTextAnyway: !initialHideText, showMediaAnyway: !initialHideMedia)
    }
    
    init(contentPost: MastodonContentPost?, context: Mastodon.Entity.FilterContext?) {
        
        guard let contentPost else {
            filtered = .nothingToWarn
            contentWarned = .nothingToWarn
            showTextAnyway = (nil, nil)
            showMedia = nil
            initialShowMedia = nil
            blurFilterReasons = []
            currentModeIsFilter = false
            currentMode = .neverConceal
            return
        }
        
        var warnTitles = [String]()
        var blurTitles = [String]()
        if let filterResults = contentPost.content.filtered, let context {
            for filterResult in filterResults {
                if filterResult.filter.context.contains(context) {
                    if filterResult.filter.filterAction == .blur {
                        blurTitles.append(filterResult.filter.title)
                    } else {
                        warnTitles.append(filterResult.filter.title)
                    }
                }
            }
        }
        if !warnTitles.isEmpty {
            filtered = .warnAll(reasons: warnTitles)
        } else {
            filtered = .nothingToWarn
        }
        contentWarned = contentPost.content.contentWarned
        currentMode = .neverConceal
        currentModeIsFilter = false
        
        // Filters always start by hiding. Content warnings can start unhidden if the user's preferences request that.
        let preferences = AuthenticationServiceProvider.shared.activeUserPreferences
        var initialShowText: (despiteFiltered: Bool?, despiteContentWarning: Bool?) = ContentConcealViewModel.hideAll(filtered: filtered, contentWarned: contentWarned)
        if preferences.readingExpandSpoilers, initialShowText.despiteContentWarning == false {
            initialShowText.despiteContentWarning = true
        }
        showTextAnyway = initialShowText
        
        let isSensitive: Bool = {
            switch contentPost.content.contentWarned {
            case .nothingToWarn:
                false
            case .warnAll, .warnMediaAttachmentOnly:
                true
            }
        }()
        let initialShowMedia: Bool? = {
            guard case .media(let attachments) = contentPost.content.attachment, !attachments.isEmpty else { return nil }
            if !blurTitles.isEmpty { return false } // blur filters take precedence over any other settings
            switch preferences.readingExpandMedia {
            case .showAll: return true
            case .hideAll: return false
            default: return !isSensitive
            }
        }()
        showMedia = initialShowMedia
        self.initialShowMedia = initialShowMedia
        blurFilterReasons = blurTitles
        let (mode, isFilter) = ContentConcealViewModel.updatedMode(filtered: filtered, contentWarned: contentWarned, showTextAnyway: showTextAnyway, showMediaAnyway: showMedia)
        currentModeIsFilter = isFilter
        currentMode = mode
        
        if let post = contentPost as? MastodonBasicPost, let quote = post.quotedPost, let quotedPost = quote.fullPost {
            self.nestedContentConcealModel = ContentConcealViewModel(contentPost: quotedPost, context: context)
        }
    }
    
    static func hideAll(filtered: GenericMastodonPost.PostContent.ContentWarned, contentWarned: GenericMastodonPost.PostContent.ContentWarned) -> (Bool?, Bool?) {
        switch (filtered, contentWarned) {
        case (.nothingToWarn, .nothingToWarn):
            return (nil, nil)
        case (.nothingToWarn, _):
            return (nil, false)
        case (_, .nothingToWarn):
            return (false, nil)
        default:
            return (false, false)
        }
    }
    
    private static func updatedMode(filtered: GenericMastodonPost.PostContent.ContentWarned, contentWarned: GenericMastodonPost.PostContent.ContentWarned, showTextAnyway: (despiteFiltered: Bool?, despiteContentWarning: Bool?), showMediaAnyway: Bool?) -> (ContentDisplayMode, isFilter: Bool) {
        switch showTextAnyway {
        case (nil, nil):  // no text concealment layers exist
            if let showMediaAnyway {
                return (.concealMediaOnly(showAnyway: showMediaAnyway), isFilter: false)
            }
            return (.neverConceal, isFilter: false)
        case (nil, .some(let overrideCW)): // there is only a content warning
            return (contentWarned.displayMode(withShowTextAnyway: overrideCW, showMediaAnyway: showMediaAnyway), isFilter: false)
        case (.some(let overrideFilter), nil):  // there is only a filter
            return (filtered.displayMode(withShowTextAnyway: overrideFilter, showMediaAnyway: showMediaAnyway), isFilter: true)
        case (false, _): // filter is NOT overridden, so it takes precedence (based on previous cases, we also have a CW, but that doesn't matter)
            return (filtered.displayMode(withShowTextAnyway: false, showMediaAnyway: showMediaAnyway), isFilter: true)
        case (.some(let overrideFilter), .some(let overrideCW)): // we have both layers, if filter is not overridden, it takes precedence
            if overrideFilter {
                return (contentWarned.displayMode(withShowTextAnyway: overrideCW, showMediaAnyway: showMediaAnyway), isFilter: false)
            } else {
                return (filtered.displayMode(withShowTextAnyway: false, showMediaAnyway: showMediaAnyway), isFilter: true)
            }
        }
    }
    
    func showMoreTextContent() {
        let newShowAnyway: (Bool?, Bool?)
        switch showTextAnyway {
        case (.none, .none), (.some(true), .some(true)), (.some(true), .none), (.none, .some(true)):
            assertionFailure("cannot show something that is not hidden")
            return
        case (.some(false), .none):  // there is only a filter, and it is in place
            newShowAnyway = (true, nil)
        case (.some(false), .some(let cw)):  // both a filter and a cw, filter is currently the top layer, so remove that
            newShowAnyway = (true, cw)
        case (.some(true), .some(false)):  // both a filter and a cw, filter is already removed, now remove the cw
            newShowAnyway = (true, true)
        case (.none, .some(false)): // only a cw, remove it
            newShowAnyway = (nil, true)
        }
        setShowTextAnyway(newShowAnyway)
    }
    
    func hideTextContent() {
        showMedia = initialShowMedia
        let newShowAnyway = ContentConcealViewModel.hideAll(filtered: filtered, contentWarned: contentWarned)
        setShowTextAnyway(newShowAnyway)
        
        nestedContentConcealModel?.hideTextContent()
    }
    
    private func setShowTextAnyway(_ newValue: (Bool?, Bool?)) {
        showTextAnyway = newValue
        recalculateMode()
    }
    
    func revealMedia() {
        guard showMedia != nil else { assertionFailure("no media to show"); return }
        showMedia = true
        recalculateMode()
    }
    
    func hideMedia() {
        guard showMedia != nil else { assertionFailure("no media to hide"); return }
        showMedia = false
        recalculateMode()
    }
    
    private func recalculateMode() {
        let (mode, isFilter) = Self.updatedMode(filtered: filtered, contentWarned: contentWarned, showTextAnyway: showTextAnyway, showMediaAnyway: showMedia)
        currentModeIsFilter = isFilter
        currentMode = mode
    }
}
