//
//  ABVideoRangeSlider.swift
//  selfband
//
//  Created by Oscar J. Irun on 26/11/16.
//  Copyright © 2016 appsboulevard. All rights reserved.
//

import UIKit

public protocol ABVideoRangeSliderDelegate {
    func didChangeValue(videoRangeSlider: ABVideoRangeSlider, startTime: Float64, endTime: Float64)
}

public class ABVideoRangeSlider: UIView {
    
    public var delegate: ABVideoRangeSliderDelegate? = nil
    
    var startIndicator  = ABStartIndicator()
    var endIndicator    = ABEndIndicator()
    var topLine         = ABBorder()
    var bottomLine      = ABBorder()
    
    let thumbnailsManager   = ABThumbnailsManager()
    var duration: Float64   = 0.0
    var videoURL            = URL(fileURLWithPath: "")
    
    var startPercentage: CGFloat    = 0         // Represented in percentage
    var endPercentage: CGFloat      = 100       // Represented in percentage
    
    let topBorderHeight: CGFloat      = 5
    let bottomBorderHeight: CGFloat   = 5
    
    public var minSpace: Float = 1              // In Seconds
    
    var isUpdatingThumbnails = false
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        self.setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func setup(){
        self.isUserInteractionEnabled = true
        
        // Setup Start Indicator
        
        let startDrag = UIPanGestureRecognizer(target:self,
                                               action: #selector(startDragged(recognizer:)))
        
        startIndicator = ABStartIndicator(frame: CGRect(x: 0,
                                                        y: -topBorderHeight,
                                                        width: 20,
                                                        height: self.frame.size.height + bottomBorderHeight + topBorderHeight))
        startIndicator.addGestureRecognizer(startDrag)
        self.addSubview(startIndicator)
        
        // Setup End Indicator
        
        let endDrag = UIPanGestureRecognizer(target:self,
                                             action: #selector(endDragged(recognizer:)))
        
        endIndicator = ABEndIndicator(frame: CGRect(x: 0,
                                                    y: -topBorderHeight,
                                                    width: 20,
                                                    height: self.frame.size.height + bottomBorderHeight + topBorderHeight))
        endIndicator.addGestureRecognizer(endDrag)
        self.addSubview(endIndicator)
        
        // Setup Top and bottom line
        
        topLine = ABBorder(frame: CGRect(x: 0,
                                         y: -topBorderHeight,
                                         width: 20,
                                         height: topBorderHeight))
        self.addSubview(topLine)
        
        bottomLine = ABBorder(frame: CGRect(x: 0,
                                            y: self.frame.size.height,
                                            width: 20,
                                            height: bottomBorderHeight))
        self.addSubview(bottomLine)
        
        self.addObserver(self,
                         forKeyPath: "bounds",
                         options: NSKeyValueObservingOptions(rawValue: 0),
                         context: nil)
    }

    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "bounds"{
            self.updateThumbnails()
        }
    }
    
    // MARK: Public functions
    
    public func setStartIndicatorImage(image: UIImage){
        self.startIndicator.imageView.image = image
    }
    
    public func setEndIndicatorImage(image: UIImage){
        self.endIndicator.imageView.image = image
    }
    
    public func setBorderImage(image: UIImage){
        self.topLine.imageView.image = image
        self.bottomLine.imageView.image = image
    }
    
    public func setVideoURL(videoURL: URL){
        self.duration = ABVideoHelper.videoDuration(videoURL: videoURL)
        self.videoURL = videoURL
        self.superview?.layoutSubviews()
        self.updateThumbnails()
    }
    
    public func updateThumbnails(){
        if !isUpdatingThumbnails{
            self.isUpdatingThumbnails = true
            let backgroundQueue = DispatchQueue(label: "com.app.queue",
                                                qos: .background,
                                                target: nil)
            backgroundQueue.async {
                self.thumbnailsManager.updateThumbnails(view: self,
                                                        videoURL: self.videoURL,
                                                        duration: self.duration)
                self.isUpdatingThumbnails = false
            }
        }
    }
    
    // MARK: Private functions
    
    private func positionFromValue(value: CGFloat) -> CGFloat{
        let position = value * self.frame.size.width / 100
        return position
    }
    
    func startDragged(recognizer: UIPanGestureRecognizer){
        let translation = recognizer.translation(in: self)
        
        var position = positionFromValue(value: self.startPercentage)
        position = position + translation.x
        
        if position < 0{
            position = 0
        }
        
        if position > self.frame.size.width{
            position = self.frame.size.width
        }
        
        let positionLimit = positionFromValue(value: self.endPercentage - valueFromSeconds(seconds: minSpace))
        
        if Float(self.duration) < self.minSpace {
            position = 0
        }else{
            if position > positionLimit {
                position = positionLimit
            }
        }
        
        recognizer.setTranslation(CGPoint.zero, in: self)
        startIndicator.center = CGPoint(x: position , y: startIndicator.center.y)
        
        let percentage = startIndicator.center.x * 100 / self.frame.width
        
        let startSeconds = secondsFromValue(value: startPercentage)
        let endSeconds = secondsFromValue(value: endPercentage)
        
        self.delegate?.didChangeValue(videoRangeSlider: self, startTime: startSeconds, endTime: endSeconds)
        
        self.startPercentage = percentage
        
        layoutSubviews()
    }
    
    
    func endDragged(recognizer: UIPanGestureRecognizer){
        let translation = recognizer.translation(in: self)
        
        var position = positionFromValue(value: self.endPercentage)
        position = position + translation.x
        
        if position < 0{
            position = 0
        }
        
        if position > self.frame.size.width{
            position = self.frame.size.width
        }
        
        let positionLimit = positionFromValue(value: valueFromSeconds(seconds: minSpace) + self.startPercentage)
        
        if Float(self.duration) < self.minSpace {
            position = self.frame.size.width
        }else{
            if position < positionLimit {
                position = positionLimit
            }
        }
        
        recognizer.setTranslation(CGPoint.zero, in: self)
        endIndicator.center = CGPoint(x: position , y: endIndicator.center.y)
        
        let percentage = endIndicator.center.x * 100 / self.frame.width
        
        let startSeconds = secondsFromValue(value: startPercentage)
        let endSeconds = secondsFromValue(value: endPercentage)
        
        self.delegate?.didChangeValue(videoRangeSlider: self, startTime: startSeconds, endTime: endSeconds)
        
        self.endPercentage = percentage

        layoutSubviews()
    }
    
    private func secondsFromValue(value: CGFloat) -> Float64{
        return duration * Float64((value / 100))
    }
    
    private func valueFromSeconds(seconds: Float) -> CGFloat{
        return CGFloat(seconds * 100) / CGFloat(duration)
    }
    
    // MARK:
    
    override public func layoutSubviews() {
        super.layoutSubviews()

        let startPosition = positionFromValue(value: self.startPercentage)
        let endPosition = positionFromValue(value: self.endPercentage)
        
        startIndicator.center = CGPoint(x: startPosition, y: startIndicator.center.y)
        endIndicator.center = CGPoint(x: endPosition, y: endIndicator.center.y)

        
        topLine.frame = CGRect(x: startIndicator.frame.origin.x + startIndicator.frame.width,
                               y: -topBorderHeight,
                               width: endIndicator.frame.origin.x - startIndicator.frame.origin.x - endIndicator.frame.size.width,
                               height: topBorderHeight)
        
        bottomLine.frame = CGRect(x: startIndicator.frame.origin.x + startIndicator.frame.width,
                                  y: self.frame.size.height,
                                  width: endIndicator.frame.origin.x - startIndicator.frame.origin.x - endIndicator.frame.size.width,
                                  height: bottomBorderHeight)
    }

    
    override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let extendedBounds = CGRect(x: -startIndicator.frame.size.width / 2,
                                    y: -topLine.frame.size.height,
                                    width: self.frame.size.width + startIndicator.frame.size.width / 2 + endIndicator.frame.size.width / 2,
                                    height: self.frame.size.height + topLine.frame.size.height + bottomLine.frame.size.height)
        return extendedBounds.contains(point)
    }
    

    
}
