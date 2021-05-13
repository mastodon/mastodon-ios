//
//  CustomScheduler.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-30.
//

import Foundation
import Combine

// Ref: https://stackoverflow.com/a/59069315/3797903
struct CustomScheduler: Scheduler {
    var runLoop: RunLoop
    var modes: [RunLoop.Mode] = [.default]

    func schedule(after date: RunLoop.SchedulerTimeType, interval: RunLoop.SchedulerTimeType.Stride,
                    tolerance: RunLoop.SchedulerTimeType.Stride, options: Never?,
                    _ action: @escaping () -> Void) -> Cancellable {
        let timer = Timer(fire: date.date, interval: interval.magnitude, repeats: true) { timer in
            action()
        }
        for mode in modes {
            runLoop.add(timer, forMode: mode)
        }
        return AnyCancellable {
            timer.invalidate()
        }
    }

    func schedule(after date: RunLoop.SchedulerTimeType, tolerance: RunLoop.SchedulerTimeType.Stride,
                    options: Never?, _ action: @escaping () -> Void) {
        let timer = Timer(fire: date.date, interval: 0, repeats: false) { timer in
            timer.invalidate()
            action()
        }
        for mode in modes {
            runLoop.add(timer, forMode: mode)
        }
    }

    func schedule(options: Never?, _ action: @escaping () -> Void) {
        runLoop.perform(inModes: modes, block: action)
    }

    var now: RunLoop.SchedulerTimeType { RunLoop.SchedulerTimeType(Date()) }
    var minimumTolerance: RunLoop.SchedulerTimeType.Stride { RunLoop.SchedulerTimeType.Stride(0.1) }

    typealias SchedulerTimeType = RunLoop.SchedulerTimeType
    typealias SchedulerOptions = Never
}
