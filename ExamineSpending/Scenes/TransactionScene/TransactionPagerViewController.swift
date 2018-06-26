//
//  TransactionPagerViewController.swift
//  ExamineSpending
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit

class TransactionPagerViewController: UIPageViewController {

  var transactions: [ESTransaction] = []
  var txnIndex = 0

  override func viewDidLoad() {
    super.viewDidLoad()
    dataSource = self
    self.view.backgroundColor = UIColor.clear
    guard transactions.count > txnIndex else { return }
    setViewControllers([createTransactionViewController(txn: transactions[txnIndex])], direction: .forward, animated: true, completion: nil)
  }
}

extension TransactionPagerViewController: UIPageViewControllerDataSource {
  func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
    txnIndex = (getCurrentTxnIndex(viewController) + 1) % transactions.count
    return createTransactionViewController(txn: transactions[txnIndex])
  }

  func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
    txnIndex = getCurrentTxnIndex(viewController) - 1
    if txnIndex < 0 {
      txnIndex = transactions.count - 1
    }
    return createTransactionViewController(txn: transactions[txnIndex])
  }

  func presentationCount(for pageViewController: UIPageViewController) -> Int {
    return transactions.count
  }

  func presentationIndex(for pageViewController: UIPageViewController) -> Int {
    return txnIndex
  }

  private func createTransactionViewController(txn: ESTransaction?) -> TransactionViewController {
    guard let controller = storyboard?.instantiateViewController(withIdentifier: "TransactionViewController") as? TransactionViewController else {
      abort()
    }
    if let txn = txn {
      if var transactionDS = controller.router?.dataStore {
        transactionDS.currentTxn = txn
      }
    }
    return controller
  }

  private func getCurrentTxnIndex(_ viewController: UIViewController) -> Int {
    guard let vc = viewController as? TransactionViewController,
      let currentTx = vc.router?.dataStore?.currentTxn,
      let currentIndex = (transactions.index { (txn) -> Bool in
        return txn.transactionId == currentTx.transactionId
      }) else {
        return 0
    }
    return currentIndex
  }
}
