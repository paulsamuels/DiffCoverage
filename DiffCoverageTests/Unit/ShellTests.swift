//
//  ShellTests.swift
//  DiffCoverage
//
//  Created by Paul Samuels on 15/01/2017.
//  Copyright © 2017 Paul Samuels. All rights reserved.
//

import XCTest

class ShellTests: XCTestCase {

    func testItCollectsTheResultsOfInvokingAShellCommand() {
        if let results = try? Shell.bash("ls /bin") {
            XCTAssertTrue(results.contains("ls"))
            XCTAssertTrue(results.contains("cat"))
            XCTAssertTrue(results.contains("mkdir"))
        } else {
            XCTFail()
        }
    }
    
    func testItThrowsWhenCommandHasNonZeroExit() {
        do {
            try Shell.bash("ls --unknown-option")
        } catch Shell.ExecutionError.exitStatus(let code) {
            XCTAssertTrue(code != 0)
        } catch {
            XCTFail()
        }
    }

}
