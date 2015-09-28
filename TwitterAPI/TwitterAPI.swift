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
}

public typealias ProgressHandler = (data: NSData) -> Void
public typealias CompletionHandler = (responseData: NSData?, response: NSHTTPURLResponse?, error: NSError?) -> Void
