/*
 * Copyright 2010-2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

import UIKit
import AWSS3
import AWSMobileClient

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     handleEventsForBackgroundURLSession identifier: String,
                     completionHandler: @escaping () -> Void) {
        
        
        //provide the completionHandler to the TransferUtility to support background transfers.
        AWSS3TransferUtility.interceptApplication(application,
                                                  handleEventsForBackgroundURLSession: identifier,
                                                  completionHandler: completionHandler)
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        AWSDDLog.sharedInstance.logLevel = .debug
        AWSDDLog.add(AWSDDTTYLogger.sharedInstance)
        let _ = Manager.shared
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("AppDelegate.applicationDidBecomeActive()")
        Manager.shared.handleForeground()
    }
}
