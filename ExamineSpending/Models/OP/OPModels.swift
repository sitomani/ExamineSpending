//
//  OPModels.swift
//  ExamineSpending
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import Foundation

struct OPAccountsRoot: Decodable {
  let data: [OPAccount]
  let meta, links: String
}

struct OPAccount: Decodable, ESAccount {
  var accountNumber: String {
    return identifier
  }

  var available: String {
    return balance
  }

  var transactionsAccess: ESAccess = .available

  static func buildFromData(_ data: Data) -> [ESAccount]? {
    do {
      let root = try JSONDecoder().decode(OPAccountsRoot.self, from: data)
      return root.data
    } catch {
      log.error("JSON parsing failed: \n \(error))")
      return []
    }
  }

  let accountName, type, balance, subType, currency, nickname, accountId, identifier, servicerScheme, identifierScheme, servicerIdentifier: String

  enum CodingKeys: String, CodingKey {
    case type, balance, subType, currency, nickname, accountId, identifier, servicerScheme, identifierScheme, servicerIdentifier
    case accountName = "name"
  }
}

struct OPTransactionsRoot: Decodable {
  let data: [OPTransaction]
  let meta, links: String
}

struct TransactionParty: Codable {
  let accountIdentifier: String
  let accountIdentifierType: String
  let accountName: String
  let servicerIdentifier: String
  let servicerIdentifierType: String
}

struct OPTransaction: Decodable, ESTransaction {
  var bookingDate: String
  var transactionId: String = ""
  var type: ESTransactionType {
    return creditDebitIndicator == "debit" ? .debit : .credit
  }
  var amount: String
  var debtorName: String? {
    return debtor?.accountName ?? ""
  }

  var creditorName: String? {
    return creditor?.accountName ?? "<unknown>"
  }
  var description: String {
      return message
  }

  static func buildFromData(_ data: Data) -> ([ESTransaction], String?)? {
    do {
      let root = try JSONDecoder().decode(OPTransactionsRoot.self, from: data)

      //To fix missing transactionId in OP Transaction data, create an unique id for each transaction
      var transactions: [OPTransaction] = []
      for txn in root.data {
        var myTxn = txn
        if myTxn.transactionId.count == 0 {
          myTxn.transactionId = UUID().uuidString
        }
        transactions.append(myTxn)
      }
      return (transactions, nil)
    } catch {
      log.error("JSON parsing failed \(error)")
      return ([], nil)
    }
  }

  let accountId, archiveId, currency, creditDebitIndicator, accountBalance, valueDateTime, status, transactionAddress: String
  let isoTransactionCode, opTransactionCode, merchantName, merchantCategoryCode, reference, message: String
  let debtor: TransactionParty?
  let creditor: TransactionParty?

  enum CodingKeys: String, CodingKey {
    case amount, accountId, archiveId, currency, creditDebitIndicator, accountBalance, valueDateTime, status, transactionAddress
    case isoTransactionCode, opTransactionCode, merchantName, merchantCategoryCode, reference, message
    case debtor, creditor
    case bookingDate = "bookingDateTime"
  }
}
