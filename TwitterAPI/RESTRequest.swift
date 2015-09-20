//
//  RESTRequest.swift
//  Justaway
//
//  Created by Shinichiro Aska on 9/5/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import Foundation

public class RESTRequest {
    
    public let request: NSURLRequest
    
    /**
    Create a RESTRequest Instance
    
    :param: request NSURLRequest
    */
    init(_ request: NSURLRequest) {
        self.request = request
    }
    
    /**
    Set progress hander.
    
    It will be called for each new line.
    
    See: https://dev.twitter.com/streaming/overview/processing
    
    :param: progress (data: NSData) -> Void
    
    :returns: NSURLSessionDataTask
    */
    public func send(completion: TwitterAPI.CompletionHandler? = nil) -> NSURLSessionDataTask {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
        let task = session.dataTaskWithRequest(request) { (responseData, response, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                completion?(responseData: responseData, response: response, error: error)
            })
        }
        task.resume()
        return task
    }
}
