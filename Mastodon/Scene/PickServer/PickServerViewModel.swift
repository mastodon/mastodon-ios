//
//  PickServerViewModel.swift
//  Mastodon
//
//  Created by BradGao on 2021/2/23.
//

import UIKit
import Combine
import MastodonSDK

class PickServerViewModel: NSObject {
    enum PickServerMode {
        case SignUp
        case SignIn
    }
    
    enum Section: CaseIterable {
        case title
        case categories
        case serverList
    }
    
    enum Category {
        // `All` means search for all categories
        case All
        // `Some` means search for specific category
        case Some(Mastodon.Entity.Category)
        
        var title: String {
            switch self {
            case .All:
                return L10n.Scene.ServerPicker.Button.Category.all
            case .Some(let masCategory):
                switch masCategory.category {
                case .academia:
                    return "AC"
                case .activism:
                    return "AT"
                case .food:
                    return "F"
                case .furry:
                    return "FU"
                case .games:
                    return "G"
                case .general:
                    return "GE"
                case .journalism:
                    return "JO"
                case .lgbt:
                    return "LG"
                case .regional:
                    return "📍"
                case .art:
                    return "🎨"
                case .music:
                    return "🎼"
                case .tech:
                    return "📱"
                case ._other:
                    return "UN"
                }
            }
        }
    }
    
    let mode: PickServerMode
    let context: AppContext
    
    var categories = [Category]()
    let selectCategoryIndex = CurrentValueSubject<Int, Never>(0)
    
    let searchText = CurrentValueSubject<String?, Never>(nil)
    
    let allServers = CurrentValueSubject<[Mastodon.Entity.Instance], Error>([])
    let searchedServers = CurrentValueSubject<[Mastodon.Entity.Instance], Error>([])
    
    let nextButtonEnable = CurrentValueSubject<Bool, Never>(false)
    
    init(context: AppContext, mode: PickServerMode) {
        self.context = context
        self.mode = mode
        super.init()
        
        configure()
    }
    
    private func configure() {
        let masCategories = context.apiService.stubCategories()
        categories.append(.All)
        categories.append(contentsOf: masCategories.map { Category.Some($0) })
    }
}

extension PickServerViewModel: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 20
        }
        else if section == 1 {
            return 10
        }
        else {
            return 10
        }
    }
    
}

extension PickServerViewModel: UITableViewDataSource {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Self.Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = Self.Section.allCases[section]
        switch section {
        case .title,
             .categories:
            return 1
        case .serverList:
            return searchedServers.value.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let section = Self.Section.allCases[indexPath.section]
        switch section {
        case .title:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PickServerTitleCell.self), for: indexPath) as! PickServerTitleCell
            return cell
        case .categories:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PickServerCategoriesCell.self), for: indexPath) as! PickServerCategoriesCell
            cell.dataSource = self
            cell.delegate = self
            return cell
        case .serverList:
            return UITableViewCell(style: .default, reuseIdentifier: "1")
        }
    }
}

extension PickServerViewModel: PickServerCategoriesDataSource, PickServerCategoriesDelegate {
    func numberOfCategories() -> Int {
        return categories.count
    }
    
    func category(at index: Int) -> Category {
        return categories[index]
    }
    
    func selectedIndex() -> Int {
        return selectCategoryIndex.value
    }
    
    func pickServerCategoriesCell(didSelect index: Int) {
        selectCategoryIndex.send(index)
    }
}
