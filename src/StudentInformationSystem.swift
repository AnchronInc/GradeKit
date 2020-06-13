//
//  StudentInformationSystem.swift
//  SimpleGrades
//
//  Created by Michael on 9/9/18.
//  Copyright © 2018 Anchron Inc. All rights reserved.
//

import Foundation
import Wrap
import Unbox

var colorDefaults = ["mathematics" : "red", "science": "green", "english": "blue", "social studies" : "yellow", "wellness" : "darkpurple", "music" : "pink", "foreign language": "orange", "lunch/study/unscheduled" : "gray", "other" : "purple"]

public struct Account {
     let username: String
     let password: String
}

public struct Course {
     var name : String
     var teacher : String
     var grade : Double
     var gradeString : String
     var period : Int
     var periodString : String
     var subject : String
     var qs : String
     var courseId : Int
     var assignments: [Assignment]
     var categories: [Category]
     var dropped : Bool
}
extension Course: Unboxable {
     public init(unboxer: Unboxer) throws {
          self.name = try unboxer.unbox(key: "name")
          self.teacher = try unboxer.unbox(key: "teacher")
          self.grade = try unboxer.unbox(key: "grade")
          self.gradeString = try unboxer.unbox(key: "gradeString")
          self.period = try unboxer.unbox(key: "period")
          self.periodString = try unboxer.unbox(key: "periodString")
          self.subject = try unboxer.unbox(key: "subject")
          self.qs = try unboxer.unbox(key: "qs")
          self.courseId = try unboxer.unbox(key: "courseId")
          self.assignments = try unboxer.unbox(key: "assignments")
          self.categories = try unboxer.unbox(key: "categories")
          self.dropped = try unboxer.unbox(key: "dropped")
     }
}

public struct ScheduleCourse : Comparable {
     var name : String
     var teacher : String
     var period : Double
     var periodString : String
     var qs : String
     var courseId : String
     var room : String
     var subject : String
     
     var unabridgedName : String
     var days : String?

     public static func == (lhs: ScheduleCourse, rhs: ScheduleCourse) -> Bool {
          return
               lhs.name == rhs.name &&
                    lhs.teacher == rhs.teacher &&
                    lhs.period == rhs.period &&
                    lhs.periodString == rhs.periodString &&
                    lhs.qs == rhs.qs &&
                    lhs.courseId == rhs.courseId &&
                    lhs.room == rhs.room && lhs.subject == rhs.subject
     }
     public static func > (lhs: ScheduleCourse, rhs: ScheduleCourse) -> Bool {
          return lhs.period > rhs.period;
     }
     public static func < (lhs: ScheduleCourse, rhs: ScheduleCourse) -> Bool {
          return lhs.period < rhs.period;
     }
     
}
extension ScheduleCourse: Unboxable {
     public init(unboxer: Unboxer) throws {
          self.name = try unboxer.unbox(key: "name")
          self.teacher = try unboxer.unbox(key: "teacher")
          self.period = try unboxer.unbox(key: "period")
          self.periodString = try unboxer.unbox(key: "periodString")
          self.qs = try unboxer.unbox(key: "qs")
          self.courseId = try unboxer.unbox(key: "courseId")
          self.room = try unboxer.unbox(key: "room")
          self.subject = try unboxer.unbox(key: "subject")
          self.unabridgedName = try unboxer.unbox(key: "unabridgedName")
          self.days = try unboxer.unbox(key: "days")
     }
}
public struct Assignment : Comparable {
     var name : String
     var date : String
     var score : Double?
     var total : Double?
     var category : String
     var avg : Double?
     var weight : Double?
     
     public static func == (lhs: Assignment, rhs: Assignment) -> Bool {
          return
               lhs.name == rhs.name &&
                    lhs.score == rhs.score &&
                    lhs.total == rhs.total &&
                    lhs.category == rhs.category &&
                    lhs.weight == rhs.weight
     }
     public static func > (lhs: Assignment, rhs: Assignment) -> Bool {
          return lhs.name > rhs.name;
     }
     public static func < (lhs: Assignment, rhs: Assignment) -> Bool {
          return lhs.name < rhs.name;
     }
}
extension Assignment: Unboxable {
     public init(unboxer: Unboxer) throws {
          self.name = try unboxer.unbox(key: "name")
          self.date = try unboxer.unbox(key: "date")
          self.score = try? unboxer.unbox(key: "score")
          self.total = try? unboxer.unbox(key: "total")
          self.category = try unboxer.unbox(key: "category")
          self.avg = try? unboxer.unbox(key: "avg")
          self.weight = try? unboxer.unbox(key : "weight")
     }
}

public struct Category {
     var name : String
     var score : Double?
     var total : Double?
     var weight : Double?
     var weightedScore : Double?
}
extension Category: Unboxable {
     public init(unboxer: Unboxer) throws {
          self.name = try unboxer.unbox(key: "name")
          self.score = try? unboxer.unbox(key: "score")
          self.total  = try? unboxer.unbox(key: "total")
          self.weight = try? unboxer.unbox(key: "weight")
          self.weightedScore = try? unboxer.unbox(key: "weightedScore")
     }
}
public struct Student {
     var name : String
     var bday : String
     var counselerName : String
     var school : String
     var gender : String
     var grade : Int
     var additionalInfo : [String : String]?
     var bigInfo : [String : (String, String)]?
}
extension Student: Unboxable {
     public init(unboxer: Unboxer) throws {
          self.name = try unboxer.unbox(key: "name")
          self.bday = try unboxer.unbox(key: "bday")
          self.counselerName = try unboxer.unbox(key: "counselerName")
          self.school = try unboxer.unbox(key: "school")
          self.gender = try unboxer.unbox(key: "gender")
          self.grade = try unboxer.unbox(key: "grade")
          self.additionalInfo = try unboxer.unbox(key: "homeroom")
          
     }
}
public struct DataStore {
     var courses : [Course]
     var student: Student?
     var schedule : [ScheduleCourse]
}
extension DataStore: Unboxable {
     public init(unboxer: Unboxer) throws {
          self.courses = try unboxer.unbox(key: "courses")
          self.student = try? unboxer.unbox(key: "student")
          self.schedule = try unboxer.unbox(key: "schedule")
     }
}
public struct AttendanceDate {
     var date : Date
     var items : [AttendanceItem]
}
public struct AttendanceItem {
     var category : String
     var period : Double
     var periodString : String
}
public struct Transcript {
     var wgpa : Double?
     var uwgpa : Double?
     var years : [TSYear]
}
public struct TSYear {
     var year : String
     var grade : String
     var courses : [TSCourse]
}
public struct TSCourse {
     var name : String
     var s1 : String?
     var s2 : String?
}

public protocol StudentInformationSystem {
     func attemptKeychainLogin(success: @escaping () -> (), error: @escaping (_ error : GradeError) -> ())
     
     func attemptLogin(account : Account, success: @escaping () -> (), error: @escaping (_ error: GradeError) -> ())
     
     func getCourses(success: @escaping (_ classes: [Course]) -> (), error: @escaping (_ error: GradeError) -> ())
     
     func fetchAttachments(courseId : Int, success: @escaping (_ urls: [String : String]) -> (), error: @escaping (_ error: GradeError) -> ())
     
     func getCourses(runs: String, success: @escaping (_ classes: [Course]) -> (), error: @escaping (_ error: GradeError) -> ())
     
     func getSchedule(success: @escaping (_ courses: [ScheduleCourse], _ title : String) -> (), error: @escaping (_ error: GradeError) -> ())
     
     func getPlainSchedule(success: @escaping (_ courses: [ScheduleCourse]) -> (), error: @escaping (_ error: GradeError) -> ())

     func getStudentInfo(success: @escaping (_ student: Student) -> (), error: @escaping (_ error: GradeError) -> ())
     
     func getStudentsFromPicker(success: @escaping (_ students : [Int:String]) -> (), error: @escaping (_ error: GradeError) -> ())
     
     func setStudent(id: Int, success: @escaping () -> (), error: @escaping (_ error: GradeError) -> ())
     
     func getAttendanceEvents(update: @escaping (_ events : [AttendanceDate]) -> (), completion: @escaping () -> (), error: @escaping (_ error: GradeError) -> ())
     
     func getTranscript(success: @escaping (_ ts : Transcript) -> (), error: @escaping (_ error: GradeError) -> ())
     
     func isLoggedIn() -> Bool
     
     func logout()
     
     func getFullAccount() -> Account?
     
     func color(fromCourse course : Course, frame : CGRect) -> UIColor
     func color(fromCourse course : ScheduleCourse, frame : CGRect) -> UIColor

     @available(*, deprecated)
     func stuffIsTemporarilyDisabled() -> Bool
}
