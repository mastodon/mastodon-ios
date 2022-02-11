//
//  SettingsAppearanceTableViewCell+ViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-2-8.
//

import UIKit
import Combine
import CoreDataStack

extension SettingsAppearanceTableViewCell {
    final class ViewModel: ObservableObject {
        var disposeBag = Set<AnyCancellable>()
        private var observations = Set<NSKeyValueObservation>()

        // input
        @Published public var customUserInterfaceStyle: UIUserInterfaceStyle = .unspecified
        @Published public var preferredTrueBlackDarkMode = false
        // output
        @Published public var appearanceMode: SettingsItem.AppearanceMode = .system

        init() {
            UserDefaults.shared.observe(\.customUserInterfaceStyle, options: [.initial, .new]) { [weak self] defaults, _ in
                guard let self = self else { return }
                self.customUserInterfaceStyle = defaults.customUserInterfaceStyle
            }
            .store(in: &observations)
        }
        
        public func prepareForReuse() {
            // do nothing
        }
    }
}

extension SettingsAppearanceTableViewCell.ViewModel {
    func bind(cell: SettingsAppearanceTableViewCell) {
        Publishers.CombineLatest(
            $customUserInterfaceStyle.removeDuplicates(),
            $preferredTrueBlackDarkMode.removeDuplicates()
        )
        .debounce(for: 0.1, scheduler: DispatchQueue.main)
        .receive(on: DispatchQueue.main)
        .sink { customUserInterfaceStyle, preferredTrueBlackDarkMode in
            cell.appearanceViews.forEach { view in
                view.selected = false
            }
            
            switch customUserInterfaceStyle {
            case .unspecified:
                cell.systemAppearanceView.selected = true
            case .dark:
                if preferredTrueBlackDarkMode {
                    cell.reallyDarkAppearanceView.selected = true
                } else {
                    cell.sortaDarkAppearanceView.selected = true
                }
            case .light:
                cell.lightAppearanceView.selected = true
            @unknown default:
                assertionFailure()
            }
        }
        .store(in: &disposeBag)
    }
}

extension SettingsAppearanceTableViewCell {
    func configure(setting: Setting) {
        setting.publisher(for: \.preferredTrueBlackDarkMode)
            .assign(to: \.preferredTrueBlackDarkMode, on: viewModel)
            .store(in: &disposeBag)
    }
    
}
