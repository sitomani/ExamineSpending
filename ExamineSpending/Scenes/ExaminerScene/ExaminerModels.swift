//
//  ExaminerModels.swift
//  ExamineSpending
//
//  Copyright (c) 2018 Aleksi Sitomaniemi. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit

struct Block {
  var valueType: ESValueType
  var expandable: Bool
  var amount: String
  var title: String
}

enum Examiner {
  // MARK: Use cases
  enum TxnFetch {
    struct Request {
      var accountId: String
      var rangeOption: RangeOption = .currentDay
      var continuationKey: String?
    }
    struct Response {
      var error: Error?
      var data: Data?
    }
    struct ViewModel {
      var title: String
      var pathlen: Int
      var blocks: [Block]
    }
  }

  enum Expand {
    struct Request {
      var groupIndex: Int
    }
    struct Response {
      var nodes: [ESNode]
    }
    struct ViewModel {
      var txns: [Block]
    }
  }

  enum Collapse {
    struct Request {
    }
    struct Response {
      var nodes: [ESNode]
    }
    struct ViewModel {
      var txns: [Block]
    }
  }

  enum Progress {
    struct Response {
      var txnCount: Int
      var range: RangeOption
    }

    struct ViewModel {
      var progressInfo: String
    }
  }
}
