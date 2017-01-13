//
//  Coverage.swift
//  DiffCoverage
//
//  Created by Paul Samuels on 14/01/2017.
//  Copyright © 2017 Paul Samuels. All rights reserved.
//

import Foundation

struct Coverage {
    let executable: String
    let profdata: String
    
    func filter(fileChanges: [String : Set<Int>]) -> [String : Any] {
        let keys = Set(fileChanges.keys)
        
        //swiftlint:disable:next force_try
        let lines = try! shell(
            //swiftlint:disable:next line_length
            "/usr/bin/xcrun", "llvm-cov", "show", "-arch", "x86_64", "-instr-profile", profdata, executable
            )
        
        var currentFileName: String? = nil
        var uncoveredBlocks: [String : [UncoveredBlock]] = [:]
        
        lines.forEach { line in
            if line.hasPrefix("/") {
                currentFileName = keys.first {
                    (line.replacingOccurrences(of: ":", with: "") as NSString).hasSuffix($0)
                }
                return
            }
            
            guard
                let currentFileName = currentFileName,
                let newBlock = UncoveredBlock(rawValue: line) else {
                    return
            }
            
            let isMergeable = uncoveredBlocks[currentFileName]?.last.map({
                $0.end + 1 == newBlock.start
            }) == true
            
            if isMergeable, let index = uncoveredBlocks[currentFileName]?.endIndex {
                uncoveredBlocks[currentFileName]?[index - 1].merge(other: newBlock)
            } else {
                var blocks = uncoveredBlocks[currentFileName] ?? []
                blocks.append(newBlock)
                uncoveredBlocks[currentFileName] = blocks
            }
        }
        
        var JSONRepresentation: [String : Any] = [:]
        
        uncoveredBlocks.forEach { fileName, uncoveredBlocks in
            JSONRepresentation[fileName] = uncoveredBlocks.map {
                [ "start" : $0.start, "end" : $0.end, "body" : $0.body ]
            }
        }
        
        return JSONRepresentation
    }
    
}

private extension Coverage {
    struct UncoveredBlock {
        private var _end: Int
        private var _body: String
        
        let start: Int
        var end: Int {
            return _end
        }
        
        var body: String {
            return _body
        }
        
        init?(rawValue: String) {
            let scanner = Scanner(string: rawValue)
            
            guard let numberOfInvocations = scanner.scanInt32(), numberOfInvocations == 0 else {
                return nil
            }
            
            scanner.swallow(string: "|")

            guard let lineNumber = scanner.scanInt32() else {
                return nil
            }
            
            scanner.swallow(string: "|")
            
            guard let tail = scanner.tail() else {
                return nil
            }
            
            start = Int(lineNumber)
            _end  = Int(lineNumber)
            _body = tail
        }
        
        mutating func merge(other: UncoveredBlock) {
            _end   = other.end
            _body += "\n" + other.body
        }
    }
}
