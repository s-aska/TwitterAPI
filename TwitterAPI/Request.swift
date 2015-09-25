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
    :param: configuration NSURLSessionConfiguration
    :param: queue NSOperationQueue
    
    :returns: Request
    */
    init(_ request: NSURLRequest, configuration: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration(), queue: NSOperationQueue? = nil) {
        originalRequest = request
        delegate = TaskDelegate()
        let session = NSURLSession(configuration: configuration, delegate: delegate, delegateQueue: queue)
        task = session.dataTaskWithRequest(originalRequest)
    }
    
    public func response(completion: CompletionHandler) {
        delegate.completion = completion
    }
    
    deinit {
        task.resume()
    }
}

// MARK: - TaskDelegate

public class TaskDelegate: NSObject, NSURLSessionDataDelegate {
    private var mutableData = NSMutableData()
    private var completion: CompletionHandler?
    public var response: NSHTTPURLResponse!
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        mutableData.appendData(data)
    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        self.response = response as! NSHTTPURLResponse
        completionHandler(.Allow)
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        dispatch_async(dispatch_get_main_queue(), {
            self.completion?(responseData: self.mutableData, response: self.response, error: error)
        })
    }
}

// MARK: - StreamingRequest

public class StreamingRequest: NSObject, NSURLSessionDataDelegate {
    
    
    
    public var session: NSURLSession?
    public var task: NSURLSessionDataTask?
    public let originalRequest: NSURLRequest
    public let delegate: StreamingDelegate
    
    /**
    Create a StreamingRequest Instance
    
    :param: request NSURLRequest
    */
    public init(_ request: NSURLRequest, configuration: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration(), queue: NSOperationQueue? = nil) {
        originalRequest = request
        delegate = StreamingDelegate()
        session = NSURLSession(configuration: configuration, delegate: delegate, delegateQueue: queue)
        task = session?.dataTaskWithRequest(request)
    }
    
    /**
    Connect streaming.
    
    :returns: self
    */
    public func start() -> StreamingRequest {
        task?.resume()
        return self
    }
    
    /**
    Disconnect streaming.
    */
    public func stop() -> StreamingRequest {
        task?.cancel()
        return self
    }
    
    /**
    Set progress hander.
    
    It will be called for each new line.
    
    See: https://dev.twitter.com/streaming/overview/processing
    
    :param: progress (data: NSData) -> Void
    
    :returns: self
    */
    public func progress(progress: ProgressHandler) -> StreamingRequest {
        delegate.progress = progress
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
    public func completion(completion: CompletionHandler) -> StreamingRequest {
        delegate.completion = completion
        return self
    }
}

// MARK: - StreamingDelegate

public class StreamingDelegate: NSObject, NSURLSessionDataDelegate {
    
    private let serial = dispatch_queue_create("pw.aska.TwitterAPI.TwitterStreamingRequest", DISPATCH_QUEUE_SERIAL)
    
    public var response: NSHTTPURLResponse!
    public let scanner = MutableDataScanner(delimiter: "\r\n")
    private var progress: ProgressHandler?
    private var completion: CompletionHandler?
    
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
        guard let httpURLResponse = response as? NSHTTPURLResponse else {
            fatalError("didReceiveResponse is not NSHTTPURLResponse")
        }
        self.response = httpURLResponse
        
        if httpURLResponse.statusCode == 200 {
            completionHandler(.Allow)
        } else {
            dispatch_async(dispatch_get_main_queue(), {
                self.completion?(responseData: self.scanner.data, response: httpURLResponse, error: nil)
            })
        }
    }
    
    public func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            completionHandler(
                NSURLSessionAuthChallengeDisposition.UseCredential,
                NSURLCredential(forTrust: challenge.protectionSpace.serverTrust!))
        }
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        dispatch_async(dispatch_get_main_queue(), {
            self.completion?(responseData: self.scanner.data, response: self.response, error: error)
        })
    }
}
