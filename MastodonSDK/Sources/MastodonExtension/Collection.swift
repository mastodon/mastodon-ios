//
//  Collection.swift
//
//
//  Created by MainasuK on 2021-12-7.
//

import Foundation

// https://gist.github.com/DougGregor/92a2e4f6e11f6d733fb5065e9d1c880f
extension Collection where Self: Sendable, Index: Sendable {
    public func parallelMap<T: Sendable>(
        parallelism requestedParallelism: Int? = nil,
        _ transform: @escaping @Sendable (Element) async throws -> T
    ) async rethrows -> [T] {
        let defaultParallelism = 2
        let parallelism = requestedParallelism ?? defaultParallelism

        let n = count
        if n == 0 {
            return []
        }
        return try await withThrowingTaskGroup(of: (Int, T).self, returning: [T].self) { group in
            var result = [T?](repeatElement(nil, count: n))

            var i = self.startIndex
            var submitted = 0

            func submitNext() async throws {
                if i == self.endIndex { return }

                group.addTask { [submitted, i] in
                    let value = try await transform(self[i])
                    return (submitted, value)
                }
                submitted += 1
                formIndex(after: &i)
            }

            // submit first initial tasks
            for _ in 0 ..< parallelism {
                try await submitNext()
            }

            // as each task completes, submit a new task until we run out of work
            while let (index, taskResult) = try await group.next() {
                result[index] = taskResult

                try Task.checkCancellation()
                try await submitNext()
            }

            assert(result.count == n)
            return Array(result.compactMap { $0 })
        }
    }

    func parallelEach(
        parallelism requestedParallelism: Int? = nil,
        _ work: @escaping @Sendable (Element) async throws -> Void
    ) async rethrows {
        _ = try await parallelMap {
            try await work($0)
        }
    }
}
