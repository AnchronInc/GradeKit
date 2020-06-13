//
//  Configs.swift
//  SimpleGrades
//
//  Created by Michael on 9/9/18.
//  Copyright © 2018 Anchron Inc. All rights reserved.
//

import Foundation
import UIKit
import ChameleonFramework

public struct DistrictConfig {
     var name : String
     var signin : String
     var signinplaceholder : String
     var system : StudentInformationSystemType
     var url : String
     var semesters : Bool
     var useID : Bool
}
public enum StudentInformationSystemType {
     case hac
     case genesis
}

public let configs = [
                      "d303" : DistrictConfig(name: "D303",
                                 signin: "with your D303 HAC account",
                                 signinplaceholder : "HAC Username",
                                 system: .hac,
                                 url: "https://istudent.d303.org/HomeAccess/",
                                 semesters: true,
                                 useID: true),
                      "sparta" : DistrictConfig(name: "Sparta",
                                   signin: "with your Sparta Parent account",
                                   signinplaceholder : "Parent Username",
                                   system: .genesis,
                                   url: "https://parents.sparta.org/sparta/",
                                   semesters: false,
                                   useID: false)
                    ]

public func gradientColor(fromName colorName : String, frame : CGRect) -> UIColor {
     if(colorName.lowercased() == "red") {
          return UIColor(gradientStyle:UIGradientStyle.topToBottom, withFrame:frame, andColors:[UIColor.flatRed, UIColor.flatRedDark])
     }
     else if(colorName.lowercased() == "green") {
          return UIColor(gradientStyle:UIGradientStyle.topToBottom, withFrame:frame, andColors:[UIColor.flatGreen, UIColor.flatGreenDark])
     }
     else if(colorName.lowercased() == "blue") {
          return UIColor(gradientStyle:UIGradientStyle.topToBottom, withFrame:frame, andColors:[UIColor.flatSkyBlue, UIColor.flatSkyBlueDark])
     }
     else if(colorName.lowercased() == "yellow") {
          return UIColor(gradientStyle:UIGradientStyle.topToBottom, withFrame:frame, andColors:[UIColor.flatYellow, UIColor.flatYellowDark])
     }
     else if(colorName.lowercased() == "darkpurple") {
          return UIColor(gradientStyle:UIGradientStyle.topToBottom, withFrame:frame, andColors:[UIColor.flatPurple, UIColor.flatPurpleDark])
     }
     else if(colorName.lowercased() == "plum") {
          return UIColor(gradientStyle:UIGradientStyle.topToBottom, withFrame:frame, andColors:[UIColor.flatPlum, UIColor.flatPlumDark])
     }
     else if(colorName.lowercased() == "teal") {
          return UIColor(gradientStyle:UIGradientStyle.topToBottom, withFrame:frame, andColors:[UIColor.flatTeal, UIColor.flatTealDark])
     }
     else if(colorName.lowercased() == "mint") {
          return UIColor(gradientStyle:UIGradientStyle.topToBottom, withFrame:frame, andColors:[UIColor.flatMint, UIColor.flatMintDark])
     }
     else if(colorName.lowercased() == "lightpink") {
          return UIColor(gradientStyle:UIGradientStyle.topToBottom, withFrame:frame, andColors:[UIColor.flatPink, UIColor.flatPink])
     }
     else if(colorName.lowercased() == "darkblue") {
          return UIColor(gradientStyle:UIGradientStyle.topToBottom, withFrame:frame, andColors:[UIColor.flatBlue, UIColor.flatBlueDark])
     }
     else if(colorName.lowercased() == "coffee") {
          return UIColor(gradientStyle:UIGradientStyle.topToBottom, withFrame:frame, andColors:[UIColor.flatCoffee, UIColor.flatCoffeeDark])
     }
     else if(colorName.lowercased() == "black") {
          return UIColor(gradientStyle:UIGradientStyle.topToBottom, withFrame:frame, andColors:[UIColor.flatBlack, UIColor.flatBlackDark])
     }
     else if(colorName.lowercased() == "orange") {
          return UIColor(gradientStyle:UIGradientStyle.topToBottom, withFrame:frame, andColors:[UIColor.flatOrange, UIColor.flatRed])
     }
     else if(colorName.lowercased() == "pink") {
          return UIColor(gradientStyle:UIGradientStyle.topToBottom, withFrame:frame, andColors:[UIColor.flatWatermelon, UIColor.flatWatermelonDark])
     }
     else if(colorName.lowercased() == "gray") {
          return UIColor(gradientStyle:UIGradientStyle.topToBottom, withFrame:frame, andColors:[UIColor.flatGray, UIColor.flatGrayDark])
     }
     else {
          return UIColor(gradientStyle:UIGradientStyle.topToBottom, withFrame:frame, andColors:[UIColor.flatMagenta, UIColor.flatMagentaDark])
     }
}
