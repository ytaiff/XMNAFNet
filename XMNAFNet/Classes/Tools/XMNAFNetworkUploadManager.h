//
//  XMNAFNetworkUploadManager.h
//  XMNAFNetworkDemo
//
//  Created by XMFraker on 16/6/8.
//  Copyright © 2016年 XMFraker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

FOUNDATION_EXTERN NSString * _Nonnull const kXMNAFUploadURLStringKey /**< 上传地址key */;
FOUNDATION_EXTERN NSString * _Nonnull const kXMNAFUploadRequestParamsKey /**< 上传请求参数key */;
FOUNDATION_EXTERN NSString * _Nonnull const kXMNAFUploadRequestHeadersKey /**< 上传头部key */;

typedef void(^XMAFUploadProgressBlock)(int64_t bytes,int64_t totalBytes);

@protocol AFMultipartFormData;
@class AFHTTPSessionManager;
@class AFHTTPRequestSerializer;
@class AFJSONResponseSerializer;
@interface XMNAFNetworkUploadManager : NSObject

@property (strong, nonatomic, readonly, nonnull) AFHTTPSessionManager *sessionManager;
@property (strong, nonatomic, readonly, nonnull) AFHTTPRequestSerializer *requestSerizalizer;

/** 上传完成后 结果解析 默认使用AFJSONResponseSerializer */
@property (strong, nonatomic, readonly, nonnull) AFJSONResponseSerializer *responseSerizalizer;

+ (instancetype _Nonnull)sharedManager;

/**
 *  构造一个NSURLSessionUploadTask实例
 *
 *  @param constructingRequestBlock 构造请求block 包含urlString,requestParams,requestHeaders
 *  @param constructingBodyBlock    构造上传文件block
 *  @param progressBlock            上传进度block
 *  @param completeBlock            上传完成block
 *
 */
- (NSURLSessionUploadTask * _Nullable)uploadFileWithConstructingRequestBlock:(NSDictionary * _Nonnull (^ _Nonnull)())constructingRequestBlock
                                         constructingBodyWithBlock:(void(^ _Nonnull)(_Nonnull id<AFMultipartFormData> formData))constructingBodyBlock
                                                     completeBlock:(void(^ _Nullable)(id _Nullable responseObject,NSError * _Nullable error))completeBlock;

/**
 *  构造一个NSURLSessionUploadTask实例
 *
 *  @param constructingRequestBlock 构造请求block 包含urlString,requestParams,requestHeaders
 *  @param constructingBodyBlock    构造上传文件block
 *  @param progressBlock            上传进度block
 *  @param completeBlock            上传完成block
 *
 */
- (NSURLSessionUploadTask * _Nullable)uploadFileWithConstructingRequestBlock:(NSDictionary * _Nonnull (^ _Nonnull)())constructingRequestBlock
                                                   constructingBodyWithBlock:(void(^ _Nonnull)(_Nonnull id<AFMultipartFormData> formData))constructingBodyBlock
                                                     progressBlock:(void(^ _Nullable)(int64_t bytes,int64_t totalBytes))progressBlock
                                                               completeBlock:(void(^ _Nullable)(id _Nullable responseObject,NSError * _Nullable error))completeBlock;

@end
