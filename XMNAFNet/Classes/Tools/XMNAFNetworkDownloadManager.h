//
//  XMNAFNetworkDownloadManager.h
//  XMNAFNetworkDemo
//
//  Created by XMFraker on 16/6/8.
//  Copyright © 2016年 XMFraker. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXTERN NSString * _Nonnull const kXMNAFDownloadURLStringKey;
FOUNDATION_EXTERN NSString * _Nonnull const kXMNAFDownloadFileNameKey;

@interface XMNAFNetworkDownloadManager : NSObject


#pragma mark - Properties

/** downloadManager 中 所有的tasks */
@property (copy, nonatomic, readonly, nonnull) NSArray<NSURLSessionDownloadTask *> *downloadTasks;

/** 缓存路径 */
@property (copy, nonatomic, readonly, nonnull) NSString *cachePath;

#pragma mark - Life Cycle

+ (instancetype _Nonnull)sharedManager;

- (instancetype _Nonnull)initWithCachePath:(NSString * _Nullable)cachePath;

#pragma mark - Methods

/**
 *  下载文件
 *
 *  @param URLString     下载地址
 *  @param fileName      下载文件名
 *  @param progressBlock 进度条block
 *  @param completeBlock 完成block
 *
 *  @return NSURLSessionDownloadTask 实例 or nil
 */
- (NSURLSessionDownloadTask * _Nullable)downloadWithURLString:(NSString * _Nonnull)URLString
                                                     fileName:(NSString * _Nonnull)fileName
                                                progressBlock:(void(^ _Nullable)(int64_t bytes,int64_t totalBytes))progressBlock
                                                completeBlock:(void(^ _Nullable)(id _Nullable responseObject,NSError * _Nullable error))completeBlock;

/**
 *  下载文件
 *
 *  @param constructingRequestBlock 构造block,返回NSDictionary类型
 *  @param progressBlock            进度条block
 *  @param completeBlock            完成block
 *
 *  @return NSURLSessionDownloadTask 实例 or nil
 */
- (NSURLSessionDownloadTask * _Nullable)downloadWithConstructingRequestBlock:(NSDictionary * _Nonnull (^ _Nonnull)(void))constructingRequestBlock
                                                     progressBlock:(void(^ _Nullable)(int64_t bytes,int64_t totalBytes))progressBlock
                                                     completeBlock:(void(^ _Nullable)(id _Nullable responseObject,NSError * _Nullable error))completeBlock;


/** 暂停所有任务 */
- (void)suspendAllTasks;

/** 恢复所有任务 */
- (void)resumeAllTasks;

/** 取消所有任务 */
- (void)cancelAllTasks;

/**
 *  根据URLString 暂停task的下载
 *
 *  @param URLString 需要暂停下载的URLString
 */
- (void)suspendTask:(NSString * _Nonnull)URLString;


/**
 *  根据URLString 恢复一个下载
 *
 *  @param URLString 需要恢复下载的URLString
 */
- (void)resumeTask:(NSString * _Nonnull)URLString;

/**
 *  根据URLString取消task下载
 *
 *  @warning  使用此方法会同步删除downloadingPath 中的文件
 *
 *  @param URLString 需要取消下载的URLString
 */
- (void)cancelTask:(NSString * _Nonnull)URLString;

/**
 *  清空正在下载中的文件缓存
 */
- (void)cleanDownloadingCache;

/**
 *  根据URLString 清除downloading中的缓存
 *
 *  @param URLString 需要清除的缓存
 */
- (void)cleanDownloadingCacheWithURLString:(NSString * _Nonnull)URLString;


/**
 *  清空所有已经下载的文件内容
 */
- (void)cleanDownloadedCahce;

/**
 *  根据URLString 清除downloading中的缓存
 *
 *  @param URLString 需要清除的缓存
 */
- (void)cleanDownloadedCacheWithURLString:(NSString * _Nonnull)URLString;

/**
 *  清空所有下载中,已经下载的文件
 */
- (void)cleanCache;

/**
 *  根据URLString 清除downloading中的缓存
 *
 *  @param URLString 需要清除的缓存
 */
- (void)cleanCacheWithURLString:(NSString * _Nonnull)URLString;

@end
