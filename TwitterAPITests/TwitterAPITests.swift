//
//  TwitterAPITests.swift
//  TwitterAPITests
//
//  Created by Shinichiro Aska on 9/19/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import XCTest
import TwitterAPI
import OAuthSwift

#if os(iOS)
    import Accounts
    import Social
#endif

class TwitterAPITests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSerializeOAuth() {
        let client = TwitterAPI.client(consumerKey: "hoge", consumerSecret: "foo", accessToken: "bar", accessTokenSecret: "baz")
        XCTAssertEqual(client.serialize, "OAuth\thoge\tfoo\tbar\tbaz", "client.serialize")
        
        let clientCopy = TwitterAPI.client(serializedString: client.serialize)
        XCTAssertEqual(clientCopy.serialize, "OAuth\thoge\tfoo\tbar\tbaz", "client.serialize")
    }
    
    func testGET() {
        let client = TwitterAPI.client(consumerKey: "hoge", consumerSecret: "foo", accessToken: "bar", accessTokenSecret: "baz")
        let request = client.get(NSURL(string: "https://api.twitter.com/1.1/statuses/home_timeline.json")!)
        XCTAssertEqual(request.request.URL?.absoluteString, "https://api.twitter.com/1.1/statuses/home_timeline.json")
        XCTAssertEqual(request.request.HTTPMethod, "GET")
    }
    
    func testPOST() {
        let client = TwitterAPI.client(consumerKey: "hoge", consumerSecret: "foo", accessToken: "bar", accessTokenSecret: "baz")
        let request = client.post(NSURL(string: "https://api.twitter.com/1.1/statuses/home_timeline.json")!)
        XCTAssertEqual(request.request.HTTPMethod, "POST")
    }
    
    func testStreaming() {
        let client = TwitterAPI.client(consumerKey: "hoge", consumerSecret: "foo", accessToken: "bar", accessTokenSecret: "baz")
        let request = client.streaming(NSURL(string: "https://userstream.twitter.com/1.1/user.json")!)
        XCTAssertEqual(request.request.URL?.absoluteString, "https://userstream.twitter.com/1.1/user.json")
        XCTAssertEqual(request.request.HTTPMethod, "GET")
    }
    
    func testGETWithParameters() {
        let client = TwitterAPI.client(consumerKey: "hoge", consumerSecret: "foo", accessToken: "bar", accessTokenSecret: "baz")
        let request = client.get(NSURL(string: "https://api.twitter.com/1.1/statuses/home_timeline.json")!, parameters: ["count": "200"])
        XCTAssertEqual(request.request.URL?.absoluteString, "https://api.twitter.com/1.1/statuses/home_timeline.json?count=200")
        XCTAssertEqual(request.request.URL?.query, "count=200")
        XCTAssertEqual(request.request.HTTPMethod, "GET")
    }
    
    func testPOSTWithParameters() {
        let client = TwitterAPI.client(consumerKey: "hoge", consumerSecret: "foo", accessToken: "bar", accessTokenSecret: "baz")
        let request = client.post(NSURL(string: "https://api.twitter.com/1.1/statuses/update.json")!, parameters: ["status": "test"])
        XCTAssertEqual(request.request.URL?.absoluteString, "https://api.twitter.com/1.1/statuses/update.json")
        XCTAssertEqual(NSString(data: request.request.HTTPBody!, encoding: NSUTF8StringEncoding), "status=test")
        XCTAssertEqual(request.request.HTTPMethod, "POST")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
