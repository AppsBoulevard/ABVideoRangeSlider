//
//  ViewController.swift
//  ABVideoRangeSlider
//
//  Created by Oscar J. Irun on 27/11/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import ABVideoRangeSlider
import AVKit
import AVFoundation

class ViewController: UIViewController, ABVideoRangeSliderDelegate {

    @IBOutlet var videoRangeSlider: ABVideoRangeSlider!
    @IBOutlet var playerView: UIView!
    @IBOutlet var lblStart: UILabel!
    @IBOutlet var lblEnd: UILabel!
    @IBOutlet var lblMinSpace: UILabel!
    
    let path = Bundle.main.path(forResource: "test", ofType:"mp4")
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func playVideo(_ sender: Any) {
        let player = AVPlayer(url: URL(fileURLWithPath: path!))
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        self.present(playerViewController, animated: true) {
            playerViewController.player!.play()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        videoRangeSlider.setVideoURL(videoURL: URL(fileURLWithPath: path!))
        videoRangeSlider.delegate = self
        videoRangeSlider.minSpace = 60.0
//        videoRangeSlider.maxSpace = 180.0

        lblMinSpace.text = "\(videoRangeSlider.minSpace)"
        
        // Set initial position of Start Indicator
        videoRangeSlider.setStartPosition(seconds: 50.0)
        
        // Set initial position of End Indicator
        videoRangeSlider.setEndPosition(seconds: 150.0)
        
        /* Uncomment to customize the Video Range Slider */
/*
        let customStartIndicator =  UIImage(named: "CustomStartIndicator")
        videoRangeSlider.setStartIndicatorImage(image: customStartIndicator!)
        
        let customEndIndicator =  UIImage(named: "CustomEndIndicator")
        videoRangeSlider.setEndIndicatorImage(image: customEndIndicator!)
        
        let customBorder =  UIImage(named: "CustomBorder")
        videoRangeSlider.setBorderImage(image: customBorder!)
         
        let customProgressIndicator =  UIImage(named: "CustomProgress")
        videoRangeSlider.setProgressIndicatorImage(image: customProgressIndicator!)
*/

        
      
        // Customize starTimeView
        let customView = UIView(frame: CGRect(x: 0,
                                              y: 0,
                                              width: 60,
                                              height: 40))
        customView.backgroundColor = .black
        customView.alpha = 0.5
        customView.layer.borderColor = UIColor.black.cgColor
        customView.layer.borderWidth = 1.0
        customView.layer.cornerRadius = 8.0
        videoRangeSlider.startTimeView.backgroundView = customView
        videoRangeSlider.startTimeView.marginLeft = 2.0
        videoRangeSlider.startTimeView.marginRight = 2.0
        videoRangeSlider.startTimeView.timeLabel.textColor = .white
    }
    
    // MARK: ABVideoRangeSlider Delegate - Returns time in seconds
    
    func didChangeValue(videoRangeSlider: ABVideoRangeSlider, startTime: Float64, endTime: Float64) {
        lblStart.text = "\(startTime)"
        lblEnd.text = "\(endTime)"
    }
    
    func indicatorDidChangePosition(videoRangeSlider: ABVideoRangeSlider, position: Float64) {
        print("position of indicator: \(position)")
    }

}
