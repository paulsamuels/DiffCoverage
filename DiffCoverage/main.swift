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
        print("Usage: diff-coverage -commit-range <sha..sha> -executable <path> -profdata <path>")
        exit(EXIT_FAILURE)
}

let sourceRoot = defaults.string(forKey: "source-root")
let diffSet = Git(sourceRoot: sourceRoot).calculateModifiedLines(for: commitRange)
let coverage = Coverage(executable: executable, profdata: profdata)
let uncoveredBlocks = coverage.filter(fileChanges: diffSet)

guard let data = try? JSONSerialization.data(
    withJSONObject: uncoveredBlocks,
    options: .prettyPrinted
    ),
    let output = String(data: data, encoding: .utf8) else {
        exit(EXIT_FAILURE)
}

print(output)
