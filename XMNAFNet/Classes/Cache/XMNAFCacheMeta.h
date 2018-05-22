//
//  XMNAFCacheObject.h
//  XMNAFNetworkDemo
//
//  Created by XMFraker on 16/4/22.
//  Copyright © 2016年 XMFraker. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class XMNAFNetworkRequest;
@interface XMNAFCacheMeta : NSObject <NSCoding, NSSecureCoding>

/** request 缓存版本 */
@property (copy, nonatomic)   NSString *cachedVersion;
/** request 缓存过期时间 */
@property (copy, nonatomic)   NSDate *expiredDate;
/** request 缓存的具体数据 */
@property (copy, nonatomic)   NSData *cachedData;
/** request 缓存的response.headers */
@property (copy, nonatomic)   NSDictionary *cachedResponseHeaders;
/** request 缓存数据是否已经过期 */
@property (assign, nonatomic, readonly) BOOL isExpired;
/** request 缓存数据是否合法 */
@property (assign, nonatomic, readonly) BOOL isCahceDataValid;

/**
 初始化方法, 根据request生成对应的CacheMeta实例
 保存对应的返回数据,过期时间,缓存版本等信息
 @param request 已经请求完成的request实例
 @return XMNAFCacheMeta实例
 */
- (instancetype)initWithRequest:(__kindof XMNAFNetworkRequest *)request;
+ (instancetype)cacheMetaWithRequest:(__kindof XMNAFNetworkRequest *)request;

@end

NS_ASSUME_NONNULL_END
