//
//  Shell.swift
//  DiffCoverage
//
//  Created by Paul Samuels on 13/01/2017.
//  Copyright © 2017 Paul Samuels. All rights reserved.
//

import Foundation

struct Shell {
    enum ExecutionError: Error {
        case exitStatus(code: Int32)
    }
    
    @discardableResult
    static func bash(_ command: String) throws -> [String] {
        return try bash(command, input: nil)
    }
    
    @discardableResult
    static func bash(_ command: String, input: [String]? = nil) throws -> [String] {
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = [ "-c", command ]
        
        let readPipe  = Pipe()
        let writePipe = Pipe()
        task.standardInput  = writePipe
        task.standardOutput = readPipe
        task.standardError  = FileHandle.nullDevice
        
        let writeHandle = writePipe.fileHandleForWriting
        
        task.launch()
        
        if let input = input {
            for line in input {
                guard let data = "\(line)\n".data(using: .utf8) else {
                    continue
                }
                
                writeHandle.write(data)
            }
            
            writeHandle.closeFile()
        }
        
        let data = readPipe.fileHandleForReading.readDataToEndOfFile()
        
        task.waitUntilExit()
        
        if task.terminationStatus != 0 {
            throw Shell.ExecutionError.exitStatus(code: task.terminationStatus)
        }
        
        guard data.count > 0 else {
            return []
        }
        
        return String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: "\n") ?? []
    }

}
