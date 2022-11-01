//
//  AutoCompleteViewModel+Trie.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-18.
//

import Foundation

public struct Trie<Element: Hashable> {
    public let isElement: Bool
    public let valueSet: NSMutableSet
    public var children: [Element: Trie<Element>]
}

extension Trie {
    public init() {
        isElement = false
        valueSet = NSMutableSet()
        children = [:]
    }
    
    public init(_ key: ArraySlice<Element>, value: Any) {
        if let (head, tail) = key.decomposed {
            let children = [head: Trie(tail, value: value)]
            self = Trie(isElement: false, valueSet: NSMutableSet(), children: children)
        } else {
            self = Trie(isElement: true, valueSet: NSMutableSet(object: value), children: [:])
        }
    }
}

extension Trie {
    public var elements: [[Element]] {
        var result: [[Element]] = isElement ? [[]] : []
        for (key, value) in children {
            result += value.elements.map { [key] + $0 }
        }
        return result
    }
}

extension ArraySlice {
    public var decomposed: (Element, ArraySlice<Element>)? {
        return isEmpty ? nil : (self[startIndex], self.dropFirst())
    }
}

extension Trie {
    public func lookup(key: ArraySlice<Element>) -> Bool {
        guard let (head, tail) = key.decomposed else { return isElement }
        guard let subtrie = children[head] else { return false }
        return subtrie.lookup(key: tail)
    }
    
    public func lookup(key: ArraySlice<Element>) -> Trie<Element>? {
        guard let (head, tail) = key.decomposed else { return self }
        guard let remainder = children[head] else { return nil }
        return remainder.lookup(key: tail)
    }
}

extension Trie {
    public func complete(key: ArraySlice<Element>) -> [[Element]] {
        return lookup(key: key)?.elements ?? []
    }
}

extension Trie {
    public mutating func inserted(_ key: ArraySlice<Element>, value: Any) {
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
    public func passthrough(_ key: ArraySlice<Element>) -> [Trie<Element>] {
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
    
    public var values: NSSet {
        let valueSet = NSMutableSet(set: self.valueSet)
        for (_, value) in children {
            valueSet.addObjects(from: Array(value.values))
        }
        
        return valueSet
    }
    
}

