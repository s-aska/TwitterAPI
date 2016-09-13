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
open class Request {

    /// Original Client
    open let originalClient: Client

    /// Original Request
    open let originalRequest: URLRequest

    /// REST API Request Task
    open let task: URLSessionDataTask

    /// REST API Request Task's Delegate
    open let delegate: TaskDelegate

    /**
    Create a Request Instance

    - parameter client: Client
    - parameter request: NSURLRequest
    - parameter configuration: NSURLSessionConfiguration
    - parameter queue: NSOperationQueue
    */
    init(_ client: Client, request: URLRequest, configuration: URLSessionConfiguration = URLSessionConfiguration.default, queue: OperationQueue? = nil) {
        originalClient = client
        originalRequest = request
        delegate = TaskDelegate()
        let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: queue)
        task = session.dataTask(with: originalRequest)
    }

    /**
    Set completion handler

    - parameter completion: CompletionHandler
    */
    open func response(_ completion: @escaping CompletionHandler) {
        delegate.completion = completion
    }

    deinit {
        task.resume()
    }
}

// MARK: - TaskDelegate

open class TaskDelegate: NSObject, URLSessionDataDelegate {

    /// API Response Data
    fileprivate var mutableData = NSMutableData()

    /// API Access Completion Hander
    fileprivate var completion: CompletionHandler?

    /// API Response
    open var response: HTTPURLResponse!

    open func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        mutableData.append(data)
    }

    @nonobjc open func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: (URLSession.ResponseDisposition) -> Void) {
        guard let response = response as? HTTPURLResponse else {
            fatalError("NSHTTPURLResponse")
        }
        self.response = response
        completionHandler(.allow)
    }

    open func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        DispatchQueue.main.async(execute: {
            self.completion?(self.mutableData as Data, self.response, error as NSError?)
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
open class StreamingRequest: NSObject, URLSessionDataDelegate {

    /// Streaming API Session
    open var session: URLSession?

    /// Streaming API Task
    open var task: URLSessionDataTask?

    /// Original Request
    open let originalRequest: URLRequest

    /// Streaming API Delegate
    open let delegate: StreamingDelegate

    /**
    Create a StreamingRequest Instance

     - parameter request: NSURLRequest
     - parameter configuration: NSURLSessionConfiguration?
     - parameter queue: NSOperationQueue?
    */
    public init(_ request: URLRequest, configuration: URLSessionConfiguration = URLSessionConfiguration.default, queue: OperationQueue? = nil) {
        originalRequest = request
        delegate = StreamingDelegate()
        session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: queue)
        task = session?.dataTask(with: request)
    }

    /**
    Connect streaming.

    - returns: self
    */
    open func start() -> StreamingRequest {
        task?.resume()
        return self
    }

    /**
    Disconnect streaming.

     - returns: self
    */
    open func stop() -> StreamingRequest {
        task?.cancel()
        return self
    }

    /**
    Set progress hander.

    It will be called for each new line.

    See: https://dev.twitter.com/streaming/overview/processing

    - parameter progress: (data: NSData) -> Void

    - returns: self
    */
    open func progress(_ progress: @escaping ProgressHandler) -> StreamingRequest {
        delegate.progress = progress
        return self
    }

    /**
    Set completion hander.

    It will be called when an error is received.

    - URLSession:dataTask:didReceiveResponse:completionHandler: (if statusCode is not 200)
    - URLSession:task:didCompleteWithError:

    - parameter completion: (responseData: NSData?, response: NSURLResponse?, error: NSError?) -> Void

    - returns: self
    */
    open func completion(_ completion: @escaping CompletionHandler) -> StreamingRequest {
        delegate.completion = completion
        return self
    }
}

// MARK: - StreamingDelegate

/**
Streaming API Delegate
*/
open class StreamingDelegate: NSObject, URLSessionDataDelegate {

    fileprivate let serial = DispatchQueue(label: "pw.aska.TwitterAPI.TwitterStreamingRequest", attributes: [])

    /// Streaming API Response
    open var response: HTTPURLResponse!

    /// Streaming API Response data buffer
    open let scanner = MutableDataScanner(delimiter: "\r\n")

    /// Streaming API Received JSON Hander
    fileprivate var progress: ProgressHandler?

    /// Streaming API Disconnect Hander
    fileprivate var completion: CompletionHandler?

    open func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        serial.sync {
            self.scanner.append(data)
            while let data = self.scanner.next() {
                if data.count > 0 {
                    self.progress?(data)
                }
            }
        }
    }

    @nonobjc open func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: (URLSession.ResponseDisposition) -> Void) {
        guard let httpURLResponse = response as? HTTPURLResponse else {
            fatalError("didReceiveResponse is not NSHTTPURLResponse")
        }
        self.response = httpURLResponse

        if httpURLResponse.statusCode == 200 {
            completionHandler(.allow)
        } else {
            DispatchQueue.main.async(execute: {
                self.completion?(self.scanner.data, httpURLResponse, nil)
            })
        }
    }

    @nonobjc open func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: (Foundation.URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            completionHandler(
                Foundation.URLSession.AuthChallengeDisposition.useCredential,
                URLCredential(trust: challenge.protectionSpace.serverTrust!))
        }
    }

    open func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        DispatchQueue.main.async(execute: {
            self.completion?(self.scanner.data, self.response, error as NSError?)
        })
    }
}
