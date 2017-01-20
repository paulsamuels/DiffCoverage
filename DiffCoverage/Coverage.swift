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
    
    struct CalculationResult {
        let executableLineCount: Int
        let untestedLineCount: Int
        let untestedChanges: [String : Any]
    }
    
    func filter(diffCalculation: Git.CalculationResult) -> CalculationResult {
        let keys = Set(diffCalculation.files)
        
        //swiftlint:disable:next force_try
        let lines = try! Shell.bash(
            //swiftlint:disable:next line_length
            "xcrun llvm-cov show -arch x86_64 -filename-equivalence -instr-profile \(profdata) \(executable) \(keys.joined(separator: " "))"
            )
        
        var currentFileName: String? = nil
        var untestedBlocks: [String : [UntestedBlock]] = [:]
        var executableLineCount = 0
        
        lines.forEach { line in
            if line.hasPrefix("/") {
                currentFileName = keys.first {
                    (line.replacingOccurrences(of: ":", with: "") as NSString).hasSuffix($0)
                }
                return
            }
            
            guard
                let currentFileName = currentFileName,
                let executableLineNumber = executableLineNumber(line: line),
                diffCalculation.changedLinesByFile[currentFileName]?.contains(executableLineNumber) == true else {
                    return
            }
            
            executableLineCount += 1
            
            guard let newBlock = UntestedBlock(rawValue: line) else {
                return
            }
            
            let isMergeable = untestedBlocks[currentFileName]?.last.map({
                $0.end + 1 == newBlock.start
            }) == true
            
            if isMergeable, let index = untestedBlocks[currentFileName]?.endIndex {
                untestedBlocks[currentFileName]?[index - 1].merge(other: newBlock)
            } else {
                var blocks = untestedBlocks[currentFileName] ?? []
                blocks.append(newBlock)
                untestedBlocks[currentFileName] = blocks
            }
        }
        
        var JSONRepresentation: [String : Any] = [:]
        
        untestedBlocks.forEach { fileName, untestedBlocks in
            JSONRepresentation[fileName] = untestedBlocks.map {
                [ "start" : $0.start, "end" : $0.end, "body" : $0.body ]
            }
        }
        
        let untestedLineCount = untestedBlocks.flatMap({
            $0.value
        }).reduce(0) { (accumulator, block) -> Int in
            return accumulator + (block.end - block.start) + 1
        }
        
        return CalculationResult(
            executableLineCount: executableLineCount,
            untestedLineCount: untestedLineCount,
            untestedChanges: JSONRepresentation
        )
    }
    
}

private extension Coverage {
    func executableLineNumber(line: String) -> Int? {
        let scanner = Scanner(string: line)
        
        guard scanner.scanInt32() != nil else {
            return nil
        }
        
        scanner.swallow(string: "|")
        
        guard let lineNumber = scanner.scanInt32() else {
            return nil
        }
        
        return Int(lineNumber)
    }
    
    struct UntestedBlock {
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
        
        mutating func merge(other: UntestedBlock) {
            _end   = other.end
            _body += "\n" + other.body
        }
    }
}
