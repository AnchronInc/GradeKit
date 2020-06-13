//
//  Login.swift
//  SimpleGrades
//
//  Created by Michael Caruso on 1/12/17.
//  Copyright © 2017 Anchron Inc. All rights reserved.
//

import Foundation
import KeychainSwift
import SwiftDate

class Login {
    //final var demoAccount = Account(username: "appstoredemo-h62T6X", password: "sPFJK5vYqZ4BSxY5JEAXn7aVymKzC5GK5tZs3j2Rgxy5LxZ9JLrXJFEd8nAnUh6Ue8FuXG9vURePVGYrHAShEYxsaA8ytJDDSJwN")
    private final var demoAccount = Account(username: "demo", password: "demo")
    private var useDemo = false
    private var expiry : Date? = nil
    private var account : Account? = nil
     
    public func attemptLogin(account : Account, success: @escaping () -> (), error: @escaping (_ error: GradeError) -> ()) {
        scrapeLogin(account: account, success: { response in
            success()
        }, error: {
            gradeError in
            if(gradeError == .demo) {
                success()
            } else {
                error(gradeError)
            }
        }, first: true)
    }
     
    public func attemptKeychainLogin(success: @escaping (_ username : String) -> (), error: @escaping (_ error: GradeError) -> ()) {
        expiry = nil
        let keychain = KeychainSwift()
        if let user = keychain.get("d303-username"), let pass = keychain.get("d303-pass") {
          let account = Account(username: user, password: pass)
            scrapeLogin(account: account, success: {
                rs in
               if(rs.contains("You have entered an invalid username or password")) {
                   _ = self.attemptDeleteKeychainData()
                   error (.invalid)
               }
               else if(rs.contains("unsuccessful") || rs == "") {
                   error (.empty)
               }
               else {
                    success(account.username)
               }
            }, error: error, first: true)
        } else {
            error(.keychain)
        }
    }
    
    public func getAccount() -> String? {
        if let username = account?.username {
            return username
        } else {
            return nil
        }
    }
    public func getFullAccount() -> Account? {
        return account;
    }
    public func isLoggedIn() -> Bool {
        if let expiry = expiry {
            return(Date() <= expiry)
        } else { return false }
    }
    public func isUsingDemo() -> Bool! {
        if (expiry != nil) {
            return useDemo;
        } else {
            return nil;
        }
    }
     public static func attemptDeleteKeychainData() {
          let keychain = KeychainSwift()
          keychain.delete("d303-username")
          keychain.delete("d303-pass")
          keychain.delete("parentlink-user")
          keychain.delete("parentlink-token")
     }
     
     private func attemptDeleteKeychainData() {
          let keychain = KeychainSwift()
          keychain.delete("d303-username")
          keychain.delete("d303-pass")
          keychain.delete("parentlink-user")
          keychain.delete("parentlink-token")
     }
    private func scrapeLogin(account : Account, success: @escaping (_ response: String) -> (), error: @escaping (_ error: GradeError) -> (), first: Bool){
        useDemo = false
        if(account.username == demoAccount.username && account.password == demoAccount.password) {
            self.account = account
            expiry = Date() + 365.days
            useDemo = true
            error(GradeError.demo)
            return;
        }
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
        
        let parameters: Parameters = [
            "Database": 10,
            "LogOnDetails.UserName": account.username,
            "LogOnDetails.Password": account.password
        ]
          GradeNetworking.login("https://istudent.d303.org/HomeAccess/Account/LogOn?ReturnUrl=%2fHomeAccess%2f", parameters: parameters) { res in
               if res == nil {
                    error(.network)
               } else {
                    TSKit.main.logWebActivity(url: "https://istudent.d303.org/HomeAccess/Account/LogOn?ReturnUrl=%2fHomeAccess%2f", params: nil, response: res!) //DO NOT include params, or we would expose sensitive login info.
                    
                    self.parseScrape(res!, success: success, error: error, first: first, account: account)
               }
          }
    }
     func parseScrape(_ rs: String, success: @escaping (_ response: String) -> (), error: @escaping (_ error: GradeError) -> (), first: Bool, account: Account) {
               if(rs.contains("HOME ACCESS CENTER IS CLOSED FOR THE SUMMER")) {
                    var dateComponents = DateComponents()
                    dateComponents.year = 2018
                    dateComponents.month = 8
                    dateComponents.day = 6
                    dateComponents.timeZone = TimeZone(abbreviation: "CDT")
                    dateComponents.hour = 8
                    dateComponents.minute = 0
                    
                    let userCalendar = Calendar.current
                    let openDate = userCalendar.date(from: dateComponents)
                    if(Date() < openDate!) {
                         error(.maintenance)
                         return
                    }
               }
     
               if(rs.contains("You have entered an invalid username or password")) {
                    error (.invalid)
               }
               else if(rs.contains("unsuccessful") || rs == "") {
                    error (.empty)
               }
               else if(rs.lowercased().contains("logon")) {
                    if(first) {
                         self.scrapeLogin(account: account, success: success, error: error, first: false)
                    } else {
                         error (.application)
                    }
               }
               else {
                    self.account = account
                    self.expiry = Date() + 19.minutes
                    let keychain = KeychainSwift()
                    
                    keychain.set(account.username, forKey:"d303-username", withAccess: .accessibleAfterFirstUnlock)
                    keychain.set(account.password, forKey:"d303-pass", withAccess: .accessibleAfterFirstUnlock)
                    success(rs)
               }

     }
    public func timeOut() {
        expiry = Date()
        GradeNetworking.get("https://istudent.d303.org/HomeAccess/Account/TimedOut") { (_) in }
    }
    public func logout() {
        expiry = nil
        student = nil
        schedule = []
        courses = []
        students = [:]
        //if let bundle = Bundle.main.bundleIdentifier {
        //    UserDefaults.standard.removePersistentDomain(forName: bundle)
        //}
        attemptDeleteKeychainData()
          _ = DataManager.remove(forKey: "courses")
          _ = DataManager.remove(forKey: "runs")
          _ = DataManager.remove(forKey: "semester")
     GradeNetworking.get("https://istudent.d303.org/HomeAccess/SessionReset?ReturnUrl=%2FHomeAccess%2FAccount%2FLogOff") { (_) in }
    }
}
