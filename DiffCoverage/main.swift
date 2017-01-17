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
        let optionalArguments = "[-source-root <path>]"
        print("diff-coverage --version: \(Info.gitSHA)")
        print("Usage: diff-coverage \(requiredArguments) \(optionalArguments)")
        exit(EXIT_FAILURE)
}

let sourceRoot = defaults.string(forKey: "source-root")

let (diffDuration, (lineCount, diffSet)) = Info.timed {
    Git(sourceRoot: sourceRoot).calculateModifiedLines(for: commitRange)
}

let (filterDuration, (uncoveredLineCount, uncoveredBlocks)) = Info.timed {
    Coverage(executable: executable, profdata: profdata).filter(fileChanges: diffSet)
}

let result: [String : Any] = [
    "stats" : [
        "coverage" : 100 - (Float(100) / Float(lineCount)) * Float(uncoveredLineCount),
        "line_count" : lineCount,
        "untested_line_count" : uncoveredLineCount,
        "diff_duration" : diffDuration,
        "llvm_cov_duration" : filterDuration,
        "tool_version" : Info.gitSHA,
    ],
    "scope" : sourceRoot ?? "",
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
