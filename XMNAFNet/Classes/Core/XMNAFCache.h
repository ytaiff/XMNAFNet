//
//  XMNAFCache.h
//  XMNAFNetworkDemo
//
//  Created by XMFraker on 16/4/22.
//  Copyright © 2016年 XMFraker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMNAFCacheObject.h"

@interface XMNAFCache : NSObject

/// ========================================
/// @name   XMNAFNetwork相关的缓存方法
/// ========================================


/**
 *  生成对应请求的MD5缓存key
 *
 *  @param aServiceIdentifier 请求的serviceIdentifier
 *  @param aMethodName        请求方法名称
 *  @param aParams            请求参数
 *
 *  @return MD5加密后的key
 */
+ (NSString * _Nullable)keyWithServiceIdentifier:(NSString * _Nonnull)aServiceIdentifier
                            methodName:(NSString * _Nonnull)aMethodName
                         requestParams:(NSDictionary * _Nonnull)aParams;


/**
 *  获取缓存
 *
 *  @param aServiceIdentifier 请求identifier
 *  @param aMethodName        请求方法名
 *  @param aParams            请求参数
 *
 *  @return nil  or NSData实例
 */
+ (NSData * _Nullable)fetchCachedDataWithServiceIdentifier:(NSString * _Nonnull)aServiceIdentifier
                                      methodName:(NSString * _Nonnull)aMethodName
                                   requestParams:(NSDictionary * _Nullable)aParams;


/**
 *  保存缓存
 *
 *  @param aCachedData        缓存内容
 *  @param aServiceIdentifier
 *  @param amethodName
 *  @param aParams
 */
+ (void)saveCacheWithData:(NSData * _Nonnull)aCachedData
        serviceIdentifier:(NSString * _Nonnull)aServiceIdentifier
               methodName:(NSString * _Nonnull)amethodName
            requestParams:(NSDictionary * _Nullable)aParams;

/**
 *  保存缓存
 *
 *  @param aCachedData        缓存内容
 *  @param aServiceIdentifier
 *  @param aMethodName
 *  @param aParams
 *  @param cacheTime          缓存时间 默认kXMNAFNetowrkRequestCacheOutdateTimeSeconds
 */
+ (void)saveCacheWithData:(NSData * _Nonnull)aCachedData
        serviceIdentifier:(NSString * _Nonnull)aServiceIdentifier
               methodName:(NSString * _Nonnull)aMethodName
            requestParams:(NSDictionary * _Nullable)aParams
                cacheTime:(NSTimeInterval)cacheTime;

/**
 *  清除对应的缓存内容
 *
 *  @param aServiceIdentifier
 *  @param aMethodName
 *  @param aParams
 */
+ (void)removeCacheWithServiceIdentifier:(NSString * _Nonnull)aServiceIdentifier
                              methodName:(NSString * _Nonnull)aMethodName
                           requestParams:(NSDictionary * _Nullable)aParams;

/// ========================================
/// @name   通用的相关缓存方法
/// ========================================

/**
 *  获取缓存内容
 *
 *  @param key 缓存的key
 *
 *  @return nil or cacheObject
 */
+ (NSData * _Nullable)fetchCachedDataWithKey:(NSString * _Nonnull)key;

/**
 *  设置缓存内容
 *
 *  @param cachedData 需要缓存的data
 *  @param key        缓存对应的key
 *  @param cacheTime  缓存时间 默认0
 */
+ (void)saveCacheWithData:(NSData * _Nonnull)cachedData
                      key:(NSString * _Nonnull)key
                cacheTime:(NSTimeInterval)cacheTime;

/**
 *  删除对应缓存key的缓存内容
 *
 *  @param key 缓存对应的key
 */
+ (void)deleteCacheWithKey:(NSString * _Nonnull)key;

/**
 *  清空所有的缓存记录
 */
+ (void)clean;

@end
