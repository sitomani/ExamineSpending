//
//  NordeaModels.swift
//  ExamineSpending
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import Foundation

// Authorization token model
struct Authorization: Decodable {
  var accessToken: String
  var expiresIn: Int
  var tokenType: String
  enum CodingKeys: String, CodingKey {
    case accessToken = "access_token"
    case expiresIn = "expires_in"
    case tokenType = "token_type"
  }
}

struct NordeaAccountNumber: Decodable {
  let value, type: String

  enum CodingKeys: String, CodingKey {
    case value
    case type = "_type"
  }
}

struct Link: Decodable {
  let rel, href: String
}

struct NordeaRootElement: Decodable {
  let nordeaResponse: NordeaResponse
  enum CodingKeys: String, CodingKey {
    case nordeaResponse = "response"
  }
}

struct NordeaResponse: Decodable {
  let accounts: [NordeaAccount]?
  let transactions: [NordeaTransaction]?
  let continuationKey: String?
  let links: [Link]?

  enum CodingKeys: String, CodingKey {
    case transactions
    case accounts
    case continuationKey = "_continuationKey"
    case links = "_links"
  }
}

struct NordeaAccount: Decodable, ESAccount {
  static func buildFromData(_ data: Data) -> [ESAccount]? {
    do {
      let rootElement = try JSONDecoder().decode(NordeaRootElement.self, from: data)
      return rootElement.nordeaResponse.accounts
    } catch {
      log.error("JSON parsing failed, \(error)")
    }
    return nil
  }

  var accountNumber: String {
    return nordeaAccountNumber.value
  }

  var accountName: String {
    return accountId
  }

  var balance: String {
    if bookedBalance == nil {
      log.error("Account \(accountNumber) has no balance")
    }
    return bookedBalance ?? "0.00"
  }

  var available: String {
    return availableBalance ?? balance
  }

  var transactionsAccess: ESAccess {
    return links.count > 0 ? .available : .restricted
  }

  let accountId, country: String
  let nordeaAccountNumber: NordeaAccountNumber
  let currency, ownerName, product, accountType: String
  let bookedBalance, availableBalance, valueDatedBalance: String?
  let links: [Link]

  enum CodingKeys: String, CodingKey {
    case accountId = "_id"
    case country, currency, ownerName, product, accountType, bookedBalance, valueDatedBalance, availableBalance
    case links = "_links"
    case nordeaAccountNumber = "accountNumber"
  }
}

// Transaction Response Model
struct NordeaTransaction: Decodable, ESTransaction {

  //ESTransaction Wrapping interfaces
  static func buildFromData(_ data: Data) -> ([ESTransaction], String?)? {
    do {
      let rootElement: NordeaRootElement = try JSONDecoder().decode(NordeaRootElement.self, from: data)
      let txns = rootElement.nordeaResponse.transactions
      return (txns!, rootElement.nordeaResponse.continuationKey)
    } catch {
      log.error("JSON parsing failed \(error)")
    }
    return ([], nil)
  }

  var transactionId: String {
    return transactionID
  }

  var description: String {
    return typeDescription
  }

  let type: ESTransactionType
  let transactionID: String
  let currency: String
  var bookingDate, valueDate: String
  let typeDescription: String
  let amount: String
  let creditorName, debtorName, message, narrative: String?

  enum CodingKeys: String, CodingKey {
    case type = "_type"
    case transactionID = "transactionId"
    case currency, bookingDate, valueDate, typeDescription, message, amount, creditorName, debtorName, narrative
  }
}
