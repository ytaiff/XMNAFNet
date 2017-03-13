//
//  XMNAFNetTests.m
//  XMNAFNetTests
//
//  Created by ws00801526 on 03/13/2017.
//  Copyright (c) 2017 ws00801526. All rights reserved.
//

@import XCTest;

#import <XMNAFNet/XMNAFNet.h>
#import <XMNAFNet/XMNAFReachabilityManager.h>

@interface Tests : XCTestCase

@property (strong, nonatomic) XMNAFNetworkRequest *request;
@property (strong, nonatomic) XMNAFReachabilityManager *reach;

@end

@implementation Tests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.request = [[XMNAFNetworkRequest alloc] init];
    [self.reach startMonitoringWithURL:[NSURL URLWithString:@"https://www.baidu.com"]];
    [self.reach setStatusDidChangedBlock:^(XMNAFReachablityStatus status) {
       
        switch (status) {
            case XMNAFReachablityStatusWifi:
                NSLog(@"change to wifi");
                break;
            case XMNAFReachablityStatusUnknown:
                NSLog(@"无连接");
                break;
            default:
                break;
        }
    }];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testQuery {
    
    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
}

@end

