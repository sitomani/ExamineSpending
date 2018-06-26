//
//  ExaminerInteractor.swift
//  ExamineSpending
//
//  Copyright (c) 2018 Aleksi Sitomaniemi. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//
import UIKit

protocol ExaminerBusinessLogic {
  func fetchAccounts()
  func expand(request: Examiner.Expand.Request)
  func collapse(request: Examiner.Collapse.Request)
}

protocol ExaminerDataStore {
  var selectedRange: RangeOption { get set }          //Range for transaction fetch
  var transactions: [ESTransaction] { get set }       //Set of all transactions
  var browsingIndex: Int { get set }                  //Index of the selected transaction on current browsing level
  func getFilteredTransactions() -> [ESTransaction]   //Returns transactions on current browsing level
}

class ExaminerInteractor: ExaminerBusinessLogic, ExaminerDataStore {
  var presenter: ExaminerPresentationLogic?
  var browsingIndex: Int = 0
  var selectedRange: RangeOption = .currentDay {
    didSet {
      changeSelectedRange(range: selectedRange)
    }
  }
  var transactions: [ESTransaction] = []

  private var worker: ExaminerWorker?
  private var txnRoot: ESNode
  private var browsingPath: [ESNode] = []

  init() {
    txnRoot = ESNode.init(title: "Accounts", amount: 0, valueType: .credit, currency: "")
    browsingPath = [txnRoot]
  }

  deinit {
    log.debug("")
  }

  func getFilteredTransactions() -> [ESTransaction] {
    let idList = browsingPath.last!.children.map { $0.objectId ?? "" }
    let filteredSet = transactions.filter { txn in
      return idList.contains(where: { $0 == txn.transactionId })
    }

    var adjustCount = 0
    for index in 0...browsingIndex where browsingPath.last!.children[index].nodeType != .transaction {
        adjustCount += 1
    }
    browsingIndex -= adjustCount

    return filteredSet
  }

  // MARK: Actions
  func fetchAccounts() {
    log.verbose("")
    let request = RESTRoutes.accounts
    guard let factoryObject = (sessionManager.adapter as? ESObjectFactory)?.accountObject() else { abort() }
    presenter?.presentRequestActive(true)
    sessionManager.request(request).validate().responseJSON(completionHandler: { restResponse in
      if restResponse.result.isSuccess, let accounts = factoryObject.buildFromData(restResponse.data!) {
        self.buildAccountNodes(accounts: accounts)
        self.presenter?.presentNode(node: self.txnRoot, pathlen: 1, range: nil)
      } else {
        self.presenter?.presentError(error: ESError.requestFailure(reason: restResponse.error?.localizedDescription ?? restResponse.result.description))
      }
    })
  }

  func expand(request: Examiner.Expand.Request) {
    log.verbose("")
    guard request.groupIndex < browsingPath.last!.children.count else {
      log.error("Invalid index on expand request")
      return
    }

    let expandNode = browsingPath.last!.children[request.groupIndex]
    if expandNode.nodeType == .restrictedAccount {
      log.error("Restricted account node")
      self.presenter?.presentError(error: ESError.requestFailure(reason: "Restricted access to this account") )
      return
    }

    switch expandNode.nodeType {
    case .restrictedAccount:
      log.error("Restricted account node")
      return
    case .expandableAccount:
      if expandNode.children.count > 0 {
        browsingPath.append(expandNode)
        self.presenter?.presentNode(node: expandNode, pathlen: browsingPath.count, range: selectedRange)
      } else {
        fetchTransactions(request: Examiner.TxnFetch.Request(accountId: expandNode.objectId ?? "",
                                                             rangeOption: selectedRange,
                                                             continuationKey: nil))
      }
    case .groupSummary:
      browsingPath.append(expandNode)
      self.presenter?.presentNode(node: expandNode, pathlen: browsingPath.count, range: selectedRange)
    case .transaction:
      browsingIndex = request.groupIndex
      self.presenter?.presentNode(node: ESNode.init(txn: transactions.first!), pathlen: browsingPath.count, range: selectedRange)
    }
  }

  func collapse(request: Examiner.Collapse.Request) {
    log.verbose("")
    guard browsingPath.count > 1 else {
      return
    }
    browsingPath.removeLast()
    self.presenter?.presentNode(node: browsingPath.last!, pathlen: browsingPath.count, range: browsingPath.count > 1 ? selectedRange: nil)
  }

  private func changeSelectedRange(range: RangeOption) {
    guard browsingPath.count > 1 else { return }
    guard let selectedAccountId = browsingPath[1].objectId else { return }
    let req = Examiner.TxnFetch.Request(accountId: selectedAccountId, rangeOption: range, continuationKey: nil)
    fetchTransactions(request: req)
  }

  private func buildAccountNodes(accounts: [ESAccount]) {
    for acct in accounts {
      let node = ESNode.init(account: acct)
      txnRoot.addChild(node: node)
    }
  }

  private func fetchTransactions(request: Examiner.TxnFetch.Request) {
    let dateRange = DateRange(range: request.rangeOption)
    presenter?.presentRequestActive(true)
    worker = ExaminerWorker()
    worker?.delegate = self
    worker?.fetchTransactions(accountId: request.accountId, dateRange: dateRange, continuationKey: nil)
  }
}

extension ExaminerInteractor: ExaminerWorkerDelegate {
  func transactionsFetchFailed(worker: ExaminerWorker, error: ESError) {
    log.verbose("")
    presenter?.presentError(error: error)
  }

  func transactionsReceived(worker: ExaminerWorker, fetchComplete: Bool) -> Bool {
    log.verbose("")
    if fetchComplete {
      guard let accountRoot = txnRoot.children.first(where: { node in
        return node.objectId == worker.accountId
      }) else { return false }

      guard worker.fetchedTransactions.count > 0 else {
        presenter?.presentError(error: .noTransactions)
        return false
      }

      transactions = worker.fetchedTransactions
      accountRoot.removeChildren()

      //Clean the browsing path for rebuilding whenever the transaction set changes
      while browsingPath.count > 1 {
        browsingPath.removeLast()
      }

      buildTransactionNodes(txns: worker.fetchedTransactions, rootNode: accountRoot)
      browsingPath.append(accountRoot)
      presenter?.presentNode(node: accountRoot, pathlen: browsingPath.count, range: selectedRange)
      return false
    } else {
      presenter?.presentProgress(txnCount: worker.fetchedTransactions.count, range: selectedRange)
      return true
    }
  }

  func buildTransactionNodes(txns: [ESTransaction], rootNode: ESNode) {
    log.verbose("")
    for txn in txns {
      let node = ESNode.init(txn: txn)
      if let parent = rootNode.search(title: node.title, valueType: node.valueType, currency: node.currency) {
        parent.addChild(node: node)
      } else {
        if let level1 = rootNode.children.first(where: { tstNode -> Bool in
          return tstNode.currency == node.currency && tstNode.valueType == node.valueType
        }) {
          if let level2 = level1.children.first(where: { tstNode -> Bool in
            return tstNode.title == node.title && tstNode.currency == node.currency && tstNode.valueType == node.valueType
          }) {
            level2.addChild(node: node)
          } else {
            let level2 = ESNode.init(title: node.title, amount: 0, valueType: node.valueType, currency: node.currency)
            level2.addChild(node: node)
            level1.addChild(node: level2)
          }
        } else {
          let level1 = ESNode.init(title: node.valueType.rawValue, amount: 0, valueType: node.valueType, currency: node.currency)
          let level2 = ESNode.init(title: node.title, amount: 0, valueType: node.valueType, currency: node.currency)
          level2.addChild(node: node)
          level1.addChild(node: level2)
          rootNode.addChild(node: level1)
        }
      }
    }

    //Remove redundant groupsummary nodes with only 1 child node
    _ = rootNode.children.map { $0.children.map {
      if $0.children.count == 1, let child = $0.children.first {
        $0.title = child.title
        $0.amount = child.amount
        $0.currency = child.currency
        $0.nodeType = child.nodeType
        $0.objectId = child.objectId
        $0.removeChildren()
      }
      }
    }
  }
}
