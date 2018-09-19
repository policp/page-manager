# page-manager

[![CI Status](https://img.shields.io/travis/policp/page-manager.svg?style=flat)](https://travis-ci.org/policp/page-manager)
[![Version](https://img.shields.io/cocoapods/v/page-manager.svg?style=flat)](https://cocoapods.org/pods/page-manager)
[![License](https://img.shields.io/cocoapods/l/page-manager.svg?style=flat)](https://cocoapods.org/pods/page-manager)
[![Platform](https://img.shields.io/cocoapods/p/page-manager.svg?style=flat)](https://cocoapods.org/pods/page-manager)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Basic Examples

###use push

```swift
///MARK: push   
PageManager.share.push("MainViewController", pushAnimator: .fade) { (target) in
            target.setValue("Joy", forKey: "name")
        }

```

### use pop

```swift
///MARK: pop
PageManager.share.pop("pageName", true) { (target) in
            target.setValue(true, forKey: "reloadData")
        }
```



## Screenshots

![avatar](https://github.com/policp/page-manager/blob/master/example.gif)

## Installation

page-manager is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'page-manager'
```

## Author

policp, chenpeng@yingyinglicai.com

## License

page-manager is available under the MIT license. See the LICENSE file for more info.
