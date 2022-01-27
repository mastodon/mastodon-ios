//
//  PollItem.swift
//  
//
//  Created by MainasuK on 2022-1-12.
//

import Foundation
import CoreData

public enum PollItem: Hashable {
    case option(record: ManagedObjectRecord<PollOption>)
}
