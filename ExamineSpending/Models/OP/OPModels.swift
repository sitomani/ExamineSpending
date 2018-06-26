//
//  OPModels.swift
//  ExamineSpending
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import Foundation

struct OPAccount: Decodable, ESAccount {
  var accountNumber: String {
    return iban
  }

  var balance: String {
    return String(opBalance)
  }

  var available: String {
    return String(amountAvailable)
  }

  var transactionsAccess: ESAccess = .available

  static func buildFromData(_ data: Data) -> [ESAccount]? {
    if let accts = try? JSONDecoder().decode([OPAccount].self, from: data) {
      return accts
    } else {
      log.error("JSON parsing failed")
      return []
    }
  }

  let accountId, iban, bic, accountName: String
  let opBalance, amountAvailable: Double
  let currency: String

  enum CodingKeys: String, CodingKey {
    case accountId, iban, bic, accountName, amountAvailable, currency
    case opBalance = "balance"
  }
}

struct OPTransaction: Decodable, ESTransaction {
  var transactionId: String
  var type: ESTransactionType {
    return opAmount < 0 ? .debit : .credit
  }
  var amount: String {
      return String(opAmount)
  }
  var debtorName: String?
  var creditorName: String?
  var description: String {
      return payer
  }

  static func buildFromData(_ data: Data) -> ([ESTransaction], String?)? {
    do {
      let transactions = try JSONDecoder().decode([OPTransaction].self, from: data)
      return (transactions, nil)
    } catch {
      log.error("JSON parsing failed \(error)")
      return ([], nil)
    }
  }

  let valueDate, bookingDate: String
  let opAmount: Double
  let currency, payer, purpose: String
  let reference, message: String?
  let accountID: String

  enum CodingKeys: String, CodingKey {
    case opAmount = "amount"
    case transactionId, valueDate, bookingDate, currency, payer, reference, purpose, message
    case accountID = "accountId"
  }
}
