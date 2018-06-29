//
//  OPRequestAdapter.swift
//  ExamineSpending
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import Foundation
import Alamofire

//OP Sandbox API has hard-coded authentication with four different accounts
//You can switch the key to experiment with different datasets
let opTokens = ["6c18c234b1b18b1d97c7043e2e41135c293d0da9",
              "b6910384440ce06f495976f96a162e2ab1bafbb4",
              "7a66629ddf3691a66eb6466ab7a9f610de531047",
              "3af871a0e3ebfc46f375ff2b63d1414982bd4f76"]

/**
 * OP-specific request adaptation layer
 */
class OPRequestAdapter: RequestAdapter, ESObjectFactory {

  //TODO: Update your OP API key here. Obtain from https://op-developer.fi/developers/login
  let opAPIKey: String = ""

  let opToken = opTokens[0]

  var requestId: Int = 0
  var sessionId: UUID = UUID.init()

  func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
    requestId += 1
    var urlReq = urlRequest

    urlReq.setValue(opAPIKey, forHTTPHeaderField: "x-api-key")
    urlReq.setValue(opToken, forHTTPHeaderField: "authorization")
    urlReq.setValue("\(requestId)", forHTTPHeaderField: "x-request-id")
    urlReq.setValue(sessionId.uuidString, forHTTPHeaderField: "x-session-id")
    let logString = "\(urlReq.httpMethod ?? "<unknown_method>") \(urlReq)"
    log.debug(logString)

    return urlReq
  }

  func accountObject() -> ESAccount.Type {
    return OPAccount.self
  }

  func transactionObject() -> ESTransaction.Type {
    return OPTransaction.self
  }
}
