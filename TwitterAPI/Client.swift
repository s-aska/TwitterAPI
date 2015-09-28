//
//  Client.swift
//  Justaway
//
//  Created by Shinichiro Aska on 8/17/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import Foundation
import OAuthSwift

#if os(iOS)
    import Accounts
    import Social
#endif

/**
Have the authentication information.

It is possible to generate the request.
*/
public protocol Client {
    
    /**
    It will generate a NSURLRequest object with the authentication header.
    
    - Parameter method: HTTPMethod
    - Parameter url: API endpoint URL
    - Parameter parameters: API Parameters
    
    - Returns: NSURLRequest
    */
    func makeRequest(method: Method, url: String, parameters: Dictionary<String, String>) -> NSURLRequest
    
    /**
    It be to storable the Client object
    
    How to Restore
    
    ```swift
    let client = ClientDeserializer.deserialize(client.serialize)
    ```
    
    - Returns: String
    */
    var serialize: String { get }
}

/**
Deserialize the Client Instance from String.
*/
public class ClientDeserializer {
    
    /**
    Create a Client Instance from serialized data.
    
    Like to restore it from the saved information Keychain.
    
    - Parameter serializedString: Getting by Client#serialize
    
    - Returns: Client
    */
    public class func deserialize(string: String) -> Client {
        #if os(iOS)
            switch string {
            case let string where string.hasPrefix(OAuthClient.serializeIdentifier):
                return OAuthClient(serializedString: string)
                
            case let string where string.hasPrefix(AccountClient.serializeIdentifier):
                return AccountClient(serializedString: string)
            default:
                fatalError("invalid serializedString:\(string)")
            }
        #else
            return OAuthClient(serializedString: string)
        #endif
    }
}

public extension Client {
    
    /**
    Create a StreamingRequest Instance.
    
    - Parameter url: Streaming API endpoint URL. (e.g., https://userstream.twitter.com/1.1/user.json)
    - Parameter parameters: Streaming API Request Parameters (See https://dev.twitter.com/streaming/overview)
    
    - Returns: StreamingRequest
    */
    public func streaming(url: String, parameters: Dictionary<String, String> = [:]) -> StreamingRequest {
        return StreamingRequest(makeRequest(.GET, url: url, parameters: parameters))
    }
    
    /**
    Create a Request Instance to use to GET Method API.
    
    - Parameter url: REST API endpoint URL. (e.g., https://api.twitter.com/1.1/statuses/home_timeline.json)
    - Parameter parameters: REST API Request Parameters (See https://dev.twitter.com/rest/public)
    
    - Returns: RESTRequest
    */
    public func get(url: String, parameters: Dictionary<String, String> = [:]) -> Request {
        return request(.GET, url: url, parameters: parameters)
    }
    
    /**
    Create a Request Instance to use to POST Method API.
    
    - Parameter url: REST API endpoint URL. (e.g., https://api.twitter.com/1.1/statuses/update.json)
    - Parameter parameters: REST API Request Parameters (See https://dev.twitter.com/rest/public)
    
    - Returns: RESTRequest
    */
    public func post(url: String, parameters: Dictionary<String, String> = [:]) -> Request {
        return request(.POST, url: url, parameters: parameters)
    }
    
    /**
    Create a Request Instance to use to Media Upload API.
    
    Media uploads for images are limited to 5MB in file size.
    
    MIME-types supported by this endpoint: PNG, JPEG, BMP, WEBP, GIF, Animated GIF
    
    See: https://dev.twitter.com/rest/reference/post/media/upload
    
    - Parameter data: The raw binary file content being uploaded.
    
    - Returns: RESTRequest
    */
    public func postMedia(data: NSData) -> Request {
        let media = data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
        let url = "https://upload.twitter.com/1.1/media/upload.json"
        return post(url, parameters: ["media": media])
    }
    
    /**
    Create a Request Instance.
    
    - Parameter method: HTTP Method
    - Parameter url: REST API endpoint URL. (e.g., https://api.twitter.com/1.1/statuses/update.json)
    - Parameter parameters: REST API Request Parameters (See https://dev.twitter.com/rest/public)
    
    - Returns: RESTRequest
    */
    public func request(method: Method, url: String, parameters: Dictionary<String, String>) -> Request {
        return Request(makeRequest(method, url: url, parameters: parameters))
    }
}

/**
Client to have the authentication information of OAuth
*/
public class OAuthClient: Client {
    
    static var serializeIdentifier = "OAuth"
    
    /// Twitter Consumer Key (API Key)
    public let consumerKey: String
    
    /// Twitter Consumer Secret (API Secret)
    public let consumerSecret: String
    
    /// Twitter Credential (AccessToken)
    public let oAuthCredential: OAuthSwiftCredential
    
    /**
    Create a TwitterAPIClient Instance from OAuth Information.
    
    See: https://apps.twitter.com/
    
    - Parameter consumerKey: Consumer Key (API Key)
    - Parameter consumerSecret: Consumer Secret (API Secret)
    - Parameter accessToken: Access Token
    - Parameter accessTokenSecret: Access Token Secret
    
    - Returns: OAuthClient
    */
    public init(consumerKey: String, consumerSecret: String, accessToken: String, accessTokenSecret: String) {
        self.consumerKey = consumerKey
        self.consumerSecret = consumerSecret
        let credential = OAuthSwiftCredential(consumer_key: consumerKey, consumer_secret: consumerSecret)
        credential.oauth_token = accessToken
        credential.oauth_token_secret = accessTokenSecret
        self.oAuthCredential = credential
    }
    
    convenience init(serializedString string: String) {
        let parts = string.componentsSeparatedByString("\t")
        self.init(consumerKey: parts[1], consumerSecret: parts[2], accessToken: parts[3], accessTokenSecret: parts[4])
    }
    
    /**
    It be to storable the Client object
    
    How to Restore
    
    ```swift
    let client = ClientDeserializer.deserialize(client.serialize)
    ```
    
    - Returns: String
    */
    public var serialize: String {
        return [OAuthClient.serializeIdentifier, consumerKey, consumerSecret, oAuthCredential.oauth_token, oAuthCredential.oauth_token_secret].joinWithSeparator("\t")
    }
    
    /**
    It will generate a NSURLRequest object with the authentication header.
    
    - Parameter method: HTTPMethod
    - Parameter url: API endpoint URL
    - Parameter parameters: API Parameters
    
    - Returns: NSURLRequest
    */
    public func makeRequest(method: Method, url urlString: String, parameters: Dictionary<String, String>) -> NSURLRequest {
        let url = NSURL(string: urlString)!
        let authorization = OAuthSwiftClient.authorizationHeaderForMethod(method.rawValue, url: url, parameters: parameters, credential: oAuthCredential)
        let headers = ["Authorization": authorization]
        
        let request: NSURLRequest
        do {
            request = try OAuthSwiftHTTPRequest.makeRequest(
                url, method: method.rawValue, headers: headers, parameters: parameters, dataEncoding: NSUTF8StringEncoding, encodeParameters: true)
        } catch let error as NSError {
            fatalError("TwitterAPIOAuthClient#request invalid request error:\(error.description)")
        } catch {
            fatalError("TwitterAPIOAuthClient#request invalid request unknwon error")
        }
        
        return request
    }
}

#if os(iOS)
    /**
    Client to have the authentication information of ACAccount
    */
    public class AccountClient: Client {
        
        static var serializeIdentifier = "Account"
        
        /// ACAccount
        public let account: ACAccount
        
        /**
        Create a Client Instance from ACAccount(Social.framework).
        
        - Parameter account: ACAccount
        
        - Returns: AccountClient
        */
        public init(account: ACAccount) {
            self.account = account
        }
        
        init(serializedString string: String) {
            let parts = string.componentsSeparatedByString("\t")
            self.account = ACAccountStore().accountWithIdentifier(parts[1])
        }
        
        /**
        It be to storable the Client object
        
        How to Restore
        
        ```swift
        let client = ClientDeserializer.deserialize(client.serialize)
        ```
        
        - Returns: String
        */
        public var serialize: String {
            return [AccountClient.serializeIdentifier, account.identifier!].joinWithSeparator("\t")
        }
        
        /**
        It will generate a NSURLRequest object with the authentication header.
        
        - Parameter method: HTTPMethod
        - Parameter url: API endpoint URL
        - Parameter parameters: API Parameters
        
        - Returns: NSURLRequest
        */
        public func makeRequest(method: Method, url urlString: String, parameters: Dictionary<String, String>) -> NSURLRequest {
            let url = NSURL(string: urlString)!
            let socialRequest = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: method.slValue, URL: url, parameters: parameters)
            socialRequest.account = account
            return socialRequest.preparedURLRequest()
        }
    }
#endif
