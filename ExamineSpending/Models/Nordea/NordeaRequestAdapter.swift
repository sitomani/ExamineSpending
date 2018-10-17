//
//  NordeaRequestAdapter.swift
//  ExamineSpending
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import Foundation
import Foundation
import Alamofire

/**
 * Nordea specific request adaptation layer
 */
class NordeaRequestAdapter: RequestAdapter, ESObjectFactory {

  //TODO: Update your Nordea API key and secret here. Obtain from https://developer.nordeaopenbanking.com/
  let clientId = ""
  let clientSecret = ""

  var auth: Authorization?

  func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
    log.verbose("")
    var urlReq = urlRequest

    let bodyString: String?
    if let bodyData = urlRequest.httpBody {
      urlReq.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
      bodyString = String.init(data: bodyData, encoding: .utf8)
    } else {
      urlReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
      bodyString = nil
    }

    if urlReq.url?.absoluteString.contains("/authorize?") == false {
      urlReq.setValue(clientId, forHTTPHeaderField: "X-IBM-Client-Id")
      urlReq.setValue(clientSecret, forHTTPHeaderField: "X-IBM-Client-Secret")
    }

    if urlReq.url?.absoluteString.contains("/authorize") == false {
      if let token = auth?.accessToken {
        urlReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
      }
    }

    var logString = "\(urlReq.httpMethod ?? "<unknown_method>") \(urlReq)"
    if bodyString != nil {
      logString += " data: \(bodyString!)"
    }
    log.debug(logString)
    return urlReq
  }

  func accountObject() -> ESAccount.Type {
    return NordeaAccount.self
  }

  func transactionObject() -> ESTransaction.Type {
    return NordeaTransaction.self
  }

  func loginWorkerObject() -> LoginWorker.Type {
    return NordeaLoginWorker.self
  }
}
