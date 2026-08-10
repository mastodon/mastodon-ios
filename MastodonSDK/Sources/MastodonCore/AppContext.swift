//
//  AppContext.swift
//  
//
//  Created by MainasuK on 22/9/30.
//

import UIKit
import SwiftUI
import Combine

@MainActor
public class AppContext: ObservableObject {
    public static let shared = { AppContext() }()
    
    public var disposeBag = Set<AnyCancellable>()

    public let placeholderImageCacheService = PlaceholderImageCacheService()
    public let blurhashImageCacheService = BlurhashImageCacheService.shared
    
    let overrideTraitCollection = CurrentValueSubject<UITraitCollection?, Never>(nil)
    let timestampUpdatePublisher = Timer.publish(every: 1.0, on: .main, in: .common)
        .autoconnect()
        .share()
        .eraseToAnyPublisher()
    
    private init() {
    }
}
