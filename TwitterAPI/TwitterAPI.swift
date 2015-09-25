//
//  TwitterAPI.swift
//  Justaway
//
//  Created by Shinichiro Aska on 8/14/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import Foundation
import OAuthSwift

#if os(iOS)
    import Accounts
    import Social
#endif

public enum Method: String {
    case GET, POST
    var slValue: SLRequestMethod {
        get {
            switch self {
            case .GET:
                return SLRequestMethod.GET
            case .POST:
                return SLRequestMethod.POST
            }
        }
    }
}

public class TwitterAPI {
    
    public typealias ProgressHandler = (data: NSData) -> Void
    public typealias CompletionHandler = (responseData: NSData?, response: NSHTTPURLResponse?, error: NSError?) -> Void
    
    /**
    Create a TwitterAPIClient Instance from OAuth Information.
    
    See: https://apps.twitter.com/
    
    :param: consumerKey Consumer Key (API Key)
    :param: consumerSecret Consumer Secret (API Secret)
    :param: accessToken Access Token
    :param: accessTokenSecret Access Token Secret
    
    :returns: TwitterAPIClient
    */
    public class func client(consumerKey consumerKey: String, consumerSecret: String, accessToken: String, accessTokenSecret: String) -> TwitterAPIClient {
        return TwitterAPI.ClientOAuth(consumerKey: consumerKey, consumerSecret: consumerSecret, accessToken: accessToken, accessTokenSecret: accessTokenSecret)
    }
    
    #if os(iOS)
    /**
    Create a TwitterAPIClient Instance from Social.framework.
    
    :param: account ACAccount
    
    :returns: TwitterAPIClient
    */
    public class func client(account account: ACAccount) -> TwitterAPIClient {
        return TwitterAPI.ClientAccount(account: account)
    }
    #endif
    
    /**
    Create a TwitterAPIClient Instance from serialized data.
    
    Like to restore it from the saved information Keychain.
    
    :param: serializedString Getting by TwitterAPIClient#serialize
    
    :returns: TwitterAPIClient
    */
    public class func client(serializedString string: String) -> TwitterAPIClient {
        #if os(iOS)
            switch string {
            case let string where string.hasPrefix(TwitterAPI.ClientOAuth.serializeIdentifier):
                return TwitterAPI.ClientOAuth(serializedString: string)
            
            case let string where string.hasPrefix(TwitterAPI.ClientAccount.serializeIdentifier):
                return TwitterAPI.ClientAccount(serializedString: string)
            default:
                fatalError("invalid serializedString:\(string)")
            }
        #else
            return TwitterAPI.ClientOAuth(serializedString: string)
        #endif
    }
}
