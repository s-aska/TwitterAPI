//
//  Request.swift
//  Justaway
//
//  Created by Shinichiro Aska on 9/5/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import Foundation
import MutableDataScanner

public class Request {
    
    public let originalRequest: NSURLRequest
    public let task: NSURLSessionDataTask
    public let delegate: TaskDelegate
    
    /**
    Create a Request Instance
    
    :param: request NSURLRequest
    */
    init(_ request: NSURLRequest) {
        originalRequest = request
        delegate = TaskDelegate()
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        task = session.dataTaskWithRequest(originalRequest)
        
    }
    
    public func response(completion: TwitterAPI.CompletionHandler) {
        delegate.completion = completion
    }
    
    deinit {
        task.resume()
    }
}

public class TaskDelegate: NSObject, NSURLSessionDataDelegate {
    private var mutableData = NSMutableData()
    private var completion: TwitterAPI.CompletionHandler?
    public var response: NSURLResponse!
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        mutableData.appendData(data)
    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        self.response = response
        completionHandler(.Allow)
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        dispatch_async(dispatch_get_main_queue(), {
            self.completion?(responseData: self.mutableData, response: self.response, error: error)
        })
    }
}

public class StreamingRequest: NSObject, NSURLSessionDataDelegate {
    
    private let serial = dispatch_queue_create("pw.aska.TwitterAPI.TwitterStreamingRequest", DISPATCH_QUEUE_SERIAL)
    
    public var session: NSURLSession?
    public var task: NSURLSessionDataTask?
    public let request: NSURLRequest
    public var response: NSURLResponse!
    public let scanner = MutableDataScanner(delimiter: "\r\n")
    private var progress: TwitterAPI.ProgressHandler?
    private var completion: TwitterAPI.CompletionHandler?
    
    /**
    Create a StreamingRequest Instance
    
    :param: request NSURLRequest
    */
    public init(_ request: NSURLRequest) {
        self.request = request
    }
    
    /**
    Connect streaming.
    
    :returns: self
    */
    public func start() -> StreamingRequest {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        task = session?.dataTaskWithRequest(request)
        task?.resume()
        return self
    }
    
    /**
    Disconnect streaming.
    */
    public func stop() {
        task?.cancel()
    }
    
    /**
    Set progress hander.
    
    It will be called for each new line.
    
    See: https://dev.twitter.com/streaming/overview/processing
    
    :param: progress (data: NSData) -> Void
    
    :returns: self
    */
    public func progress(progress: TwitterAPI.ProgressHandler) -> StreamingRequest {
        self.progress = progress
        return self
    }
    
    /**
    Set completion hander.
    
    It will be called when an error is received.
    
    - URLSession:dataTask:didReceiveResponse:completionHandler: (if statusCode is not 200)
    - URLSession:task:didCompleteWithError:
    
    :param: completion (responseData: NSData?, response: NSURLResponse?, error: NSError?) -> Void
    
    :returns: self
    */
    public func completion(completion: TwitterAPI.CompletionHandler) -> StreamingRequest {
        self.completion = completion
        return self
    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        dispatch_sync(serial) {
            self.scanner.appendData(data)
            while let data = self.scanner.next() {
                if data.length > 0 {
                    self.progress?(data: data)
                }
            }
        }
    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        self.response = response
        if let httpURLResponse = response as? NSHTTPURLResponse {
            if httpURLResponse.statusCode == 200 {
                completionHandler(.Allow)
            } else {
                completion?(responseData: scanner.data, response: response, error: nil)
            }
        } else {
            fatalError("didReceiveResponse is not NSHTTPURLResponse")
        }
    }
    
    public func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if challenge.protectionSpace.host == request.URL?.host {
                completionHandler(
                    NSURLSessionAuthChallengeDisposition.UseCredential,
                    NSURLCredential(forTrust: challenge.protectionSpace.serverTrust!))
            }
        }
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        dispatch_async(dispatch_get_main_queue(), {
            self.completion?(responseData: self.scanner.data, response: self.response, error: error)
        })
    }
}
