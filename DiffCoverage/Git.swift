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
    
    struct CalculationResult {
        let changedLinesByFile: DiffSet
        let files: [String]
        let lineCount: Int
        
        init(changedLinesByFile: DiffSet) {
            self.changedLinesByFile = changedLinesByFile
            files     = changedLinesByFile.map { $0.key }
            lineCount = changedLinesByFile.map({ $0.value.count }).reduce(0, +)
        }
    }
    
    fileprivate let invoker: InvokerType
    fileprivate let fileFilterExecutable: String?
    
    init(invoker: @escaping InvokerType = Shell.bash, fileFilterExecutable: String? = nil) {
        self.invoker              = invoker
        self.fileFilterExecutable = fileFilterExecutable
    }
    
    func calculateModifiedLines(for range: CommitRange) -> CalculationResult {
        let commitSHAs = shas(for: range)
        
        var changedLinesByFile: DiffSet = [:]
        
        filesChanged(in: range).forEach { fileName in
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
        
        return CalculationResult(changedLinesByFile: changedLinesByFile)
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
        let fileNames = try! self.invoker("git diff --diff-filter=d --name-only \(range)")
        
        guard let fileFilterExecutable = fileFilterExecutable else {
            return fileNames
        }
        
        //swiftlint:disable:next force_try
        let filteredFiles = try! Shell.bash(fileFilterExecutable, input: Array(fileNames))
        
        if filteredFiles.count > 0 && !Set(fileNames).isSuperset(of: filteredFiles) {
            fatalError("The result of -file-filter-executable must be a subset of the passed files")
        }
        
        return filteredFiles
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
        return (try? invoker("git annotate -l --porcelain \"\(file)\"")) ?? []
    }
}
