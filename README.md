# ABVideoRangeSlider

[![CI Status](http://img.shields.io/travis/Oscar%20J.%20Irun/ABVideoRangeSlider.svg?style=flat)](https://travis-ci.org/Oscar%20J.%20Irun/ABVideoRangeSlider)
[![Version](https://img.shields.io/cocoapods/v/ABVideoRangeSlider.svg?style=flat)](http://cocoapods.org/pods/ABVideoRangeSlider)
[![License](https://img.shields.io/cocoapods/l/ABVideoRangeSlider.svg?style=flat)](http://cocoapods.org/pods/ABVideoRangeSlider)
[![Platform](https://img.shields.io/cocoapods/p/ABVideoRangeSlider.svg?style=flat)](http://cocoapods.org/pods/ABVideoRangeSlider)

Customizable Video Range Slider for trimming videos written in Swift 3.

![Portrait](https://raw.githubusercontent.com/AppsBoulevard/ABVideoRangeSlider/master/Screenshots/Portrait.png "Portrait")

![Custom Indicators](https://raw.githubusercontent.com/AppsBoulevard/ABVideoRangeSlider/master/Screenshots/CustomIndicators.png "Custom Indicators")

![Progress Indicator](https://raw.githubusercontent.com/AppsBoulevard/ABVideoRangeSlider/master/Screenshots/ProgressIndicator.png "Progress Indicator")

![Custom Time Labels](https://raw.githubusercontent.com/AppsBoulevard/ABVideoRangeSlider/master/Screenshots/CustomTimeLabels.png "Custom Time Labels")

## Installation

ABVideoRangeSlider is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "ABVideoRangeSlider"
```

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Usage
1. Insert an `UIView` in your Storyboard's `ViewController`
2. Change the class of your view to 'ABVideoRangeSlider'
3. Import `ABVideoRangeSlider` into your `ViewController`
4. `Control + Drag` your `UIView`  to create an `IBOutlet` in your `ViewController`
```Swift
@IBOutlet var videoRangeSlider: ABVideoRangeSlider!
```
5. Add `ABVideoRangeSliderDelegate` to your controller
6. Setup:
``` Swift
// Set the video URL
var path = Bundle.main.path(forResource: "myVideo", ofType:"mp4")
videoRangeSlider.setVideoURL(videoURL: URL(fileURLWithPath: path!))

// Set the delegate
videoRangeSlider.delegate = self

// Set a minimun space (in seconds) between the Start indicator and End indicator
videoRangeSlider.minSpace = 60.0

// Set a maximun space (in seconds) between the Start indicator and End indicator - Default is 0 (no max limit)
videoRangeSlider.maxSpace = 120.0
```

``` Swift
// Set initial position of Start Indicator
videoRangeSlider.setStartPosition(seconds: 50.0)

// Set initial position of End Indicator
videoRangeSlider.setEndPosition(seconds: 150.0)
```

## Progress indicator

You can show/hide this indicator using the following methods

```Swift
    videoRangeSlider.hideProgressIndicator()
    videoRangeSlider.showProgressIndicator()
```
If you want to update the position:

```Swift
    videoRangeSlider.updateProgressIndicator(seconds: elapsedTimeOfVideo)
```

## Custom Time Labels

You can customize the time label's backgrounds providing a custom `UIView` to `videoRangeSlider.startTimeView.backgroundView`.

Example
```Swift
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

```

Properties
```Swift
  // Shows the formatted time
  timeLabel: UILabel

  // UILabel's margins - Default = 5.0
  marginTop: CGFloat     
  marginBottom: CGFloat   
  marginLeft: CGFloat      
  marginRight: CGFloat   

  // Background View
  backgroundView : UIView

```

## Protocols

```Swift
func didChangeValue(videoRangeSlider: ABVideoRangeSlider, startTime: Float64, endTime: Float64) {
    print(startTime)    // Prints the position of the Start indicator in seconds
    print(endTime)      // Prints the position of the End indicator in seconds
}
```

```Swift
func indicatorDidChangePosition(videoRangeSlider: ABVideoRangeSlider, position: Float64) {
    print(position)      // Prints the position of the Progress indicator in seconds
}
```

## Customization

```Swift
        // Customize the Start indicator with a custom image
        let customStartIndicator =  UIImage(named: "CustomStartIndicator")
        videoRangeSlider.setStartIndicatorImage(image: customStartIndicator!)

        // Customize the End indicator with a custom image
        let customEndIndicator =  UIImage(named: "CustomEndIndicator")
        videoRangeSlider.setEndIndicatorImage(image: customEndIndicator!)

        // Customize bottom and top border with a custom image
        let customBorder =  UIImage(named: "CustomBorder")
        videoRangeSlider.setBorderImage(image: customBorder!)

        // Customize Progress indicator with a custom image
        let customProgressIndicator =  UIImage(named: "CustomProgressIndicator")
        videoRangeSlider.setProgressIndicatorImage(image: customProgressIndicator!)
```

## Public method
If you need to update the thumbnails of the video, you can call this method manually. (By default it's called every time the view changes its bounds)
```Swift
videoRangeSlider.updateThumbnails()
```
## Author
[Apps Boulevard](http://www.appsboulevard.com)

* Twitter: [@AppsBoulevard](twitter.com/AppsBoulevard)
* Facebook: [facebook.com/AppsBoulevard](facebook.com/AppsBoulevard)
* Email: hello@appsboulevard.com

## License

ABVideoRangeSlider is available under the MIT license. See the LICENSE file for more info.
