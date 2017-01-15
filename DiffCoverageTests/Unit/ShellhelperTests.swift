//
//  ShellhelperTests.swift
//  DiffCoverage
//
//  Created by Paul Samuels on 15/01/2017.
//  Copyright © 2017 Paul Samuels. All rights reserved.
//

import XCTest

class ShellhelperTests: XCTestCase {

    func testItCollectsTheResultsOfInvokingAShellCommand() {
        if let results = try? shell("/bin/ls", "/bin") {
            XCTAssertTrue(results.contains("ls"))
            XCTAssertTrue(results.contains("cat"))
            XCTAssertTrue(results.contains("mkdir"))
        } else {
            XCTFail()
        }
    }
    
    func testItThrowsWhenCommandHasNonZeroExit() {
        do {
            try shell("/bin/ls", "--unknown-option")
        } catch ShellError.exitStatus(let code) {
            XCTAssertTrue(code != 0)
        } catch {
            XCTFail()
        }
    }

}
