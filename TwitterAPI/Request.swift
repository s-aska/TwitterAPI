//
//  Request.swift
//  Justaway
//
//  Created by Shinichiro Aska on 9/5/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import Foundation
import MutableDataScanner

/**
REST API Request

```swift
// Get a Request Instance
let request = client.get("https://api.twitter.com/1.1/statuses/home_timeline.json")
```
*/
public class Request {
    
    /// Original Request
    public let originalRequest: NSURLRequest
    
    /// REST API Request Task
    public let task: NSURLSessionDataTask
    
    /// REST API Request Task's Delegate
    public let delegate: TaskDelegate
    
    /**
    Create a Request Instance
    
    - Parameter request: NSURLRequest
    - Parameter configuration: NSURLSessionConfiguration
    - Parameter queue: NSOperationQueue
    
    - returns: Request
    */
    init(_ request: NSURLRequest, configuration: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration(), queue: NSOperationQueue? = nil) {
        originalRequest = request
        delegate = TaskDelegate()
        let session = NSURLSession(configuration: configuration, delegate: delegate, delegateQueue: queue)
        task = session.dataTaskWithRequest(originalRequest)
    }
    
    /**
    Set completion handler
    
    - Parameter completion: CompletionHandler
    */
    public func response(completion: CompletionHandler) {
        delegate.completion = completion
    }
    
    deinit {
        task.resume()
    }
}

// MARK: - TaskDelegate

public class TaskDelegate: NSObject, NSURLSessionDataDelegate {
    
    /// API Response Data
    private var mutableData = NSMutableData()
    
    /// API Access Completion Hander
    private var completion: CompletionHandler?
    
    /// API Response
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

/**
Streaming API Request

```swift
// Get a StreamingRequest Instance
let request = client.streaming("https://userstream.twitter.com/1.1/user.json")
```
*/
public class StreamingRequest: NSObject, NSURLSessionDataDelegate {
    
    /// Streaming API Session
    public var session: NSURLSession?
    
    /// Streaming API Task
    public var task: NSURLSessionDataTask?
    
    /// Original Request
    public let originalRequest: NSURLRequest
    
    /// Streaming API Delegate
    public let delegate: StreamingDelegate
    
    /**
    Create a StreamingRequest Instance
    
    - Parameter request: NSURLRequest
    */
    public init(_ request: NSURLRequest, configuration: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration(), queue: NSOperationQueue? = nil) {
        originalRequest = request
        delegate = StreamingDelegate()
        session = NSURLSession(configuration: configuration, delegate: delegate, delegateQueue: queue)
        task = session?.dataTaskWithRequest(request)
    }
    
    /**
    Connect streaming.
    
    - returns: self
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
    
    - Parameter progress: (data: NSData) -> Void
    
    - returns: self
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
    
    - Parameter completion: (responseData: NSData?, response: NSURLResponse?, error: NSError?) -> Void
    
    - returns: self
    */
    public func completion(completion: CompletionHandler) -> StreamingRequest {
        delegate.completion = completion
        return self
    }
}

// MARK: - StreamingDelegate

/**
Streaming API Delegate
*/
public class StreamingDelegate: NSObject, NSURLSessionDataDelegate {
    
    private let serial = dispatch_queue_create("pw.aska.TwitterAPI.TwitterStreamingRequest", DISPATCH_QUEUE_SERIAL)
    
    /// Streaming API Response
    public var response: NSHTTPURLResponse!
    
    /// Streaming API Response data buffer
    public let scanner = MutableDataScanner(delimiter: "\r\n")
    
    /// Streaming API Received JSON Hander
    private var progress: ProgressHandler?
    
    /// Streaming API Disconnect Hander
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
