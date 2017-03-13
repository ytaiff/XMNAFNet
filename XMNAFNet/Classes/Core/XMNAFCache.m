//
//  XMNAFCache.m
//  XMNAFNetworkDemo
//
//  Created by XMFraker on 16/4/22.
//  Copyright © 2016年 XMFraker. All rights reserved.
//

#import "XMNAFCache.h"

#import <CommonCrypto/CommonCrypto.h>
#import "XMNAFNetworkConfiguration.h"

#import "NSDictionary+XMNAFJSON.h"

@implementation XMNAFCache

#pragma mark - Methods

+ (NSString *)keyWithServiceIdentifier:(NSString *)aServiceIdentifier
                            methodName:(NSString *)aMethodName
                         requestParams:(NSDictionary *)aParams {
    
    return XMNAF_MD5([NSString stringWithFormat:@"%@%@%@", aServiceIdentifier, aMethodName, [aParams XMNAF_urlParamsStringSignature:NO]]);
}

+ (NSData *)fetchCachedDataWithServiceIdentifier:(NSString *)aServiceIdentifier
                                      methodName:(NSString *)aMethodName
                                   requestParams:(NSDictionary *)aParams {
    
    return [self fetchCachedDataWithKey:[self keyWithServiceIdentifier:aServiceIdentifier
                                                            methodName:aMethodName
                                                         requestParams:aParams]];
}

+ (void)saveCacheWithData:(NSData *)aCachedData
        serviceIdentifier:(NSString *)aServiceIdentifier
               methodName:(NSString *)aMethodName
            requestParams:(NSDictionary *)aParams {
    
    [self saveCacheWithData:aCachedData
          serviceIdentifier:aServiceIdentifier
                 methodName:aMethodName
              requestParams:aParams
                  cacheTime:kXMNAFNetowrkRequestCacheOutdateTimeSeconds];
}


+ (void)saveCacheWithData:(NSData *)aCachedData
        serviceIdentifier:(NSString *)aServiceIdentifier
               methodName:(NSString *)aMethodName
            requestParams:(NSDictionary *)aParams
                cacheTime:(NSTimeInterval)cacheTime {
    
    [self saveCacheWithData:aCachedData
                        key:[self keyWithServiceIdentifier:aServiceIdentifier
                                                methodName:aMethodName
                                             requestParams:aParams]
                  cacheTime:cacheTime];
}

+ (void)removeCacheWithServiceIdentifier:(NSString *)serviceIdentifier
                              methodName:(NSString *)methodName
                           requestParams:(NSDictionary *)requestParams
{
    [self deleteCacheWithKey:[self keyWithServiceIdentifier:serviceIdentifier methodName:methodName requestParams:requestParams]];
}

+ (NSData *)fetchCachedDataWithKey:(NSString *)key {
    
    if (!key) {
        XMNLog(@"key should not be nil");
        return nil;
    }
    XMNAFCacheObject *cacheObject = [[XMNAFCacheObject alloc] initWithKey:key];
    
    if (!cacheObject || cacheObject.isOutDated || cacheObject.isEmpty) {
        /** 过期 不存在 空内容 清除内容 */
        cacheObject ? [cacheObject cleanCacheObject] : nil;
        return nil;
    }
    return cacheObject.content;
}

+ (void)saveCacheWithData:(NSData *)cachedData
                      key:(NSString *)key
                cacheTime:(NSTimeInterval)cacheTime {
    
    if (!cachedData || !key) {
        XMNLog(@"cacheData and key should not be nil");
        return;
    }
    XMNAFCacheObject *cachedObject = [[XMNAFCacheObject alloc] initWithKey:key];
    if (cachedObject == nil) {
        cachedObject = [[XMNAFCacheObject alloc] initWithCacheKey:key
                                                        cacheTime:cacheTime];
    }
    [cachedObject updateContent:cachedData];
}

+ (void)deleteCacheWithKey:(NSString *)key {

    if (!key) {
        XMNLog(@"key should not be nil");
        return;
    }
    XMNAFCacheObject *cachedObject = [[XMNAFCacheObject alloc] initWithKey:key];
    [cachedObject cleanCacheObject];
}

+ (void)clean {
    
    /** 移除所有内存中的缓存 */
    [kXMNAFCache removeAllObjects];
    /** 创建默认缓存目录 */
    if ([[NSFileManager defaultManager] fileExistsAtPath:kXMNAFCahcePath]) {
    
        /** 直接删除文件夹 */
        [[NSFileManager defaultManager] removeItemAtPath:kXMNAFCahcePath error:nil];
        /** 重新创建新的空缓存文件夹 */
        [[NSFileManager defaultManager] createDirectoryAtPath:kXMNAFCahcePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

@end
