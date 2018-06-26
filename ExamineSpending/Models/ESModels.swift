//
//  ESModels.swift
//  ExamineSpending
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import Foundation

enum ESBank {
  case nordea
  case op
}

enum ESAccess {
  case available
  case restricted
}

// Account information models
enum ESValueType: String {
  case debit = "Expenditure"
  case credit = "Income"
}

enum ESTransactionType: String, Decodable {
  case debit = "DebitTransaction"
  case credit = "CreditTransaction"
}

protocol ESObjectFactory {
  func accountObject() -> ESAccount.Type
  func transactionObject() -> ESTransaction.Type
}

protocol ESAccount {
  var accountId: String { get }
  var accountName: String { get }
  var accountNumber: String { get }
  var currency: String { get }
  var balance: String { get }
  var available: String { get }
  var transactionsAccess: ESAccess { get }
  static func buildFromData(_ data: Data) -> [ESAccount]?
}

protocol ESTransaction {
  var transactionId: String { get }
  var type: ESTransactionType { get }
  var bookingDate: String { get }
  var amount: String { get }
  var debtorName: String? { get }
  var creditorName: String? { get }
  var currency: String { get }
  var description: String { get }
  static func buildFromData(_ data: Data) -> ([ESTransaction], String?)?
}

enum ESError: Error {
  case authenticationFailure
  case networkFailure
  case requestFailure(reason: String)
  case noTransactions

  func message() -> String {
    var errorMsg: String
    switch self {
    case .authenticationFailure:
      errorMsg = "Failed to authenticate"
    case .networkFailure:
      errorMsg = "Network error"
    case .requestFailure(let reason):
      errorMsg = "Request failed (\(reason))"
    case .noTransactions:
      errorMsg = "No transactions on this account for given period"
    }
    return errorMsg
  }
}
