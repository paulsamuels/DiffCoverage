//
//  Scanner+Swift.swift
//  DiffCoverage
//
//  Created by Paul Samuels on 16/01/2017.
//  Copyright © 2017 Paul Samuels. All rights reserved.
//

import Foundation

extension Scanner {
    
    func scanInt32() -> Int32? {
        var result: Int32 = 0
        if scanInt32(&result) {
            return result
        }
        return nil
    }
    
    func tail() -> String? {
        return (string as NSString).substring(from: scanLocation)
    }
    
    func swallow(string: String) {
        scanString(string, into: nil)
    }
    
}
