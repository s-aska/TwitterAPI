//
//  Client.swift
//  Justaway
//
//  Created by Shinichiro Aska on 8/17/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import Foundation

#if os(iOS)
    import OAuthSwift
    import Accounts
    import Social
#else
    import OAuthSwiftOSX
#endif

public protocol TwitterAPIClient {
    
    func request(method: String, url: NSURL, parameters: Dictionary<String, String>) -> NSURLRequest
    
    var serialize: String { get }
}

public extension TwitterAPIClient {
    
    public func streaming(url: NSURL, parameters: Dictionary<String, String> = [:]) -> StreamingRequest {
        return StreamingRequest(request("GET", url: url, parameters: parameters))
    }
    
    public func get(url: NSURL, parameters: Dictionary<String, String> = [:]) -> RESTRequest {
        return RESTRequest(request("GET", url: url, parameters: parameters))
    }
    
    public func post(url: NSURL, parameters: Dictionary<String, String> = [:]) -> RESTRequest {
        return RESTRequest(request("POST", url: url, parameters: parameters))
    }
    
    public func postMedia(data: NSData) -> RESTRequest {
        let media = data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
        let url = NSURL(string: "https://upload.twitter.com/1.1/media/upload.json")!
        return post(url, parameters: ["media": media])
    }
}

extension TwitterAPI {
    
    public class ClientOAuth: TwitterAPIClient {
        
        static var serializeIdentifier = "OAuth"
        
        public let consumerKey: String
        public let consumerSecret: String
        public let oAuthCredential: OAuthSwiftCredential
        
        init(consumerKey: String, consumerSecret: String, accessToken: String, accessTokenSecret: String) {
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
        
        public var serialize: String {
            return [ClientOAuth.serializeIdentifier, consumerKey, consumerSecret, oAuthCredential.oauth_token, oAuthCredential.oauth_token_secret].joinWithSeparator("\t")
        }
        
        public func request(method: String, url: NSURL, parameters: Dictionary<String, String>) -> NSURLRequest {
            let authorization = OAuthSwiftClient.authorizationHeaderForMethod(method, url: url, parameters: parameters, credential: oAuthCredential)
            let headers = ["Authorization": authorization]
            
            let request: NSURLRequest
            do {
                request = try OAuthSwiftHTTPRequest.makeRequest(
                    url, method: method, headers: headers, parameters: parameters, dataEncoding: NSUTF8StringEncoding, encodeParameters: true)
            } catch let error as NSError {
                fatalError("TwitterAPIOAuthClient#request invalid request error:\(error.description)")
            }
            
            return request
        }
    }
}

#if os(iOS)
    extension TwitterAPI {
        
        public class ClientAccount: TwitterAPIClient {
            
            static var serializeIdentifier = "Account"
            
            public let account: ACAccount
            
            init(account: ACAccount) {
                self.account = account
            }
            
            init(serializedString string: String) {
                let parts = string.componentsSeparatedByString("\t")
                self.account = ACAccountStore().accountWithIdentifier(parts[1])
            }
            
            public var serialize: String {
                return [ClientAccount.serializeIdentifier, account.identifier!].joinWithSeparator("\t")
            }
            
            public func request(method: String, url: NSURL, parameters: Dictionary<String, String>) -> NSURLRequest {
                let requestMethod: SLRequestMethod = method == "GET" ? .GET : .POST
                let socialRequest = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: requestMethod, URL: url, parameters: parameters)
                socialRequest.account = account
                return socialRequest.preparedURLRequest()
            }
        }
    }
#endif