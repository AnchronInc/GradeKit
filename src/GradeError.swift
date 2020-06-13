//
//  GradeError.swift
//  SimpleGrades
//
//  Created by Michael Caruso on 1/12/17.
//  Copyright © 2017 Anchron Inc. All rights reserved.
//

public enum GradeError : Error {
    case relogin
    case network
    case application
    case empty
    case invalid
    case keychain
    case demo
    case maintenance
}
enum GNError : Error {
     case network
     case parse
     case file
}
