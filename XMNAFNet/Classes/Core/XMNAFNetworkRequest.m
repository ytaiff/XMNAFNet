//
//  XMNAFNetworkRequest.m
//  XMNAFNetworkDemo
//
//  Created by XMFraker on 16/4/22.
//  Copyright © 2016年 XMFraker. All rights reserved.
//

#import <XMNAFNet/XMNAFNet.h>

#import "XMNAFLogger.h"
#import "XMNAFCache.h"

#import "NSURLSessionTask+XMNAFNet.h"

NSString * const kXMNAFNetworkRequestIDKey = @"com.XMFraker.XMNAFNetwork.kXMNAFNetworkRequestIDKey";

NSString * const kXMNAFNetworkErrorDomain = @"com.XMFraker.XMNAFNetwork..kXMNAFNetworkErrorDomain";


@interface XMNAFNetworkRequest ()

@property (nonatomic, strong) id fetchedRawData;

@property (nonatomic, copy)   NSString *message;
@property (nonatomic, assign) XMNAFNetworkRequestStatus requestStatus;

/** 自身的请求ID */
@property (copy, nonatomic)   NSString *requestID;

@end

@implementation XMNAFNetworkRequest
@synthesize requestMode = _requestMode;
@synthesize shouldCache = _shouldCache;
@synthesize serviceIdentifier = _serviceIdentifier;
@synthesize methodName = _methodName;
@synthesize response = _response;

#pragma mark - Life Cycle

- (instancetype)init {
    
    if (self = [super init]) {
        
        _delegate = nil;
        _paramSource = nil;
        _interceptor = nil;
        _signInterceptor = nil;
        _fetchedRawData = nil;
        
        _message = nil;
        _requestStatus = XMNAFNetworkRequestDefault;
        
        _shouldSign = NO;
        _shouldCache = NO;
        _requestMode = XMNAFNetworkRequestGET;
        
        _timeoutInterval = kXMNAFNetworkTimeoutSeconds;
    }
    return self;
}


- (instancetype _Nullable)initWithServiceIdentifier:(NSString * _Nonnull)identifier
                                         methodName:(NSString * _Nonnull)methodName
                                        requestMode:(XMNAFNetworkRequestMode)requestMode {
    
    
    if (self = [[[self class] alloc] init]) {
        
        _requestMode = requestMode;
        _methodName = methodName;
        _serviceIdentifier = identifier;
    }
    return self;
}

- (void)dealloc {
    
    [self cancelRequest];
    self.completionBlock = nil;
    self.delegate = nil;
    self.signInterceptor = nil;
    self.interceptor = nil;
}

#pragma mark - Methods

- (void)cancelRequest {
    
    [XMNAFService cancelTaskWithIdentifier:self.requestID];
    self.requestID = nil;
}

- (id)fetchDataWithReformer:(id<XMNAFNetworkRequestDataReformer>)reformer {
    
    
    return [self fetchDataWithReformer:reformer error:nil];
}

- (_Nullable id)fetchDataWithReformer:(_Nullable id<XMNAFNetworkRequestDataReformer>)reformer
                                error:(NSError * __nullable)error {
    
    id resultData = nil;
    if (reformer) {
        resultData = [reformer request:self reformerOriginData:self.fetchedRawData error:error];
    } else {
        resultData = self.fetchedRawData;
    }
    return resultData;
}

- (NSString *)loadData {
    
    return [self loadDataWithPathParams:nil params:nil];
}


- (NSString *)loadDataWithParams:(NSDictionary *)aParams {
    
    return [self loadDataWithPathParams:nil
                                 params:aParams];
}

- (NSString * _Nullable)loadDataWithPathParams:(NSDictionary *)pathParams
                                        params:(NSDictionary *)params {
    
    NSMutableDictionary *allParams = [NSMutableDictionary dictionaryWithDictionary:[self.paramSource paramsForRequest:self]];
    if (params && [params isKindOfClass:[NSDictionary class]]) {
        [allParams addEntriesFromDictionary:params];
    }
    return [self loadDataInternalWithPathParams:pathParams
                                         params:[allParams copy]];
}

- (NSString * _Nullable)loadDataInternalWithPathParams:(NSDictionary *)pathParams
                                                params:(NSDictionary *)params {
    
    NSMutableDictionary *reformParams = [NSMutableDictionary dictionaryWithDictionary:[self reformParams:params]];
    
    if (self.isLoading) {
        
        XMNLog(@"request is doing cancel request");
        [XMNAFService cancelTaskWithIdentifier:self.requestID];
    }
    
    /** 1. 判断serviceIdentifier methodName 是否存在 */
    NSAssert(self.serviceIdentifier, @"you must implements serviceIdentifier in your class :%@",NSStringFromClass([self class]));
    NSAssert(self.methodName, @"you must implements methodName in your class :%@",NSStringFromClass([self class]));
    
    __block NSString *methodName = self.methodName;
    if (pathParams && [pathParams isKindOfClass:[NSDictionary class]]) {
        [pathParams enumerateKeysAndObjectsUsingBlock:^(NSString  *key, NSString  *obj, BOOL * _Nonnull stop) {
            
            methodName = [methodName stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"{%@}",key] withString:[NSString stringWithFormat:@"%@",obj]];
        }];
    }
    
    /** 2. 获取service */
    XMNAFService *service = [XMNAFService serviceWithIdentifier:self.serviceIdentifier];
    NSAssert(service, @"service with serviceIdentifier :%@ is not exists", self.serviceIdentifier);
    
    /** 3. 判断请求是否需要进行加密 */
    if (self.shouldSign && self.signInterceptor && [self.signInterceptor respondsToSelector:@selector(signParamsWithURLString:params:)]) {
        
        NSDictionary *signParams = [self.signInterceptor signParamsWithURLString:[service.apiBaseURL stringByAppendingString:methodName]
                                                                          params:reformParams];
        if (signParams) {
            [reformParams addEntriesFromDictionary:signParams];
        }
    }
    
    /** 4. 判断请求 是否可以正常发起 */
    if ([self handleShouldContineWithParams:reformParams]) {
        
        /** 5. 判断请求 是否有缓存 */
        if (self.shouldCache && [self handleHasCacheWithParams:reformParams]) {
            
            return self.requestID;
        }
        /** 6. 判断网络连接是否有问题 */
        if ([self isReachable]) {
            
            /** 7. 正常发起请求 */
            __weak typeof(*&self) wSelf = self;
            
            /** 8. 增加超时时间设置功能 */
            [service.sessionManager.requestSerializer setTimeoutInterval:self.timeoutInterval];
            
            self.requestID = [service requestWithMode:self.requestMode
                                               params:reformParams
                                           methodName:methodName
                                      completionBlock:^(XMNAFNetworkResponse *response, NSError *error) {
                                          
                                          __strong typeof(*&wSelf) self = wSelf;
                                          [self handleCompletionWithResponse:response
                                                                      params:reformParams
                                                                       error:error];
                                      }];
            return self.requestID;
        } else {
            
            /** 请求无网络连接错误 */
            NSError *error = [NSError errorWithDomain:kXMNAFNetworkErrorDomain code:XMNAFNetworkRequestUnreachableNetwork userInfo:nil];
            self.requestStatus =  XMNAFNetworkRequestUnreachableNetwork;
            [self handleCompletionWithResponse:nil
                                        params:reformParams
                                         error:error];
        }
    } else {
        
        /** 请求参数错误,无法正常发起请求 */
        NSError *error = [NSError errorWithDomain:kXMNAFNetworkErrorDomain code:XMNAFNetworkRequestParamsError userInfo:nil];
        self.requestStatus =  XMNAFNetworkRequestParamsError;
        [self handleCompletionWithResponse:nil
                                    params:reformParams
                                     error:error];
    }
    return self.requestID;
}

- (BOOL)handleShouldContineWithParams:(id)aParams {
    
    if (self.interceptor && self.interceptor != self && [self.interceptor respondsToSelector:@selector(request:shouldContinueWithParams:)]) {
        return [self.interceptor request:self shouldContinueWithParams:aParams];
    }
    return YES;
}

- (BOOL)handleHasCacheWithParams:(id)aParams {
    
    NSString *serviceIdentifier = self.serviceIdentifier;
    NSString *methodName = self.methodName;
    NSData *result = [XMNAFCache fetchCachedDataWithServiceIdentifier:serviceIdentifier
                                                           methodName:methodName
                                                        requestParams:aParams];
    
    if (result == nil) { return NO; }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        XMNAFNetworkResponse *response = [[XMNAFNetworkResponse alloc] initWithData:result];
        [XMNAFLogger logCacheResponseInfoWithResposne:response
                                           methodName:methodName
                                           forService:[XMNAFService serviceWithIdentifier:serviceIdentifier]];
        [self handleCompletionWithResponse:response
                                    params:aParams
                                     error:nil];
    });
    return YES;
}

- (void)handleCompletionWithResponse:(XMNAFNetworkResponse *)aResponse
                              params:(id)aParams
                               error:(NSError *)aError {
    
    if (aError) {
        
        /** 不处理取消的请求回调 */
        if (aError.code != NSURLErrorCancelled) {
            _response = aResponse;
            if (self.delegate && [self.delegate respondsToSelector:@selector(didFailed:)]) { [self.delegate didFailed:self]; }
            self.completionBlock ? self.completionBlock(self, aError) : nil;
        }
    } else {
        
        _response = aResponse;
        if (aResponse.responseObject) {
            self.fetchedRawData = [aResponse.responseObject copy];
        } else {
            self.fetchedRawData = [aResponse.responseData copy];
        }
        
        self.requestID = nil;
        if (self.delegate && [self.delegate respondsToSelector:@selector(didSuccess:)]) { [self.delegate didSuccess:self]; }
        if (self.completionBlock) self.completionBlock(self, nil);
        
        /** 存储缓存记录 */
        if (self.shouldCache && !aResponse.fromCache) {
            
            if (self.interceptor && [self.interceptor respondsToSelector:@selector(requestShouldCache:)]) {
                if ([self.interceptor requestShouldCache:self]) {
                    [XMNAFCache saveCacheWithData:self.fetchedRawData
                                serviceIdentifier:self.serviceIdentifier
                                       methodName:self.methodName
                                    requestParams:aParams
                                        cacheTime:self.cacheTime];
                }
            } else {
                [XMNAFCache saveCacheWithData:self.fetchedRawData
                            serviceIdentifier:self.serviceIdentifier
                                   methodName:self.methodName
                                requestParams:aParams
                                    cacheTime:self.cacheTime];
            }
        }
    }
}


- (void)cleanData {
    
    self.fetchedRawData = nil;
    self.message = nil;
    self.requestStatus = XMNAFNetworkRequestDefault;
}

- (NSDictionary *)reformParams:(NSDictionary *)params {
    
    return params;
}


#pragma mark - Setters

- (void)setSignInterceptor:(id<XMNAFNetworkRequestSignInterceptor>)signInterceptor {
    
    _signInterceptor = signInterceptor;
    _shouldSign = YES;
}


#pragma mark - Getters

- (NSString *)message {
    
    
    /** 优先处理response.status逻辑 */
    if (self.response) {
        switch (self.response.responseStatus) {
                
            case XMNAFNetworkResponseSuccess:
                return @"网络请求成功";
            case XMNAFNetworkResponseTimeoutError:
                return @"网络请求超时";
            case XMNAFNetworkResponseNetworkError:
            default:
                return @"网络请求失败";
        }
    }
    
    /** 如果没有response 则按照request处理 */
    switch (self.requestStatus) {
        case XMNAFNetworkRequestParamsError:
            return @"请求参数不正确";
        case XMNAFNetworkRequestUnreachableNetwork:
            return @"暂无网络连接";
        default:
            return @"网络请求成功";
    }
}

- (BOOL)isReachable {
    
#if kXMNAFReachablityAvailable
    if ([XMNAFReachabilityManager sharedManager].isMonitoring) return [XMNAFReachabilityManager isNetworkEnable];
    return YES;
#else
    return YES;
#endif
}

- (BOOL)isLoading {
    
    return self.dataTask && self.dataTask.state == NSURLSessionTaskStateRunning;
}

- (NSURLSessionDataTask *)dataTask {
    
    return [XMNAFService taskWithIdentifier:self.requestID];
}

- (NSDictionary *)requestParams {
    
    return self.dataTask.requestParams;
}

@end
