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

/**
HTTP Request Method
*/
public enum Method: String {
    case GET, POST
    #if os(iOS)
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
    #endif
    var oAuthSwiftValue: OAuthSwiftHTTPRequest.Method {
        get {
            switch self {
            case .GET:
                return OAuthSwiftHTTPRequest.Method.GET
            case .POST:
                return OAuthSwiftHTTPRequest.Method.POST
            }
        }
    }
}

public typealias ProgressHandler = (_ data: Data) -> Void
public typealias CompletionHandler = (_ responseData: Data?, _ response: HTTPURLResponse?, _ error: NSError?) -> Void
