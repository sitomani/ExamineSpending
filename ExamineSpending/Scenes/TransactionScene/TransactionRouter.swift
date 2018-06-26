//
//  TransactionRouter.swift
//  ExamineSpending
//
//  Copyright (c) 2018 Aleksi Sitomaniemi. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit

// No routing logic in Transaction View but protocol kept for symmetry
@objc protocol TransactionRoutingLogic {
}

protocol TransactionDataPassing {
  var dataStore: TransactionDataStore? { get }
}

class TransactionRouter: NSObject, TransactionRoutingLogic, TransactionDataPassing {
  weak var viewController: TransactionViewController?
  var dataStore: TransactionDataStore?
}
