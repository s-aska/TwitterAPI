//
//  ViewController.swift
//  TwitterAPIiOSDemo
//
//  Created by Shinichiro Aska on 9/19/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import Accounts
import TwitterAPI
import OAuthSwift

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func addSocialClient() {
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
                let alert = UIAlertController(title: "Error", message: message, preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
                return
            }
            
            let client = TwitterAPI.client(account: account)
            let url = NSURL(string: "")!
            let parameters = [String: String]()
            client.get(url, parameters: parameters).send() {
                (responseData: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
                
            }
        }
    }
    
    func addOAuthClient() {
        let oauthswift = OAuth1Swift(
            consumerKey:    "",
            consumerSecret: "",
            requestTokenUrl: "https://api.twitter.com/oauth/request_token",
            authorizeUrl:    "https://api.twitter.com/oauth/authorize",
            accessTokenUrl:  "https://api.twitter.com/oauth/access_token"
        )
        oauthswift.authorizeWithCallbackURL(NSURL(string: "yourappscheme://success")!, success: { (credential, response) -> Void in
            let client = TwitterAPI.client(
                consumerKey: "",
                consumerSecret: "",
                accessToken: credential.oauth_token,
                accessTokenSecret: credential.oauth_token_secret)
            
            let url = NSURL(string: "")!
            let parameters = [String: String]()
            client.get(url, parameters: parameters).send() {
                (responseData: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
                
            }
            
            client
                .streaming(NSURL(string: "https://userstream.twitter.com/1.1/user.json")!)
                .progress({ (data: NSData) -> Void in

                })
                .completion({ (responseData: NSData?, response: NSURLResponse?, error: NSError?) -> Void in

                })
                .start()
        }) { (error) -> Void in
            let message = error.description
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
}

