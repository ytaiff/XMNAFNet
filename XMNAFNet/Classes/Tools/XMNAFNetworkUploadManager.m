//
//  XMNAFNetworkUploadManager.m
//  XMNAFNetworkDemo
//
//  Created by XMFraker on 16/6/8.
//  Copyright © 2016年 XMFraker. All rights reserved.
//

#import "XMNAFNetworkUploadManager.h"

NSString *const kXMNAFUploadManagerSessionIdentifier = @"com.XMFraker.XMNAFNetwork.XMNAFUploadManager.SessionIdentifier";
NSString *const kXMNAFUploadURLStringKey = @"com.XMFraker.XMNAFNetwork.XMNAFUploadManager.URLStringKey";
NSString *const kXMNAFUploadRequestHeadersKey = @"com.XMFraker.XMNAFNetwork.XMNAFUploadManager.RequestHeadersKey";
NSString *const kXMNAFUploadRequestParamsKey = @"com.XMFraker.XMNAFNetwork.XMNAFUploadManager.RequestParamsKey";


@implementation XMNAFNetworkUploadManager
@synthesize sessionManager = _sessionManager;
@synthesize requestSerizalizer = _requestSerizalizer;
@synthesize responseSerizalizer = _responseSerizalizer;

#pragma mark - Life Cycle

+ (instancetype)sharedManager {
    
    static id manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[[self class] alloc] init];
    });
    return manager;
}


#pragma mark - Methods


- (NSURLSessionUploadTask *)uploadFileWithConstructingRequestBlock:(NSDictionary *(^)())constructingRequestBlock
                                         constructingBodyWithBlock:(void(^)(id<AFMultipartFormData> formData))constructingBodyBlock
                                                     completeBlock:(void(^)(id responseObject,NSError *error))completeBlock {
    
   return  [self uploadFileWithConstructingRequestBlock:constructingRequestBlock
                       constructingBodyWithBlock:constructingBodyBlock
                                   progressBlock:nil
                                   completeBlock:completeBlock];
}

- (NSURLSessionUploadTask *)uploadFileWithConstructingRequestBlock:(NSDictionary *(^)())constructingRequestBlock
                                         constructingBodyWithBlock:(void(^)(id<AFMultipartFormData> formData))constructingBodyBlock
                                                     progressBlock:(void(^)(int64_t bytes,int64_t totalBytes))progressBlock
                                                     completeBlock:(void(^)(id responseObject,NSError *error))completeBlock {
    
    
    /** 校验是否含有上传路径 */
    NSDictionary *arguments = constructingRequestBlock();
    NSAssert(arguments[kXMNAFUploadURLStringKey], @"does not have urlstring");
    
    /** 配置上传头部信息 */
    NSDictionary *requestHeaders = arguments[kXMNAFUploadRequestHeadersKey];
    
    NSArray<NSHTTPCookie *> *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:arguments[kXMNAFUploadURLStringKey]]];
    NSDictionary *headers = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
    NSString *cookieString = [headers allValues].count ? [[headers allValues] firstObject] : nil;

    if (requestHeaders) {
        [requestHeaders enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            
            if ([[obj lowercaseString] isEqualToString:@"cookie"]) {
                if (cookieString && cookieString.length) {
                    [self.requestSerizalizer setValue:[obj stringByAppendingFormat:@";%@",cookieString] forHTTPHeaderField:key];
                }else {
                    [self.requestSerizalizer setValue:obj forHTTPHeaderField:key];
                }
            }else {
                [self.requestSerizalizer setValue:obj forHTTPHeaderField:key];
            }
        }];
    }else if (cookieString && cookieString.length){
        [self.requestSerizalizer setValue:cookieString forHTTPHeaderField:@"Cookie"];
    }
    
    /** 获取请求 */
    NSMutableURLRequest *request = [self.requestSerizalizer multipartFormRequestWithMethod:@"POST" URLString:arguments[kXMNAFUploadURLStringKey] parameters:arguments[kXMNAFUploadRequestParamsKey] constructingBodyWithBlock:constructingBodyBlock error:nil];
    request.HTTPShouldHandleCookies = YES;
    
    NSURLSessionUploadTask *uploadTask = [self.sessionManager uploadTaskWithStreamedRequest:request  progress:^(NSProgress * _Nonnull uploadProgress) {
        
        progressBlock ? progressBlock(uploadProgress.completedUnitCount,uploadProgress.totalUnitCount) : nil;
    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {

        completeBlock ? completeBlock(responseObject, error) : nil;
    }];
    [uploadTask resume];
    return uploadTask;
}

#pragma mark - Getters

- (AFHTTPRequestSerializer *)requestSerizalizer {
    
    if (!_requestSerizalizer) {
        _requestSerizalizer = [AFHTTPRequestSerializer serializer];
    }
    return _requestSerizalizer;
}

- (AFJSONResponseSerializer *)responseSerizalizer {
    
    if (!_responseSerizalizer) {
        _responseSerizalizer = [AFJSONResponseSerializer serializer];
    }
    return _responseSerizalizer;
}


- (AFHTTPSessionManager *)sessionManager {
    
    if (!_sessionManager) {
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        _sessionManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:sessionConfiguration];
        _sessionManager.requestSerializer = self.requestSerizalizer;
    }
    return _sessionManager;
}


@end
