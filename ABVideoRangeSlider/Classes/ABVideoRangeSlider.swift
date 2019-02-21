//
//  ABVideoRangeSlider.swift
//  selfband
//
//  Created by Oscar J. Irun on 26/11/16.
//  Copyright © 2016 appsboulevard. All rights reserved.
//

import UIKit

@objc public protocol ABVideoRangeSliderDelegate: class {
    func didChangeValue(videoRangeSlider: ABVideoRangeSlider, startTime: Float64, endTime: Float64)
    func indicatorDidChangePosition(videoRangeSlider: ABVideoRangeSlider, position: Float64)

    @objc optional func sliderGesturesBegan()
    @objc optional func sliderGesturesEnded()
}

public class ABVideoRangeSlider: UIView, UIGestureRecognizerDelegate {

    private enum DragHandle {
        case start
        case end
    }

    public weak var delegate: ABVideoRangeSliderDelegate?

    var startIndicator      = ABStartIndicator()
    var endIndicator        = ABEndIndicator()
    var topLine             = ABBorder()
    var bottomLine          = ABBorder()
    var progressIndicator   = ABProgressIndicator()
    var draggableView       = UIView()

    public var startTimeView       = ABTimeView()
    public var endTimeView         = ABTimeView()
    
   

    let thumbnailsManager   = ABThumbnailsManager()
    var duration: Float64   = 0.0
    var videoURL            = URL(fileURLWithPath: "")

    var progressPercentage: CGFloat = 0         /// Represented in percentage (0-100)
    var startPercentage: CGFloat    = 0         /// Represented in percentage (0-100)
    var endPercentage: CGFloat      = 100       /// Represented in percentage (0-100)

    let topBorderHeight: CGFloat      = 5
    let bottomBorderHeight: CGFloat   = 5
    let timeviewHeight:CGFloat = 25

    let indicatorWidth: CGFloat = 20.0

    public var minSpace: Float = 1              // In Seconds
    public var maxSpace: Float = 0              // In Seconds

    public var isProgressIndicatorDraggable = false
    public var rangeHandleChangeResetsProgress = false /// range handle change will effect progress indicator
    public var rangeHandlesConstrainProgress = false /// progress indicator is bounded by start/end range

    var isUpdatingThumbnails = false
    var isReceivingGesture: Bool = false

    public enum ABTimeViewPosition {
        case top
        case bottom
    }

    override public func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private func setup() {
        isUserInteractionEnabled = true

        // Setup Start Indicator
        let startDrag = UIPanGestureRecognizer(target: self,
                                               action: #selector(startDragged(recognizer:)))

        startIndicator = ABStartIndicator(frame: CGRect(x: 0,
                                                        y: -topBorderHeight,
                                                        width: 20,
                                                        height: frame.size.height + bottomBorderHeight + topBorderHeight))
        startIndicator.layer.anchorPoint = CGPoint(x: 0, y: 0.5)
        startIndicator.addGestureRecognizer(startDrag)
        addSubview(startIndicator)

        // Setup End Indicator

        let endDrag = UIPanGestureRecognizer(target: self,
                                             action: #selector(endDragged(recognizer:)))

        endIndicator = ABEndIndicator(frame: CGRect(x: 0,
                                                    y: -topBorderHeight,
                                                    width: indicatorWidth,
                                                    height: frame.size.height + bottomBorderHeight + topBorderHeight))
        endIndicator.layer.anchorPoint = CGPoint(x: 1, y: 0.5)
        endIndicator.addGestureRecognizer(endDrag)
        addSubview(endIndicator)

        // Setup Top and bottom line

        topLine = ABBorder(frame: CGRect(x: 0,
                                         y: -topBorderHeight,
                                         width: indicatorWidth,
                                         height: topBorderHeight))
        addSubview(topLine)

        bottomLine = ABBorder(frame: CGRect(x: 0,
                                            y: frame.size.height,
                                            width: indicatorWidth,
                                            height: bottomBorderHeight))
        addSubview(bottomLine)

        addObserver(self,
                         forKeyPath: "bounds",
                         options: NSKeyValueObservingOptions(rawValue: 0),
                         context: nil)

        // Setup Progress Indicator

        let progressDrag = UIPanGestureRecognizer(target: self,
                                                  action: #selector(progressDragged(recognizer:)))

        progressIndicator = ABProgressIndicator(frame: CGRect(x: 0,
                                                              y: -topBorderHeight,
                                                              width: 10,
                                                              height: frame.size.height + bottomBorderHeight + topBorderHeight))
        progressIndicator.addGestureRecognizer(progressDrag)
        addSubview(progressIndicator)

        // Setup Draggable View

        let viewDrag = UIPanGestureRecognizer(target: self,
                                              action: #selector(viewDragged(recognizer:)))

        draggableView.addGestureRecognizer(viewDrag)
        draggableView.backgroundColor = .clear
        addSubview(draggableView)
        sendSubviewToBack(draggableView)

        // Setup time labels

        startTimeView = ABTimeView(size: CGSize(width: 60, height: 25), position: 1)
        startTimeView.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        addSubview(startTimeView)

        endTimeView = ABTimeView(size: CGSize(width: 60, height: 25), position: 1)
        endTimeView.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        addSubview(endTimeView)
    }

    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "bounds"{
            updateThumbnails()
            updateHandles()
        }
    }
    
    private func updateHandles() {
        var newStart = startIndicator.frame
        newStart.size.height = bounds.height
        startIndicator.frame = newStart
        
        var newEnd = endIndicator.frame
        newEnd.size.height = bounds.height
        endIndicator.frame = newEnd
    }

    // MARK: Public functions

    public func setProgressIndicatorImage(image: UIImage) {
        progressIndicator.imageView.image = image
    }

    public func hideProgressIndicator() {
        progressIndicator.isHidden = true
    }

    public func showProgressIndicator() {
        progressIndicator.isHidden = false
    }

    public func updateProgressIndicator(seconds: Float64) {
        if !isReceivingGesture {
            
            let endSeconds = secondsFromValue(value: endPercentage)
            let shouldReset = seconds >= endSeconds && rangeHandlesConstrainProgress
            if shouldReset {
                resetProgressPosition()
            } else {
                progressPercentage = valueFromSeconds(seconds: Float(seconds))
            }

            layoutSubviews()
        }
    }

    public func setStartIndicatorImage(image: UIImage) {
        startIndicator.imageView.image = image
    }

    public func setEndIndicatorImage(image: UIImage) {
        endIndicator.imageView.image = image
    }

    public func setBorderImage(image: UIImage) {
        topLine.imageView.image = image
        bottomLine.imageView.image = image
    }

    public func setTimeView(view: ABTimeView) {
        startTimeView = view
        endTimeView = view
    }

    public func setTimeViewPosition(position: ABTimeViewPosition) {
        switch position {
        case .top:

            break
        case .bottom:

            break
        }
    }

    public func setVideoURL(videoURL: URL) {
        duration = ABVideoHelper.videoDuration(videoURL: videoURL)
        self.videoURL = videoURL
        superview?.layoutSubviews()
        updateThumbnails()
    }

    public func updateThumbnails() {
        if !isUpdatingThumbnails {
            isUpdatingThumbnails = true
            let backgroundQueue = DispatchQueue(label: "com.app.queue", qos: .background, target: nil)
            backgroundQueue.async {
                _ = self.thumbnailsManager.updateThumbnails(view: self, videoURL: self.videoURL, duration: self.duration)
                self.isUpdatingThumbnails = false
            }
        }
    }

    public func setStartPosition(seconds: Float) {
        startPercentage = valueFromSeconds(seconds: seconds)
        layoutSubviews()
    }

    public func setEndPosition(seconds: Float) {
        endPercentage = valueFromSeconds(seconds: seconds)
        layoutSubviews()
    }
    
    public func resetHandles() {
        startPercentage = 0
        endPercentage = 100
        layoutSubviews()
    }

    // MARK: - Private functions

    // MARK: - Crop Handle Drag Functions
    @objc private func startDragged(recognizer: UIPanGestureRecognizer) {
        processHandleDrag(
            recognizer: recognizer,
            handle: .start,
            currentPositionPercentage: startPercentage,
            currentIndicator: startIndicator
        )
    }

    @objc private func endDragged(recognizer: UIPanGestureRecognizer) {
        processHandleDrag(
            recognizer: recognizer,
            handle: .end,
            currentPositionPercentage: endPercentage,
            currentIndicator: endIndicator
        )
    }

    private func processHandleDrag(
        recognizer: UIPanGestureRecognizer,
        handle: DragHandle,
        currentPositionPercentage: CGFloat,
        currentIndicator: UIView
        ) {

        updateGestureStatus(recognizer: recognizer)
        let translation = recognizer.translation(in: self)
        
        var position: CGFloat = positionFromValue(value: currentPositionPercentage) // startPercentage or endPercentage
        position = position + translation.x
        if position < 0 { position = 0 }

        if position > frame.size.width {
            position = frame.size.width
        }

        let positionLimits = getPositionLimits(with: handle)
        position = checkEdgeCasesForPosition(with: position, and: positionLimits.min, and: handle)

        if Float(duration) > maxSpace && maxSpace > 0 {
            if handle == .start {
                if position < positionLimits.max {
                    position = positionLimits.max
                }
            } else {
                if position > positionLimits.max {
                    position = positionLimits.max
                }
            }
        }

        recognizer.setTranslation(CGPoint.zero, in: self)
        currentIndicator.center = CGPoint(x: position, y: currentIndicator.center.y)
        let percentage = currentIndicator.center.x * 100 / frame.width
        let startSeconds = secondsFromValue(value: startPercentage)
        let endSeconds = secondsFromValue(value: endPercentage)

        delegate?.didChangeValue(videoRangeSlider: self, startTime: startSeconds, endTime: endSeconds)

        if handle == .start {
            startPercentage = percentage
        } else {
            endPercentage = percentage
        }

        if rangeHandleChangeResetsProgress {
            resetProgressIndicatorForHandle(handle, recognizer: recognizer)
        }

        layoutSubviews()
    }
    
    private func resetProgressIndicatorForHandle(_ drag: DragHandle, recognizer: UIGestureRecognizer) {
        
        var progressPosition: CGFloat = 0.0
        
        if drag == .start {
            progressPosition = positionFromValue(value: startPercentage)
        } else {
            if recognizer.state != .ended {
                progressPosition = positionFromValue(value: endPercentage)
            } else {
                progressPosition = positionFromValue(value: startPercentage)
            }
        }
        
        progressIndicator.center = CGPoint(x: progressPosition, y: progressIndicator.center.y)
        let progressPercentage = progressIndicator.center.x * 100 / frame.width
        
        if progressPercentage != progressPercentage {
            let progressSeconds = secondsFromValue(value: progressPercentage)
            delegate?.indicatorDidChangePosition(videoRangeSlider: self, position: progressSeconds)
        }
        
        self.progressPercentage = progressPercentage
    }
    

	@objc func progressDragged(recognizer: UIPanGestureRecognizer) {
        if !isProgressIndicatorDraggable {
            return
        }

        updateGestureStatus(recognizer: recognizer)

        let translation = recognizer.translation(in: self)

        let positionLimitStart  = positionFromValue(value: startPercentage)
        let positionLimitEnd    = positionFromValue(value: endPercentage)

        var position = positionFromValue(value: progressPercentage)
        position = position + translation.x

        if position < positionLimitStart {
            position = positionLimitStart
        }

        if position > positionLimitEnd {
            position = positionLimitEnd
        }

        recognizer.setTranslation(CGPoint.zero, in: self)
        progressIndicator.center = CGPoint(x: position, y: progressIndicator.center.y)
        let percentage = progressIndicator.center.x * 100 / frame.width
        let progressSeconds = secondsFromValue(value: progressPercentage)
        delegate?.indicatorDidChangePosition(videoRangeSlider: self, position: progressSeconds)
        progressPercentage = percentage
        layoutSubviews()
    }

	@objc func viewDragged(recognizer: UIPanGestureRecognizer) {
        updateGestureStatus(recognizer: recognizer)

        let translation = recognizer.translation(in: self)

        var progressPosition = positionFromValue(value: progressPercentage)
        var startPosition = positionFromValue(value: startPercentage)
        var endPosition = positionFromValue(value: endPercentage)

        startPosition = startPosition + translation.x
        endPosition = endPosition + translation.x
        progressPosition = progressPosition + translation.x

        if startPosition < 0 {
            startPosition = 0
            endPosition = endPosition - translation.x
            progressPosition = progressPosition - translation.x
        }

        if endPosition > frame.size.width {
            endPosition = frame.size.width
            startPosition = startPosition - translation.x
            progressPosition = progressPosition - translation.x
        }

        recognizer.setTranslation(CGPoint.zero, in: self)

        startIndicator.center = CGPoint(x: startPosition, y: startIndicator.center.y)
        endIndicator.center = CGPoint(x: endPosition, y: endIndicator.center.y)

        let startPercentage = startIndicator.center.x * 100 / frame.width
        let endPercentage = endIndicator.center.x * 100 / frame.width
        
        let startSeconds = secondsFromValue(value: startPercentage)
        let endSeconds = secondsFromValue(value: endPercentage)
        
        delegate?.didChangeValue(videoRangeSlider: self, startTime: startSeconds, endTime: endSeconds)
        
        self.startPercentage = startPercentage
        self.endPercentage = endPercentage
        
        if rangeHandleChangeResetsProgress {
            progressIndicator.center = CGPoint(x: progressPosition, y: progressIndicator.center.y)
            let progressPercentage = progressIndicator.center.x * 100 / frame.width
            if progressPercentage != progressPercentage {
                let progressSeconds = secondsFromValue(value: progressPercentage)
                delegate?.indicatorDidChangePosition(videoRangeSlider: self, position: progressSeconds)
            }
            self.progressPercentage = progressPercentage
        }
        
        layoutSubviews()
    }

    // MARK: - Drag Functions Helpers
    private func positionFromValue(value: CGFloat) -> CGFloat {
        let position = value * frame.size.width / 100
        return position
    }

    private func getPositionLimits(with drag: DragHandle) -> (min: CGFloat, max: CGFloat) {
        if drag == .start {
            return (
                positionFromValue(value: endPercentage - valueFromSeconds(seconds: minSpace)),
                positionFromValue(value: endPercentage - valueFromSeconds(seconds: maxSpace))
            )
        } else {
            return (
                positionFromValue(value: startPercentage + valueFromSeconds(seconds: minSpace)),
                positionFromValue(value: startPercentage + valueFromSeconds(seconds: maxSpace))
            )
        }
    }

    private func checkEdgeCasesForPosition(with position: CGFloat, and positionLimit: CGFloat, and drag: DragHandle) -> CGFloat {
        if drag == .start {
            if Float(duration) < minSpace {
                return 0
            } else {
                if position > positionLimit {
                    return positionLimit
                }
            }
        } else {
            if Float(duration) < minSpace {
                return frame.size.width
            } else {
                if position < positionLimit {
                    return positionLimit
                }
            }
        }

        return position
    }

    private func secondsFromValue(value: CGFloat) -> Float64 {
        return duration * Float64((value / 100))
    }

    private func valueFromSeconds(seconds: Float) -> CGFloat {
        return duration > 0 ? CGFloat(seconds * 100) / CGFloat(duration):0
    }

    private func updateGestureStatus(recognizer: UIGestureRecognizer) {
        if recognizer.state == .began {

            isReceivingGesture = true
            delegate?.sliderGesturesBegan?()

        } else if recognizer.state == .ended {

            isReceivingGesture = false
            delegate?.sliderGesturesEnded?()
        }
    }

    private func resetProgressPosition() {
        progressPercentage = startPercentage
        let progressPosition = positionFromValue(value: progressPercentage)
        progressIndicator.center = CGPoint(x: progressPosition, y: progressIndicator.center.y)

        let startSeconds = secondsFromValue(value: progressPercentage)
        delegate?.indicatorDidChangePosition(videoRangeSlider: self, position: startSeconds)
    }

    // MARK: -

    override public func layoutSubviews() {
        super.layoutSubviews()

        startTimeView.timeLabel.text = secondsToFormattedString(totalSeconds: secondsFromValue(value: startPercentage))
        endTimeView.timeLabel.text = secondsToFormattedString(totalSeconds: secondsFromValue(value: endPercentage))

        let startPosition = positionFromValue(value: startPercentage)
        let endPosition = positionFromValue(value: endPercentage)
        let progressPosition = positionFromValue(value: progressPercentage)

        startIndicator.center = CGPoint(x: startPosition, y: startIndicator.center.y)
        endIndicator.center = CGPoint(x: endPosition, y: endIndicator.center.y)
        progressIndicator.center = CGPoint(x: progressPosition, y: progressIndicator.center.y)
        draggableView.frame = CGRect(x: startIndicator.frame.origin.x + startIndicator.frame.size.width,
                                     y: 0,
                                     width: endIndicator.frame.origin.x - startIndicator.frame.origin.x - endIndicator.frame.size.width,
                                     height: frame.height)

        topLine.frame = CGRect(x: startIndicator.frame.origin.x + startIndicator.frame.width,
                               y: -topBorderHeight,
                               width: endIndicator.frame.origin.x - startIndicator.frame.origin.x - endIndicator.frame.size.width,
                               height: topBorderHeight)

        bottomLine.frame = CGRect(x: startIndicator.frame.origin.x + startIndicator.frame.width,
                                  y: frame.size.height,
                                  width: endIndicator.frame.origin.x - startIndicator.frame.origin.x - endIndicator.frame.size.width,
                                  height: bottomBorderHeight)

        // Update time view
        startTimeView.center = CGPoint(x: startIndicator.center.x, y: startTimeView.center.y)
        endTimeView.center = CGPoint(x: endIndicator.center.x, y: endTimeView.center.y)
    }

    override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let extendedBounds = CGRect(x: -startIndicator.frame.size.width,
                                    y: -topLine.frame.size.height,
                                    width: frame.size.width + startIndicator.frame.size.width + endIndicator.frame.size.width,
                                    height: frame.size.height + topLine.frame.size.height + bottomLine.frame.size.height)
        return extendedBounds.contains(point)
    }

    private func secondsToFormattedString(totalSeconds: Float64) -> String {
        let minutes: Int = Int(totalSeconds.truncatingRemainder(dividingBy: 3600) / 60)
        let seconds: Int = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
        let subseconds: Int = Int(totalSeconds.truncatingRemainder(dividingBy: 1)  * 10)

        if minutes > 0 {
            return String(format: "%i:%02i.%i", minutes, seconds, subseconds)
        } else {
            return String(format: "%i.%i", seconds, subseconds)
        }
    }

    deinit {
      // removeObserver(self, forKeyPath: "bounds")
    }
}
