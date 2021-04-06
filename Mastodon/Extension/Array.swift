//
//  Array.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/7.
//

import Foundation

public extension Array where Element: Equatable {

   func removeDuplicate() -> Array {
      return self.enumerated().filter { (index,value) -> Bool in
           return self.firstIndex(of: value) == index
       }.map { (_, value) in
           value
       }
   }
}

