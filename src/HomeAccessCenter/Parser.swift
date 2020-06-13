//
//  Parser.swift
//  SimpleGrades
//
//  Created by Michael Caruso on 1/12/17.
//  Copyright © 2017 Anchron Inc. All rights reserved.
//

import Kanna
import ChameleonFramework
import Crashlytics
import Unbox

class Parser {
     func parseClasses(response: String, scraper: Scraper, success: @escaping (_ classes : [Course]) -> (), error: @escaping(_ error: GradeError) -> ()) {
          let classGroup = DispatchGroup()
          var classes = [Course]()
          var completedSuccessfully = true;
          guard let doc = try? HTML(html: response, encoding: .utf8) else {
               
               let err = NSError(domain: "com.anchron.simplegrades.error", code: 0, userInfo: [NSLocalizedDescriptionKey : "Document couldn't be parsed as HTML [parseClasses]"])
               err.record()
               
               error(.application)
               completedSuccessfully = false
               return
          }
          let num = doc.css("div.AssignmentClass").count
          if(num == 0) {
               if(response.lowercased().contains("login")) {
                    error(.relogin)
                    return
               } else {
                    let err = NSError(domain: "com.anchron.simplegrades.error", code: 1, userInfo: [NSLocalizedDescriptionKey : "Login application error \(response) [parseClasses]"])
                    err.record()
                    
                    error(.application)
                    return
               }
          }
          var count = 0;
          for course in doc.css("div.AssignmentClass") {
               let courseNumber = count;
               if let id = course.css("a.sg-header-heading").first?["onclick"] {
                    var courseId = id
                    courseId = String(courseId.split(separator: "'")[1])
                    var assignments = [Assignment]()
                    for assignmentRow in course.css(".sg-asp-table-data-row") {
                         if let a = assignmentRow.css("td")[2].css("a").first {
                              
                              guard let date = assignmentRow.css("td")[0].text?.trimmingCharacters(in: .whitespacesAndNewlines),
                                   let assignmentName = a.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                                   let assignmentCategory = assignmentRow.css("td")[3].text?.trimmingCharacters(in: .whitespacesAndNewlines),
                                   let rawScore = assignmentRow.css("td")[4].text?.trimmingCharacters(in: .whitespacesAndNewlines),let total = assignmentRow.css("td")[5].text?.trimmingCharacters(in: .whitespacesAndNewlines),
                                   let weight = assignmentRow.css("td")[6].text?.trimmingCharacters(in: .whitespacesAndNewlines),
                                   let avg = assignmentRow.css("td")[9].text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                                        
                                        // we don't want the actual data, just a representation of what we're missing...
                                        let errString = "\(nullable(assignmentRow.css("td")[0].text))\(nullable(a.text))\(nullable(assignmentRow.css("td")[3].text))\(nullable(assignmentRow.css("td")[4].text))\(nullable(assignmentRow.css("td")[5].text))\(nullable(assignmentRow.css("td")[6].text))\(nullable(assignmentRow.css("td")[9].text))"
                                        let err = NSError(domain: "com.anchron.simplegrades.error", code: 2, userInfo: [NSLocalizedDescriptionKey : "A key value [\(errString)] is missing from an assignment [parseClasses]"])
                                        err.record()
                                        
                                        error(.application)
                                        return
                              }
                              var score = rawScore;
                              if(score=="C") {
                                   score = "500"
                              }
                              if(score=="I") {
                                   score = "-500"
                              }
                              if(score=="E") {
                                   score = "-600"
                              }
                              assignments.append(Assignment(name: assignmentName, date: date, score: Double(score), total: Double(total), category: assignmentCategory, avg: Double(avg), weight: Double(weight)))
                         }
                    }
                    let dropped = doc.css("#plnMain_rptAssigmnetsByCourse_lblDroppedCourse_\(courseNumber)").first != nil
                    if let result = DataManager.getDict(forKey: courseId) {
                         do {
                              let res = result as UnboxableDictionary
                              var cc : Course = try unbox(dictionary: res)
                              if let grade = doc.css("#plnMain_rptAssigmnetsByCourse_lblOverallAverage_\(courseNumber)").first?.text, let g =  Double(grade) {
                                   cc.grade = g
                              } else {
                                   cc.grade = -100
                              }
                              cc.gradeString = self.letterGrade("\(cc.grade)")
                              cc.assignments = assignments
                              cc.dropped = dropped
                              try cc.categories = self.parseCategories(doc: course, count: courseNumber)
                              classes.append(cc)
                              
                         }
                         catch let gradeError as GradeError {
                              _ = DataManager.remove(forKey: courseId)
                              error(gradeError)
                              
                              let err = NSError(domain: "com.anchron.simplegrades.error", code: 3, userInfo: [NSLocalizedDescriptionKey : "GradeError \(gradeError) when unboxing course [parseClasses]"])
                              err.record()
                              
                              return
                         }
                         catch (_) {
                              _ = DataManager.remove(forKey: courseId)
                              
                              classGroup.enter()
                              guard let cID = Int(courseId) else {
                                   completedSuccessfully = false
                                   classGroup.leave()
                                   
                                   let err = NSError(domain: "com.anchron.simplegrades.error", code: 4, userInfo: [NSLocalizedDescriptionKey : "CourseID is not an integer \(courseId) [parseClasses]"])
                                   err.record()
                                   
                                   error(.application)
                                   return
                              }
                              scraper.scrapeCourseInfo(courseId: cID, success: { info in
                                   do {
                                        var cc = try self.parseCourseInfo(courseId: cID, response: info)
                                        if let grade = doc.css("#plnMain_rptAssigmnetsByCourse_lblOverallAverage_\(courseNumber)").first?.text, let g =  Double(grade) {
                                             cc.grade = g
                                        } else {
                                             cc.grade = -100
                                        }
                                        cc.gradeString = self.letterGrade("\(cc.grade)")
                                        cc.assignments = assignments
                                        cc.dropped = dropped
                                        try cc.categories = self.parseCategories(doc: course, count: courseNumber)
                                        classes.append(cc)
                                        _ = try DataManager.set(mainViewController.compressToDictionary(course: cc), forKey: courseId)
                                   }
                                   catch let gradeError as GradeError {
                                        completedSuccessfully = false
                                        classGroup.leave()
                                        error(gradeError)
                                        return
                                   }
                                   catch (_) {
                                        completedSuccessfully = false
                                        classGroup.leave()
                                        error(.application)
                                        return
                                   }
                                   classGroup.leave()
                              }, error: {
                                   gradeError in
                                   completedSuccessfully = false
                                   classGroup.leave()
                                   error(gradeError)
                                   return
                              })
                         }
                         
                    } else {
                         classGroup.enter()
                         guard let cID = Int(courseId) else {
                              completedSuccessfully = false
                              classGroup.leave()
                              error(.application)
                              
                              let err = NSError(domain: "com.anchron.simplegrades.error", code: 5, userInfo: [NSLocalizedDescriptionKey : "CourseID is not an integer \(courseId) [parseClasses]"])
                              err.record()
                              
                              return
                         }
                         scraper.scrapeCourseInfo(courseId: cID, success: { info in
                              do {
                                   var cc = try self.parseCourseInfo(courseId: cID, response: info)
                                   if let grade = doc.css("#plnMain_rptAssigmnetsByCourse_lblOverallAverage_\(courseNumber)").first?.text, let g =  Double(grade) {
                                        cc.grade = g
                                   } else {
                                        cc.grade = -100
                                   }
                                   cc.gradeString = self.letterGrade("\(cc.grade)")
                                   cc.assignments = assignments
                                   cc.dropped = dropped
                                   try cc.categories = self.parseCategories(doc: course, count: courseNumber)
                                   classes.append(cc)
                                   _ = try DataManager.set(mainViewController.compressToDictionary(course: cc), forKey: courseId)
                              }
                              catch let gradeError as GradeError {
                                   completedSuccessfully = false
                                   classGroup.leave()
                                   error(gradeError)
                                   return
                              }
                              catch (_) {
                                   completedSuccessfully = false
                                   classGroup.leave()
                                   error(.application)
                                   return
                              }
                              classGroup.leave()
                         }, error: {
                              gradeError in
                              completedSuccessfully = false
                              classGroup.leave()
                              error(gradeError)
                              return
                         })
                    }
               }
               count+=1
          }
          _ = classGroup.wait(timeout: DispatchTime.distantFuture)
          if(completedSuccessfully) {
               success (classes)
          }
     }
     func parseSchedule(response: String, scraper: Scraper, success: @escaping (_ classes : [ScheduleCourse]) -> (), error: @escaping(_ error: GradeError) -> ()) {
          var schedule = [ScheduleCourse]()
          var completedSuccessfully = true;
          let classGroup = DispatchGroup()
          guard let doc = try? HTML(html: response, encoding: .utf8) else {
               error(.application)
               
               let err = NSError(domain: "com.anchron.simplegrades.error", code: 6, userInfo: [NSLocalizedDescriptionKey : "Document couldn't be parsed as HTML [parseSchedule]"])
               err.record()
               
               return
          }
          let num = doc.css(".sg-asp-table-data-row").count
          if(num == 0) {
               completedSuccessfully=false;
               if(response.lowercased().contains("logon")) {
                    error(.relogin)
                    return
               } else {
                    error(.application)
                    let err = NSError(domain: "com.anchron.simplegrades.error", code: 7, userInfo: [NSLocalizedDescriptionKey : "Login application error [parseSchedule]"])
                    err.record()
                    
                    return
               }
          }
          for course in doc.css(".sg-asp-table-data-row") {
               guard let cID = course.css("td")[1].css("a")[0]["onclick"] else {
                    error(.application)
                    
                    let err = NSError(domain: "com.anchron.simplegrades.error", code: 8, userInfo: [NSLocalizedDescriptionKey : "A key value CID is missing from an assignment [parseSchedule]"])
                    err.record()
                    
                    return
               }
               
               let courseId = String(cID.split(separator: "'")[1])
               if Int(courseId) == nil {
                    error(.application)
                    let err = NSError(domain: "com.anchron.simplegrades.error", code: 8, userInfo: [NSLocalizedDescriptionKey : "CID is not an integer \(courseId) [parseSchedule]"])
                    err.record()
                    
                    return
               }
               guard let courseIdInt = Int(courseId), let courseTitle = course.css("td")[1].css("a")[0].text?.trimmingCharacters(in: .whitespacesAndNewlines), let periodRaw = course.css("td")[2].text?.trimmingCharacters(in: .whitespacesAndNewlines), let room = course.css("td")[4].text?.trimmingCharacters(in: .whitespacesAndNewlines), let qs = course.css("td")[6].text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                    error(.application)
                    
                    // we don't want the actual data, just a representation of what we're missing...
                    let errString = "\(nullable(Int(courseId)))\(nullable(course.css("td")[1].css("a")[0].text))\(nullable(course.css("td")[2].text))\(nullable(course.css("td")[4].text))\(nullable(course.css("td")[4].text))\(nullable(course.css("td")[6].text))"
                    let err = NSError(domain: "com.anchron.simplegrades.error", code: 9, userInfo: [NSLocalizedDescriptionKey : "A key value [\(errString)] is missing from a class [parseSchedule]"])
                    err.record()
                    
                    return
               }
               var period = periodRaw
               var periodNumber = 9.0
               if(period.contains("-")) {
                    guard let pN = Double(period.substring(to: period.index(period.startIndex,offsetBy:1))) else {
                         error(.application)
                         
                         let err = NSError(domain: "com.anchron.simplegrades.error", code: 10, userInfo: [NSLocalizedDescriptionKey : "A key value pN is off \(period.substring(to: period.index(period.startIndex,offsetBy:1))) [parseSchedule]"])
                         err.record()
                         
                         return
                    }
                    periodNumber = pN
                    period = "Period \(Int(periodNumber))"
               }
               else if(period.contains("A") || period.contains("B")) {
                    if let pN = Double(period.replacingOccurrences(of: "A", with: "")) {
                         periodNumber = pN
                    }
                    if let pN = Double(period.replacingOccurrences(of: "B", with: ".5")) {
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
               if let row = course.css("td")[3].css("a").first, let tN = row.text?.trimmingCharacters(in: .whitespacesAndNewlines)  {
                    teacherName = tN
                    let nameArray = teacherName.split(separator: ",")
                    if nameArray.count >= 2 {
                         let last = nameArray[0]
                         let first = nameArray[1].split(separator: " ")[0]
                         teacherName = "\(String(first)) \(String(last))";
                    }
               }
               
               if let result = DataManager.getDict(forKey: "\(courseIdInt)\(periodNumber)-sc") {
                    do {
                         let res = result as UnboxableDictionary
                         let course : ScheduleCourse = try unbox(dictionary: res)
                         schedule.append(course)
                    }
                    catch let gradeError as GradeError {
                         _ = DataManager.remove(forKey: "\(courseIdInt)\(periodNumber)-sc")
                         error(gradeError)
                         return
                    }
                    catch (_) {
                         _ = DataManager.remove(forKey: "\(courseIdInt)\(periodNumber)-sc")
                         error(.application)
                         return
                    }
                    
               } else {
                    classGroup.enter()
                    scraper.scrapeCourseInfo(courseId: courseIdInt, success: { info in
                         do {
                              let cc = try self.parseScheduleCourseInfo(courseId: courseIdInt, response: info, qs: qs)
                              let sc = ScheduleCourse(name: courseTitle, teacher: cc.teacher, period: periodNumber, periodString: period, qs: qs, courseId: courseId, room: room, subject: cc.subject, unabridgedName: cc.teacher, days: nil)
                              schedule.append(sc)
                              _ = try DataManager.set(mainViewController.compressToDictionary(course: sc), forKey: "\(courseIdInt)\(periodNumber)-sc")
                         }
                         catch let gradeError as GradeError {
                              completedSuccessfully = false
                              classGroup.leave()
                              error(gradeError)
                              return
                         }
                         catch (_) {
                              completedSuccessfully = false
                              classGroup.leave()
                              error(.application)
                              return
                         }
                         classGroup.leave()
                    }, error: {
                         gradeError in
                         completedSuccessfully = false
                         classGroup.leave()
                         error(gradeError)
                         return
                    })
               }
               
          }
          _ = classGroup.wait(timeout: DispatchTime.distantFuture)
          if(completedSuccessfully) {
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
                    if (!schedule[index].qs.contains("Q1, Q2, Q3, Q4") && !schedule[index].qs.contains("M1, M2, M3, M4, M5, M6"))  {
                         let shortenedName = schedule[index].teacher.split(separator: " ").count==2 ? "\(schedule[index].teacher.split(separator: " ")[0].first!). \(String(schedule[index].teacher.split(separator: " ")[1]))" : schedule[index].teacher
                         schedule[index].teacher = schedule[index].teacher.count + shortenQs(qs: schedule[index].qs).count > 12 ? "\(shortenedName) - \(shortenQs(qs: schedule[index].qs))" : "\(schedule[index].teacher) - \(shortenQs(qs: schedule[index].qs))"
                    }
               }
               success(schedule.sorted(by: { (a, b) -> Bool in
                    return a.period < b.period
               }))
          }
     }
     func parseAttendance(response: String, success: @escaping (_ events : [AttendanceDate], _ previousID : String?, _ eventValidation : String, _ viewState : String) -> (), error: @escaping(_ error: GradeError) -> ()) {
          var events = [AttendanceDate]()
          
          guard let doc = try? HTML(html: response, encoding: .utf8) else {
               error(.application)
               
               let err = NSError(domain: "com.anchron.simplegrades.error", code: 100, userInfo: [NSLocalizedDescriptionKey : "Document couldn't be parsed as HTML [parseAttendance]"])
               err.record()
               
               return
          }
          guard let attendanceTable = doc.css("#plnMain_cldAttendance").first else {
               error(.application)
               
               let err = NSError(domain: "com.anchron.simplegrades.error", code: 101, userInfo: [NSLocalizedDescriptionKey : "Document missing attendanceTable [parseAttendance]"])
               err.record()
               
               return
          }
          guard let headerTD = doc.css(".sg-asp-calendar-header").first?.css("td"), headerTD.count >= 2, let monthYear = headerTD[1].text else {
               error(.application)
               
               let err = NSError(domain: "com.anchron.simplegrades.error", code: 104, userInfo: [NSLocalizedDescriptionKey : "Document missing month / year [parseAttendance]"])
               err.record()
               
               return
          }
          
          let dateFormatter = DateFormatter()
          dateFormatter.dateFormat = "dd MM yyyy"
          dateFormatter.timeZone = TimeZone.current
          
          let rows = attendanceTable.css("tr")
          for x in 3..<rows.count {
               for day in rows[x].css("td") {
                    if let dayNumber = day.text, let date = dateFormatter.date(from: "\(dayNumber) \(monthYear)"), let info = day["title"] {
                         let items = info.split(separator: "\r")
                         var insertableItems = [AttendanceItem]()
                         var a = 0
                         while a<items.count {
                              if(items[a].starts(with: "Arrive Time")) {
                                   a+=1;
                                   if(a >= items.count) {
                                        break;
                                   }
                              }
                              let period = items[a].replacingOccurrences(of: "period:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                              a+=1
                              let item = items[a].replacingOccurrences(of: "Attendance:", with: "")
                              var periodNumber = 0.0;
                              if(period.contains("-")) {
                                   guard let pN = Double(period.substring(to: period.index(period.startIndex,offsetBy:1))) else {
                                        error(.application)
                                        
                                        let err = NSError(domain: "com.anchron.simplegrades.error", code: 105, userInfo: [NSLocalizedDescriptionKey : "Period # off for some reason \(period) [parseAttendance]"])
                                        err.record()
                                        
                                        return
                                   }
                                   periodNumber = pN
                              }
                              else if(period.contains("A")) {
                                   guard let pN = Double(period.replacingOccurrences(of: "A", with: "")) else {
                                        error(.application)
                                        
                                        let err = NSError(domain: "com.anchron.simplegrades.error", code: 106, userInfo: [NSLocalizedDescriptionKey : "Period # off for some reason \(period) [parseAttendance]"])
                                        err.record()
                                        
                                        return
                                        
                                   }
                                   periodNumber = pN
                              }
                              else if(period.contains("B")) {
                                   guard let pN = Double(period.replacingOccurrences(of: "B", with: ".5")) else {
                                        error(.application)
                                        
                                        let err = NSError(domain: "com.anchron.simplegrades.error", code: 107, userInfo: [NSLocalizedDescriptionKey : "Period # off for some reason \(period) [parseAttendance]"])
                                        err.record()
                                        
                                        return
                                        
                                   }
                                   periodNumber = pN
                              }
                              else {
                                   guard let pN = Double(period) else {
                                        error(.application)
                                        
                                        let err = NSError(domain: "com.anchron.simplegrades.error", code: 108, userInfo: [NSLocalizedDescriptionKey : "Period # off for some reason \(period) [parseAttendance]"])
                                        err.record()
                                        
                                        return
                                        
                                   }
                                   periodNumber = pN
                              }
                              
                              insertableItems.append(AttendanceItem(category: item, period: periodNumber, periodString: period))
                              a+=1
                         }
                         if(items.count > 0) {
                              events.append(AttendanceDate(date: date, items: insertableItems))
                         }
                    }
               }
          }
          
          var nextLink : String?
          
          if let leftLink = doc.css(".sg-asp-calendar-header").first?.css("td").first?.css("a").first?["href"], doc.css(".sg-asp-calendar-header").first?.css("td").first?.css("a").first?.text != "", leftLink.split(separator: "'").count >= 4 {
               nextLink = String(leftLink.split(separator: "'")[3])
          }
          
          guard let ev = doc.css("#__EVENTVALIDATION").first?["value"], let vs = doc.css("#__VIEWSTATE").first?["value"] else {
               error(.application)
               
               let err = NSError(domain: "com.anchron.simplegrades.error", code: 103, userInfo: [NSLocalizedDescriptionKey : "Document missing EV or VS"])
               err.record()
               
               return
          }
          events.sort { (a, b) -> Bool in
               return a.date > b.date
          }
          success(events, nextLink, ev, vs)
     }
     func fetchAttachments(response: String) throws -> [String : String] {
          var fileURLs : [String: String] = [:]
          guard let doc = try? HTML(html: response, encoding: .utf8)  else {
               throw GradeError.application
          }
          if let attachments = doc.css("#plnMain_divAttachments").first, attachments.css(".sg-asp-table-data-row").count > 0 {
               for item in attachments.css(".sg-asp-table-data-row") {
                    if let link = item.css("a").first, let title = link.text, let href = link["href"] {
                         fileURLs[title.trimmingCharacters(in: .whitespacesAndNewlines)] = href
                    }
               }
          }
          return fileURLs
     }
     func parseCourseInfo(courseId : Int, response: String) throws -> Course {
          guard let doc = try? HTML(html: response, encoding: .utf8)  else {
               let err = NSError(domain: "com.anchron.simplegrades.error", code: 12, userInfo: [NSLocalizedDescriptionKey : "HTML doc isn't parsing right [parseCourseInfo]"])
               err.record()
               
               throw GradeError.application
          }
          if(response.lowercased().contains("login")) {
               throw GradeError.relogin
          }
          if let title = doc.title, !title.lowercased().contains("class information") {
               let err = NSError(domain: "com.anchron.simplegrades.error", code: 12, userInfo: [NSLocalizedDescriptionKey : "Course info page loaded wrong; title is 'class information' [parseCourseInfo]"])
               err.record()
               throw GradeError.application
          }
          guard let firstHeader = doc.css(".sg-asp-table-header-row").first?.css("td").first?.text else {
               let err = NSError(domain: "com.anchron.simplegrades.error", code: 16, userInfo: [NSLocalizedDescriptionKey : "Missing firstHeader [parseCourseInfo]"])
               err.record()
               
               throw GradeError.application
          }
          var inc = 0;
          if(firstHeader != "Teacher") {
               inc = 1
          }
          guard let courseTitle = doc.css("#plnMain_lblName").first?.text?.trimmingCharacters(in: .whitespaces),
               let rawTeacherName = doc.css(".sg-asp-table-data-row").first?.css("td")[0+inc].text?.trimmingCharacters(in: .whitespaces), let qs = doc.css(".sg-asp-table-data-row").first?.css("td")[4+inc].text?.trimmingCharacters(in: .whitespaces), let periodRaw = doc.css(".sg-asp-table-data-row").first?.css("td")[2+inc].text?.trimmingCharacters(in: .whitespaces), let subject = doc.css("#plnMain_lblDepartment").first?.text
               else {
                    
                    // we don't want the actual data, just a representation of what we're missing...
                    let errString = "\(nullable(doc.css("#plnMain_lblName").first?.text))\(nullable(doc.css(".sg-asp-table-data-row").first?.css("td")[0+inc].text))\(nullable(doc.css(".sg-asp-table-data-row").first?.css("td")[4+inc].text))\(nullable(doc.css(".sg-asp-table-data-row").first?.css("td")[2+inc].text))\(nullable(doc.css("#plnMain_lblDepartment").first?.text))"
                    let err = NSError(domain: "com.anchron.simplegrades.error", code: 13, userInfo: [NSLocalizedDescriptionKey : "A key value [\(errString)] is missing from a class [parseCourseInfo]"])
                    err.record()
                    
                    throw GradeError.application
          }
          var teacherName = rawTeacherName
          let nameArray = teacherName.split(separator: ",")
          if(nameArray.count > 1) {
               let last = nameArray[0]
               let first = nameArray[1].split(separator: " ")[0]
               teacherName = "\(String(first)) \(String(last))";
          }
          var period = periodRaw
          var periodNumber = 0;
          if(period.contains("-")) {
               guard let pN = Int(period.substring(to: period.index(period.startIndex,offsetBy:1))) else {
                    let err = NSError(domain: "com.anchron.simplegrades.error", code: 14, userInfo: [NSLocalizedDescriptionKey : "A key value pN is off \(period.substring(to: period.index(period.startIndex,offsetBy:1))) [parseCourseInfo]"])
                    err.record()
                    
                    throw GradeError.application
               }
               periodNumber = pN
          }
          else if(period.contains("A")) {
               guard let pN = Int(period.replacingOccurrences(of: "A", with: "")) else {
                    let err = NSError(domain: "com.anchron.simplegrades.error", code: 15, userInfo: [NSLocalizedDescriptionKey : "A key value pN is off \(period.replacingOccurrences(of: "A", with: "")) [parseCourseInfo]"])
                    err.record()
                    
                    throw GradeError.application
               }
               periodNumber = pN
          }
          else if(period.contains("B")) {
               guard let pN = Int(period.replacingOccurrences(of: "B", with: "")) else {
                    let err = NSError(domain: "com.anchron.simplegrades.error", code: 17, userInfo: [NSLocalizedDescriptionKey : "A key value pN is off \(period.replacingOccurrences(of: "B", with: "")) [parseCourseInfo]"])
                    err.record()
                    
                    throw GradeError.application
               }
               periodNumber = pN
          }
          else {
               guard let pN = Int(period) else {
                    let err = NSError(domain: "com.anchron.simplegrades.error", code: 18, userInfo: [NSLocalizedDescriptionKey : "A key value pN is off \(period.substring(to: period.index(period.startIndex,offsetBy:1))) [parseCourseInfo]"])
                    err.record()
                    
                    throw GradeError.application
               }
               periodNumber = pN
               period = "Period \(period)"
          }
          return (Course(name: courseTitle, teacher: teacherName, grade: -100, gradeString: "N/A", period: periodNumber, periodString: period, subject: subject, qs:qs, courseId: courseId, assignments: [Assignment](), categories: [Category](), dropped: false))
     }
     
     func parseScheduleCourseInfo(courseId : Int, response: String, qs: String) throws -> Course {
          guard let doc = try? HTML(html: response, encoding: .utf8)  else {
               let err = NSError(domain: "com.anchron.simplegrades.error", code: 19, userInfo: [NSLocalizedDescriptionKey : "Document couldn't be parsed as HTML [parseScheduleCourseInfo]"])
               err.record()
               
               throw GradeError.application
          }
          if(response.lowercased().contains("login")) {
               throw GradeError.relogin
          }
          if let title = doc.title, !title.lowercased().contains("class information") {
               let err = NSError(domain: "com.anchron.simplegrades.error", code: 20, userInfo: [NSLocalizedDescriptionKey : "Schedule course info page loaded wrong; title is 'class information' \(courseId) [parseScheduleCourseInfo]"])
               err.record()
               
               throw GradeError.application
          }
          guard let firstHeader = doc.css(".sg-asp-table-header-row").first?.css("td").first?.text else {
               let err = NSError(domain: "com.anchron.simplegrades.error", code: 21, userInfo: [NSLocalizedDescriptionKey : "Missing firstHeader [parseScheduleCourseInfo]"])
               err.record()
               
               throw GradeError.application
          }
          var inc = 0;
          if(firstHeader != "Teacher") {
               inc = 1
          }
          guard let courseTitle = doc.css("#plnMain_lblName").first?.text?.trimmingCharacters(in: .whitespaces),
               let rawTeacherName = doc.css(".sg-asp-table-data-row").first?.css("td")[0+inc].text?.trimmingCharacters(in: .whitespaces), let periodRaw = doc.css(".sg-asp-table-data-row").first?.css("td")[2+inc].text?.trimmingCharacters(in: .whitespaces), let subject = doc.css("#plnMain_lblDepartment").first?.text
               else {
                    // we don't want the actual data, just a representation of what we're missing...
                    let errString = "\(nullable(doc.css("#plnMain_lblName").first?.text))\(nullable(doc.css(".sg-asp-table-data-row").first?.css("td")[0+inc].text))\(nullable(doc.css(".sg-asp-table-data-row").first?.css("td")[2+inc].text))\(nullable(doc.css("#plnMain_lblDepartment").first?.text))"
                    let err = NSError(domain: "com.anchron.simplegrades.error", code: 22, userInfo: [NSLocalizedDescriptionKey : "A key value [\(errString)] is missing from a class [parseScheduleCourseInfo]"])
                    err.record()
                    
                    throw GradeError.application
          }
          var teacherName = rawTeacherName
          let nameArray = teacherName.split(separator: ",")
          if(nameArray.count > 1) {
               let last = nameArray[0]
               let first = nameArray[1].split(separator: " ")[0]
               teacherName = "\(String(first)) \(String(last))";
          }
          var period = periodRaw
          var periodNumber = 0;
          if(period.contains("-")) {
               guard let pN = Int(period.substring(to: period.index(period.startIndex,offsetBy:1))) else {
                    throw GradeError.application
               }
               periodNumber = pN
          }
          else if(period.contains("A")) {
               guard let pN = Int(period.replacingOccurrences(of: "A", with: "")) else {
                    let err = NSError(domain: "com.anchron.simplegrades.error", code: 23, userInfo: [NSLocalizedDescriptionKey : "A key value pN is off \(period.replacingOccurrences(of: "A", with: "")) [parseScheduleCourseInfo]"])
                    err.record()
                    
                    throw GradeError.application
               }
               periodNumber = pN
          }
          else if(period.contains("B")) {
               guard let pN = Int(period.replacingOccurrences(of: "B", with: "")) else {
                    let err = NSError(domain: "com.anchron.simplegrades.error", code: 24, userInfo: [NSLocalizedDescriptionKey : "A key value pN is off \(period.replacingOccurrences(of: "B", with: "")) [parseScheduleCourseInfo]"])
                    err.record()
                    
                    throw GradeError.application
               }
               periodNumber = pN
          }
          else {
               guard let pN = Int(period) else {
                    let err = NSError(domain: "com.anchron.simplegrades.error", code: 25, userInfo: [NSLocalizedDescriptionKey : "A key value pN is off \(period.substring(to: period.index(period.startIndex,offsetBy:1))) [parseScheduleCourseInfo]"])
                    err.record()
                    
                    throw GradeError.application
               }
               periodNumber = pN
               period = "Period \(period)"
          }
          return (Course(name: courseTitle, teacher: teacherName, grade: -100, gradeString: "N/A", period: periodNumber, periodString: period, subject: subject, qs:qs, courseId: courseId, assignments: [Assignment](), categories: [Category](), dropped: false))
     }
     func parseCategories(doc: XMLElement, count: Int) throws -> [Category] {
          var categories = [Category]()
          guard let categoryBox = doc.css("#plnMain_rptAssigmnetsByCourse_dgCourseCategories_\(count)").first else {
               return categories
          }
          for row in categoryBox.css(".sg-asp-table-data-row") {
               guard let name = row.css("td")[0].text?.trimmingCharacters(in: .whitespacesAndNewlines), let sc = row.css("td")[1].text?.trimmingCharacters(in: .whitespacesAndNewlines), let score = Double(sc), let t = row.css("td")[2].text?.trimmingCharacters(in: .whitespacesAndNewlines), let total = Double(t) else {
                    
                    let errString = "\(nullable(row.css("td")[0].text))\(nullable(row.css("td")[1].text))X\(nullable(row.css("td")[2].text))X"
                    let err = NSError(domain: "com.anchron.simplegrades.error", code: 22, userInfo: [NSLocalizedDescriptionKey : "A key value [\(errString)] is missing from a class [parseScheduleCourseInfo]"])
                    err.record()
                    
                    throw GradeError.application
               }
               var weight = -1.0
               var weightedScore = -1.0
               if (row.css("td").count >= 5) {
                    if let wt = row.css("td")[4].text?.trimmingCharacters(in: .whitespacesAndNewlines), let wtD = Double(wt)
                    {
                         weight = wtD
                    }
                    if let wtS = row.css("td")[5].text?.trimmingCharacters(in: .whitespacesAndNewlines), let wtSD = Double(wtS) {
                         weightedScore = wtSD
                    }
               }
               categories.append(Category(name:name, score:score, total:total, weight:weight, weightedScore:weightedScore))
          }
          return categories
     }
     func parseStudentPicker(response: String) throws -> [Int:String] {
          guard let doc = try? HTML(html: response, encoding: .utf8) else {
               throw GradeError.application
          }
          var students  = [Int : String]()
          for row in doc.css(".sg-student-picker-row") {
               guard let idVal = row.css("#studentId").first?["value"], let id = Int(idVal), let name = row.css(".sg-picker-student-name").first?.text else {
                    throw GradeError.application
               }
               students[id] = name
          }
          return (students)
     }
     
     func parseStudentInfo(response: String) throws -> Student {
          guard let doc = try? HTML(html: response, encoding: .utf8) else {
               throw GradeError.application
          }
          guard let title = doc.title else {
               throw GradeError.application
          }
          if(!title.lowercased().contains("homeaccess")) {
               if(title.lowercased()=="") {
                    throw GradeError.relogin
               } else {
                    throw GradeError.application
               }
          }
          guard let nameRaw = doc.css("#plnMain_lblRegStudentName").first?.text?.trimmingCharacters(in: .whitespaces), let bday = doc.css("#plnMain_lblBirthDate").first?.text?.trimmingCharacters(in: .whitespaces), let school = doc.css("#plnMain_lblBuildingName").first?.text?.trimmingCharacters(in: .whitespaces), let gender = doc.css("#plnMain_lblGender").first?.text?.trimmingCharacters(in: .whitespaces), let grade = doc.css("#plnMain_lblGrade").first?.text?.trimmingCharacters(in: .whitespaces), let gradeInt = Int(grade) else {
               throw GradeError.application
          }
          
          var name = nameRaw
          var counseler = ""
          if let counselerName = doc.css("#plnMain_lblCounselor").first?.css("a").first?.text?.trimmingCharacters(in: .whitespaces) {
               counseler = counselerName
          } else {
               guard let cc = doc.css("#plnMain_lblCounselor").first?.text?.trimmingCharacters(in: .whitespaces) else {
                    throw GradeError.application
               }
               counseler = cc
          }
          
          let nameArray = name.split(separator: ",")
          if nameArray.count >= 2 {
               let last = nameArray[0]
               let first = nameArray[1].split(separator: " ")[0]
               name = "\(String(first)) \(String(last))";
          }
          
          let counselerArray = counseler.split(separator: ",")
          let counselerlast = counselerArray[0]
          let counselerfirst = counselerArray[1].split(separator: " ")[0]
          counseler = "\(String(counselerfirst)) \(String(counselerlast))";
          return (Student(name: name, bday: bday, counselerName: counseler, school: school, gender: gender, grade: gradeInt, additionalInfo: nil, bigInfo: nil))
          
     }
     func parseTranscript(response : String) throws -> Transcript {
          guard let doc = try? HTML(html: response, encoding: .utf8)  else {
               let err = NSError(domain: "com.anchron.simplegrades.error", code: 200, userInfo: [NSLocalizedDescriptionKey : "Document couldn't be parsed as HTML [parseTranscript]"])
               err.record()
               
               throw GradeError.application
          }
          guard let title = doc.title else {
               let err = NSError(domain: "com.anchron.simplegrades.error", code: 201, userInfo: [NSLocalizedDescriptionKey : "Document title missing [parseTranscript]"])
               err.record()
               
               throw GradeError.application
          }
          
          if(!title.lowercased().contains("homeaccess")) {
               if(title.lowercased()=="") {
                    throw GradeError.relogin
               } else {
                    let err = NSError(domain: "com.anchron.simplegrades.error", code: 202, userInfo: [NSLocalizedDescriptionKey : "Document title wrong \(title) [parseTranscript]"])
                    err.record()
                    
                    throw GradeError.application
               }
          }
          var weighted : Double?
          var unweighted : Double?
          if let weightedRaw = doc.css("#plnMain_rpTranscriptGroup_lblGPACum1")[doc.css("#plnMain_rpTranscriptGroup_lblGPACum1").count-1].text?.trimmingCharacters(in: .whitespaces), let unweightedRaw = doc.css("#plnMain_rpTranscriptGroup_lblGPACum2")[doc.css("#plnMain_rpTranscriptGroup_lblGPACum2").count-1].text?.trimmingCharacters(in: .whitespaces) {
               weighted = Double(weightedRaw)
               unweighted = Double(unweightedRaw)
               
          }
          
          var years = [TSYear]()
          var count = 0
          for item in doc.css(".sg-transcript-group") {
               if let year = item.css("#plnMain_rpTranscriptGroup_lblYearValue_\(count)").first?.text, let grade = item.css("#plnMain_rpTranscriptGroup_lblGradeValue_\(count)").first?.text, let courses =  item.css("#plnMain_rpTranscriptGroup_dgCourses_\(count)").first?.css(".sg-asp-table-data-row") {
                    var tsCourses = [TSCourse]()
                    
                    var a = 0
                    while(a < courses.count) {
                         let course = courses[a]
                         let columns = course.css("td")
                         if columns.count >= 4, let name = columns[1].text {
                              if let s1 = columns[2].text?.trimmingCharacters(in: .whitespacesAndNewlines), let s2 = columns[3].text?.trimmingCharacters(in: .whitespacesAndNewlines), s1 != "", s2 != "" {
                                   tsCourses.append(TSCourse(name: name, s1: s1, s2: s2))
                              } else if a+1 < courses.count, courses[a+1].css("td").count >= 4, name == courses[a+1].css("td")[1].text {
                                   tsCourses.append(TSCourse(name: name, s1: columns[2].text?.trimmingCharacters(in: .whitespacesAndNewlines), s2: courses[a+1].css("td")[3].text?.trimmingCharacters(in: .whitespacesAndNewlines)))
                                   a+=1
                              } else {
                                   tsCourses.append(TSCourse(name: name, s1: columns[2].text?.trimmingCharacters(in: .whitespacesAndNewlines), s2: columns[3].text?.trimmingCharacters(in: .whitespacesAndNewlines)))
                              }
                         }
                         a+=1
                    }
                    if(tsCourses.count > 0) {
                         years.append(TSYear(year: year, grade: grade, courses: tsCourses))
                    }
               }
               count += 1
          }
          return Transcript(wgpa: weighted, uwgpa: unweighted, years: years)
     }
     func parseGPAs(response: String) throws -> (Double, Double) {
          /*guard let doc = HTML(html: response, encoding: .utf8) else {
           throw GradeError.application
           }
           guard let title = doc.title else {
           throw GradeError.application
           }
           if(!title.lowercased().contains("homeaccess")) {
           if(title.lowercased()=="") {
           throw GradeError.relogin
           } else {
           throw GradeError.application
           }
           }
           guard let weightedRaw = doc.css("#plnMain_rpTranscriptGroup_lblGPACum1")[doc.css("#plnMain_rpTranscriptGroup_lblGPACum1").count-1]?.text?.trimmingCharacters(in: .whitespaces), let weighted = Double(weightedRaw), let unweightedRaw = doc.css("#plnMain_rpTranscriptGroup_lblGPACum2")[doc.css("#plnMain_rpTranscriptGroup_lblGPACum2").count-1]?.text?.trimmingCharacters(in: .whitespaces), let unweighted = Double(unweightedRaw) else {
           throw GradeError.application
           }
           return (weighted, unweighted)*/
          return (0,0)
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
     func nullable(_ a : Any?) -> Int {
          return a != nil ? 1 : 0
     }
     
     func letterGrade (_ grade : String) -> String {
          guard let number = Double(grade) else {
               return "N/A"
          }
          if(number == -100) {
               return "N/A";
          }
          else if number >= 97 {
               return "A+";
          }
          else if number >= 93 {
               return "A";
          }
          else if number >= 89.5 {
               return "A-";
          }
          else if number >= 87 {
               return "B+";
          }
          else if number >= 83 {
               return "B";
          }
          else if number >= 79.5 {
               return "B-";
          }
          else if number >= 77 {
               return "C+";
          }
          else if number >= 73{
               return "C";
          }
          else if number >= 69.5 {
               return "C-";
          }
          else if number >= 67 {
               return "D+";
          }
          else if number >= 63 {
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
extension String {
     
     var length: Int {
          return self.count
     }
     
     subscript (i: Int) -> String {
          return self[Range(i ..< i + 1)]
     }
     
     func substring(from: Int) -> String {
          return self[Range(min(from, length) ..< length)]
     }
     
     func substring(to: Int) -> String {
          return self[Range(0 ..< max(0, to))]
     }
     
     subscript (r: Range<Int>) -> String {
          let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                              upper: min(length, max(0, r.upperBound))))
          let start = index(startIndex, offsetBy: range.lowerBound)
          let end = index(start, offsetBy: range.upperBound - range.lowerBound)
          return String(self[start ..< end])
     }
     
}

extension NSError {
     
     func record() {
          Crashlytics.sharedInstance().recordError(self)
     }
     
}
