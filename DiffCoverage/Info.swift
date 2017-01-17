//
//  Info.swift
//  DiffCoverage
//
//  Created by Paul Samuels on 17/01/2017.
//  Copyright © 2017 Paul Samuels. All rights reserved.
//

import Foundation
import MachO

struct Info {
    static var gitSHA: String {
        return Bundle.main.infoDictionary.flatMap { $0["GIT_SHA"] as? String } ?? "unknown"
    }
    
    typealias TimeResult<Result> = (duration: TimeInterval, result: Result)
    
    static func timed<Result>(_ block: (Void) -> Result) -> TimeResult<Result> {
        let date = Date()
        let result = block()
        return (duration: -date.timeIntervalSinceNow, result: result)
    }

}
