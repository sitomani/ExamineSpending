//
//  RESTRoutes.swift
//  ExamineSpending
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import Foundation
import Alamofire

enum RESTRoutes: URLRequestConvertible {
  //Router paths
  case authcode(clientId: String, scenario: AuthenticationMode)
  case token(code: String)
  case accounts
  case transactions(account: String, startDate: Date?, endDate: Date?, contKey: String?)

  //URL root and account api version are set in each bank specific loginworker implementation
  static var urlRoot: String = ""
  static var accountAPIVersion: String = ""

  var method: HTTPMethod {
    switch self {
    case .token:
      return .post
    default:
      return .get
    }
  }

  var route: (path: String, parameters: [String: Any]?) {
    switch self {
    case .authcode(let clientId, let scenario):
      return ("v1/authentication?client_id=\(clientId)&redirect_uri=\(clientRedirectURI)&X-Response-Scenarios=\(scenario.rawValue)&state=", nil)
    case .token(let code):
      return ("v1/authentication/access_token", ["code": code, "redirect_uri": clientRedirectURI])
    case .accounts:
      return (RESTRoutes.accountAPIVersion + "/accounts", nil)
    case .transactions(let accountId, let fromDate, let toDate, let continuationKey):
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy-MM-dd"

      var endpoint = RESTRoutes.accountAPIVersion + "/accounts/\(accountId)/transactions"
      if let start = fromDate, let end = toDate {
        let fromString = dateFormatter.string(from: start)
        let endString = dateFormatter.string(from: end)
        endpoint = "\(endpoint)?fromDate=\(fromString)&toDate=\(endString)"
      }
      if let ckey = continuationKey {
        endpoint = "\(endpoint)&continuationKey=\(ckey)"
      }
      return (endpoint, nil)
    }
  }

  var encoding: Alamofire.ParameterEncoding {
    switch self.method {
    case .post, .put:
      return Alamofire.URLEncoding.default
    default:
      return Alamofire.URLEncoding.default
    }
  }

  //URLRequestConvertible protocol implementation
  func asURLRequest() throws -> URLRequest {
    guard let url = URL.init(string: self.route.path, relativeTo: URL.init(string: RESTRoutes.urlRoot)) else {
      throw NSError.init()
    }

    var request = URLRequest(url: url)
    request.httpMethod = self.method.rawValue

    let urlRequest = try self.encoding.encode(request, with: route.parameters)
    return urlRequest
  }
}
