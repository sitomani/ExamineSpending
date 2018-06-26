//
//  AppDelegate.swift
//  ExamineSpending
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyBeaver

let clientRedirectURI = "http://httpbin.org/get"
let sessionManager = SessionManager.default
let log = SwiftyBeaver.self

let debitColor =  UIColor.init(red: 200/255, green: 44/255, blue: 55/255, alpha: 1)
let creditColor = UIColor.init(red: 88/255, green: 126/255, blue: 49/255, alpha: 1)

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    setupLogging()
    return true
  }

  func setupLogging() {
    let console = ConsoleDestination()  // log to Xcode Console
    // use custom format and set console output to short time, log level & message
    console.format = "$DHH:mm:ss $d $L $N.$F $M"
    console.levelString.error = "🛑"
    console.levelString.warning = "🔶"
    console.levelString.info = "🔷"
    console.levelString.debug = "◾️"
    console.levelString.verbose = "◽️"
    log.addDestination(console)

    console.minLevel = .warning
    #if DEBUG
      console.minLevel = .debug
    #endif
    log.info("Logger initialized")
  }
}

protocol DismissalDelegate: class {
  func finishedShowing(viewController: UIViewController, result: [String: Any?]?)
}

protocol Dismissable: class {
  var dismissalDelegate: DismissalDelegate? { get set }
}
