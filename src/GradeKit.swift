import Foundation
import KeychainSwift

public class GradeKit {
     
     @available(*, deprecated, renamed: "current()")
     public static let hac = HomeAccessCenter()
     private static let genesis = Genesis()
     private static let unselected = UnselectedSystem()
     
     private static var currentCFG : DistrictConfig? = nil
     
     public static func current() -> StudentInformationSystem {
          if let cfg = currentCFG, cfg.system == .genesis {
               return genesis
          }
          if let cfg = currentCFG, cfg.system == .hac {
               return hac
          } else {
               return unselected
          }
     }
     public static func config() -> DistrictConfig? {
          if let cfg = currentCFG {
               return cfg
          } else {
               let keychain = KeychainSwift()
               if let school = keychain.get("selected-school"), let cfg = configs[school] {
                    currentCFG = cfg
                    return cfg
               } else {
                    return nil
               }
          }
     }
     
     public static func config(to: String) {
          if let cfg = configs[to] {
               let keychain = KeychainSwift()
               keychain.set(to, forKey: "selected-school")
               self.currentCFG = cfg
          }
     }
     
     public static func schoolSwitch() {
          let keychain = KeychainSwift()
          keychain.delete("selected-school")
          self.currentCFG = nil
     }
     
     private static var haQCompletion : [() -> ()] = []
     private static var negatoryHAQCompletion : [(GradeError) -> ()] = []
     
     public static func loadEvent() {
          for haQComp in self.haQCompletion {
               haQComp()
          }
     }
     public static func negatoryLoadEvent(err : GradeError) {
          for haQComp in self.negatoryHAQCompletion {
               haQComp(err)
          }
     }
     public static func onLoad(_ eventHandler : @escaping () -> ()) {
          haQCompletion.append(eventHandler)
     }
     public static func onFail(_ eventHandler : @escaping (GradeError) -> ()) {
          negatoryHAQCompletion.append(eventHandler)
     }
     
     
}
