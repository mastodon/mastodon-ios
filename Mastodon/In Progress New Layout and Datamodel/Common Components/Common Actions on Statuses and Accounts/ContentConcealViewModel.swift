// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonSDK
import MastodonLocalization

extension GenericMastodonPost.PostContent.ContentWarned {
    func displayMode(withShowAnyway showAnyway: Bool) -> ContentConcealViewModel.ContentDisplayMode {
        switch self {
        case .nothingToWarn:
            return .neverConceal
        case .warnAll(let reasons):
            return .concealAll(reasons: reasons, showAnyway: showAnyway)
        case .warnMediaAttachmentOnly:
            return .concealMediaOnly(showAnyway: showAnyway)
        }
    }
}

/// Posts can have no concealment, or be content warned (either full post or media only) or filtered, or both.
/// For a post that carries both a content warning and filter hits, we treat this as a layered reveal, with the actual content at the bottom, a layer of contentWarned protection on top of it, and a layer of filtered on top of that.
/// Revealing content removes the filtered layer first, then the contentWarned layer. Concealing content replaces both layers at once.
@MainActor
@Observable
class ContentConcealViewModel {
    
    static let alwaysShow = ContentConcealViewModel(contentPost: nil, context: nil)
    
    public var nestedContentConcealModel: ContentConcealViewModel?
    
    public enum ContentDisplayMode {
        case neverConceal
        case concealAll(reasons: [String], showAnyway: Bool)
        case concealMediaOnly(showAnyway: Bool)
        
        var isShowingMedia: Bool {
            switch self {
            case .neverConceal, .concealMediaOnly(showAnyway: true), .concealAll(_, showAnyway: true):
                return true
            default:
                return false
            }
        }
        
        var isShowingContent: Bool {
            switch self {
            case .neverConceal, .concealMediaOnly, .concealAll(_, showAnyway: true):
                return true
            default:
                return false
            }
        }
        
        var reasons: [String]? {
            switch self {
            case .neverConceal, .concealMediaOnly:
                return nil
            case .concealAll(let reasons, _):
                return reasons
            }
        }
    }
    
    private let filtered: GenericMastodonPost.PostContent.ContentWarned
    private let contentWarned: GenericMastodonPost.PostContent.ContentWarned
    
    private var showAnyway: (despiteFiltered: Bool?, despiteContentWarning: Bool?)
    
    private(set) var currentModeIsFilter: Bool
    
    var currentMode: ContentDisplayMode
    
    init(contentPost: MastodonContentPost?, context: Mastodon.Entity.FilterContext?) {
        
        guard let contentPost, let context else {
            filtered = .nothingToWarn
            contentWarned = .nothingToWarn
            showAnyway = (nil, nil)
            currentModeIsFilter = false
            currentMode = .neverConceal
            return
        }
        
        var filterTitles = [String]()
        if let filterResults = contentPost.content.filtered {
            for filterResult in filterResults {
                if filterResult.filter.context.contains(context) {
                    filterTitles.append(filterResult.filter.title)
                }
            }
        }
        if !filterTitles.isEmpty {
            filtered = .warnAll(reasons: filterTitles)
        } else {
            filtered = .nothingToWarn
        }
        contentWarned = contentPost.content.contentWarned
        currentMode = .neverConceal
        currentModeIsFilter = false
        
        showAnyway = ContentConcealViewModel.hideAll(filtered: filtered, contentWarned: contentWarned)
        let (mode, isFilter) = ContentConcealViewModel.updatedMode(filtered: filtered, contentWarned: contentWarned, showAnyway: showAnyway)
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
    
    private static func updatedMode(filtered: GenericMastodonPost.PostContent.ContentWarned, contentWarned: GenericMastodonPost.PostContent.ContentWarned, showAnyway: (despiteFiltered: Bool?, despiteContentWarning: Bool?)) -> (ContentDisplayMode, isFilter: Bool) {
        switch showAnyway {
        case (nil, nil):  // no concealment layers exist
            return (.neverConceal, isFilter: false)
        case (nil, .some(let overrideCW)): // there is only a content warning
            return (contentWarned.displayMode(withShowAnyway: overrideCW), isFilter: false)
        case (.some(let overrideFilter), nil):  // there is only a filter
            return (filtered.displayMode(withShowAnyway: overrideFilter), isFilter: true)
        case (false, _): // filter is NOT overridden, so it takes precedence (based on previous cases, we also have a CW, but that doesn't matter)
            return (filtered.displayMode(withShowAnyway: false), isFilter: true)
        case (.some(let overrideFilter), .some(let overrideCW)): // we have both layers, if filter is not overridden, it takes precedence
            if overrideFilter {
                return (contentWarned.displayMode(withShowAnyway: overrideCW), isFilter: false)
            } else {
                return (filtered.displayMode(withShowAnyway: false), isFilter: true)
            }
        }
    }
    
    func showMore() {
        let newShowAnyway: (Bool?, Bool?)
        switch showAnyway {
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
        setShowAnyway(newShowAnyway)
    }
    
    func hide() {
        let newShowAnyway = ContentConcealViewModel.hideAll(filtered: filtered, contentWarned: contentWarned)
        setShowAnyway(newShowAnyway)
        
        nestedContentConcealModel?.hide()
    }
    
    func setShowAnyway(_ newValue: (Bool?, Bool?)) {
        showAnyway = newValue
        let (mode, isFilter) = Self.updatedMode(filtered: filtered, contentWarned: contentWarned, showAnyway: showAnyway)
        currentModeIsFilter = isFilter
        currentMode = mode
    }
}
