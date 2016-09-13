# TwitterAPI

[![Build Status](https://www.bitrise.io/app/b4ece76000399048.svg?token=3fi0raeSSGrPVhXLDXNk2w&branch=master)](https://www.bitrise.io/app/b4ece76000399048)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![](https://img.shields.io/badge/Xcode-8%2B-brightgreen.svg?style=flat)]()
[![](https://img.shields.io/badge/iOS-9.0%2B-brightgreen.svg?style=flat)]()
[![](https://img.shields.io/badge/OS%20X-10.10%2B-brightgreen.svg?style=flat)]()

This Twitter framework is to both support the OAuth and Social.framework, can handle REST and Streaming API.

:warning: **DEVELOPER RELEASE**

## Features

- Streaming API connection using the NSURLSession
- Both support the OAuth and Social.framework (iOS only)
- Both support the iOS and OSX


## Usage


### Streaming API

```swift
import TwitterAPI
import SwiftyJSON

let request = client
    .streaming("https://userstream.twitter.com/1.1/user.json")
    .progress({ (data: NSData) -> Void in
        // The already divided by CRLF ;)
        // https://dev.twitter.com/streaming/overview/processing
        let json = JSON(data: data)
    })
    .completion({ (responseData: NSData?, response: NSURLResponse?, error: NSError?) -> Void in

    })
    .start()

// disconnect
request.stop()
```

### REST API

```swift
let parameters = [String: String]()
client
    .get("https://api.twitter.com/1.1/statuses/home_timeline.json", parameters: parameters)
    .response {
        (responseData: NSData?, response: NSHTTPURLResponse?, error: NSError?) -> Void in

    }

// Without parameters
client
    .get("https://api.twitter.com/1.1/statuses/home_timeline.json")
    .response {
        (responseData: NSData?, response: NSHTTPURLResponse?, error: NSError?) -> Void in

    }

// POST
client
    .post("https://api.twitter.com/1.1/statuses/update.json", parameters: parameters)
    .response {
        (responseData: NSData?, response: NSHTTPURLResponse?, error: NSError?) -> Void in

    }
```

### with Alamofire

```swift
let client = OAuthClient(
    consumerKey: "",
    consumerSecret: "",
    accessToken: "",
    accessTokenSecret: "")

let url = "https://api.twitter.com/1.1/statuses/update.json"
let parameters = ["status": "Alamofire"]

Alamofire
    .request(client.makeRequest(.POST, url: url, parameters: parameters))
    .reponseJSON { response in

    }
```


## How to get client object

### by OAuth

```swift
import TwitterAPI

let client = OAuthClient(
    consumerKey: "",
    consumerSecret: "",
    accessToken: "",
    accessTokenSecret: "")
```

### by Social.framework

```swift
import Accounts
import TwitterAPI

let client = AccountClient(account: account)
```

### Serialize / Deserialize

Saving and loading can be, for example, using a keychain.

```swift
let string = client.serialize

let client = ClientDeserializer.deserialize(client.serialize)
```


## How to use Social.framework

```swift
import Accounts
import TwitterAPI

let accountStore = ACAccountStore()
let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)

// Prompt the user for permission to their twitter account stored in the phone's settings
accountStore.requestAccessToAccountsWithType(accountType, options: nil) {
    granted, error in

    if !granted {
        let message = error.description
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
        return
    }

    let accounts = accountStore.accountsWithAccountType(accountType) as! [ACAccount]

    guard let account = accounts.first else {
        let message = "There are no Twitter accounts configured. You can add or create a Twitter account in Settings."
        let alert = UIAlertController(title: "Error", message: message,
            preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
        return
    }

    let client = AccountClient(account: account)
    client
        .get("https://api.twitter.com/1.1/statuses/home_timeline.json")
        .response {
            (responseData: NSData?, response: NSHTTPURLResponse?, error: NSError?) -> Void in

        }
}
```


## How to use OAuthSwift

```swift
import OAuthSwift
import TwitterAPI


let oauthswift = OAuth1Swift(
    consumerKey:    "YOUR_APP_CONSUMER_KEY",
    consumerSecret: "YOUR_APP_CONSUMER_SECRET",
    requestTokenUrl: "https://api.twitter.com/oauth/request_token",
    authorizeUrl:    "https://api.twitter.com/oauth/authorize",
    accessTokenUrl:  "https://api.twitter.com/oauth/access_token"
)
oauthswift.authorizeWithCallbackURL(NSURL(string: "yourappscheme://success")!,
    success: { (credential, response) -> Void in
        let client = OAuthClient(
            consumerKey: "YOUR_APP_CONSUMER_KEY",
            consumerSecret: "YOUR_APP_CONSUMER_SECRET",
            accessToken: credential.oauth_token,
            accessTokenSecret: credential.oauth_token_secret)
    }) { (error) -> Void in
        let message = error.description
        let alert = UIAlertController(title: "Error", message: message,
            preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }

// AppDelegate.swift

import UIKit
import OAuthSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(application: UIApplication, openURL url: NSURL,
        sourceApplication: String?, annotation: AnyObject) -> Bool {
        if url.absoluteString.hasPrefix("yourappscheme://success") {
            OAuth1Swift.handleOpenURL(url)
        }

        return true
    }
}
```


## Requirements

- iOS 9.0+ / Mac OS X 10.10+
- Swift 3 and Xcode 8


## Installation

#### Carthage

Add the following line to your [Cartfile](https://github.com/carthage/carthage)

```swift
github "s-aska/TwitterAPI"
```

## License

TwitterAPI is released under the MIT license. See LICENSE for details.
