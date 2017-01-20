//
//  main.swift
//  DiffCoverage
//
//  Created by Paul Samuels on 13/01/2017.
//  Copyright © 2017 Paul Samuels. All rights reserved.
//

import Foundation

let defaults = UserDefaults.standard

guard
    let commitRange = defaults.string(forKey: "commit-range"),
    let executable  = defaults.string(forKey: "executable"),
    let profdata    = defaults.string(forKey: "profdata") else {
        let requiredArguments = "-commit-range <sha..sha> -executable <path> -profdata <path>"
        let optionalArguments = "[-file-filter-executable <executable>]"
        print("diff-coverage --version: \(Info.gitSHA)")
        print("Usage: diff-coverage \(requiredArguments) \(optionalArguments)")
        exit(EXIT_FAILURE)
}

let fileFilterExecutable = defaults.string(forKey: "file-filter-executable")

let (diffDuration, diffCalculation) = Info.timed {
    Git(fileFilterExecutable: fileFilterExecutable).calculateModifiedLines(for: commitRange)
}

let (filterDuration, (executableLineCount, uncoveredLineCount, uncoveredBlocks)) = Info.timed {
    Coverage(executable: executable, profdata: profdata).filter(diffCalculation: diffCalculation)
}

var coverage = Float(0)

if executableLineCount > 0 {
    coverage = 100 - (Float(100) / Float(executableLineCount)) * Float(uncoveredLineCount)
}

let result: [String : Any] = [
    "stats" : [
        "coverage" : coverage,
        "line_count" : executableLineCount,
        "untested_line_count" : uncoveredLineCount,
        "diff_duration" : diffDuration,
        "llvm_cov_duration" : filterDuration,
        "tool_version" : Info.gitSHA,
        "file_filter_executable" : fileFilterExecutable ?? ""
    ],
    "data"  : uncoveredBlocks,
]

guard let data = try? JSONSerialization.data(
    withJSONObject: result,
    options: .prettyPrinted
    ),
    let output = String(data: data, encoding: .utf8) else {
        exit(EXIT_FAILURE)
}

print(output)
