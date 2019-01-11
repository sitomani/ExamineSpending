//
//  TreemapView.swift
//  ExamineSpending
//
//  Copyright © 2018 Aleksi Sitomaniemi. All rights reserved.
//

import UIKit
import YMTreeMap

protocol TreemapDelegate: NSObjectProtocol {
  func didTapRectangle(view: TreemapView, rectIndex: Int)
  func didPinchOut(view: TreemapView)
}

class TreemapView: UIView, UIGestureRecognizerDelegate {
  //var treeMap: YMTreeMap
  var treeMapRects: [YMTreeMap.SystemRect]
  var values: [Double] = []
  var titles: [String] = []
  var types: [ESValueType] = []
  var hilight: UIView?

  weak var delegate: TreemapDelegate?

  override init(frame: CGRect) {
    //self.treeMap = YMTreeMap(withValues: [Double]())
    self.treeMapRects = []
    super.init(frame: frame)
    setup()
  }

  required init?(coder aDecoder: NSCoder) {
    //self.treeMap = YMTreeMap(withValues: [Double]())
    self.treeMapRects = []
    super.init(coder: aDecoder)
    setup()
  }

  deinit {
    log.debug("")
  }

  func setup() {
    //treeMapRects = []
    let tapRecognizer = UITapGestureRecognizer(target: self,
                                               action: #selector(TreemapView.tapDetected(_:)))
    self.addGestureRecognizer(tapRecognizer)
    let pinchRecognizer = UIPinchGestureRecognizer(target: self,
                                                   action: #selector(TreemapView.pinchDetected(_:)))
    self.addGestureRecognizer(pinchRecognizer)

    let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(TreemapView.edgePanDetected(_:)))
    edgePan.edges = UIRectEdge.left
    self.addGestureRecognizer(edgePan)
  }

  override func draw(_ rect: CGRect) {
    let treeMap = YMTreeMap(withValues: values)
    treeMapRects = treeMap.tessellate(inRect: self.bounds)

    let context = UIGraphicsGetCurrentContext()
    var index = 0
    treeMapRects.forEach { treeMapRect in
      let alpha: CGFloat = CGFloat(0.5 + (values[index]/values.max()! * 0.5))

      if types[index] == .debit {
        debitColor.withAlphaComponent(alpha).setFill()
      } else {
        creditColor.withAlphaComponent(alpha).setFill()
      }
      context?.fill(treeMapRect.insetBy(dx: 1, dy: 1))
      let str: String = "\(titles[index]) \(String.init(format: "%.2f", values[index]))"
      let fontSize: CGFloat
      if treeMapRect.width < 40 {
        fontSize = 6.0
      } else {
        fontSize = 10.0
      }
      let attrs = [NSAttributedString.Key.foregroundColor: UIColor.white,
                   NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontSize)
                   ] as [NSAttributedString.Key: Any]
      str.draw(in: treeMapRect.insetBy(dx: 4, dy: 4), withAttributes: attrs)
      index += 1
    }
  }

  func updateValues(blocks: [Block]) {
    values = blocks.map { (Double($0.amount)?.magnitude) ?? 0 }
    titles = blocks.map { $0.title + ($0.expandable ? "▶" : "")  }
    types = blocks.map { $0.valueType }
    self.setNeedsDisplay()
  }

  @objc func tapDetected(_ sender: UITapGestureRecognizer) {
    let tapLocation = sender.location(in: self)
    if let index = treeMapRects.index(where: { rect in
      return rect.contains(tapLocation)
    }) {
        removeHilight()
        self.delegate?.didTapRectangle(view: self, rectIndex: index)
    }
  }

  @objc func pinchDetected(_ sender: UIPinchGestureRecognizer) {
    if sender.scale < 1 && sender.state == .ended {
      removeHilight()
      delegate?.didPinchOut(view: self)
    }
  }

  @objc func edgePanDetected(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended {
      removeHilight()
      delegate?.didPinchOut(view: self)
    }
  }

  func removeHilight() {
    hilight?.removeFromSuperview()
    hilight = nil
  }

  func highlightRectAt(_ touchPoint: CGPoint) {
    if let index = treeMapRects.index(where: { rect in
      return rect.contains(touchPoint)
    }) {
      //skip hilight if the target frame is already highlighted
      guard self.hilight?.frame != treeMapRects[index] else { return }

      self.hilight?.removeFromSuperview()
      self.hilight = UIView.init(frame: treeMapRects[index])
      self.hilight?.backgroundColor = UIColor.white
      self.hilight?.alpha = 0.3
      self.addSubview(self.hilight!)
    }
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    if touches.count == 1, let loc = touches.first?.location(in: self) {
      highlightRectAt(loc)
    }
  }

  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    if touches.count == 1, let loc = touches.first?.location(in: self) {
      highlightRectAt(loc)
    }
    super.touchesMoved(touches, with: event)
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    hilight?.removeFromSuperview()
    hilight = nil
    super.touchesEnded(touches, with: event)
  }
}
