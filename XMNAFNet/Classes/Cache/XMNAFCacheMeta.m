//
//  XMNAFCacheObject.m
//  XMNAFNetworkDemo
//
//  Created by XMFraker on 16/4/22.
//  Copyright © 2016年 XMFraker. All rights reserved.
//

#import "XMNAFCacheMeta.h"
#import "XMNAFNetworkRequest+Cache.h"

#import <YYModel/YYModel.h>

@interface XMNAFCacheMeta ()

@end

@implementation XMNAFCacheMeta

#pragma mark - Life Cycle

+ (instancetype)cacheMetaWithRequest:(__kindof XMNAFNetworkRequest *)request {
    return [[XMNAFCacheMeta alloc] initWithRequest:request];
}

- (instancetype)initWithRequest:(__kindof XMNAFNetworkRequest *)request {
    if (!request) return nil;
    if (self = [super init]) {
        _cachedVersion = request.cacheVersion;
        _cachedResponseHeaders = request.responseHeaders;
        if (request.responseObject) {
            _cachedData = [NSJSONSerialization dataWithJSONObject:request.responseObject
                                                          options:NSJSONWritingPrettyPrinted
                                                            error:nil];
        } else if (request.responseJSONObject) {
            _cachedData = [NSJSONSerialization dataWithJSONObject:request.responseJSONObject
                                                          options:NSJSONWritingPrettyPrinted
                                                            error:nil];
        } else if (request.responseData) {
            _cachedData = request.responseData;
        } else if (request.responseString) {
            _cachedData = [NSJSONSerialization dataWithJSONObject:[[request responseString] dataUsingEncoding:NSUTF8StringEncoding]
                                                          options:NSJSONWritingPrettyPrinted
                                                            error:nil];
        }

        _expiredDate = [NSDate dateWithTimeIntervalSinceNow:request.cacheTime];
    }
    return self;
}

#pragma mark - Override

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [self yy_modelEncodeWithCoder:aCoder];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    return [self yy_modelInitWithCoder:aDecoder];
}

#pragma mark - Public

- (BOOL)isEqualToMeta:(XMNAFCacheMeta *)meta {
    if (self.isExpired || !self.isCahceDataValid) return NO;
    if (meta.isExpired || !meta.isCahceDataValid) return NO;
    return [self.cachedData isEqual:meta.cachedData] && [self.cachedVersion isEqualToString:meta.cachedVersion];
}

#pragma mark - Getter

- (BOOL)isCahceDataValid { return self.cachedData.length; }

- (BOOL)isExpired { return [self.expiredDate timeIntervalSinceDate:[NSDate date]] <= 0; }

#pragma mark - Class

+ (BOOL)supportsSecureCoding { return YES; }

@end
