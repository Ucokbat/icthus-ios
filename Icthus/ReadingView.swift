//
//  ReadingScrollView.swift
//  Icthus
//
//  Created by Matthew Lorentz on 5/22/15.
//  Copyright (c) 2015 Matthew Lorentz. All rights reserved.
//

import Foundation

class ReadingView: UIView, UIScrollViewDelegate {
    private var textViewMetadata: Array<BibleTextViewMetadata> = []
    private var textViews: Array<BibleTextView?> = []
    private var currentBook: Book?
    private var lastFrameIndex = 0
    private let numberOfFramesToShow = 15
    private var scrollView: UIScrollView
    
    required init(coder aDecoder: NSCoder) {
        scrollView = UIScrollView()
        super.init(coder: aDecoder)
    }
    
    private var currentFrameIndex: Int {
        get {
            if textViewMetadata.count > 0 {
                var yPos: CGFloat = 0
                var index = 0
                for datum in textViewMetadata {
                    yPos += datum.frame.size.height
                    if yPos >= self.scrollView.contentOffset.y {
                        break
                    }
                    index++
                }
                return index
            } else {
                return 0
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Configure the scrollView
        scrollView = UIScrollView(frame: self.frame)
        scrollView.delegate = self
        scrollView.scrollsToTop = false
        self.addSubview(scrollView)
    }
    
    override func layoutSubviews() {
        scrollView.frame = self.frame
    }
    
    func redraw(metadata: Array<BibleTextViewMetadata>, book: Book, location: BookLocation? = nil) {
        textViewMetadata = metadata
        textViews = Array<BibleTextView?>(count: metadata.count, repeatedValue: nil)
        currentBook = book
        
        // Set the content size of the scroll view
        let contentHeight = textViewMetadata.reduce(0) { $0 + $1.frame.size.height }
        scrollView.contentSize = CGSizeMake(self.frame.size.width, contentHeight)
        
        if let actualLocation = location {
            self.showLocation(actualLocation)
        } else {
//            scrollView.contentOffset = CGPoint(x: 0, y: self.frame.origin.y - scrollView.contentInset.top)
            scrollView.contentOffset = self.frame.origin
        }
        
        self.addAndRemoveTextViews()
    }
    
    private func showLocation(location: BookLocation) {
        
    }
    
    private func addAndRemoveTextViews() {
        // loop through all text views and instantiate the ones close to the current one and destroy all others
        for i in 0..<textViewMetadata.count {
            var textView: BibleTextView? = textViews[i]
            if textViewWithIndexShouldBeInstantiated(i) {
                if textView == nil, let actualBook = currentBook {
                    textView = BibleTextView(metadata: textViewMetadata[i], book: actualBook)
                    scrollView.addSubview(textView!)
                    textViews[i] = textView
                }
            } else {
                if textView != nil {
                    textView?.removeFromSuperview()
                    textViews[i] = nil
                }
            }
        }
    }
    
    private func textViewWithIndexShouldBeInstantiated(textViewIndex: Int) -> Bool {
        let margin = numberOfFramesToShow / 2
        return abs(currentFrameIndex - textViewIndex) <= margin
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        println("contentOffset: \(scrollView.contentOffset.y)")
        println("self.frame: \(self.frame)")
        println("self.scrollView.frame: \(scrollView.frame)")
        if currentFrameIndex != lastFrameIndex {
            addAndRemoveTextViews()
        }
    }
}