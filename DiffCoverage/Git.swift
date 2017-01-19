//
//  Git.swift
//  DiffCoverage
//
//  Created by Paul Samuels on 13/01/2017.
//  Copyright © 2017 Paul Samuels. All rights reserved.
//

import Foundation

struct Git {
    typealias CommitRange = String
    typealias DiffSet     = [FileName : Set<Int>]
    typealias Line        = String
    typealias FileName    = String
    typealias InvokerType = (_ command: String) throws -> [String]
    typealias SHA         = String
    
    let invoker: InvokerType
    let sourceRoot: String?
    
    init(invoker: @escaping InvokerType = Shell.bash, sourceRoot: String? = nil) {
        self.invoker    = invoker
        self.sourceRoot = sourceRoot
    }
    
    func calculateModifiedLines(for range: CommitRange) -> (lineCount: Int, changes: DiffSet) {
        let commitSHAs = shas(for: range)
        
        var changedLinesByFile: DiffSet = [:]
        
        let fileNames: [String]
        
        if let sourceRoot = sourceRoot {
            fileNames = filesChanged(in: range).filter({ $0.hasPrefix(sourceRoot) })
        } else {
            fileNames = filesChanged(in: range)
        }
        
        fileNames.forEach { fileName in
            let updatedLines = self.lineInformation(for: fileName, in: commitSHAs).map({
                $0.line
            })
            
            let lineNumbers = changedLinesByFile[fileName] ?? Set<Int>()
            changedLinesByFile[fileName] = lineNumbers.union(updatedLines)
        }
        
        changedLinesByFile.keys.forEach {
            if changedLinesByFile[$0]?.count == 0 {
                changedLinesByFile.removeValue(forKey: $0)
            }
        }
        
        return (
            lineCount: changedLinesByFile.map({ $0.value.count }).reduce(0, +),
            changes: changedLinesByFile
        )
    }
}

private extension Git {
    struct LineInfo {
        let line: Int
        let sha: String
    }
    
    func shas(for range: CommitRange) -> [SHA] {
        //swiftlint:disable:next force_try
        return try! invoker("git rev-list \(range)")
    }
    
    func filesChanged(in range: CommitRange) -> [FileName] {
        //swiftlint:disable:next force_try
        return try! invoker("git diff --diff-filter=d --name-only \(range)")
    }
    
    func lineInformation(for file: FileName, in SHAs: [String]) -> [LineInfo] {
        var lines = [LineInfo]()
        
        _ = annotations(for: file).reduce(true) { (shouldCollect: Bool, line: Line) -> Bool in
            guard shouldCollect else {
                return line.hasPrefix("\t")
            }
            
            let components = line.components(separatedBy: " ")
            
            guard components.count >= 3 else {
                return false
            }
            
            let sha = components[0]
            
            if SHAs.contains(sha), let line = Int(components[2]) {
                lines.append(LineInfo(line: line, sha: sha))
            }
                
            return false
        }
        
        return lines
    }
    
    func annotations(for file: FileName) -> [Line] {
        //swiftlint:disable:next force_try
        return try! invoker("git annotate -l --porcelain \(file)")
    }
}
