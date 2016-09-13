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
        let client = OAuthClient(consumerKey: "hoge", consumerSecret: "foo", accessToken: "bar", accessTokenSecret: "baz")
        
        XCTAssertEqual(client.debugDescription, "[consumerKey: hoge, consumerSecret: foo, accessToken: bar, accessTokenSecret: baz]", "client.debugDescription")
        
        XCTAssertEqual(client.serialize, "OAuth\thoge\tfoo\tbar\tbaz", "client.serialize")
        
        let clientCopy = ClientDeserializer.deserialize(client.serialize)
        XCTAssertEqual(clientCopy.serialize, "OAuth\thoge\tfoo\tbar\tbaz", "client.serialize")
    }
    
    func testGET() {
        let client = OAuthClient(consumerKey: "hoge", consumerSecret: "foo", accessToken: "bar", accessTokenSecret: "baz")
        let request = client.get("https://api.twitter.com/1.1/statuses/home_timeline.json")
        XCTAssertEqual(request.originalRequest.url?.absoluteString, "https://api.twitter.com/1.1/statuses/home_timeline.json")
        XCTAssertEqual(request.originalRequest.httpMethod, "GET")
    }
    
    func testPOST() {
        let client = OAuthClient(consumerKey: "hoge", consumerSecret: "foo", accessToken: "bar", accessTokenSecret: "baz")
        let request = client.post("https://api.twitter.com/1.1/statuses/home_timeline.json", parameters: ["status": "hoge/\nfoo\nbar"])
        XCTAssertEqual(NSString(data: request.originalRequest.httpBody!, encoding: String.Encoding.utf8.rawValue)!, "status=hoge%2F%0Afoo%0Abar")
        XCTAssertEqual(request.originalRequest.httpMethod, "POST")
    }
    
    func testStreaming() {
        let client = OAuthClient(consumerKey: "hoge", consumerSecret: "foo", accessToken: "bar", accessTokenSecret: "baz")
        let request = client.streaming("https://userstream.twitter.com/1.1/user.json")
        XCTAssertEqual(request.originalRequest.url?.absoluteString, "https://userstream.twitter.com/1.1/user.json")
        XCTAssertEqual(request.originalRequest.httpMethod, "GET")
    }
    
    func testGETWithParameters() {
        let client = OAuthClient(consumerKey: "hoge", consumerSecret: "foo", accessToken: "bar", accessTokenSecret: "baz")
        let request = client.get("https://api.twitter.com/1.1/statuses/home_timeline.json", parameters: ["count": "200"])
        XCTAssertEqual(request.originalRequest.url?.absoluteString, "https://api.twitter.com/1.1/statuses/home_timeline.json?count=200")
        XCTAssertEqual(request.originalRequest.url?.query, "count=200")
        XCTAssertEqual(request.originalRequest.httpMethod, "GET")
    }
    
    func testPOSTWithParameters() {
        let client = OAuthClient(consumerKey: "hoge", consumerSecret: "foo", accessToken: "bar", accessTokenSecret: "baz")
        let request = client.post("https://api.twitter.com/1.1/statuses/update.json", parameters: ["status": "test"])
        XCTAssertEqual(request.originalRequest.url?.absoluteString, "https://api.twitter.com/1.1/statuses/update.json")
        XCTAssertEqual(NSString(data: request.originalRequest.httpBody!, encoding: String.Encoding.utf8.rawValue), "status=test")
        XCTAssertEqual(request.originalRequest.httpMethod, "POST")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
