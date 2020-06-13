//
//  Genesis.swift
//  SimpleGrades
//
//  Created by Michael on 9/9/18.
//  Copyright © 2018 Anchron Inc. All rights reserved.
//

import Foundation
import UIKit

public class Genesis : StudentInformationSystem {
     public func stuffIsTemporarilyDisabled() -> Bool {
          return true
     }

     private var scraper = GenesisScraper()
     private var parser = GenesisParser();

     private var haQCompletion : [() -> ()] = []
     private var negatoryHAQCompletion : [(GradeError) -> ()] = []
     public func attemptKeychainLogin(success: @escaping () -> (), error: @escaping (_ error : GradeError) -> ()) {
          scraper.attemptKeychainLogin(success: {
               self.loadEvent()
               success()
          }, error: { err in
               for haQComp in self.negatoryHAQCompletion {
                    haQComp(err)
               }
               error(err)
          })
     }
     public func attemptLogin(account : Account, success: @escaping () -> (), error: @escaping (_ error: GradeError) -> ()) {
          scraper.attemptLogin(account: account, success: {
               self.loadEvent()
               success()
          }, error: error)
     }
     public func loadEvent() {
          for haQComp in self.haQCompletion {
               haQComp()
          }
     }
     public func onLoad(_ eventHandler : @escaping () -> ()) {
          haQCompletion.append(eventHandler)
     }
     public func onFail(_ eventHandler : @escaping (GradeError) -> ()) {
          negatoryHAQCompletion.append(eventHandler)
     }

     public func getCourses(success: @escaping (_ classes: [Course]) -> (), error: @escaping (_ error: GradeError) -> ())
     {
          getCourses(runs: runs, success: success, error: error)
     }

     public func fetchAttachments(courseId : Int, success: @escaping (_ urls: [String : String]) -> (), error: @escaping (_ error: GradeError) -> ())
     {
          success([:])
     }

     public func getCourses(runs: String, success: @escaping (_ classes: [Course]) -> (), error: @escaping (_ error: GradeError) -> ())
     {
          login({success(demoCourses)}, {
               self.scraper.scrapeClasses(success: {
                    response, overview in
                    self.getPlainSchedule(success: { (schedule) in
                         self.parser.parseClasses(response: response, overview : overview, schedule: schedule, success: success, error: {
                              gradeError in
                              if(gradeError == .relogin) {
                                   self.attemptKeychainLogin(success: {
                                        self.getCourses(success: success, error: error)
                                   }, error: { keychainloginError in
                                        error(keychainloginError == .network ? .network : .relogin)
                                   })
                              } else {
                                   error(gradeError)
                              }
                         })
                    }, error: error)

               }, error: {
                    gradeError in
                    if(gradeError == .relogin) {
                         self.attemptKeychainLogin(success: {
                              self.getCourses(success: success, error: error)
                         }, error: { keychainloginError in
                              error(keychainloginError == .network ? .network : .relogin)
                         })
                    } else {
                         error(gradeError)
                    }
               })

          }, error)
     }
     public func getPlainSchedule(success: @escaping (_ courses: [ScheduleCourse]) -> (), error: @escaping (_ error: GradeError) -> ())
     {
          //.listrowselected = current class
          login({
               success(demoSchedule)
          },{
               self.scraper.scrapeSchedule(success: {
                    response in
                    self.parser.parseSchedule(response: response, success: { schedule, title in
                         success(schedule)
                    }, useBlock: false, error: {
                         gradeError in
                         if(gradeError == .relogin) {
                              self.attemptKeychainLogin(success: {
                                   self.getPlainSchedule(success: success, error: error)
                              }, error: { keychainloginError in
                                   error(keychainloginError == .network ? .network : .relogin)
                              })
                         } else {
                              error(gradeError)
                         }
                    })
               }, error: {
                    gradeError in
                    if(gradeError == .relogin) {
                         self.attemptKeychainLogin(success: {
                              self.getPlainSchedule(success: success, error: error)
                         }, error: { keychainloginError in
                              error(keychainloginError == .network ? .network : .relogin)
                         })
                    } else {
                         error(gradeError)
                    }
               })
          }, error)
     }
     public func getSchedule(success: @escaping (_ courses: [ScheduleCourse], _ title : String) -> (), error: @escaping (_ error: GradeError) -> ())
     {
          //.listrowselected = current class
          login({
               success(demoSchedule, "Schedule")
          },{
               self.scraper.scrapeSchedule(success: {
                    response in
                    self.parser.parseSchedule(response: response, success: success, useBlock: true, error: {
                         gradeError in
                         if(gradeError == .relogin) {
                              self.attemptKeychainLogin(success: {
                                   self.getSchedule(success: success, error: error)
                              }, error: { keychainloginError in
                                   error(keychainloginError == .network ? .network : .relogin)
                              })
                         } else {
                              error(gradeError)
                         }
                    })
               }, error: {
                    gradeError in
                    if(gradeError == .relogin) {
                         self.attemptKeychainLogin(success: {
                              self.getSchedule(success: success, error: error)
                         }, error: { keychainloginError in
                              error(keychainloginError == .network ? .network : .relogin)
                         })
                    } else {
                         error(gradeError)
                    }
               })
          }, error)
     }

     public func getStudentInfo(success: @escaping (_ student: Student) -> (), error: @escaping (_ error: GradeError) -> ())
     {
          login({
               success(Student(name: "John Appleseed", bday: "1/20/81",counselerName:"Eric Widget",school:"Anchron University",gender:"Male",grade:10, additionalInfo: nil, bigInfo: nil))
          }, {
               self.scraper.scrapeStudentInfo(success: {
                    response in
                    do {
                         let student = try self.parser.parseStudentInfo(response: response)
                         success(student)
                    }
                    catch let gradeError as GradeError {
                         error(gradeError)
                    }
                    catch _ {
                         error(.application)
                    }
               }, error: {
                    gradeError in
                    if(gradeError == .relogin) {
                         self.attemptKeychainLogin(success: {
                              self.getStudentInfo(success: success, error: error)
                         }, error: { keychainloginError in
                              error(keychainloginError == .network ? .network : .relogin)
                         })
                    } else {
                         error(gradeError)
                    }
               })
          }, error)
     }

     public func getStudentsFromPicker(success: @escaping (_ students : [Int:String]) -> (), error: @escaping (_ error: GradeError) -> ())
     {
          login({
               self.scraper.scrapePicker(success: { (response) in
                    do {
                         let students = try self.parser.parseStudentPicker(response: response)
                         success(students)
                    }
                    catch let gradeError as GradeError {
                         error(gradeError)
                    }
                    catch _ {
                         error(.application)
                    }
               }, error: { (gradeError) in
                    if(gradeError == .relogin) {
                         self.attemptKeychainLogin(success: {
                              self.getStudentsFromPicker(success: success, error: error)
                         }, error: { keychainloginError in
                              error(keychainloginError == .network ? .network : .relogin)
                         })
                    } else {
                         error(gradeError)
                    }
               })

          }, error)
     }

     public func setStudent(id: Int, success: @escaping () -> (), error: @escaping (_ error: GradeError) -> ())
     {
          self.scraper.setStudent(id: id, success: success, error: error)
     }

     func attendanceSuccess(response: String, update: @escaping (_ events : [AttendanceDate]) -> (), completion: @escaping () -> (), error: @escaping (_ error: GradeError) -> (), num : Int = 0) {
          /*self.parser.parseAttendance(response: response, success: { (events, next, ev, vs) in
               update(events)
               if let nextID = next, num <= 12 {
                    self.scraper.scrapeAttendance(id: nextID, ev: ev, vs: vs, success: { (response) in
                         self.attendanceSuccess(response: response, update: update, completion: completion, error: error, num: num + 1)
                    }, error: { (gradeError) in
                         error(gradeError)
                    })
               } else {
                    completion()
               }
          }, error: { (gradeError) in
               error(gradeError) //avoid infinite recursion or same data getting sent twice
          })*/
     }
     public func getAttendanceEvents(update: @escaping (_ events : [AttendanceDate]) -> (), completion: @escaping () -> (), error: @escaping (_ error: GradeError) -> ()) {
     }

     public func getTranscript(success: @escaping (_ ts : Transcript) -> (), error: @escaping (_ error: GradeError) -> ())
     {

     }

     public func isLoggedIn() -> Bool
     {
          return scraper.isLoggedIn()
     }

     public func logout()
     {
          scraper.logout()
     }

     public func getFullAccount() -> Account?
     {
          return scraper.getFullAccount()
     }

     private func login(_ demo: @escaping () -> (), _ success: @escaping () -> (), _ error: @escaping (_ error: GradeError) -> ()) {
          if(scraper.isLoggedIn()) {
               if(scraper.isUsingDemo()) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                         demo()
                    }
                    return
               }
               success()
          } else {
               self.attemptKeychainLogin(success: {
                    success()
               }, error: { keychainloginError in
                    if(keychainloginError != .network) {
                         error(keychainloginError == .network ? .network : .relogin)
                    }
                    else {
                         error(.network)
                    }
               })
          }
     }
     private func login(_ success: @escaping () -> (), _ error: @escaping (_ error: GradeError) -> ()) {
          if(isLoggedIn() == true) {
               if(scraper.isUsingDemo() == true) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                         error(.demo)
                    }
                    return
               }
               success()
          } else {
               self.attemptKeychainLogin(success: {
                    success()
               }, error: { keychainloginError in
                    error(keychainloginError == .network ? .network : .relogin)
               })
          }
     }

/*var colorDefaults = ["mathematics" : "red", "science": "green", "english": "blue", "social studies" : "yellow", "wellness" : "darkpurple", "music" : "pink", "foreign language": "orange", "lunch/study/unscheduled" : "gray", "other" : "purple"]*/
     public func color(fromCourse course : ScheduleCourse, frame : CGRect) -> UIColor {
          let newCourse = Course(name: course.name, teacher: course.teacher, grade: -1, gradeString: "N/A", period: -1, periodString: course.periodString, subject: course.subject, qs:course.qs, courseId: -1, assignments: [Assignment](), categories: [Category](), dropped: false)

          return color(fromCourse: newCourse, frame: frame)
     }

     public func color(fromCourse course : Course, frame : CGRect) -> UIColor {
          let courseName = course.name.lowercased()
          var name = ""
          if(courseName.grp_contains("theory", "music", "band", "orchestra", "ensemble", "jazz", "wind", "guitar","piano", "choir", "lesson")) {
               name = "music"
          }
          if(courseName.grp_contains("math", "calc", "algebra", "geometry", "statistics", "variable", "computer", "coding", "software")) {
               name = "mathematics"
          }
          if(courseName.grp_contains("lab", "science", "environmental", "physics", "chem", "bio", "meteorology", "ecology", "astronomy", "body systems", "medical")) {
               name = "science"
          }
          if(courseName.grp_contains("history", "euro", "philosophy", "psychology", "sociology", "geography", "econ", "gov", "issue")) {
               name = "social studies"
          }
          if(courseName.grp_contains("health", "physical ed")) {
               name = "wellness"
          }
          if(courseName.grp_contains("lang", "english", "writing", "literature", "fiction", "page", "seminar", "research")) {
               name = "english"
          }
          if(courseName.grp_contains("cultures", "spanish", "russian", "german", "french")) {
               name = "foreign language"
          }

          if let color = UserDefaults.standard.value(forKey: "cl-\(name.lowercased())") as? String {
               return(gradientColor(fromName: color, frame: frame))
          }
          else {
               if let defaultColor = colorDefaults[name.lowercased()] {
                    UserDefaults.standard.setValue(defaultColor, forKey: "cl-\(name.lowercased())")
                    return(gradientColor(fromName: defaultColor, frame: frame))
               }
               else if let color = UserDefaults.standard.value(forKey: "cl-other") as? String {
                    return(gradientColor(fromName: color, frame: frame))
               }
               else if let defaultColor = colorDefaults["other"] {
                    UserDefaults.standard.setValue(defaultColor, forKey: "cl-other")
                    return(gradientColor(fromName: defaultColor, frame: frame))
               }
               else {
                    return(gradientColor(fromName: "purple", frame: frame))
               }
          }
     }
}
 extension String {
     func grp_contains(_ items : String... ) -> Bool {
          for item in items {
               if(self.contains(item)) {
                    return true
               }
          }
          return false
     }
}
