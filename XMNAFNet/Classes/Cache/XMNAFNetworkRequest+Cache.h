//  XMNAFNetworkRequest+Cache.h
//  Pods
//
//  Created by  XMFraker on 2018/5/21
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      XMNAFNetworkRequest_Cache
//  @version    <#class version#>
//  @abstract   <#class description#>

#import <XMNAFNet/XMNAFNetworkRequest.h>

typedef NS_ENUM(NSUInteger, XMNAFNetworkCachePolicy) {
    /** 不使用缓存数据 */
    XMNAFNetworkCachePolicyIgnoringCacheData = 0,
    /** 忽略当前缓存, 发起网络请求后, 缓存缓存数据 */
    XMNAFNetworkCachePolicyIgnoringCacheDataRefresh,
    /** 如果存在缓存数据则使用, 否则加载失败, 不去发起网络请求 */
    XMNAFNetworkCachePolicyReturnCacheDataDontLoad,
    /** 如果存在缓存数据则使用, 否则发起网络请求, 加载缓存数据 */
    XMNAFNetworkCachePolicyReturnCacheDataElseLoad,
    /** 如果存在缓存数据先使用, 并且发起网络请求, 刷新缓存数据 */
    XMNAFNetworkCachePolicyReturnAndRefresh,
    /** 如果存在缓存数据先使用, 并判断当前缓存日期是否即将过期, 是则刷新缓存 */
    XMNAFNetworkCachePolicyReturnAndRefreshWhileSoonExpire,
};

typedef NS_ENUM(NSInteger, XMNAFNetworkCacheErrorCode) {
    XMNAFNetworkCacheErrorExpired = -201,
    XMNAFNetworkCacheErrorUnexists = -100,
    XMNAFNetworkCacheErrorVersionMismatch = -202,
    XMNAFNetworkCacheErrorInvaildCacheData = -203,
};

@class XMNAFCacheMeta;
typedef void(^XMNAFCacheMetaHandler)(XMNAFCacheMeta *__nullable meta, NSError *__nullable error);
@interface XMNAFNetworkRequest (Cache)

/** 当前请求对应的缓存key */
@property (copy, nonatomic, nullable)   NSString *cacheKey;
/** 缓存版本 默认 @"0.1.0" */
@property (copy, nonatomic, nonnull)   NSString *cacheVersion;
/** 缓存时间 默认 0.f */
@property (assign, nonatomic) NSTimeInterval cacheTime;
/** 缓存即将到期的 需要刷新的时间范围 默认 60 * 5 */
@property (assign, nonatomic) NSTimeInterval soonExpireTime;
/** 缓存策略 默认 InnoringCacheData */
@property (assign, nonatomic) XMNAFNetworkCachePolicy cachePolicy;
/** cacheTime > 0 && cachePolicy != ignoringCahceData 时为YES */
@property (assign, nonatomic, readonly) BOOL shouldCache;

/** 判断是否需要刷新当前缓存 */
- (BOOL)shouldRefreshCacheMeta:(XMNAFCacheMeta * __nonnull)meta;
/** 获取当前request的缓存内容 */
- (void)loadResponseObjectFromCacheWithCompletionHandler:(nonnull XMNAFCacheMetaHandler)handler;
/** 清除对应请求的缓存内容 */
+ (void)clearCacheOfRequest:(__kindof XMNAFNetworkRequest * __nonnull)request;
/** 清除对应service的所有缓存内容 */
+ (void)clearCahcesOfService:(XMNAFService * __nonnull)service;
/** 清除所有缓存内容 */
+ (void)clearAllChaches;

@end
