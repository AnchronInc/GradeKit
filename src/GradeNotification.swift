//
//  GradeNotification.swift
//  SimpleGrades
//
//  Created by Michael Caruso on 9/9/17.
//  Copyright © 2017 Anchron Inc. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications
import SwiftDate


class GradeNotification {
    static func agnostic(title : String, desc: String, sound: String, id: String, date: Date) {
       let notificationContent = UNMutableNotificationContent()
       notificationContent.title = title
       notificationContent.body = desc
       notificationContent.sound = UNNotificationSound(named: UNNotificationSoundName(sound))
       notificationContent.badge = 1
       let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date), repeats: false)
       let request = UNNotificationRequest(identifier: id, content: notificationContent, trigger: trigger)
       UNUserNotificationCenter.current().add(request) { _ in
       }
    }
    static func agnostic(title: String, desc: String, sound: String) {
       let notificationContent = UNMutableNotificationContent()
       notificationContent.title = title
       notificationContent.body = desc
       notificationContent.sound = UNNotificationSound(named: UNNotificationSoundName(sound))
       let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
       let request = UNNotificationRequest(identifier: "\(UUID())", content: notificationContent, trigger: trigger)
       UNUserNotificationCenter.current().add(request) { _ in}
       DispatchQueue.main.async {
           UIApplication.shared.applicationIconBadgeNumber += 1
       }
    }
     static func planner(id: Int, date : Date, name : String, courseName : String, type : String) {
          let time = (date.dateAtStartOf(.day) - 1.days) + 18.hours
          let secondTime = date.dateAtStartOf(.day) + 6.hours + 30.minutes
          
          var courseName = courseName
          for word in commonReplacements {
               courseName = courseName.replacingOccurrences(of: word.key, with: word.value)
          }
          
          var title = ""
          var desc = ""
          var semanticSubject = "is"
          if (name.contains(" and ")) {
               semanticSubject = "are"
          }
          else if(name.components(separatedBy: " ").count == 1 && name.components(separatedBy: " ")[0].hasSuffix("s")) {
               semanticSubject = "are"
          }
          
          switch(type) {
          case "Homework":
               title = "Homework Due"
               desc = "\(name) for \(courseName) \(semanticSubject) due tomorrow"
          case "Project":
               title = "Project Due"
               desc = "\(name) for \(courseName) \(semanticSubject) due tomorrow"
          case "Assessment":
               title = "Assessment Tomorrow"
               desc = "\(name) in \(courseName) \(semanticSubject) tomorrow"
          case "Event":
               title = "Event Tomorrow"
               if(courseName != "After School") {
                    desc = "\(name) in \(courseName) \(semanticSubject) tomorrow"
               } else {
                    desc = "\(name) \(semanticSubject) \(courseName) tomorrow"
               }
          default:
               title = "Assignment Due"
               desc = "\(name) for \(courseName) \(semanticSubject) due tomorrow"
          }
          self.remove(plannerID: id)
          self.agnostic(title: title, desc: desc, sound: "planner.caf", id: "planner-a-\(id)", date: time)
          
          switch(type) {
          case "Homework":
               title = "Homework Due"
               desc = "\(name) for \(courseName) \(semanticSubject) due today"
          case "Project":
               title = "Project Due"
               desc = "\(name) for \(courseName) \(semanticSubject) due today"
          case "Assessment":
               title = "Assessment Reminder"
               desc = "\(name) in \(courseName) \(semanticSubject) today"
          case "Event":
               title = "Event Reminder"
               if(courseName != "After School") {
                    desc = "\(name) in \(courseName) \(semanticSubject) today"
               } else {
                    desc = "\(name) \(semanticSubject) \(courseName) today"
               }
          default:
               title = "Assignment Due"
               desc = "\(name) for \(courseName) \(semanticSubject) due today"
          }
          
          self.agnostic(title: title, desc: desc, sound: "planner.caf", id: "planner-b-\(id)", date: secondTime)
     }
     
     static func remove(plannerID id: Int) {
          UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers : ["planner-a-\(id)","planner-b-\(id)"])
     }
}
