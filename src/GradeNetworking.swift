//
//  GradeNetworking.swift
//  SimpleGrades
//
//  Created by Michael Caruso on 9/14/17.
//  Copyright © 2017 Anchron Inc. All rights reserved.
//

import Foundation
import UIKit

public typealias Parameters = [String: Any]
public typealias Headers = [String: String]

class GradeNetworking {
     static func post(_ url : String, parameters: Parameters, completion: @escaping (_ response: String?) -> ()) {
               toggleActivityIndicator(true)
               let queue = OperationQueue()
          
               let delegate = SessionDelegate()
               let sessionConfig = URLSessionConfiguration.background(withIdentifier: "com.anchron.simplegrades-\(UUID())")
               sessionConfig.httpCookieAcceptPolicy = .always
               sessionConfig.httpCookieStorage = HTTPCookieStorage.shared
               sessionConfig.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData

               let session = URLSession(configuration: sessionConfig, delegate: delegate, delegateQueue: queue)
               delegate.completion = {(data : Data?, response : URLResponse?, err : Error?) in
                    toggleActivityIndicator(false)
                    if err == nil, let data = data {
                         if let rs = String(data: data, encoding: .utf8) {
                              completion(rs)
                         } else {
                              completion(nil)
                         }
                    }
                    else {
                         completion(nil)
                    }
                    session.invalidateAndCancel()
               }
               var dataRequest : URLRequest = URLRequest(url: URL(string: url)!)
               dataRequest.httpMethod = "POST"
          
               dataRequest.httpBody = query(parameters).data(using: .utf8, allowLossyConversion: false)
               dataRequest.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
               let task = session.dataTask(with: dataRequest)
               task.resume()
     }
     static func post(_ url : String, body: String, completion: @escaping (_ response: String?) -> ()) {
          toggleActivityIndicator(true)
          let queue = OperationQueue()
          
          let delegate = SessionDelegate()
          let sessionConfig = URLSessionConfiguration.background(withIdentifier: "com.anchron.simplegrades-\(UUID())")
          sessionConfig.httpCookieAcceptPolicy = .always
          sessionConfig.httpCookieStorage = HTTPCookieStorage.shared
          sessionConfig.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
          
          let session = URLSession(configuration: sessionConfig, delegate: delegate, delegateQueue: queue)
          delegate.completion = {(data : Data?, response : URLResponse?, err : Error?) in
               toggleActivityIndicator(false)
               if err == nil, let data = data {
                    if let rs = String(data: data, encoding: .utf8) {
                         completion(rs)
                    } else {
                         completion(nil)
                    }
               }
               else {
                    completion(nil)
               }
               session.invalidateAndCancel()
          }
          var dataRequest : URLRequest = URLRequest(url: URL(string: url)!)
          dataRequest.httpMethod = "POST"
          
          dataRequest.httpBody = body.data(using: .utf8, allowLossyConversion: false)
          let task = session.dataTask(with: dataRequest)
          task.resume()
     }
     
     static func login(_ url : String, parameters: Parameters, completion: @escaping (_ response: String?) -> ()) {
          
          toggleActivityIndicator(true)
          let queue = OperationQueue()
          
          let delegate = SessionDelegate()
          let sessionConfig = URLSessionConfiguration.default
          sessionConfig.httpCookieAcceptPolicy = .always
          sessionConfig.httpCookieStorage = HTTPCookieStorage.shared
          sessionConfig.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
          let session = URLSession(configuration: sessionConfig, delegate: delegate, delegateQueue: queue)
          delegate.completion = {(data : Data?, response : URLResponse?, err : Error?) in
               toggleActivityIndicator(false)
               if err == nil, let data = data {
                    if let rs = String(data: data, encoding: .utf8) {
                         completion(rs)
                    } else {
                         completion(nil)
                    }
               }
               else {
                    completion(nil)
               }
               session.invalidateAndCancel()
          }
          var dataRequest : URLRequest = URLRequest(url: URL(string: url)!)
          dataRequest.httpMethod = "POST"
          
          dataRequest.httpBody = query(parameters).data(using: .utf8, allowLossyConversion: false)
          dataRequest.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
          let task = session.dataTask(with: dataRequest)
          task.resume()
     }
     static func get(_ url : String, completion: @escaping (_ response: String?) -> ()) {
               toggleActivityIndicator(true)
               let queue = OperationQueue()
               
               let delegate = SessionDelegate()
               let sessionConfig = URLSessionConfiguration.background(withIdentifier: "com.anchron.simplegrades-\(UUID())")
               sessionConfig.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData

               let session = URLSession(configuration: sessionConfig, delegate: delegate, delegateQueue: queue)
               delegate.completion = {(data : Data?, response : URLResponse?, err : Error?) in
                    toggleActivityIndicator(false)
                    if err == nil, let data = data, let response = response, (response as! HTTPURLResponse).statusCode == 200 {
                         if let rs = String(data: data, encoding: .utf8) {
                              completion(rs)
                         }
                         else if let rs = String(data: data, encoding: .isoLatin1) {
                              completion(rs)
                         } else {
                              completion(nil)
                         }
                    }
                    else {
                         completion(nil)
                    }
                    session.invalidateAndCancel()
               }
               let dataRequest : URLRequest = URLRequest(url: URL(string: url)!)
               
               let task = session.dataTask(with: dataRequest)
               task.resume()
     }
     
     static func getJSON(_ url : String, headers: Headers, completion: @escaping (_ text: NSDictionary?, _ statusCode : Int?, _ error: GNError?) -> ()) {
          toggleActivityIndicator(true)
          let queue = OperationQueue()
          let delegate = SessionDelegate()
          let sessionConfig = URLSessionConfiguration.background(withIdentifier: "com.anchron.simplegrades-\(UUID())")
          let session = URLSession(configuration: sessionConfig, delegate: delegate, delegateQueue: queue)
          delegate.completion = {(data : Data?, response : URLResponse?, err : Error?) in
               toggleActivityIndicator(false)
               if let data = data, let response = response, (response as! HTTPURLResponse).statusCode == 200 {
                    if let json = try? JSONSerialization.jsonObject(with: data) {
                         completion(json as? NSDictionary, (response as? HTTPURLResponse)?.statusCode, nil)
                    } else {
                         completion(nil, nil, .parse)
                    }
               }
               else {
                    completion(nil, nil, .network)
               }
               session.invalidateAndCancel()
          }
          var dataRequest : URLRequest = URLRequest(url: URL(string: url)!)
          for (header, value) in headers {
               dataRequest.addValue(value, forHTTPHeaderField: header)
          }
          let task = session.dataTask(with: dataRequest)
          task.resume()
     }
     
     static func download(_ url: String, to localUrl: URL, completion: @escaping (_ error: GNError?) -> ()) {
          let sessionConfig = URLSessionConfiguration.default
          let session = URLSession(configuration: sessionConfig)
          let request = URLRequest(url: URL(string: url)!)
          let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
               if let tempLocalUrl = tempLocalUrl, error == nil {
                    do {
                         try FileManager.default.removeItem(at: localUrl)
                    } catch {}
                    
                    do {
                         try FileManager.default.copyItem(at: tempLocalUrl, to: localUrl)
                         completion(nil)
                    } catch {
                         completion(.file)
                    }
                    
               } else {
                    completion(.network)
               }
          }
          task.resume()
     }
     
     //from ALAMOFIRE
     public static func query(_ parameters: [String: Any]) -> String {
          var components: [(String, String)] = []
          
          for key in parameters.keys.sorted(by: <) {
               let value = parameters[key]!
               components += queryComponents(fromKey: key, value: value)
          }
          return components.map { "\($0)=\($1)" }.joined(separator: "&")
     }
     private static func queryComponents(fromKey key: String, value: Any) -> [(String, String)] {
          var components: [(String, String)] = []
          
          if let dictionary = value as? [String: Any] {
               for (nestedKey, value) in dictionary {
                    components += queryComponents(fromKey: "\(key)[\(nestedKey)]", value: value)
               }
          } else if let array = value as? [Any] {
               for value in array {
                    components += queryComponents(fromKey: "\(key)[]", value: value)
               }
          } else if let value = value as? NSNumber {
               if value.isBool {
                    components.append((escape(key), escape((value.boolValue ? "1" : "0"))))
               } else {
                    components.append((escape(key), escape("\(value)")))
               }
          } else if let bool = value as? Bool {
               components.append((escape(key), escape((bool ? "1" : "0"))))
          } else {
               components.append((escape(key), escape("\(value)")))
          }
          
          return components
     }
     
     private static func escape(_ string: String) -> String {
          let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
          let subDelimitersToEncode = "!$&'()*+,;="
          
          var allowedCharacterSet = CharacterSet.urlQueryAllowed
          allowedCharacterSet.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
          
          var escaped = ""
          
          //==========================================================================================================
          //
          //  Batching is required for escaping due to an internal bug in iOS 8.1 and 8.2. Encoding more than a few
          //  hundred Chinese characters causes various malloc error crashes. To avoid this issue until iOS 8 is no
          //  longer supported, batching MUST be used for encoding. This introduces roughly a 20% overhead. For more
          //  info, please refer to:
          //
          //      - https://github.com/Alamofire/Alamofire/issues/206
          //
          //==========================================================================================================
          if #available(iOS 8.3, *) {
               escaped = string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? string
          } else {
               let batchSize = 50
               var index = string.startIndex
               
               while index != string.endIndex {
                    let startIndex = index
                    let endIndex = string.index(index, offsetBy: batchSize, limitedBy: string.endIndex) ?? string.endIndex
                    let range = startIndex..<endIndex
                    
                    let substring = string[range]
                    
                    escaped += substring.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? String(substring)
                    
                    index = endIndex
               }
          }
          
          return escaped
     }
     static private func percentEscape(_ urlParameter : Any) -> String
     {
          return "\(urlParameter)".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
     }
     static private func toggleActivityIndicator(_ state : Bool) {
          DispatchQueue.main.async {
               UIApplication.shared.isNetworkActivityIndicatorVisible = state
          }
     }
}

//Also from Alamofire
extension NSNumber {
     fileprivate var isBool: Bool { return CFBooleanGetTypeID() == CFGetTypeID(self) }
}

class SessionDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate,
URLSessionDataDelegate{
     public var requestTime:TimeInterval?
     public var response:URLResponse?
     public var completion:((Data?, URLResponse?, Error?) -> Void)?
     var responseData = NSMutableData()
     
     public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask,
                            didReceive response: URLResponse,
                            completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
          self.response = response
          completionHandler(.allow)
     }
     
     public func urlSession(_ session: URLSession, task: URLSessionTask,
                            didCompleteWithError error: Error?) {
          if let completion = completion {
               completion(responseData as Data, task.response, error)
          }
     }
     
     public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask,
                            didReceive data: Data) {
          responseData.append(data)
     }
}

