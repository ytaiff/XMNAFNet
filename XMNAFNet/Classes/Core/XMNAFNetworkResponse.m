//
//  XMNAFNetworkResponse.m
//  XMNAFNetworkDemo
//
//  Created by XMFraker on 16/4/22.
//  Copyright © 2016年 XMFraker. All rights reserved.
//

#import "XMNAFNetworkResponse.h"

#import "NSURLSessionTask+XMNAFNet.h"

@interface XMNAFNetworkResponse ()

@property (nonatomic, copy)   id responseObject;
@property (nonatomic, copy)   NSData *responseData;
@property (nonatomic, copy)   NSString *responseString;

@property (nonatomic, assign) XMNAFNetworkResponseStatus responseStatus;

@property (nonatomic, assign) BOOL fromCache;

@end
@implementation XMNAFNetworkResponse

#pragma mark - Life Cycle

- (instancetype)initWithResponse:(id)response
                           error:(NSError *)error {
    
    
    if (self = [super init]) {
        
        NSError *jsonError;
        if ([response isKindOfClass:[NSData class]]) {
            self.responseData = response;
            if (self.responseData) {
                self.responseObject = [NSJSONSerialization JSONObjectWithData:response options:NSJSONReadingMutableContainers error:&jsonError];
            }
        }else {
            self.responseObject = response;
            if (self.responseObject) {
                self.responseData = [NSJSONSerialization dataWithJSONObject:self.responseObject options:NSJSONWritingPrettyPrinted error:&jsonError];
            }
        }
        if (!jsonError) {
            self.responseString = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
        }
        self.responseStatus = [self responseStatusWithError:error];
        self.fromCache = NO;
    }
    return self;
}

- (instancetype)initWithData:(NSData *)data {

    if (self = [super init]) {
        
        self.responseStatus = XMNAFNetworkResponseSuccess;
        self.responseData = [data copy];
        self.responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        self.responseObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:NULL];
        
        self.fromCache = YES;
    }
    return self;
}

#pragma mark - Private Methods

- (XMNAFNetworkResponseStatus)responseStatusWithError:(NSError *)error {
    
    XMNAFNetworkResponseStatus responseStatus = XMNAFNetworkResponseSuccess;
    if (error) {
        // 除了超时以外，所有错误都当成是无网络
        responseStatus = error.code == NSURLErrorTimedOut ? XMNAFNetworkResponseTimeoutError : XMNAFNetworkResponseNetworkError;
    }
    return responseStatus;
}

@end
