//
//  XMNAFNetworkDownloadManager.m
//  XMNAFNetworkDemo
//
//  Created by XMFraker on 16/6/8.
//  Copyright © 2016年 XMFraker. All rights reserved.
//

#import "XMNAFNetworkDownloadManager.h"
#import "XMNAFNetworkConfiguration.h"
#import <AFNetworking/AFNetworking.h>
#import <objc/runtime.h>

NSString *const kXMNAFDownloadSessionIdentifier = @"com.XMFraker.XMNAFNetwork.XMAFDownloadManager.kXMNAFDownloadSessionIdentifier";
NSString *const kXMNAFDownloadURLStringKey = @"com.XMFraker.XMNAFNetwork.XMAFDownloadManager.URLStringKey";
NSString *const kXMNAFDownloadFileNameKey = @"com.XMFraker.XMNAFNetwork.XMAFDownloadManager.FileNameKey";

static NSString *kXMNAFDownloadTaskProgressKey;
@interface XMNAFNetworkDownloadManager ()

@property (strong, nonatomic) AFURLSessionManager *sessionManager;

/** 下载中的缓存地址 */
@property (copy, nonatomic, readonly) NSString *downloadingCachePath;
/** 下载完成后的存放地址 */
@property (copy, nonatomic, readonly) NSString *downloadedCachePath;

/** 缓存的路径 */
@property (copy, nonatomic) NSString *cachePath;

@end

@implementation XMNAFNetworkDownloadManager

#pragma mark - Life Cycle

+ (instancetype)sharedManager {
    
    static id manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[[self class] alloc] initWithCachePath:nil];
    });
    return manager;
}

- (instancetype)initWithCachePath:(NSString *)cachePath {
    
    if (self = [super init]) {
        
        if (cachePath) {
            self.cachePath = cachePath;
        } else {
            NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
            NSString *cachePath = [cachePaths firstObject];
            self.cachePath = [cachePath stringByAppendingPathComponent:@"com.XMFraker.XMNAFNetwork.XMAFDownloadManager"];
        }
        
        /** 创建缓存文件夹 */
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.downloadingCachePath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:self.downloadingCachePath withIntermediateDirectories:YES attributes:nil error:NULL];
        }
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.downloadedCachePath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:self.downloadedCachePath withIntermediateDirectories:YES attributes:nil error:NULL];
        }
        
        XMNLog(@"-------XMNAFNetwork Download Path---------\ndownloading cache path:\n%@\ndownloaded cache path:\n%@\n-------XMNAFNetwork Download Path---------\n\n\n",self.downloadingCachePath,self.downloadedCachePath);
    }
    return self;
}

#pragma mark - Methods

- (NSURLSessionDownloadTask *)downloadWithURLString:(NSString *)URLString
                                           fileName:(NSString *)fileName
                                      progressBlock:(void (^)(int64_t, int64_t))progressBlock
                                      completeBlock:(void (^)(id _Nullable, NSError * _Nullable))completeBlock {
    
    
    if (!URLString) {
        
        XMNLog(@"you should pass URLString");
        return nil;
    }
    
    NSString *resultFileName = fileName ?  : XMNAF_MD5(URLString);
    
    NSString *fileDownloadingPath = [self.downloadingCachePath stringByAppendingPathComponent:resultFileName];
    BOOL isFileDownloading = [self isFileExists:fileDownloadingPath];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URLString]];
    NSURLSessionDownloadTask *task;

    __weak typeof(*&self) wSelf = self;
    if (!isFileDownloading) {
        
        /** 强制删除下文本 */
        [[NSFileManager defaultManager] removeItemAtPath:fileDownloadingPath error:nil];
        /** 无缓存记录 */
        task = [self.sessionManager downloadTaskWithRequest:request progress:nil destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            
            return [NSURL fileURLWithPath:fileDownloadingPath isDirectory:NO];
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {

            __strong typeof(*&wSelf) self = wSelf;
            NSString *absoulateFilePath = [self handleDownCompleted:response filePath:fileDownloadingPath error:error];
            completeBlock ? completeBlock(absoulateFilePath, error) : nil;
        }];
    } else {
        
        /** 有缓存记录 */
        task = [self.sessionManager downloadTaskWithResumeData:[NSData dataWithContentsOfFile:fileDownloadingPath] progress:nil destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            
            return [NSURL fileURLWithPath:fileDownloadingPath isDirectory:NO];
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            
            __strong typeof(*&wSelf) self = wSelf;
            NSString *absoulateFilePath = [self handleDownCompleted:response filePath:fileDownloadingPath error:error];
            completeBlock ? completeBlock(absoulateFilePath, error) : nil;
        }];
    }
    objc_setAssociatedObject(task, &kXMNAFDownloadTaskProgressKey, progressBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    [task resume];
    return task;
}


- (NSURLSessionDownloadTask *)downloadWithConstructingRequestBlock:(NSDictionary * _Nonnull (^)(void))constructingRequestBlock
                                                     progressBlock:(void (^)(int64_t, int64_t))progressBlock
                                                     completeBlock:(void (^)(id _Nullable, NSError * _Nullable))completeBlock {
    
    
    if (!constructingRequestBlock) {
        
        XMNLog(@"%@",XMNLocalizedString(@"NON_CONSTRUCT_BLOCK", @""));
        return nil;
    }
    NSDictionary *arguments = constructingRequestBlock();
    NSString *URLString = arguments[kXMNAFDownloadURLStringKey];
    if (!URLString) {
        
        XMNLog(@"%@",XMNLocalizedString(@"NON_CONSTRUCT_URL", @""));
        return nil;
    }
    NSString *fileName = arguments[kXMNAFDownloadFileNameKey];
    
    if (!fileName) {
        fileName = XMNAF_MD5(URLString);
    }
    return [self downloadWithURLString:URLString
                              fileName:fileName
                         progressBlock:progressBlock
                         completeBlock:completeBlock];
}



/// ========================================
/// @name   task 管理相关Methods
/// ========================================

/** 暂停所有任务 */
- (void)suspendAllTasks {
    
    [self.downloadTasks makeObjectsPerformSelector:@selector(suspend)];
}

/** 恢复所有任务 */
- (void)resumeAllTasks {
    
    [self.downloadTasks makeObjectsPerformSelector:@selector(resume)];
}

/** 取消所有任务 */
- (void)cancelAllTasks {
    
    [self.downloadTasks makeObjectsPerformSelector:@selector(cancel)];
}

/**
 *  根据URLString 暂停task的下载
 *
 *  @param URLString 需要暂停下载的URLString
 */
- (void)suspendTask:(NSString * _Nonnull)URLString {
    
    if (!URLString) {

        XMNLog(@"%@",XMNLocalizedString(@"SUSPEND_NON_URL", @"you should pass URLString while suspend task"));
        return;
    }
    
    [[self.downloadTasks filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSURLSessionDownloadTask  *evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [XMNAF_MD5(evaluatedObject.currentRequest.URL.absoluteString) isEqualToString:XMNAF_MD5(URLString)] && evaluatedObject.state == NSURLSessionTaskStateRunning;
    }]] makeObjectsPerformSelector:@selector(suspend)];
}


/**
 *  根据URLString 恢复一个下载
 *
 *  @param URLString 需要恢复下载的URLString
 */
- (void)resumeTask:(NSString * _Nonnull)URLString {
    
    if (!URLString) {

        XMNLog(@"%@",XMNLocalizedString(@"RESUME_NON_URL", @"you should pass URLString while resume task"));
        return;
    }
    
    [[self.downloadTasks filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSURLSessionDownloadTask  *evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [XMNAF_MD5(evaluatedObject.currentRequest.URL.absoluteString) isEqualToString:XMNAF_MD5(URLString)] && evaluatedObject.state == NSURLSessionTaskStateSuspended;
    }]] makeObjectsPerformSelector:@selector(resume)];
}

/**
 *  根据URLString取消task下载
 *
 *  @warning  使用此方法会同步删除downloadingPath 中的文件
 *
 *  @param URLString 需要取消下载的URLString
 */
- (void)cancelTask:(NSString * _Nonnull)URLString {
    
    if (!URLString) {

        XMNLog(@"%@",XMNLocalizedString(@"CANCEL_NON_URL", @"you should pass URLString while cancel task"));
        return;
    }
    [[self.downloadTasks filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSURLSessionDownloadTask  *evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        
        return [XMNAF_MD5(evaluatedObject.currentRequest.URL.absoluteString) isEqualToString:XMNAF_MD5(URLString)];
    }]] makeObjectsPerformSelector:@selector(cancel)];
    
    [self cleanCacheWithURLString:URLString];
}

/**
 *  清空正在下载中的文件缓存
 */
- (void)cleanDownloadingCache {
    
    [[NSFileManager defaultManager] removeItemAtPath:self.downloadingCachePath error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:self.downloadingCachePath withIntermediateDirectories:YES attributes:nil error:nil];
}

- (void)cleanDownloadingCacheWithURLString:(NSString *)URLString {
    
    if (!URLString) {

        XMNLog(@"%@",XMNLocalizedString(@"CLEAN_DOWNING_NON_URL", @"you should pass URLString while clean downloading cache"));
        return;
    }
    [[NSFileManager defaultManager] removeItemAtPath:[self.downloadingCachePath stringByAppendingString:XMNAF_MD5(URLString)] error:nil];
}

- (void)cleanDownloadedCahce {
    
    [[NSFileManager defaultManager] removeItemAtPath:self.downloadedCachePath error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:self.downloadedCachePath withIntermediateDirectories:YES attributes:nil error:nil];
}

- (void)cleanDownloadedCacheWithURLString:(NSString *)URLString {
    
    if (!URLString) {
        
        XMNLog(@"%@",XMNLocalizedString(@"CLEAN_DOWNED_NON_URL", @"you should pass URLString while clean downloaded cache"));
        return;
    }
    [[NSFileManager defaultManager] removeItemAtPath:[self.downloadedCachePath stringByAppendingString:XMNAF_MD5(URLString)] error:nil];
}

/** 清空所有缓存 */
- (void)cleanCache {
    
    [self cleanDownloadingCache];
    [self cleanDownloadedCahce];
}

- (void)cleanCacheWithURLString:(NSString *)URLString {
    
    if (!URLString) {

        XMNLog(@"%@",XMNLocalizedString(@"CLEAN_NON_URL", @"you should pass URLString while clean cache"));
        return;
    }
    [self cleanDownloadedCacheWithURLString:URLString];
    [self cleanDownloadingCacheWithURLString:URLString];
}

/// ========================================
/// @name   Private Methods
/// ========================================

- (BOOL)isFileExists:(NSString *)filePath {
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]
        && [[NSFileManager defaultManager] isReadableFileAtPath:filePath]
        && [[NSFileManager defaultManager] isWritableFileAtPath:filePath]) {
        return YES;
    }
    return NO;
}

- (NSString *)handleDownCompleted:(NSURLResponse *)response
                   filePath:(NSString *)filePath
                      error:(NSError *)error {
 
    if (!error && [self isFileExists:filePath]) {
        
        NSString *absoultePath = [self.downloadedCachePath stringByAppendingString:[filePath lastPathComponent]];
        /** 移动已经下载的文件 */
        
        [[NSFileManager defaultManager] moveItemAtPath:filePath toPath:absoultePath error:&error];
        /** 删除下载中的文件 */
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        
        return error ? nil : absoultePath;
    }
    return nil;
}

#pragma mark - Getters

- (AFURLSessionManager *)sessionManager {
    
    if (!_sessionManager) {
        
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:kXMNAFDownloadSessionIdentifier];
        sessionConfiguration.HTTPMaximumConnectionsPerHost = 1;
        _sessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:sessionConfiguration];
        
        /** 监听所有的download task 下载进度 */
        [_sessionManager setDownloadTaskDidWriteDataBlock:^(NSURLSession * _Nonnull session, NSURLSessionDownloadTask * _Nonnull downloadTask, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
            
            void(^progressBlock)(int64_t bytes,int64_t totalBytes) = objc_getAssociatedObject(downloadTask, &kXMNAFDownloadTaskProgressKey);
            progressBlock(totalBytesWritten,totalBytesExpectedToWrite);
        }];
    }
    return _sessionManager;
}

- (NSArray *)downloadTasks {
    
    return self.sessionManager.downloadTasks;
}

/**
 *  正在下载的缓存路径
 *  当用户cancel某个downloadTask时,将已经下载的部分数据移动到此目录下,方便用户之后重新下载的话,使用断点续传功能
 */
- (NSString *)downloadingCachePath {
    
    return [self.cachePath stringByAppendingPathComponent:@"downloading"];
}

/**
 *  下载完成后存放目录路径,当用户没有传入destination时使用
 */
- (NSString *)downloadedCachePath {
    
    return [self.cachePath stringByAppendingPathComponent:@"downloaded"];
}

@end
