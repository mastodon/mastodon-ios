//
//  DataSourceFacade.swift
//  DataSourceFacade
//
//  Created by Cirno MainasuK on 2021-8-30.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation

enum DataSourceFacade {
    enum StatusTarget {
        case status         // remove reblog wrapper
        case reblog         // keep reblog wrapper
    }
}
