//
//  XMNAFCacheObject.m
//  XMNAFNetworkDemo
//
//  Created by XMFraker on 16/4/22.
//  Copyright © 2016年 XMFraker. All rights reserved.
//

#import "XMNAFCacheObject.h"

#import "XMNAFNetworkConfiguration.h"

@interface XMNAFCacheObject ()

@property (nonatomic, strong) NSData *content;

@property (nonatomic, assign) NSTimeInterval lastUpdateTime;
@property (nonatomic, assign) NSTimeInterval cacheLimitTime;

@property (nonatomic, copy)   NSString *cacheKey;

@end

@implementation XMNAFCacheObject
@synthesize content = _content;

#pragma mark - Life Cycle

+ (void)initialize {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        kXMNAFCache = [[NSCache alloc] init];
        /** 缓存数量500 */
        kXMNAFCache.countLimit = 100;
        /** 缓存大小3MB */
        kXMNAFCache.totalCostLimit = 1024 * 1024 * 3;
        
        kXMNAFCahcePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent: @"com.XMFraker.XMNAFNetwork.kXMNAFCachePath"];
       
        /** 创建默认缓存目录 */
        if (![[NSFileManager defaultManager] fileExistsAtPath:kXMNAFCahcePath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:kXMNAFCahcePath withIntermediateDirectories:YES attributes:nil error:nil];
        }
    });
}

- (instancetype)initWithKey:(NSString *)key {
    
    /** 1. 先从内存缓存中查找是否存在XMNAFCacheObject */
    NSDictionary *dictionary = [kXMNAFCache objectForKey:key];
    
    /** 2. 内存中不存在,则从文件缓存中获取数据 */
    if (!dictionary) {
        NSString *cachePath = [kXMNAFCahcePath stringByAppendingPathComponent:[key stringByAppendingString:@"_object"]];
        dictionary = [NSDictionary dictionaryWithContentsOfFile:cachePath];
    }
    
    /** 如果数据不存在,则返回nil */
    if (!dictionary) {
        return nil;
    }
    if (self = [super init]) {

        self.cacheKey = key;
        self.lastUpdateTime = dictionary[@"lastUpdateTime"] ?  [dictionary[@"lastUpdateTime"] doubleValue] : [[NSDate date] timeIntervalSince1970];
        self.cacheLimitTime = dictionary[@"cacheLimitTime"] ?  [dictionary[@"cacheLimitTime"] doubleValue] : 0;
    }
    return self;
}

- (instancetype)initWithCacheKey:(NSString *)cacheKey
                       cacheTime:(NSTimeInterval)cacheTime {
    
    if (self = [super init]) {
        
        self.cacheKey = cacheKey;
        self.cacheLimitTime = cacheTime;
    }
    return self;
}

#pragma mark - Methods

- (void)updateContent:(NSData *)content {
    
    self.content = content;
}

/** 清除缓存 */
- (void)cleanCacheObject {
    
    [kXMNAFCache removeObjectForKey:self.cacheKey];
    NSError *error;
    /** 清除已经存在的缓存地址 */
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.cacheObjectPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:self.cacheObjectPath error:&error];
    }
    /** 清除已经存在的缓存地址 */
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.cacheContentPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:self.cacheContentPath error:&error];
    }
}

#pragma mark - Setters

- (void)setContent:(NSData *)content {
    
    if ([content isKindOfClass:[NSData class]]) {
        _content = [content copy];
    }else if ([content isKindOfClass:[NSDictionary class]]) {
        _content = [[NSJSONSerialization dataWithJSONObject:content options:NSJSONWritingPrettyPrinted error:nil] copy];
    }else {
        
        XMNLog(@"content type is not validate");
        return;
    }
    
    self.lastUpdateTime = [[NSDate date] timeIntervalSince1970];
    
    NSError *error;
    /** 清除已经存在的缓存地址 */
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.cacheContentPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:self.cacheContentPath error:nil];
    }
    
    BOOL cacheSuccess = YES;
    cacheSuccess = cacheSuccess & [_content writeToFile:self.cacheContentPath options:NSAtomicWrite error:&error];
    cacheSuccess = cacheSuccess & [self.objectDict writeToFile:self.cacheObjectPath atomically:YES];
    /** 记录新的cacheObject */
    [kXMNAFCache setObject:self.objectDict forKey:self.cacheKey];
    if (cacheSuccess) {
        XMNLog(@"%@ cache success",self.cacheKey);
    }else {
        XMNLog(@"%@ cache failed",self.cacheKey);
        /** 移除已经缓存的 */
        [self cleanCacheObject];
    }
}

#pragma mark - Getters

- (id)content {
    
    if (!_content) {
        _content = [NSData dataWithContentsOfFile:self.cacheContentPath];
    }
    return _content;
}

- (NSDictionary *)objectDict {
    
    return @{@"lastUpdateTime":@(self.lastUpdateTime),
             @"cacheLimitTime":@(self.cacheLimitTime)};
}

- (NSString *)cacheObjectPath {
    
    return [kXMNAFCahcePath stringByAppendingPathComponent:[self.cacheKey stringByAppendingString:@"_object"]];
}

- (NSString *)cacheContentPath {
    
    return [kXMNAFCahcePath stringByAppendingPathComponent:[self.cacheKey stringByAppendingString:@"_content"]];
}

- (BOOL)isEmpty {
    
    return self.content == nil;
}

- (BOOL)isOutDated {
    
    return ([[NSDate date] timeIntervalSince1970] - self.lastUpdateTime) >= self.cacheLimitTime;
}

@end
