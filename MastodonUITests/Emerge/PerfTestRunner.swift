import UIKit
import XCTest

@objc public class PerfTestRunner: NSObject {
  
    @objc public static func runAllPerfTestsForBundle(ofClass classInBundle: AnyClass) {
        let imageName = class_getImageName(classInBundle)!
        var outCount: UInt32 = 0
        let classNames = objc_copyClassNamesForImage(imageName, &outCount)!
        for i in 0..<Int(outCount) {
            let className = classNames[i]
            let aClass = objc_getClass(className)
          
            if let perfTestClass = aClass as? EMGPerfTest.Type {
                let objcClass = perfTestClass as! NSObject.Type
                let test = objcClass.init() as! EMGPerfTest
                print("🚀 EMERGE: Testing perf test class \(String(describing: perfTestClass))")
                print("🚀 EMERGE: Running initial setup for \(String(describing: perfTestClass))")
                
                let setupApp = makeSetupApplication(forTest: test)
                test.runInitialSetup(withApp: setupApp)
              
                print("🚀 EMERGE: Running two iterations for \(String(describing: perfTestClass))")
                for i in 0..<3 {
                    print("🚀 EMERGE: Iteration \(i + 1)")
                    let app = makeRunIterationApplication(forTest: test, iteration: i)
                    test.runIteration(withApp: app)
                    print("🚀 EMERGE: Finished iteration")
                }
                print("🚀 EMERGE: Finished testing")
            }
        }
    }
    
    private static func makeSetupApplication(forTest test: EMGPerfTest) -> XCUIApplication {
        let emergeLaunchEnvironment = [
            "EMERGE_CLASS_NAME" : String(describing: test.self),
        ]
        let testLaunchEnvironment = test.launchEnvironmentForSetup?() ?? [:]
        let mergedLaunchEnvironments = emergeLaunchEnvironment.merging(testLaunchEnvironment) { (emergeValue, _) in emergeValue }
        
        let launchArguments = test.launchArgumentsForSetup?() ?? []
        return makeApplication(forTest: test, environment: mergedLaunchEnvironments, launchArguments: launchArguments)
    }
    
    private static func makeRunIterationApplication(forTest test: EMGPerfTest, iteration: Int) -> XCUIApplication {
        var emergeLaunchEnvironment = [
            "EMERGE_CLASS_NAME" : String(describing: test.self),
            "EMERGE_IS_PERFORMANCE_TESTING" : "1",
        ]
        if iteration == 0 {
            // Don't replay/record for the first iteration
        } else if iteration == 1 {
            emergeLaunchEnvironment["EMG_RECORD_NETWORK"] = "1"
        } else {
            emergeLaunchEnvironment["EMG_REPLAY_NETWORK"] = "1"
        }
        
        let testLaunchEnvironment = test.launchEnvironmentForIterations?() ?? [:]
        let mergedLaunchEnvironments = emergeLaunchEnvironment.merging(testLaunchEnvironment) { (emergeValue, _) in emergeValue }
        
        let launchArguments = test.launchArgumentsForIterations?() ?? []
        return makeApplication(forTest: test, environment: mergedLaunchEnvironments, launchArguments: launchArguments)
    }
    
    private static func makeApplication(forTest test: EMGPerfTest, environment: [String : String], launchArguments: [String]) -> XCUIApplication {
        let setupApp = XCUIApplication()
        setupApp.launchEnvironment = environment
        setupApp.launchArguments = launchArguments
        setupApp.launch()
        return setupApp
    }
  
}
