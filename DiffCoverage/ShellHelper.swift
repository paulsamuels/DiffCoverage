//
//  ShellHelper.swift
//  DiffCoverage
//
//  Created by Paul Samuels on 13/01/2017.
//  Copyright © 2017 Paul Samuels. All rights reserved.
//

import Foundation

enum ShellError: Error {
    case exitStatus(code: Int32)
}

@discardableResult
func shell(_ launchPath: String, _ arguments: String...) throws -> [String] {
    let task = Process()
    task.launchPath = launchPath
    task.arguments = arguments
    
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError  = FileHandle.nullDevice
    task.launch()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    
    task.waitUntilExit()
    
    if task.terminationStatus != 0 {
        throw ShellError.exitStatus(code: task.terminationStatus)
    }
    
    return String(data: data, encoding: .utf8)?
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .components(separatedBy: "\n") ?? []
}
