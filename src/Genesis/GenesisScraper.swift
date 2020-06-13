//
//  GenesisScraper.swift
//  SimpleGrades
//
//  Created by Michael on 9/9/18.
//  Copyright © 2018 Anchron Inc. All rights reserved.
//

import Foundation
import Kanna

class GenesisScraper {

     private var login = GenesisLogin()

     let utilityQueue = DispatchQueue.global(qos: .userInteractive)

     func attemptKeychainLogin(success: @escaping () -> (), error: @escaping (_ error : GradeError) -> ()) {
          login.attemptKeychainLogin(success: {
               success()
          }, error: {
               gradeError in
               error(gradeError)
          })
     }
     func attemptLogin(account : Account, success: @escaping () -> (), error: @escaping (_ error: GradeError) -> ()) {
          login.attemptLogin(account: account, success: success, error: error)
     }

     func scrapeClasses(success: @escaping (_ response: String, _ overview : String) -> (), error: @escaping (_ error: GradeError) -> ()) {
          scrapeClasses(runs: runs, success: success, error: error)
     }

     func scrapeClasses(runs : String, success: @escaping (_ response: String, _ overview : String) -> (), error: @escaping (_ error: GradeError) -> ()) {
          let formatter = DateFormatter()
          formatter.dateFormat = "MM/dd/yyyy"

         var genesisRuns = "MP2"
          if(runs == "1" || runs == "2" || runs == "3" || runs == "4") {
               genesisRuns = "MP\(runs)"
          }

          //https://parents.sparta.org/sparta/parents?tab1=studentdata&tab2=gradebook&tab3=weeklysummary&action=form&studentid=162509&mpToView=MP2
          scrape("https://parents.sparta.org/sparta/parents?tab1=studentdata&tab2=gradebook&tab3=weeklysummary&studentid=\(login.getUserID())&action=form&date=\(formatter.string(from: Date()))&mpToView=\(genesisRuns)", { allGradeRes in

               self.scrape("https://parents.sparta.org/sparta/parents?tab1=studentdata&tab2=gradebook&tab3=listassignments&studentid=\(self.login.getUserID())&action=form&date=\(formatter.string(from: Date()))&dateRange=\(genesisRuns)&courseAndSection=&status=", { res in

                    if let doc = try? HTML(html: res, encoding: .utf8) {
                         if let first = doc.css("#fldDateRange").first {
                              for var node in first.css("option") {
                                   if(node["selected"]=="selected") {
                                        switch(node["value"]!) {
                                        case "MP1", "MP2", "MP3", "MP4":
                                             SimpleGrades.runs = node["value"]!.replacingOccurrences(of: "MP", with: "")
                                             if(node["value"]=="MP1" || node["value"]=="MP2") {
                                                  semester = 1
                                             } else {
                                                  semester = 2
                                             }
                                             break;
                                        default:
                                             error(.application)
                                             return;
                                        }
                                        DispatchQueue.main.async {
                                             if((semester == 1 && (SimpleGrades.runs == "1" || SimpleGrades.runs=="2")) || (semester == 2 && (SimpleGrades.runs == "3" || SimpleGrades.runs=="4"))) {
                                                  mainViewController.runsLabel.setTitle("QUARTER \(SimpleGrades.runs)", for: .normal)
                                             } else {
                                                  mainViewController.runsLabel.setTitle("SEMESTER \(semester)", for: .normal)
                                             }
                                        }

                                   }
                              }

                         }
                         success(res, allGradeRes)
                    } else {
                         error(.application)
                    }
               }, error)
          }, error)
     }

     func scrapeSchedule(success: @escaping (_ response: String) -> (), error: @escaping (_ error: GradeError) -> ()) {
          scrape("https://parents.sparta.org/sparta/parents?tab1=studentdata&studentid=\(login.getUserID())", success, error)
     }
     func scrapeStudentInfo(success: @escaping (_ response: String) -> (), error: @escaping (_ error: GradeError) -> ()) {
          scrape("https://parents.sparta.org/sparta/parents?tab1=studentdata&studentid=\(login.getUserID())", success, error)
     }

     func scrapeTranscript(success: @escaping (_ response: String) -> (), error: @escaping (_ error: GradeError) -> ()) {
     }

     public func scrapePicker(success: @escaping (_ response: String) -> (), error: @escaping (_ error: GradeError) -> ()) {
          scrape("https://parents.sparta.org/sparta/parents?tab1=studentdata&studentid=\(login.getUserID())", success, error)
     }
     public func setStudent(id : Int, success: @escaping() -> (), error: @escaping (_ error: GradeError) -> ()) {
          self.login.setUserID("\(id)")
          success()
     }
     public func scrapeAttendance(month : String, success: @escaping (_ response: String) -> (), error: @escaping (_ error: GradeError) -> ()) {
          scrape("https://parents.sparta.org/sparta/parents?tab1=studentdata&tab2=attendance&tab3=class&studentid=\(login.getUserID())&action=form&MONTH=\(month)", success, error)
     }

     private func scrape(_ url: String, _ success: @escaping (_ response: String) -> (), _ error: @escaping (_ error: GradeError) -> ()) {
          GradeNetworking.get(url) { response in
               guard let utf8Text = response else {
                    error(.network)
                    return
               }
               success(utf8Text)
          }
     }
     public func logout() {
          login.logout()
     }

     public func isLoggedIn() -> Bool {
          return login.isLoggedIn()
     }
     public func getFullAccount() -> Account? {
          return login.getFullAccount()
     }
     public func isUsingDemo() -> Bool {
          return login.isUsingDemo()
     }
}
