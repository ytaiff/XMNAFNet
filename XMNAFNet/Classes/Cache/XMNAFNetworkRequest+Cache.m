//  XMNAFNetworkRequest+Cache.m
//  Pods
//
//  Created by  XMFraker on 2018/5/21
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      XMNAFNetworkRequest_Cache
//  @version    <#class version#>
//  @abstract   <#class description#>

#import "XMNAFNetworkRequest+Cache.h"

#import "XMNAFCacheMeta.h"
#import "XMNAFNetworkPrivate.h"
#import "XMNAFNetworkConfiguration.h"

#import <objc/runtime.h>
#import <YYCache/YYCache.h>
#import <AFNetworking/AFNetworking.h>

@implementation XMNAFNetworkRequest (Cache)
@dynamic cacheTime;
@dynamic cachePolicy;
@dynamic cacheVersion;

#pragma mark - Public

- (void)loadResponseObjectFromCacheWithCompletionHandler:(void(^)(XMNAFCacheMeta *meta, NSError * error))handler {
    
    if (!self.cacheKey.length) self.cacheKey = [self.service cacheKeyWithRequest:self];
    if ([self.service.cache containsObjectForKey:self.cacheKey]) {
        XMNAFCacheMeta *cacheMeta = (XMNAFCacheMeta *)[self.service.cache objectForKey:self.cacheKey];
        if (!cacheMeta.isCahceDataValid) {
            [self.service.cache removeObjectForKey:self.cacheKey];
            handler(nil, kXMNAFNetworkError(XMNAFNetworkCacheErrorInvaildCacheData, @"缓存数据无效"));
        } else if(![cacheMeta.cachedVersion isEqualToString:self.cacheVersion]) {
            [self.service.cache removeObjectForKey:self.cacheKey];
            handler(nil, kXMNAFNetworkError(XMNAFNetworkCacheErrorVersionMismatch, @"缓存数据版本不匹配"));
        } else if(cacheMeta.isExpired) {
            [self.service.cache removeObjectForKey:self.cacheKey];
            handler(nil, kXMNAFNetworkError(XMNAFNetworkCacheErrorExpired, @"缓存数据已经过期"));
        } else {
            handler(cacheMeta, nil);
        }
    } else {
        handler(nil, kXMNAFNetworkError(XMNAFNetworkCacheErrorUnexists, @"缓存数据不存在"));
    }
}

#pragma mark - Setter

- (void)setCacheTime:(NSTimeInterval)cacheTime {
    objc_setAssociatedObject(self, @selector(cacheTime), @(cacheTime), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setCacheVersion:(NSString *)cacheVersion {
    objc_setAssociatedObject(self, @selector(cacheVersion), cacheVersion, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setCachePolicy:(XMNAFNetworkCachePolicy)cachePolicy {
    objc_setAssociatedObject(self, @selector(cachePolicy), @(cachePolicy), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setCacheKey:(NSString *)cacheKey {
    objc_setAssociatedObject(self, @selector(cacheKey), cacheKey, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Getter

- (NSTimeInterval)cacheTime {
    id obj = objc_getAssociatedObject(self, _cmd);
    if (obj && [obj respondsToSelector:@selector(doubleValue)]) { return [obj doubleValue]; }
    return 0.f;
}

- (XMNAFNetworkCachePolicy)cachePolicy {
    id obj = objc_getAssociatedObject(self, _cmd);
    if (obj && [obj respondsToSelector:@selector(intValue)]) { return [obj intValue]; }
    return XMNAFNetworkCachePolicyInnoringCacheData;
}

- (NSString *)cacheVersion {
    
    id obj = objc_getAssociatedObject(self, _cmd);
    return obj ? : @"0.1.0";
}

- (NSString *)cacheKey { return objc_getAssociatedObject(self, _cmd); }

- (BOOL)shouldCache {
    return self.cachePolicy != XMNAFNetworkCachePolicyInnoringCacheData && self.cacheTime > 0;
}

#pragma mark - Class

+ (void)clearCacheOfRequest:(__kindof XMNAFNetworkRequest * __nonnull)request {
    
    if (!request) return;
    NSString *cacheKey = request.cacheKey;
    if (!cacheKey.length) { cacheKey = [request.service cacheKeyWithRequest:request]; }
    [request.service.cache removeObjectForKey:cacheKey];
}

+ (void)clearCahcesOfService:(XMNAFService *)service {

    if (!service || !service.cache) return;
    [service.cache removeAllObjects];
}

+ (void)clearAllChaches {
    for (XMNAFService *service in [XMNAFService storedServices]) {
        [self clearCahcesOfService:service];
    }
}

@end
