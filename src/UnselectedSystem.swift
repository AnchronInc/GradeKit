//
//  UnselectedSystem.swift
//  SimpleGrades
//
//  Created by Michael on 12/7/18.
//  Copyright © 2018 Anchron Inc. All rights reserved.
//

import Foundation
import UIKit

public class UnselectedSystem : StudentInformationSystem {
     public func stuffIsTemporarilyDisabled() -> Bool {
          return true
     }
     public func attemptKeychainLogin(success: @escaping () -> (), error: @escaping (_ error : GradeError) -> ()) {
          error(.relogin)
     }
     
     public func attemptLogin(account : Account, success: @escaping () -> (), error: @escaping (_ error: GradeError) -> ()) {
          error(.relogin)
     }
     
     public func getCourses(success: @escaping (_ classes: [Course]) -> (), error: @escaping (_ error: GradeError) -> ()) {
          error(.relogin)
     }
     
     public func fetchAttachments(courseId : Int, success: @escaping (_ urls: [String : String]) -> (), error: @escaping (_ error: GradeError) -> ()) {
          error(.relogin)
     }
     
     public func getCourses(runs: String, success: @escaping (_ classes: [Course]) -> (), error: @escaping (_ error: GradeError) -> ()) {
          error(.relogin)
     }
     
     public func getSchedule(success: @escaping (_ courses: [ScheduleCourse], _ title : String) -> (), error: @escaping (_ error: GradeError) -> ())  {
          error(.relogin)
     }
     
     public func getPlainSchedule(success: @escaping (_ courses: [ScheduleCourse]) -> (), error: @escaping (_ error: GradeError) -> ()) {
          error(.relogin)
     }
     
     public func getStudentInfo(success: @escaping (_ student: Student) -> (), error: @escaping (_ error: GradeError) -> ()) {
          error(.relogin)
     }
     
     public func getStudentsFromPicker(success: @escaping (_ students : [Int:String]) -> (), error: @escaping (_ error: GradeError) -> ()) {
          error(.relogin)
     }
     
     public func setStudent(id: Int, success: @escaping () -> (), error: @escaping (_ error: GradeError) -> ())  {
          error(.relogin)
     }
     
     public func getAttendanceEvents(update: @escaping (_ events : [AttendanceDate]) -> (), completion: @escaping () -> (), error: @escaping (_ error: GradeError) -> ()) {
          error(.relogin)
     }
     
     public func getTranscript(success: @escaping (_ ts : Transcript) -> (), error: @escaping (_ error: GradeError) -> ()) {
          error(.relogin)
     }
     
     public func isLoggedIn() -> Bool {
          return false
     }
     
     public func logout() { }
     
     public func getFullAccount() -> Account? {
          return nil
     }
     
     public func color(fromCourse course : Course, frame : CGRect) -> UIColor {
          return gradientColor(fromName: "other", frame: frame)
     }
     public func color(fromCourse course : ScheduleCourse, frame : CGRect) -> UIColor {
          return gradientColor(fromName: "other", frame: frame)
     }
     
}
