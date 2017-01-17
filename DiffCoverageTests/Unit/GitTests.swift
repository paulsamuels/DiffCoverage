//
//  GitTests.swift
//  DiffCoverage
//
//  Created by Paul Samuels on 15/01/2017.
//  Copyright © 2017 Paul Samuels. All rights reserved.
//

import XCTest

class GitTests: XCTestCase {
    
    func testItCalculatesAChangeSet() {
        
        let invocationRecorder = configuredInvocationRecorder()
        
        let git = Git(invoker: invocationRecorder.shell)
        
        let (lineCount, actual) = git.calculateModifiedLines(for: "abcdef..mnopqr")
        
        if invocationRecorder.unexpectedInvocations.count > 0 {
            XCTFail(invocationRecorder.unexpectedInvocations.joined(separator: ", "))
        }
        
        let expected = [
            "SomeProject/Models/Car.swift" : Set([11, 13]),
            "SomeProject/Models/Bike.swift" : Set([11, 13, 15]),
            ]
        
        XCTAssertEqual(expected, actual)
        XCTAssertEqual(5, lineCount)
        
    }
    
    //swiftlint:disable function_body_length
    private func configuredInvocationRecorder() -> InvocationRecorder {
        let invocationRecorder = InvocationRecorder()
        
        /// This command gets all the relevant SHAs
        /// for the commit range
        invocationRecorder.expect(
            command: "/usr/bin/git rev-list abcdef..mnopqr",
            result: [
                "ghijklzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz",
                "mnopqrzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"
            ]
        )
        
        /// This command gets the files that have been modified
        /// within the commit range
        invocationRecorder.expect(
            command: "/usr/bin/git diff --diff-filter=d --name-only abcdef..mnopqr",
            result: [
                "SomeProject/Models/Car.swift",
                "SomeProject/Models/Bike.swift",
                "SomeProject/Models/Boat.swift"
            ]
        )
        
        /// The following commands are then used to get the annotations
        /// for each of the files that have been modified
        /// within the commit range
        
        //swiftlint:disable line_length
        invocationRecorder.expect(
            command: "/usr/bin/git annotate -l --porcelain SomeProject/Models/Car.swift",
            result: [
                "ghijklzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz 11 11 3",
                "author Paul Samuels",
                "author-mail <paulio1987@gmail.com>",
                "author-time 1484344541",
                "author-tz +0000",
                "committer Paul Samuels",
                "committer-mail <paulio1987@gmail.com>",
                "committer-time 1484477044",
                "committer-tz +0000",
                "summary Initial Commit",
                "boundary",
                "SomeProject/Models/Car.swift",
                "\tstruct Car {",
                "9498bdbb7346445585ec71e746263c624eba51cc 12 12",
                "\t    let make: String",
                "mnopqrzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz 13 13",
                "\t}",
                ]
        )
        
        invocationRecorder.expect(
            command: "/usr/bin/git annotate -l --porcelain SomeProject/Models/Bike.swift",
            result: [
                "ghijklzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz 11 11 3",
                "author Paul Samuels",
                "author-mail <paulio1987@gmail.com>",
                "author-time 1484344541",
                "author-tz +0000",
                "committer Paul Samuels",
                "committer-mail <paulio1987@gmail.com>",
                "committer-time 1484477044",
                "committer-tz +0000",
                "summary Initial Commit",
                "boundary",
                "SomeProject/Models/Bike.swift",
                "\tstruct Bike {",
                "ghijklzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz 13 13",
                "\t    let make: String",
                "ghijklzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz 15 15",
                "\t}",
                ]
        )
        
        invocationRecorder.expect(
            command: "/usr/bin/git annotate -l --porcelain SomeProject/Models/Boat.swift",
            result: [
                "notacommitwithintherangeweareinterestedin 11 11 3",
                "author Paul Samuels",
                "author-mail <paulio1987@gmail.com>",
                "author-time 1484344541",
                "author-tz +0000",
                "committer Paul Samuels",
                "committer-mail <paulio1987@gmail.com>",
                "committer-time 1484477044",
                "committer-tz +0000",
                "summary Initial Commit",
                "boundary",
                "SomeProject/Models/Boat.swift",
                "\tstruct Boat {",
                "ghijknotacommitwithintherangeweareinterestedinlzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz 13 13",
                "\t    let make: String",
                "notacommitwithintherangeweareinterestedin 15 15",
                "\t}",
                ]
        )
        //swiftlint:enable line_length
        
        return invocationRecorder
    }
    //swiftlint:enable function_body_length
    
}

class InvocationRecorder {
    var invocations = [String]()
    var unexpectedInvocations = [String]()
    var cannedResults = [CannedResult]()
    
    func expect(command: String, result: [String]) {
        cannedResults.append(CannedResult(command: command, result: result))
    }
    
    @discardableResult
    func shell(_ launchPath: String, _ arguments: String...) throws -> [String] {
        let command = ([launchPath] + arguments).joined(separator: " ")
        
        self.invocations.append(command)
        
        guard let index = self.cannedResults.index(where: { $0.command == command }) else {
            self.unexpectedInvocations.append(command)
            return []
        }
        
        return self.cannedResults.remove(at: index).result
    }
    
    struct CannedResult {
        let command: String
        let result: [String]
    }
}
