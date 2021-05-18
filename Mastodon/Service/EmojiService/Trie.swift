//
//  AutoCompleteViewModel+Trie.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-18.
//

import Foundation

struct Trie<Element: Hashable> {
    let isElement: Bool
    let valueSet: NSMutableSet
    var children: [Element: Trie<Element>]
}

extension Trie {
    init() {
        isElement = false
        valueSet = NSMutableSet()
        children = [:]
    }
    
    init(_ key: ArraySlice<Element>, value: Any) {
        if let (head, tail) = key.decomposed {
            let children = [head: Trie(tail, value: value)]
            self = Trie(isElement: false, valueSet: NSMutableSet(), children: children)
        } else {
            self = Trie(isElement: true, valueSet: NSMutableSet(object: value), children: [:])
        }
    }
}

extension Trie {
    var elements: [[Element]] {
        var result: [[Element]] = isElement ? [[]] : []
        for (key, value) in children {
            result += value.elements.map { [key] + $0 }
        }
        return result
    }
}

//extension Array {
//    var slice: ArraySlice<Element> {
//        return ArraySlice(self)
//    }
//}

extension ArraySlice {
    var decomposed: (Element, ArraySlice<Element>)? {
        return isEmpty ? nil : (self[startIndex], self.dropFirst())
    }
}

extension Trie {
    func lookup(key: ArraySlice<Element>) -> Bool {
        guard let (head, tail) = key.decomposed else { return isElement }
        guard let subtrie = children[head] else { return false }
        return subtrie.lookup(key: tail)
    }
    
    func lookup(key: ArraySlice<Element>) -> Trie<Element>? {
        guard let (head, tail) = key.decomposed else { return self }
        guard let remainder = children[head] else { return nil }
        return remainder.lookup(key: tail)
    }
}

extension Trie {
    func complete(key: ArraySlice<Element>) -> [[Element]] {
        return lookup(key: key)?.elements ?? []
    }
}

extension Trie {
    mutating func inserted(_ key: ArraySlice<Element>, value: Any) {
        guard let (head, tail) = key.decomposed else {
            self.valueSet.add(value)
            return
        }
        
        if var nextTrie = children[head] {
            nextTrie.inserted(tail, value: value)
            children[head] = nextTrie
        } else {
            children[head] = Trie(tail, value: value)
        }
    }
}

extension Trie {
    func passthrough(_ key: ArraySlice<Element>) -> [Trie<Element>] {
        guard let (head, tail) = key.decomposed else {
            return [self]
        }
        
        let passthroughed = children[head]?.passthrough(tail) ?? []
        if isElement {
            return passthroughed + [self]
        } else {
            return passthroughed
        }
    }
    
    var values: NSSet {
        let valueSet = NSMutableSet(set: self.valueSet)
        for (key, value) in children {
            valueSet.addObjects(from: Array(value.values))
        }
        
        return valueSet
    }
    
}

