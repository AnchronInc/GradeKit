//
//  Login.swift
//  SimpleGrades
//
//  Created by Michael Caruso on 9/9/18.
//  Copyright © 2018 Anchron Inc. All rights reserved.
//

import Foundation
import KeychainSwift
import SwiftDate
import Kanna

class GenesisLogin {
     //final var demoAccount = Account(username: "appstoredemo-h62T6X", password: "sPFJK5vYqZ4BSxY5JEAXn7aVymKzC5GK5tZs3j2Rgxy5LxZ9JLrXJFEd8nAnUh6Ue8FuXG9vURePVGYrHAShEYxsaA8ytJDDSJwN")
     private final var demoAccount = Account(username: "demo", password: "demo")
     private var useDemo = false
     private var loggedIn = false
     private var account : Account? = nil
     private var userID = "0"

     public func attemptLogin(account : Account, success: @escaping () -> (), error: @escaping (_ error: GradeError) -> ()) {
          scrapeLogin(account: account, success: success, error: {
               gradeError in
               if(gradeError == .demo) {
                    self.userID = "0"
                    success()
               } else {
                    error(gradeError)
               }
          })
     }

     public func attemptKeychainLogin(success: @escaping () -> (), error: @escaping (_ error: GradeError) -> ()) {
          loggedIn = false
          let keychain = KeychainSwift()
          if let user = keychain.get("genesis-username"), let pass = keychain.get("genesis-pass") {
               let account = Account(username: user, password: pass)
               scrapeLogin(account: account, success: success, error: error)
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
          return loggedIn
     }
     public func isUsingDemo() -> Bool! {
          if (loggedIn != false) {
               return useDemo;
          } else {
               return nil;
          }
     }
     public static func attemptDeleteKeychainData() {
          let keychain = KeychainSwift()
          keychain.delete("genesis-username")
          keychain.delete("genesis-pass")
          keychain.delete("genesis-student")
     }

     private func attemptDeleteKeychainData() {
          let keychain = KeychainSwift()
          keychain.delete("genesis-username")
          keychain.delete("genesis-pass")
          keychain.delete("genesis-student")
     }
     private func scrapeLogin(account : Account, success: @escaping () -> (), error: @escaping (_ error: GradeError) -> ()){
          useDemo = false
          if(account.username == demoAccount.username && account.password == demoAccount.password) {
               self.account = account
               loggedIn = true
               useDemo = true
               error(GradeError.demo)
               return;
          }
          if let cookies = HTTPCookieStorage.shared.cookies {
               for cookie in cookies {
                    HTTPCookieStorage.shared.deleteCookie(cookie)
               }
          }
          GradeNetworking.get("https://parents.sparta.org/sparta/parents?gohome=true") { response in
               guard let utf8Text = response else {
                    error(.network)
                    return
               }
               let parameters: Parameters = [
                    "j_username": account.username,
                    "j_password": account.password
               ]
               GradeNetworking.login("https://parents.sparta.org/sparta/j_security_check", parameters: parameters) { res in
                    if res == nil {
                         error(.network)
                    } else {
                         //JSESSIONID is the relevant cookie

                         self.parseScrape(res!, success: {
                              self.detectStudent(response: res!, success: success, error: error)
                         }, error: error, account: account)

                    }
               }

          }
     }

     func detectStudent(response: String, success: @escaping () -> (), error: @escaping(_ error: GradeError) -> ()) {

          let keychain = KeychainSwift()
          if let student = keychain.get("genesis-student") {
               self.userID = student
               success()
               return
          }

          if(response.lowercased().contains("parent access")) {
               error(.relogin)
               return
          }

          guard let doc = try? HTML(html: response, encoding: .utf8) else {
               error(.application)
               return
          }

          if let item = doc.at_css("#fldStudent option:selected"), let idVal = item["value"] {
               self.setUserID(idVal)
               success()
          } else {
               error(.application)
          }
     }

     func parseScrape(_ rs: String, success: @escaping () -> (), error: @escaping (_ error: GradeError) -> (), account: Account) {
          if(rs.contains("Invalid user name or password.  Please try again.")) {
               error (.invalid)
          }
          else if(rs == "") {
               error (.empty)
          }
          else if(rs.lowercased().contains("parent access")) {
                    error (.application)
          }
          else {
               self.account = account
               self.loggedIn = true
               let keychain = KeychainSwift()

               keychain.set(account.username, forKey:"genesis-username", withAccess: .accessibleAfterFirstUnlock)
               keychain.set(account.password, forKey:"genesis-pass", withAccess: .accessibleAfterFirstUnlock)
               success()
          }

     }

     public func logout() {
          userID = ""
          loggedIn = false
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
          GradeNetworking.get("https://parents.sparta.org/sparta/parents?logout=true") { (_) in }
     }
     public func setUserID(_ id : String) {
          self.userID = id

          let keychain = KeychainSwift()
          keychain.set(id, forKey:"genesis-student", withAccess: .accessibleAfterFirstUnlock)
     }
     public func getUserID() -> String {
          return userID
     }
}
