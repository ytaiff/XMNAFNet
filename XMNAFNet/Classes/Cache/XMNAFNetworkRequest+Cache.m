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
    
    XMNAFCacheMetaHandler mainHandler = ^(XMNAFCacheMeta *__nullable meta, NSError *__nullable error) {
        if ([NSThread isMainThread]) {
            if (handler) { handler(meta, error); }
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (handler) { handler(meta, error); }
            });
        }
    };

    if (!self.cacheKey.length) self.cacheKey = [self.service cacheKeyWithRequest:self];
    NSString *cacheKey = self.cacheKey;
    if ([self.service.cache containsObjectForKey:cacheKey]) {
        
        __weak typeof(self) wSelf = self;
        [self.service.cache objectForKey:cacheKey withBlock:^(NSString * _Nonnull key, XMNAFCacheMeta *cacheMeta) {
            __strong typeof(wSelf) self = wSelf;
            if (!cacheMeta.isCahceDataValid) {
                [self.service.cache removeObjectForKey:cacheKey];
                mainHandler(nil, kXMNAFNetworkError(XMNAFNetworkCacheErrorInvaildCacheData, @"缓存数据无效"));
            } else if(![cacheMeta.cachedVersion isEqualToString:self.cacheVersion]) {
                [self.service.cache removeObjectForKey:cacheKey];
                mainHandler(nil, kXMNAFNetworkError(XMNAFNetworkCacheErrorVersionMismatch, @"缓存数据版本不匹配"));
            } else if(cacheMeta.isExpired) {
                [self.service.cache removeObjectForKey:cacheKey];
                mainHandler(nil, kXMNAFNetworkError(XMNAFNetworkCacheErrorExpired, @"缓存数据已经过期"));
            } else {
                mainHandler(cacheMeta, nil);
            }
        }];
    } else {
        mainHandler(nil, kXMNAFNetworkError(XMNAFNetworkCacheErrorUnexists, @"缓存数据不存在"));
    }
}

- (BOOL)shouldRefreshCacheMeta:(XMNAFCacheMeta *)meta {
//    if (!self.shouldCache) return NO;
//    if (meta.isExpired || !meta.isCahceDataValid) return YES;
    XMNAFNetworkCachePolicy cachePolicy = self.cachePolicy;
    switch (cachePolicy) {
        case XMNAFNetworkCachePolicyReturnAndRefresh: // fall though
        case XMNAFNetworkCachePolicyIgnoringCacheDataRefresh: return YES;
        case XMNAFNetworkCachePolicyReturnAndRefreshWhileSoonExpire: {
            NSTimeInterval timeDiff = [meta.expiredDate timeIntervalSinceDate:[NSDate date]];
            return timeDiff < self.soonExpireTime;
        } break;
        default: return NO;
    }
}

#pragma mark - Setter

- (void)setCacheTime:(NSTimeInterval)cacheTime {
    objc_setAssociatedObject(self, @selector(cacheTime), @(cacheTime), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setSoonExpireTime:(NSTimeInterval)soonExpireTime {
    objc_setAssociatedObject(self, @selector(soonExpireTime), @(soonExpireTime), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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

- (NSTimeInterval)soonExpireTime {
    id obj = objc_getAssociatedObject(self, _cmd);
    if (obj && [obj respondsToSelector:@selector(doubleValue)]) { return [obj doubleValue]; }
    return 60.f * 5;
}

- (XMNAFNetworkCachePolicy)cachePolicy {
    id obj = objc_getAssociatedObject(self, _cmd);
    if (obj && [obj respondsToSelector:@selector(intValue)]) { return [obj intValue]; }
    return XMNAFNetworkCachePolicyIgnoringCacheData;
}

- (NSString *)cacheVersion {
    
    id obj = objc_getAssociatedObject(self, _cmd);
    return obj ? : @"0.1.0";
}

- (NSString *)cacheKey { return objc_getAssociatedObject(self, _cmd); }

- (BOOL)shouldCache {
    
    switch (self.cachePolicy) {
        case XMNAFNetworkCachePolicyReturnAndRefresh:
        case XMNAFNetworkCachePolicyReturnCacheDataDontLoad:
        case XMNAFNetworkCachePolicyReturnCacheDataElseLoad:
        case XMNAFNetworkCachePolicyIgnoringCacheDataRefresh:
        case XMNAFNetworkCachePolicyReturnAndRefreshWhileSoonExpire:
            return (self.cacheTime > 0);
            break;
        case XMNAFNetworkCachePolicyIgnoringCacheData:
        default: return NO;
    }
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
