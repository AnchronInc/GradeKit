//
//  Scraper.swift
//  SimpleGrades
//
//  Created by Michael Caruso on 1/12/17.
//  Copyright © 2017 Anchron Inc. All rights reserved.
//

import Kanna
var lastValidation = ""
var lastViewState = ""

class Scraper {
    let utilityQueue = DispatchQueue.global(qos: .userInteractive)
    var studentID = -1
    var parentLinkToken = ""
    var parentLinkUserID = 0
    private var login = Login()
    
     func attemptKeychainLogin(success: @escaping () -> (), error: @escaping (_ error : GradeError) -> ()) {
          login.attemptKeychainLogin(success: { username in
               success()
               if let id = Int(username) {
                    self.studentID = id
               }
          }, error: {
               gradeError in
               error(gradeError)
          })
     }
     func attemptLogin(account : Account, success: @escaping () -> (), error: @escaping (_ error: GradeError) -> ()) {
          login.attemptLogin(account: account, success: success, error: error)
     }
    private func preLoginCheck(success: @escaping (_ EVENTVALIDATION: String, _ VIEWSTATE : String) -> (), error: @escaping (_ error : GradeError) -> ()) {
        if(lastValidation != "" && lastViewState != "") {
            success(lastValidation, lastViewState)
            lastValidation = ""
            lastViewState = ""
        } else {
          GradeNetworking.get("https://istudent.d303.org/HomeAccess/Content/Student/Assignments.aspx") { response in
               guard let utf8Text = response else {
                    error(.network)
                    return
               }
               TSKit.main.logWebActivity(url: "https://istudent.d303.org/HomeAccess/Content/Student/Assignments.aspx", params: nil, response: utf8Text)

               guard let doc = try? HTML(html: utf8Text, encoding: .utf8) else {
                   error(.application)
                   return
               }
               if(utf8Text.lowercased().contains("login")) {
                   error(.relogin)
                   return
               }
               guard let eventValidation = doc.css("#__EVENTVALIDATION").first?["value"], let viewState = doc.css("#__VIEWSTATE").first?["value"] else {
                   error(.application)
                   return
               }
               success(eventValidation,viewState)
               lastValidation = eventValidation
               lastViewState = viewState
            }
        }
    }
    
    func scrapeParentlinkToken(account : Account, success: @escaping (_ token: String) -> (), error: @escaping (_ error: GradeError) -> ()) {
        let user = account.username
        let password = account.password

        let credentialData = "\(user):\(password)".data(using: String.Encoding.utf8)!
        let base64Credentials = credentialData.base64EncodedString()
        let headers = ["Authorization": "Basic \(base64Credentials)"]
     GradeNetworking.getJSON("https://d303.parentlink.net/api/v1/user?appName=D303&appVersion=Version%3A%205.0.300%20%281950001%29&build=1950001&token=1", headers: headers) { json, status, err in
          if(err != nil) {
               error(.network)
          } else if(status == 401) {
               error(.relogin)
          } else if let response = json {
               self.parentLinkUserID = response.object(forKey: "accountID") as! Int
               self.parentLinkToken = response.object(forKey: "token") as! String
               success(self.parentLinkToken)
          } else {
               error(.application)
          }
     }
    }
    
    func scrapeParentlink(success: @escaping (_ data: NSDictionary) -> (), error: @escaping (_ error: GradeError) -> ()) {
        if(parentLinkToken != "") {
            let headers = ["AUTH_TOKEN": parentLinkToken]
          GradeNetworking.getJSON("https://d303.parentlink.net/api/v1/accounts/\(parentLinkUserID)", headers: headers) { json, status, err in
               if(err != nil) {
                    error(.network)
               } else if(status == 401) {
                    error(.relogin)
               } else if let response = json {
                    success(response)
               } else {
                    error(.application)
               }
          }
        } else {
            error(.relogin)
        }
    }
    
     func scrapeClasses(success: @escaping (_ response: String) -> (), error: @escaping (_ error: GradeError) -> ()) {
          GradeNetworking.get("https://istudent.d303.org/HomeAccess/Content/Student/Assignments.aspx") { response in
               guard let utf8Text = response else {
                    error(.network)
                    return
               }
               TSKit.main.logWebActivity(url: "https://istudent.d303.org/HomeAccess/Content/Student/Assignments.aspx", params: nil, response: utf8Text)
               
               if let doc = try? HTML(html: utf8Text, encoding: .utf8) {
                    if(doc.css("#plnMain_ddlMarkingPeriods").first != nil) {
                         GradeNetworking.get("https://istudent.d303.org/HomeAccess/Content/Student/Assignments.aspx") { response in
                              guard let resp = response else {
                                   error(.network)
                                   return
                              }
                              TSKit.main.logWebActivity(url: "https://istudent.d303.org/HomeAccess/Content/Student/Assignments.aspx", params: nil, response: resp)
                              
                              if let doc2 = try? HTML(html: resp, encoding: .utf8), let validation = doc2.css("#__EVENTVALIDATION").first?["value"], let viewState = doc2.css("#__VIEWSTATE").first?["value"] {
                                   lastValidation = validation
                                   lastViewState = viewState
                              }
                         }
                    } else {
                         if let first = doc.css("#plnMain_ddlReportCardRuns").first {
                              for var node in first.css("option") {
                                   if(node["selected"]=="selected") {
                                        switch(node["value"]!) {
                                        case "ALL":
                                             runs = "ALL"
                                             break;
                                        default:
                                             runs = node["value"]!
                                             if(node["value"]=="1" || node["value"]=="2") {
                                                  semester = 1
                                             } else {
                                                  semester = 2
                                             }
                                        }
                                        DispatchQueue.main.async {
                                             if((semester == 1 && (runs == "1" || runs=="2")) || (semester == 2 && (runs == "3" || runs=="4"))) {
                                                  mainViewController.runsLabel.setTitle("QUARTER \(runs)", for: .normal)
                                             } else {
                                                  mainViewController.runsLabel.setTitle("SEMESTER \(semester)", for: .normal)
                                             }
                                        }
                                        
                                   }
                              }
                              
                         }
                         success(utf8Text)
                         if let validation = doc.css("#__EVENTVALIDATION").first?["value"], let viewState = doc.css("#__VIEWSTATE").first?["value"] {
                              lastValidation = validation
                              lastViewState = viewState
                         }
                         
                    }
                    
               } else {
                    error(.application)
               }
          }
     }
    
    func scrapeClasses(runs : String, success: @escaping (_ response: String) -> (), error: @escaping (_ error: GradeError) -> ()) {
        preLoginCheck(success: { EVENTVALIDATION, VIEWSTATE in
            var parameters: Parameters
            parameters = [
                "__EVENTARGUMENT":"",
                "__EVENTTARGET" : "ctl00$plnMain$btnRefreshView",
                "__EVENTVALIDATION" : EVENTVALIDATION,
                "__VIEWSTATE" : VIEWSTATE,
                "ctl00$plnMain$ddlClasses" : "ALL",
                "ctl00$plnMain$ddlReportCardRuns": runs
            ]
          GradeNetworking.post("https://istudent.d303.org/HomeAccess/Content/Student/Assignments.aspx", parameters: parameters, completion: { response in

               guard let resp = response else {
                    error(.network)
                    return
               }
               TSKit.main.logWebActivity(url:"https://istudent.d303.org/HomeAccess/Content/Student/Assignments.aspx", params: GradeNetworking.query(parameters), response: resp)
               
                    if let doc = try? HTML(html: resp, encoding: .utf8) {
                         if(doc.css("#plnMain_ddlMarkingPeriods").first != nil) {
                              GradeNetworking.get("https://istudent.d303.org/HomeAccess/Content/Student/Assignments.aspx") { response in
                                   guard let utf8Text2 = response else {
                                        error(.network)
                                        return
                                   }
                                   TSKit.main.logWebActivity(url:"https://istudent.d303.org/HomeAccess/Content/Student/Assignments.aspx", params: nil, response: utf8Text2)
                                   
                                   success(utf8Text2)
                                   if let doc2 = try? HTML(html: utf8Text2, encoding: .utf8), let validation = doc2.css("#__EVENTVALIDATION").first?["value"], let viewState = doc2.css("#__VIEWSTATE").first?["value"] {
                                        lastValidation = validation
                                        lastViewState = viewState
                                   }
                              }
                         } else {
                              success(response!)
                              if let validation = doc.css("#__EVENTVALIDATION").first?["value"], let viewState = doc.css("#__VIEWSTATE").first?["value"] {
                                   lastValidation = validation
                                   lastViewState = viewState
                              }
                         }
                         
                    } else {
                         error(.application)
                    }
          })
        }, error: {
            gradeError in
            error(gradeError)
        })
    }
    
    func scrapeCourseInfo(courseId : Int, success: @escaping (_ response: String) -> (), error: @escaping (_ error: GradeError) -> ()) {
        scrape("https://istudent.d303.org/HomeAccess/Content/Student/ClassPopUp.aspx?section_key=\(courseId)", success, error)
    }
    func scrapeSchedule(success: @escaping (_ response: String) -> (), error: @escaping (_ error: GradeError) -> ()) {
        scrape("https://istudent.d303.org/HomeAccess/Content/Student/Classes.aspx", success, error)
    }
    func scrapeStudentInfo(success: @escaping (_ response: String) -> (), error: @escaping (_ error: GradeError) -> ()) {
        scrape("https://istudent.d303.org/HomeAccess/Content/Student/Registration.aspx", success, error)
    }
    
    func scrapeTranscript(success: @escaping (_ response: String) -> (), error: @escaping (_ error: GradeError) -> ()) {
        scrape("https://istudent.d303.org/HomeAccess/Content/Student/Transcript.aspx", success, error)
    }
    
    public func scrapePicker(success: @escaping (_ response: String) -> (), error: @escaping (_ error: GradeError) -> ()) {
        scrape("https://istudent.d303.org/HomeAccess/Frame/StudentPicker", success, error)
    }
    public func setStudent(id : Int, success: @escaping() -> (), error: @escaping (_ error: GradeError) -> ()) {
     let parameters: Parameters = [
          "studentId": id,
          "url" : "/HomeAccess/Registration/Demographic"
     ]
     GradeNetworking.post("https://istudent.d303.org/HomeAccess/Frame/StudentPicker", parameters: parameters) { response in
          if(response == nil) {
               error(.network)
          } else {
               TSKit.main.logWebActivity(url: "https://istudent.d303.org/HomeAccess/Frame/StudentPicker", params: GradeNetworking.query(parameters), response: response!)
               
               success()
          }
     }
    }
     public func firstAttendanceEvent(success: @escaping (_ response: String) -> (), error: @escaping (_ error: GradeError) -> ()) {
          scrape("https://istudent.d303.org/HomeAccess/Content/Attendance/MonthlyView.aspx", success, error)
     }
     
     func scrapeAttendance(id : String, ev: String, vs : String, success: @escaping (_ response: String) -> (), error: @escaping (_ error: GradeError) -> ()) {
          var parameters: Parameters
          parameters = [
               "__EVENTARGUMENT":id,
               "__EVENTTARGET" : "ctl00$plnMain$cldAttendance",
               "__EVENTVALIDATION" : ev,
               "__VIEWSTATE" : vs
          ]
          GradeNetworking.post("https://istudent.d303.org/HomeAccess/Content/Attendance/MonthlyView.aspx", parameters: parameters, completion: { response in
               guard let utf8Text = response else {
                    error(.network)
                    return
               }
               
               TSKit.main.logWebActivity(url:"https://istudent.d303.org/HomeAccess/Content/Attendance/MonthlyView.aspx", params: GradeNetworking.query(parameters), response: utf8Text)
               
               success(utf8Text)
          })
     }
     
    private func scrape(_ url: String, _ success: @escaping (_ response: String) -> (), _ error: @escaping (_ error: GradeError) -> ()) {

          GradeNetworking.get(url) { response in
               guard let utf8Text = response else {
                    error(.network)
                    return
               }
               TSKit.main.logWebActivity(url: url, params: nil, response: utf8Text)
               
               success(utf8Text)
          }
    }
     public func logout() {
          login.logout()
          parentLinkToken = ""
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
