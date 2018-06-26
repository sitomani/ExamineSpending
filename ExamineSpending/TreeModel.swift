//
//  TreeModel.swift
//  ExamineSpending
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import Foundation

enum RangeOption: Int {
  case currentDay
  case pastSevenDays
  case currentMonth
  case pastThirtyDays
}

struct DateRange {
  var startDate: Date
  var endDate: Date

  init() {
    self.startDate = Date()
    self.endDate = Date()
  }

  init(startDate: Date, endDate: Date) {
    self.startDate = startDate
    self.endDate = endDate
  }

  init(range: RangeOption) {
    switch range {
    case .currentDay:
      self.startDate = Date()
      self.endDate = Date()
    case .currentMonth:
      let calendar = Calendar.current
      let parts = calendar.dateComponents([.year, .month], from: Date())
      self.startDate = calendar.date(from: parts) ?? Date()
      var parts2 = DateComponents()
      parts2.month = 1
      parts2.day = -1
      self.endDate = calendar.date(byAdding: parts2, to: startDate) ?? Date()
    case .pastSevenDays:
      self.startDate = Date().addingTimeInterval(-7*24*60*60)
      self.endDate = Date()
    case .pastThirtyDays:
      self.startDate = Date().addingTimeInterval(-30*24*60*60)
      self.endDate = Date()
    }
  }
}

enum NodeType {
  case expandableAccount
  case restrictedAccount
  case groupSummary
  case transaction
}

class ESNode {
  var objectId: String?
  var nodeType: NodeType
  var title: String
  var amount: Double
  var currency: String
  var valueType: ESValueType
  var children: [ESNode] = []

  init(txn: ESTransaction) {
    self.nodeType = .transaction
    self.objectId = txn.transactionId
    self.amount = Double(txn.amount) ?? 0
    self.valueType = txn.type == ESTransactionType.credit ? .credit : .debit
    if self.valueType == .credit {
      self.title = txn.debtorName ?? txn.description
    } else {
      self.title = txn.creditorName ?? txn.description
    }
    self.currency = txn.currency
  }

  init(account: ESAccount) {
    if account.transactionsAccess == .available {
      self.nodeType = .expandableAccount
    } else {
      self.nodeType = .restrictedAccount
    }
    self.title = account.accountName
    self.objectId = account.accountId
    self.amount = Double(account.balance) ?? 0
    self.currency = account.currency
    self.valueType = self.amount > 0 ? .credit : .debit
  }

  init(title: String, amount: Double, valueType: ESValueType, currency: String) {
    self.title = title
    self.amount = amount
    self.currency = currency
    self.valueType = valueType
    self.nodeType = .groupSummary
  }

  func totalValue() -> Double {
    if self.nodeType == .expandableAccount {
      return self.amount
    }

    var val = self.amount
    if self.children.count == 0 {
      val = self.amount
    } else {
      val = self.children.reduce(0) { (prev, node) -> Double in
        return prev + node.totalValue()
      }
    }
    return val
  }

  func addChild(node: ESNode) {
    children.append(node)
  }

  func removeChildren() {
    children.removeAll()
  }

  func search(title: String, valueType: ESValueType, currency: String) -> ESNode? {
    if title == self.title && valueType == self.valueType && currency == self.currency {
      return self
    }

    for child in children {
      if let found = child.search(title: title, valueType: valueType, currency: currency) {
        return found
      }
    }
    return nil
  }
}
