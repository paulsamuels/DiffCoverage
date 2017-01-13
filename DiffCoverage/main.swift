//
//  main.swift
//  DiffCoverage
//
//  Created by Paul Samuels on 13/01/2017.
//  Copyright © 2017 Paul Samuels. All rights reserved.
//

import Foundation

guard
    let commitRange = UserDefaults.standard.string(forKey: "commit-range"),
    let executable  = UserDefaults.standard.string(forKey: "executable"),
    let profdata    = UserDefaults.standard.string(forKey: "profdata") else {
        print("Usage: diff-coverage -commit-range <sha..sha> -executable <path> -profdata <path>")
        exit(EXIT_FAILURE)
}

let diffSet = Git().calculateModifiedLines(for: commitRange)
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
