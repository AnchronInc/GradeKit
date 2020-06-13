//
//  HomeAccessQuery.swift
//  SimpleGrades
//
//  Created by Michael Caruso on 1/12/17.
//  Copyright © 2017 Anchron Inc. All rights reserved.
//

import Foundation
import UIKit

public class HomeAccessCenter : StudentInformationSystem {
     public func stuffIsTemporarilyDisabled() -> Bool {
          return false
     }
     
     private var scraper = Scraper()
     var parser = Parser();
     var lastRun : String = ""

     public func attemptKeychainLogin(success: @escaping () -> (), error: @escaping (_ error : GradeError) -> ()) {
          scraper.attemptKeychainLogin(success: {
               GradeKit.loadEvent()
               success()
          }, error: { err in
               GradeKit.negatoryLoadEvent(err: err)
               error(err)
          })
     }
     public func attemptLogin(account : Account, success: @escaping () -> (), error: @escaping (_ error: GradeError) -> ()) {
          scraper.attemptLogin(account: account, success: {
               GradeKit.loadEvent()
               success()
          }, error: error)
     }

     public func getCourses(success: @escaping (_ classes: [Course]) -> (), error: @escaping (_ error: GradeError) -> ()) {
          login({success(demoCourses)}, {
               self.scraper.scrapeClasses(success: {
                    response in
                    self.parseClasses(response: response, success: success, error: {
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
     public func fetchAttachments(courseId : Int, success: @escaping (_ urls: [String : String]) -> (), error: @escaping (_ error: GradeError) -> ()) {
          login({ success([:]) },
                {
                    self.scraper.scrapeCourseInfo(courseId: courseId, success: {
                         response in
                         do {
                              try success(self.parser.fetchAttachments(response: response))
                         } catch(_) {
                              error(.application)
                         }
                    }, error: {
                         gradeError in
                         if(gradeError == .relogin) {
                              self.attemptKeychainLogin(success: {
                                   self.fetchAttachments(courseId: courseId, success: success, error: error)
                              }, error: { keychainloginError in
                                   error(keychainloginError == .network ? .network : .relogin)
                              })
                         } else {
                              error(gradeError)
                         }
                    })
          }, error)
     }
     public func getCourses(runs: String, success: @escaping (_ classes: [Course]) -> (), error: @escaping (_ error: GradeError) -> ()) {
          if(runs == self.lastRun) {
               getCourses(success: success, error: error)
          } else {
               login({
                    success(demoCourses)
               }, {
                    self.scraper.scrapeClasses(runs: runs, success: {
                         response in
                         self.parseClasses(response: response, success: success, error: {
                              gradeError in
                              if(gradeError == .relogin) {
                                   self.attemptKeychainLogin(success: {
                                        self.getCourses(runs: runs, success: success, error: error)
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
                                   self.getCourses(runs: runs, success: success, error: error)
                              }, error: { keychainloginError in
                                   error(keychainloginError == .network ? .network : .relogin)
                              })
                         } else {
                              error(gradeError)
                         }
                    })
               }, error)
          }
     }

     private func parseClasses(response : String, success: @escaping (_ classes: [Course]) -> (), error: @escaping (_ error: GradeError) -> ()) {
          self.parser.parseClasses(response: response, scraper: self.scraper, success: success, error: error)
     }
     private func parseSchedule(response : String, success: @escaping (_ classes: [ScheduleCourse]) -> (), error: @escaping (_ error: GradeError) -> ()) {
          self.parser.parseSchedule(response: response, scraper: self.scraper, success: success, error: error)
     }
     public func getPlainSchedule(success: @escaping (_ courses: [ScheduleCourse]) -> (), error: @escaping (_ error: GradeError) -> ()) {
          login({
               success(demoSchedule)
          },{
               self.scraper.scrapeSchedule(success: {
                    response in
                    self.parseSchedule(response: response, success: { schedule in
                         success(schedule)
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
     public func getSchedule(success: @escaping (_ courses: [ScheduleCourse], _ title : String) -> (), error: @escaping (_ error: GradeError) -> ()) {
          login({
               success(demoSchedule, "Schedule")
          },{
               self.scraper.scrapeSchedule(success: {
                    response in
                    self.parseSchedule(response: response, success: { schedule in
                         success(schedule, "Schedule")
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
     public func getStudentInfo(success: @escaping (_ student: Student) -> (), error: @escaping (_ error: GradeError) -> ()) {
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
     public func getStudentsFromPicker(success: @escaping (_ students : [Int:String]) -> (), error: @escaping (_ error: GradeError) -> ()) {
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
     public func setStudent(id: Int, success: @escaping () -> (), error: @escaping (_ error: GradeError) -> ()) {
          login({
               self.scraper.setStudent(id: id, success: success, error: { (gradeError) in
                    if(gradeError == .relogin) {
                         self.attemptKeychainLogin(success: {
                              self.setStudent(id: id, success: success, error: error)
                         }, error: { keychainloginError in
                              error(keychainloginError == .network ? .network : .relogin)
                         })
                    } else {
                         error(gradeError)
                    }
               })
          }, error)
     }
     func attendanceSuccess(response: String, update: @escaping (_ events : [AttendanceDate]) -> (), completion: @escaping () -> (), error: @escaping (_ error: GradeError) -> (), num : Int = 0) {
          self.parser.parseAttendance(response: response, success: { (events, next, ev, vs) in
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
          })
     }
     public func getAttendanceEvents(update: @escaping (_ events : [AttendanceDate]) -> (), completion: @escaping () -> (), error: @escaping (_ error: GradeError) -> ()) {
          login({
               self.scraper.firstAttendanceEvent(success: {
                    response in
                    self.attendanceSuccess(response: response, update: update, completion: completion, error: error)
               }, error: { (gradeError) in
                    if(gradeError == .relogin) {
                         self.attemptKeychainLogin(success: {
                              self.getAttendanceEvents(update: update, completion: completion, error: error)
                         }, error: { keychainloginError in
                              error(keychainloginError == .network ? .network : .relogin)
                         })
                    } else {
                         error(gradeError)
                    }
               })
          }, error)
     }
     public func getTranscript(success: @escaping (_ ts : Transcript) -> (), error: @escaping (_ error: GradeError) -> ()) {
          login({
               self.scraper.scrapeTranscript(success: { response in
                    do {
                         try success(self.parser.parseTranscript(response: response))
                    } catch (_) {
                         error(.application)
                    }
               }, error: { (gradeError) in
                    if(gradeError == .relogin) {
                         self.attemptKeychainLogin(success: {
                              self.getTranscript(success: success, error: error)
                         }, error: { keychainloginError in
                              error(keychainloginError == .network ? .network : .relogin)
                         })
                    } else {
                         error(gradeError)
                    }
               })
          }, error)
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
     public func isLoggedIn() -> Bool {
          return scraper.isLoggedIn()
     }
     public func logout() {
          scraper.logout()
     }
     public func setParentLink(parentLinkToken : String, parentLinkUserID : Int) {
          scraper.parentLinkToken = parentLinkToken
          scraper.parentLinkUserID = parentLinkUserID
     }
     public func getParentLink() -> (String, Int) {
          return (scraper.parentLinkToken, scraper.parentLinkUserID)
     }
     public func scrapeParentlink(success: @escaping (_ data: NSDictionary) -> (), error: @escaping (_ error: GradeError) -> ()) {
          scraper.scrapeParentlink(success: success, error: error)
     }
     func scrapeParentlinkToken(account : Account, success: @escaping (_ token: String) -> (), error: @escaping (_ error: GradeError) -> ()) {
          scraper.scrapeParentlinkToken(account: account, success: success, error: error)
     }
     public func getFullAccount() -> Account? {
          return scraper.getFullAccount()
     }
     public func color(fromCourse course : ScheduleCourse, frame : CGRect) -> UIColor {
          let newCourse = Course(name: course.name, teacher: course.teacher, grade: -1, gradeString: "N/A", period: -1, periodString: course.periodString, subject: course.subject, qs:course.qs, courseId: -1, assignments: [Assignment](), categories: [Category](), dropped: false)

         return color(fromCourse: newCourse, frame: frame)
     }
     public func color(fromCourse course : Course, frame : CGRect) -> UIColor {
          let name = course.subject
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
