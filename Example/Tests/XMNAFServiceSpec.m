//
//  XMNAFServiceSpec.m
//  XMNAFNet
//
//  Created by XMFraker on 2017/5/15.
//  Copyright 2017年 ws00801526. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import <XMNAFNet/XMNAFNet.h>


@interface XMNTestService : XMNAFService

@end

@implementation XMNTestService

- (NSString *)apiBaseURL {
    
    return @"https://www.baidu.com";
}

- (NSString *)apiVersion {
    
    return @"1.2.0";
}

@end

SPEC_BEGIN(XMNAFServiceSpec)

describe(@"XMNAFService", ^{

    context(@"test service", ^{
        
        
        it(@"service ", ^{
           
            [[[XMNTestService class] shouldNot] beNil];
            
            XMNTestService *service = [[XMNTestService alloc] init];
            [[service shouldNot] beNil];
            
            [[[XMNAFService storedServices] should] beEmpty];
            
            [XMNAFService storeService:service forIdentifier:@"123"];
            
            [[[XMNAFService storedServices] should] haveCountOf:1];
            
            [[[XMNAFService serviceWithIdentifier:@"123"] shouldNot] beNil];
            
            [[[XMNAFService serviceWithIdentifier:@"123"].apiVersion should] equal:@"1.2.0"];
            [[[XMNAFService serviceWithIdentifier:@"123"].apiBaseURL should] equal:@"https://www.baidu.com"];

            [[[XMNAFService serviceWithIdentifier:@"1234"] should] beNil];

        });
    });
});

SPEC_END
