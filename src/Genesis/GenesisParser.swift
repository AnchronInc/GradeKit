//
//  Parser.swift
//  SimpleGrades
//
//  Created by Michael on 9/9/18.
//  Copyright © 2018 Anchron Inc. All rights reserved.
//

import Foundation
import Kanna
import ChameleonFramework
import Crashlytics
import Unbox

class GenesisParser {
     func parseClasses(response: String, overview : String, schedule : [ScheduleCourse], success: @escaping (_ classes : [Course]) -> (), error: @escaping(_ error: GradeError) -> ()) {
          if(response.lowercased().contains("parent access") || overview.lowercased().contains("parent access")) {
               error(.relogin)
               return
          }

          guard let doc = try? HTML(html: response, encoding: .utf8), let list = doc.css(".list").first, let ovDoc =  try? HTML(html: overview, encoding: .utf8), let ovList = ovDoc.css(".list").first else {
               error(.application)
               return
          }
          var courses = [Course]()
          for course in ovList.css("tr.listroweven, tr.listrowodd") {
               if(course.className == "listheading" || course.css("td").count < 3) {
                    continue;
               }
               
               guard let courseName = course.css("td.cellLeft").first?.css("u").first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                    let grade = course.css("td.cellRight").first?.css("td").first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                    error(.application)
                    return
               }
               
               var numGrade = -100.0
               var stringGrade = letterGrades(grade.substring(to: grade.count-1))
               if let gr = Double(grade.substring(to: grade.count-1)) {
                    numGrade = gr
               } else if(grade.lowercased() != "no grades"){
                    stringGrade = grade
               }
               
               
               if let sc = schedule.first(where: { (course) -> Bool in
                    return course.name == courseName && course.periodString != "A" && course.periodString != "B" && course.qs.replacingOccurrences(of: "FY", with: "1,2,3,4").replacingOccurrences(of: "S1", with: "1,2").replacingOccurrences(of: "S2", with: "3,4").contains(runs)
               }) {
                    let period = Int(sc.period)
                    let periodString = sc.periodString
                    let teacher = sc.unabridgedName
                    
                    courses.append(Course(name: courseName, teacher: teacher, grade: numGrade, gradeString: stringGrade, period: period, periodString: periodString, subject: "Other", qs: "", courseId: courseName.hashValue, assignments: [], categories: [], dropped: false))
               }
               
          }
          
          for course in list.css("tr.listroweven, tr.listrowodd") {
               if(course.className == "listheading" || course.css("td.cellLeft").count < 6) {
                    continue;
               }
               let catTD = course.css("td.cellLeft")[2]
               for child in catTD.css("*") {
                    catTD.removeChild(child)
               }
               guard let courseName = course.css("td.cellLeft")[1].css("div").first?.text?.trimmingCharacters(in: .whitespacesAndNewlines), let tN = course.css("td.cellLeft")[1].css("div")[1].text?.trimmingCharacters(in: .whitespacesAndNewlines), let assignmentName = course.css("td.cellLeft")[3].css("b").first?.text?.trimmingCharacters(in: .whitespacesAndNewlines), let date = course.css("td")[1].css("div")[1].text?.trimmingCharacters(in: .whitespacesAndNewlines), let category = catTD.text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                    error(.application)
                    return
               }
               var teacher = tN
               let nameArray = teacher.split(separator: ",")
               if(nameArray.count >= 2) {
                    let last = nameArray[0]
                    let first = nameArray[1].split(separator: " ")[0]
                    teacher = "\(String(first)) \(String(last))";
               }
               
               var score : Double?;
               var total : Double?;
               
               if let tempGrade = course.css("td.cellLeft")[4].text?.trimmingCharacters(in: .whitespacesAndNewlines), tempGrade.contains("/"), tempGrade.split(separator: "/").count == 2 {
                    for item in course.css("td.cellLeft")[4].css("div") {
                         course.css("td.cellLeft")[4].removeChild(item)
                    }
               }
               guard let grade = course.css("td.cellLeft")[4].text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                    error(.application)
                    return
               }
               if grade.contains("/"), grade.split(separator: "/").count == 2 {
                    score = Double(grade.split(separator:  "/")[0].trimmingCharacters(in: .whitespacesAndNewlines))
                    total = Double(grade.split(separator:  "/")[1].trimmingCharacters(in: .whitespacesAndNewlines))
               } else {
                    if let containerDiv = course.css("td.cellLeft")[4].css("div").first,
                         containerDiv.css("div").count >= 2,
                         let rawinfo = containerDiv.css("div")[1].text, rawinfo.split(separator: ":").count >= 2 {
                         total = Double(rawinfo.split(separator: ":")[1].trimmingCharacters(in: .whitespacesAndNewlines))
                    } else {
                         if let code = course.css("td.cellLeft")[4].css("span").first?.text {
                              if(code.trimmingCharacters(in: .whitespacesAndNewlines)=="MI") {
                                   score = -700;
                              } else if(code.trimmingCharacters(in: .whitespacesAndNewlines)=="INC" ) {
                                   score = -500;
                              } else if(code.trimmingCharacters(in: .whitespacesAndNewlines)=="EX" || code.trimmingCharacters(in: .whitespacesAndNewlines)=="ABS") {
                                   score = -800;
                              }
                         }
                    }
               }
               let assignment = Assignment(name: assignmentName, date: date, score: score, total: total, category: category, avg: nil, weight: nil)
               if let courseID = courses.index(where: { (course) -> Bool in
                    return (course.name == courseName)
               }) {
                    var course = courses[courseID]
                    course.assignments.append(assignment)
                    if(!course.categories.contains(where: { (cat) -> Bool in
                         cat.name == category
                    })) {
                         course.categories.append(Category(name: category, score: 0, total: 0, weight: -1, weightedScore: -1))
                    }
                    courses[courseID] = Course(name: courseName, teacher: teacher, grade: course.grade, gradeString: course.gradeString, period: course.period, periodString: course.periodString, subject: course.subject, qs: runs, courseId: course.courseId, assignments: course.assignments, categories: course.categories, dropped: false)
               } else {
                   error(.application)
                   return
               }
               
          }
          success(courses)
     }
     
     func parseSchedule(response: String, success: @escaping (_ classes : [ScheduleCourse], _ title : String) -> (), useBlock: Bool, error: @escaping(_ error: GradeError) -> ()) {
          var schedule = [ScheduleCourse]()
          if(response.lowercased().contains("parent access")) {
               error(.relogin)
               return
          }
          
          guard let doc = try? HTML(html: response, encoding: .utf8) else {
               error(.application)
               return
          }
          
          guard let body = doc.css("form[name=\"frmHome\"]").first, let notecard = body.css(".notecard").first, notecard.css("tr").count >= 2 else {
               error(.application)
               return
          }
          guard let tbody = notecard.css("tr")[1].css("table").first else {
               error(.application)
               return
          }
          
          let sections = tbody.css("td[valign=\"top\"]")
          guard sections.count >= 2, sections[1].css("table").count >= 2 else {
               error(.application)
               return
          }
          let table = sections[1].css("table")[1]
          guard table.css("tr").count >= 2 else {
               error(.application)
               return
          }
          
          for course in table.css("tr") {
               if(course.className == "listheading" || course.css("td").count < 6) {
                    continue;
               }
               
               guard let periodRaw = course.css("td")[0].text?.trimmingCharacters(in: .whitespacesAndNewlines), let courseTitle = course.css("td")[1].text?.trimmingCharacters(in: .whitespacesAndNewlines), let qs = course.css("td")[2].text?.trimmingCharacters(in: .whitespacesAndNewlines), let days = course.css("td")[3].text?.trimmingCharacters(in: .whitespacesAndNewlines), let room = course.css("td")[4].text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                    error(.application)
                    
                    // we don't want the actual data, just a representation of what we're missing...
                    /*let errString = "\(nullable(Int(courseId)))\(nullable(course.css("td")[1].css("a")[0].text))\(nullable(course.css("td")[2].text))\(nullable(course.css("td")[4].text))\(nullable(course.css("td")[4].text))\(nullable(course.css("td")[6].text))"
                     let err = NSError(domain: "com.anchron.simplegrades.error", code: 9, userInfo: [NSLocalizedDescriptionKey : "A key value [\(errString)] is missing from a class [parseSchedule]"])
                     err.record()*/
                    
                    return
               }
               
               var period = periodRaw
               var periodNumber = 9.0
               if(period.contains("A") || period.contains("B")) {
                    if let pN = Double(period.replacingOccurrences(of: "A", with: "4.2")) {
                         periodNumber = pN
                    }
                    if let pN = Double(period.replacingOccurrences(of: "B", with: "4.5")) {
                         periodNumber = pN
                    }
               } else {
                    guard let pN = Double(period) else {
                         let err = NSError(domain: "com.anchron.simplegrades.error", code: 11, userInfo: [NSLocalizedDescriptionKey : "A key value pN is off \(period) [parseSchedule]"])
                         err.record()
                         error(.application)
                         return
                    }
                    periodNumber = pN
                    period = "Period \(period)"
               }
               var teacherName = "N/A"
               if let tN = course.css("td")[5].text?.trimmingCharacters(in: .whitespacesAndNewlines)  {
                    teacherName = tN
                    let nameArray = teacherName.split(separator: ",")
                    if nameArray.count >= 2 {
                         let last = nameArray[0]
                         let first = nameArray[1].split(separator: " ")[0]
                         teacherName = "\(String(first)) \(String(last))";
                    }
               }
               
               let sc = ScheduleCourse(name: courseTitle, teacher: teacherName, period: periodNumber, periodString: period, qs: qs, courseId: courseTitle, room: room, subject: "other", unabridgedName: teacherName, days: days)
               schedule.append(sc)
          }
          
          var blacklist : [Int] = []
          var removeIndex : [Int] = []
          for (index,course) in schedule.enumerated().reversed() {
               for (otherIndex,otherCourse) in schedule.enumerated().reversed() {
                    if(!(blacklist.contains(index) || blacklist.contains(otherIndex)) && course.name == otherCourse.name && course.period == otherCourse.period && String(course.teacher.split(separator: "-")[0]) == String(otherCourse.teacher.split(separator: "-")[0]) && course.qs != otherCourse.qs) {
                         schedule[index].qs = "\(otherCourse.qs), \(course.qs)"
                         blacklist.append(index)
                         blacklist.append(otherIndex)
                         removeIndex.append(otherIndex)
                         schedule.remove(at: otherIndex)
                    }
               }
          }
          for (index,_) in schedule.enumerated().reversed() {
               if (!schedule[index].qs.contains("FY") && !schedule[index].qs.contains("Q1,Q2,Q3,Q4"))  {
                    let shortenedName = schedule[index].teacher.split(separator: " ").count==2 ? "\(schedule[index].teacher.split(separator: " ")[0].first!). \(String(schedule[index].teacher.split(separator: " ")[1]))" : schedule[index].teacher
                    schedule[index].teacher = schedule[index].teacher.count + shortenQs(qs: schedule[index].qs).count > 12 ? "\(shortenedName) - \(shortenQs(qs: schedule[index].qs))" : "\(schedule[index].teacher) - \(shortenQs(qs: schedule[index].qs))"
               }
          }
          if useBlock, sections[1].css("div").count >= 2, let rawDay = sections[1].css("div")[1].css("span").first?.css("b").first?.text?.trimmingCharacters(in: .whitespacesAndNewlines), let day = Int(rawDay) {
               if(day == 1) {
                    var newSchedule = [ScheduleCourse]()
                    for var course in schedule {
                         if let days = course.days {
                              if(days.contains("\(day)")) {
                                   newSchedule.append(course)
                              }
                         }
                    }
                    success(newSchedule.sorted(by: { (a, b) -> Bool in
                         return a.period < b.period
                    }), "Day 1")
               }
               else if(day == 2) {
                    var newSchedule = [ScheduleCourse]()
                    let DAY2 = [
                         2: 1,
                         3: 2,
                         4: 3,
                         1 : 4,
                         4.2 : 4.2,
                         4.5: 4.5,
                         6: 5,
                         7: 6,
                         8: 7,
                         5: 8,
                    ]
                    for var course in schedule {
                         if let days = course.days {
                              if days.contains("\(day)") {
                                   if let new = DAY2[course.period] {
                                        course.period = new
                                        
                                        if(course.period != 4.2 && course.period != 4.5) {
                                             let per = Int(course.period)
                                             course.periodString = "Period \(per)"
                                        }
                                        newSchedule.append(course)
                                   } else {
                                        error(.application)
                                   }
                              }
                         }
                    }
                    success(newSchedule.sorted(by: { (a, b) -> Bool in
                         return a.period < b.period
                    }), "Day 2")
               }
               else if(day == 3) {
                    var newSchedule = [ScheduleCourse]()
                    let DAY3 = [
                         3: 1,
                         4: 2,
                         1: 3,
                         2 : 4,
                         4.2 : 4.2,
                         4.5: 4.5,
                         7: 5,
                         8: 6,
                         5: 7,
                         6: 8,
                         ]
                    for var course in schedule {
                         if let days = course.days {
                              if days.contains("\(day)") {
                                   if let new = DAY3[course.period] {
                                        course.period = new
                                        
                                        if(course.period != 4.2 && course.period != 4.5) {
                                             let per = Int(course.period)
                                             course.periodString = "Period \(per)"
                                        }
                                        newSchedule.append(course)
                                   } else {
                                        error(.application)
                                   }
                              }
                         }
                    }
                    success(newSchedule.sorted(by: { (a, b) -> Bool in
                         return a.period < b.period
                    }), "Day 3")
               }
               else if(day == 4) {
                    var newSchedule = [ScheduleCourse]()
                    let DAY4 = [
                         4: 1,
                         1: 2,
                         2: 3,
                         3 : 4,
                         4.2 : 4.2,
                         4.5: 4.5,
                         8: 5,
                         5: 6,
                         6: 7,
                         7: 8,
                         ]
                    for var course in schedule {
                         if let days = course.days {
                              if days.contains("\(day)") {
                                   if let new = DAY4[course.period] {
                                        course.period = new
                                        
                                        if(course.period != 4.2 && course.period != 4.5) {
                                             let per = Int(course.period)
                                             course.periodString = "Period \(per)"
                                        }
                                        newSchedule.append(course)
                                   } else {
                                        error(.application)
                                   }
                              }
                         }
                    }
                    success(newSchedule.sorted(by: { (a, b) -> Bool in
                         return a.period < b.period
                    }), "Day 4")
               } else {
                    success(schedule.sorted(by: { (a, b) -> Bool in
                         return a.period < b.period
                    }), "Schedule")
               }
          } else {
               success(schedule.sorted(by: { (a, b) -> Bool in
                    return a.period < b.period
               }), "Schedule")
          }
     }
     
     func parseStudentPicker(response: String) throws -> [Int:String] {
          guard let doc = try? HTML(html: response, encoding: .utf8) else {
               throw GradeError.application
          }
          var students  = [Int : String]()
          for item in doc.css("#fldStudent option") {
               guard let idVal = item["value"], let id = Int(idVal), let name = item.text else {
                    throw GradeError.application
               }
               let correctedName = "\(name.split(separator: ",")[1]) \(name.split(separator: ",")[0])"
               students[id] = correctedName
          }
          return (students)
     }
     
     func parseStudentInfo(response: String) throws -> Student {          
          if(response.lowercased().contains("parent access")) {
               throw GradeError.relogin
          }
          
          guard let doc = try? HTML(html: response, encoding: .utf8) else {
               throw GradeError.application
          }
          
          guard let body = doc.css("form[name=\"frmHome\"]").first, let notecard = body.css(".notecard").first, notecard.css("tr").count >= 2 else {
               throw GradeError.application

          }
          guard let tbody = notecard.css("tr")[1].css("table").first else {
               throw GradeError.application
          }
          
          let sections = tbody.css("td[valign=\"top\"]")
          guard sections.count >= 2, let table = sections[0].css("table").first else {
               throw GradeError.application
          }
          guard table.css("tr").count >= 6,
               let homeroom = table.css("tr")[1].css("span").first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
               let counselerRaw = table.css("tr")[2].css("span").first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
               table.css("tr")[4].css("td").count == 2,
               let bday = table.css("tr")[4].css("td")[1].text?.trimmingCharacters(in: .whitespacesAndNewlines),
               let locker = table.css("tr")[5].css("td")[1].text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
               throw GradeError.application
          }
          
          let otherTable = sections[1].css("table")[0]
          guard let topSection = otherTable.css("tr").first,
               let name = topSection.css("td").first,
               let first = name.css("span").first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
               let gradeRaw = topSection.css("td")[1].css("span")[1].text?.trimmingCharacters(in: .whitespacesAndNewlines),
               let grade = Int(gradeRaw) else {
               throw GradeError.application
          }
          for child in name.css("*") {
               name.removeChild(child)
          }
          guard let last = name.text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
               throw GradeError.application
          }
          
          var counselerName = counselerRaw
          let nameArray = counselerName.split(separator: ",")
          if(nameArray.count >= 2) {
               let last = nameArray[0]
               let first = nameArray[1].split(separator: " ")[0]
               counselerName = "\(String(first)) \(String(last))";
          }
          var bigInfo = [String : (String, String)]()
          if sections[1].css("table").count >= 3  {
               let busTable = sections[1].css("table")[2]
               if let am = busTable.css(".list").first?.css(".listroweven").first, am.css("td").count >= 5, let busTime = am.css("td")[2].text?.trimmingCharacters(in: .whitespacesAndNewlines), let busRoad = am.css("td")[3].text?.trimmingCharacters(in: .whitespacesAndNewlines), let busRoute = am.css("td")[4].text?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    bigInfo["Bus Info"] = (busRoad, "at \(busTime) | \(busRoute)")
               }
          }

          return Student(name: "\(first) \(last)", bday: bday, counselerName: counselerName, school: "N/A", gender: "N/A", grade: grade, additionalInfo: ["Homeroom" : homeroom, "Locker" : locker], bigInfo: bigInfo)
     }
     func shortenQs(qs: String) -> String {
          var qsArr = " \(qs)".split(separator: ",")
          qsArr = qsArr.sorted()
          if(qsArr.count < 3) { return qs }
          var count = 0
          var newQsStr = ""
          var lookingForMatch = false
          while count < qsArr.count {
               let q = String(qsArr[count])
               if(count+1<qsArr.count-1) {
                    let next = String(qsArr[count+1])
                    if let q1 = Int(q[2]), let q2 = Int(next[2]){
                         if(q1+1 == q2) {
                              if(!lookingForMatch) {
                                   newQsStr = (newQsStr == "" ? "\(q) -" : "\(newQsStr),\(q) -")
                                   lookingForMatch = true
                              }
                         } else {
                              if(lookingForMatch) {
                                   newQsStr = "\(newQsStr)\(q),\(next),"
                                   count += 1;
                              } else {
                                   newQsStr = (newQsStr == "" ? "\(q)," : "\(newQsStr),\(q),")
                              }
                              lookingForMatch = false
                         }
                    }
                    else {
                         if(lookingForMatch) {
                              newQsStr = "\(newQsStr)\(q),\(next),"
                              count += 1;
                         } else {
                              newQsStr = (newQsStr == "" ? "\(q)," : "\(newQsStr),\(q),")
                         }
                         lookingForMatch = false
                    }
               } else {
                    if(newQsStr[newQsStr.count-1] == "," || newQsStr[newQsStr.count-1] == "-") {
                         newQsStr = "\(newQsStr)\(q)"
                    } else {
                         newQsStr = "\(newQsStr),\(q)"
                    }
               }
               count+=1;
          }
          return newQsStr.substring(from: 1)
     }
     private func letterGrades (_ grade : String) -> String {
          guard let number = Double(grade) else {
               return "N/A"
          }
          if(number == -100) {
               return "N/A";
          }
          else if number >= 97.5 {
               return "A+";
          }
          else if number >= 92.5 {
               return "A";
          }
          else if number >= 89.5 {
               return "A-";
          }
          else if number >= 86.5 {
               return "B+";
          }
          else if number >= 82.5 {
               return "B";
          }
          else if number >= 79.5 {
               return "B-";
          }
          else if number >= 76.5 {
               return "C+";
          }
          else if number >= 72.5 {
               return "C";
          }
          else if number >= 69.5 {
               return "C-";
          }
          else if number >= 66.5 {
               return "D+";
          }
          else if number >= 62.5 {
               return "D";
          }
          else if number >= 59.5 {
               return "D-";
          }
          else {
               return "F";
          }
     }
}
