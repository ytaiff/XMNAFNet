//
//  XMNAFCacheObject.h
//  XMNAFNetworkDemo
//
//  Created by XMFraker on 16/4/22.
//  Copyright © 2016年 XMFraker. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSCache * kXMNAFCache;
/** 默认XMNAFNetwork缓存路径 */
static NSString * kXMNAFCahcePath;

@interface XMNAFCacheObject : NSObject

/** 缓存的内容 */
@property (nonatomic, strong, readonly)   NSData *content;

/** 最后次更新缓存时间 */
@property (nonatomic, assign, readonly) NSTimeInterval lastUpdateTime;
/** 限制缓存时间 */
@property (nonatomic, assign, readonly) NSTimeInterval cacheLimitTime;

/** 是否过期  now - lastUpdateTime > cacheLimitTime */
@property (nonatomic, assign, readonly) BOOL isOutDated;
/** 是否无数据 */
@property (nonatomic, assign, readonly) BOOL isEmpty;

/** 生成XMNAFCacheObject实例的Dict 
 *  lastUpdateTime  : 时间戳
 *  cacheLimitTime  : 时间戳
 */
@property (nonatomic, copy, readonly)   NSDictionary *objectDict;

/** 缓存object的文件路径 */
@property (nonatomic, copy, readonly)   NSString *cacheObjectPath;
/** 缓存content的文件路径 */
@property (nonatomic, copy, readonly)   NSString *cacheContentPath;

/** 缓存的key */
@property (nonatomic, copy, readonly)   NSString *cacheKey;

/**
 *  实例化方法 ,从缓存中查找 已经缓存的数据
 *
 *  @param key 缓存的key
 *
 *  @return nil or XMNAFCacheObject 实例
 */
- (instancetype)initWithKey:(NSString *)key;

/**
 *  实例化方法
 *
 *  @param cacheKey  缓存的key
 *  @param cacheTime 缓存时间
 *
 *  @return XMNAFCacheObject 实例
 */
- (instancetype)initWithCacheKey:(NSString *)cacheKey
                       cacheTime:(NSTimeInterval)cacheTime;

/**
 *  更新缓存的内容 同时会更新lastUpdateTime
 *
 *  @param content 缓存内容
 */
- (void)updateContent:(NSData *)content;

/** 清除缓存 */
- (void)cleanCacheObject;

@end
