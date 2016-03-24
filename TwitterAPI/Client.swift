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

    - parameter method: HTTPMethod
    - parameter url: API endpoint URL
    - parameter parameters: API Parameters

    - returns: NSURLRequest
    */
    func makeRequest(method: Method, url: String, parameters: Dictionary<String, String>) -> NSURLRequest

    /**
    It be to storable the Client object

    How to Restore

    ```swift
    let client = ClientDeserializer.deserialize(client.serialize)
    ```

    - returns: String
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

    - parameter string: Getting by Client#serialize

    - returns: Client
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

    - parameter url: Streaming API endpoint URL. (e.g., https://userstream.twitter.com/1.1/user.json)
    - parameter parameters: Streaming API Request Parameters (See https://dev.twitter.com/streaming/overview)

    - returns: StreamingRequest
    */
    public func streaming(url: String, parameters: Dictionary<String, String> = [:]) -> StreamingRequest {
        return StreamingRequest(makeRequest(.GET, url: url, parameters: parameters))
    }

    /**
    Create a Request Instance to use to GET Method API.

    - parameter url: REST API endpoint URL. (e.g., https://api.twitter.com/1.1/statuses/home_timeline.json)
    - parameter parameters: REST API Request Parameters (See https://dev.twitter.com/rest/public)

    - returns: RESTRequest
    */
    public func get(url: String, parameters: Dictionary<String, String> = [:]) -> Request {
        return request(.GET, url: url, parameters: parameters)
    }

    /**
    Create a Request Instance to use to POST Method API.

    - parameter url: REST API endpoint URL. (e.g., https://api.twitter.com/1.1/statuses/update.json)
    - parameter parameters: REST API Request Parameters (See https://dev.twitter.com/rest/public)

    - returns: RESTRequest
    */
    public func post(url: String, parameters: Dictionary<String, String> = [:]) -> Request {
        return request(.POST, url: url, parameters: parameters)
    }

    /**
    Create a Request Instance to use to Media Upload API.

    Media uploads for images are limited to 5MB in file size.

    MIME-types supported by this endpoint: PNG, JPEG, BMP, WEBP, GIF, Animated GIF

    See: https://dev.twitter.com/rest/reference/post/media/upload

    - parameter data: The raw binary file content being uploaded.

    - returns: RESTRequest
    */
    public func postMedia(data: NSData) -> Request {
        let media = data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
        let url = "https://upload.twitter.com/1.1/media/upload.json"
        return post(url, parameters: ["media": media])
    }

    /**
    Create a Request Instance.

    - parameter method: HTTP Method
    - parameter url: REST API endpoint URL. (e.g., https://api.twitter.com/1.1/statuses/update.json)
    - parameter parameters: REST API Request Parameters (See https://dev.twitter.com/rest/public)

    - returns: RESTRequest
    */
    public func request(method: Method, url: String, parameters: Dictionary<String, String>) -> Request {
        return Request(self, request: makeRequest(method, url: url, parameters: parameters))
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

    public var debugDescription: String {
        return "[consumerKey: \(consumerKey), consumerSecret: \(consumerSecret), accessToken: \(oAuthCredential.oauth_token), accessTokenSecret: \(oAuthCredential.oauth_token_secret)]"
    }

    /**
    Create a TwitterAPIClient Instance from OAuth Information.

    See: https://apps.twitter.com/

    - parameter consumerKey: Consumer Key (API Key)
    - parameter consumerSecret: Consumer Secret (API Secret)
    - parameter accessToken: Access Token
    - parameter accessTokenSecret: Access Token Secret
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

    - returns: String
    */
    public var serialize: String {
        return [OAuthClient.serializeIdentifier, consumerKey, consumerSecret, oAuthCredential.oauth_token, oAuthCredential.oauth_token_secret].joinWithSeparator("\t")
    }

    /**
    It will generate a NSURLRequest object with the authentication header.

    - parameter method: HTTPMethod
    - parameter url: API endpoint URL
    - parameter parameters: API Parameters

    - returns: NSURLRequest
    */
    public func makeRequest(method: Method, url urlString: String, parameters: Dictionary<String, String>) -> NSURLRequest {
        let url = NSURL(string: urlString)!
        let authorization = oAuthCredential.authorizationHeaderForMethod(method.oAuthSwiftValue, url: url, parameters: parameters)
        let headers = ["Authorization": authorization]

        let request: NSURLRequest
        do {
            request = try OAuthSwiftHTTPRequest.makeRequest(
                url, method: method.oAuthSwiftValue, headers: headers, parameters: parameters, dataEncoding: NSUTF8StringEncoding)
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

        public let identifier: String

        /// ACAccount
        public var account: ACAccount {
            get {
                if let ac = accountCache {
                    return ac
                } else {
                    let ac = ACAccountStore().accountWithIdentifier(identifier)
                    accountCache = ac
                    return ac
                }
            }
        }
        private var accountCache: ACAccount?

        public var debugDescription: String {
            return "[identifier: \(identifier), cache: " + (accountCache != nil ? "exists" : "nil") + "]"
        }

        /**
        Create a Client Instance from ACAccount(Social.framework).

        - parameter account: ACAccount
        */
        public init(account: ACAccount) {
            self.accountCache = account
            self.identifier = account.identifier!
        }

        init(serializedString string: String) {
            let parts = string.componentsSeparatedByString("\t")
            self.identifier = parts[1]
        }

        /**
        It be to storable the Client object

        How to Restore

        ```swift
        let client = ClientDeserializer.deserialize(client.serialize)
        ```

        - returns: String
        */
        public var serialize: String {
            return [AccountClient.serializeIdentifier, account.identifier!].joinWithSeparator("\t")
        }

        /**
        It will generate a NSURLRequest object with the authentication header.

        - parameter method: HTTPMethod
        - parameter url: API endpoint URL
        - parameter parameters: API Parameters

        - returns: NSURLRequest
        */
        public func makeRequest(method: Method, url urlString: String, parameters: Dictionary<String, String>) -> NSURLRequest {
            let url = NSURL(string: urlString)!
            let socialRequest = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: method.slValue, URL: url, parameters: parameters)
            socialRequest.account = account
            return socialRequest.preparedURLRequest()
        }
    }
#endif
