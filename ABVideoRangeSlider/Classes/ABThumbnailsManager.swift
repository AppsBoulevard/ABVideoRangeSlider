//
//  ABThumbnailsHelper.swift
//  selfband
//
//  Created by Oscar J. Irun on 27/11/16.
//  Copyright © 2016 appsboulevard. All rights reserved.
//

import UIKit
import AVFoundation

class ABThumbnailsManager: NSObject {
    
    private var thumbnailViews = [UIImageView]()
    private var imageGenerator: AVAssetImageGenerator!
    private var isGeneratingThumbnails = false
    
    private func addImagesToView(_ images: [UIImage], view: UIView) {
        self.thumbnailViews.removeAll()
        var xPos: CGFloat = 0.0
        var width: CGFloat = 0.0
        for image in images{
            DispatchQueue.main.async {
                if xPos + view.frame.size.height < view.frame.width {
                    width = view.frame.size.height
                } else {
                    width = view.frame.size.width - xPos
                }
                
                let imageView = UIImageView(image: image)
                imageView.alpha = 0
                imageView.contentMode = UIViewContentMode.scaleAspectFill
                imageView.clipsToBounds = true
                imageView.frame = CGRect(x: xPos,
                                         y: 0.0,
                                         width: width,
                                         height: view.frame.size.height)
                self.thumbnailViews.append(imageView)
                
                
                view.addSubview(imageView)
                UIView.animate(withDuration: 0.2, animations: {() -> Void in
                    imageView.alpha = 1.0
                })
                view.sendSubview(toBack: imageView)
                xPos = xPos + view.frame.size.height
            }
        }
    }
    
    private func thumbnailCount(_ inView: UIView) -> Int {
        let num = Double(inView.frame.size.width) / Double(inView.frame.size.height)
        return Int(ceil(num))
    }
    
    private func timePointsForCount(_ avasset: AVAsset, count: Int) -> [CMTime]? {
        let duration = CMTimeGetSeconds(avasset.duration)
        
        if duration == 0 || count == 0 {
            return nil
        }
        
        var timePoints = [CMTime]()
        let increment = duration / Double(count)
        for frameNumber in 0..<count {
            let seconds: Float64 = Float64(increment) * Float64(frameNumber)
            let time = CMTimeMakeWithSeconds(seconds, 600)
            timePoints.append(time)
        }
        
        return timePoints
    }
    
    func cancelThumbnailGeneration() {
        guard let generator = self.imageGenerator, isGeneratingThumbnails else { return }
        generator.cancelAllCGImageGeneration()
        isGeneratingThumbnails = false
    }
    
    func generateThumbnails(_ view: UIView, for avasset: AVAsset) {
        
        cancelThumbnailGeneration()
        
        for view in self.thumbnailViews {
            DispatchQueue.main.async {
                view.removeFromSuperview()
            }
        }
    
        let imagesCount = self.thumbnailCount(view)
        
        guard let timePoints  = self.timePointsForCount(avasset, count: imagesCount) else { return }
        
        self.imageGenerator = AVAssetImageGenerator(asset: avasset)
        self.imageGenerator.appliesPreferredTrackTransform = true
        self.isGeneratingThumbnails = true
        
        var thumbnailImages = [UIImage]()
        self.imageGenerator.generateCGImagesAsynchronouslyForTimePoints(timePoints, completionHandler: { (requestedTime: CMTime, cgImage: CGImage?, actualTime: CMTime, result: AVAssetImageGeneratorResult, error: Error?) in
            guard let image = cgImage, error == nil else {
                return
            }
            
            thumbnailImages.append(UIImage(cgImage: image))
            
            if requestedTime == timePoints.last {
                self.isGeneratingThumbnails = false
                self.addImagesToView(thumbnailImages, view: view)
            }
        })
    }
}

public extension AVAssetImageGenerator {
    public func generateCGImagesAsynchronouslyForTimePoints(_ timePoints: [CMTime], completionHandler: @escaping AVAssetImageGeneratorCompletionHandler) {
        let times = timePoints.map {timePoint in
            return NSValue(time: timePoint)
        }
        self.generateCGImagesAsynchronously(forTimes: times, completionHandler: completionHandler)
    }
}

