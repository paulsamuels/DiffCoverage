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
        print("Usage: diff-coverage \(requiredArguments) \(optionalArguments)")
        exit(EXIT_FAILURE)
}

let sourceRoot = defaults.string(forKey: "source-root")
let (lineCount, diffSet) = Git(sourceRoot: sourceRoot).calculateModifiedLines(for: commitRange)
let coverage = Coverage(executable: executable, profdata: profdata)
let (uncoveredLineCount, uncoveredBlocks) = coverage.filter(fileChanges: diffSet)

let result: [String : Any] = [
    "code_coverage" : (Float(100) / Float(lineCount)) * Float(uncoveredLineCount),
    "scope"         : sourceRoot ?? "",
    "data"          : uncoveredBlocks,
]

guard let data = try? JSONSerialization.data(
    withJSONObject: result,
    options: .prettyPrinted
    ),
    let output = String(data: data, encoding: .utf8) else {
        exit(EXIT_FAILURE)
}

print(output)
