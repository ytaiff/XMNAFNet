//
//  XMNAFNetworkRequest.m
//  XMNAFNetworkDemo
//
//  Created by XMFraker on 16/4/22.
//  Copyright © 2016年 XMFraker. All rights reserved.
//


#import "XMNAFNetworkPrivate.h"
#import "XMNAFNetworkConfiguration.h"

#if kXMNAFCacheAvailable
    #import "XMNAFCacheMeta.h"
    #import "XMNAFNetworkRequest+Cache.h"
#endif

NSString *const kXMNAFNetworkErrorDomain = @"com.XMFraker.XMNAFNetwork.Domain";

@implementation XMNAFNetworkRequest
@synthesize methodName = _methodName;
@synthesize requestMode = _requestMode;
@synthesize serviceIdentifier = _serviceIdentifier;
@synthesize allowsCellularAccess = _allowsCellularAccess;
#pragma mark - Life Cycle

- (instancetype)init {
    
    if (self = [super init]) {

        _priority = NSURLSessionTaskPriorityDefault;
        _requestMode = XMNAFNetworkRequestGET;
        _timeoutInterval = 10.f;
        _allowsCellularAccess = YES;
        _ignoredCancelledRequest = YES;
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
    
    if (self.isExecuting) [_datatask cancel];
    _completionBlock = NULL;
    _paramSource = nil;
    _delegate = nil;
    _interceptor = nil;
    _responseInterceptor = nil;
}

#pragma mark - Override Methods

- (NSString *)description {
    
    NSMutableString *desc = [NSMutableString stringWithFormat:@"<%@: %p>{ URL: %@ } { method: %@ }", NSStringFromClass([self class]), self, self.currentRequest.URL, self.currentRequest.HTTPMethod];
    
    if (self.currentRequest.URL) {
        NSArray<NSHTTPCookie *> *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:self.currentRequest.URL];
        if (cookies.count) {
            [desc appendFormat:@"{ params: %@ } ", cookies];
        }
    }
    
    if (self.requestParams.count) {
        [desc appendFormat:@"{ params: %@ } ", self.requestParams];
    }
    
    if (self.error) {
        [desc appendFormat:@"{ error: %@ } ", self.error];
    }
    
    return [desc copy];
}

#pragma mark - Public

- (id)fetchDataWithReformer:(id<XMNAFNetworkRequestDataReformer>)reformer {

    return [self fetchDataWithReformer:reformer error:nil];
}

- (_Nullable id)fetchDataWithReformer:(_Nullable id<XMNAFNetworkRequestDataReformer>)reformer
                                error:(NSError * __nullable)error {
    
    if (reformer) {
        return [reformer request:self reformerOriginData:self.responseObject error:error];
    }
    return self.responseObject;
}

- (void)loadData { [self startRequestWithParams:nil completionHandler:NULL]; }

- (void)loadDataWithParams:(NSDictionary *)aParams {
    
    [self startRequestWithParams:aParams completionHandler:NULL];
}

- (void)loadDataWithPathParams:(NSDictionary *)pathParams
                                        params:(NSDictionary *)params {
    
    NSMutableDictionary *allParams = [pathParams ? : @{} mutableCopy];
    if (params && [params isKindOfClass:[NSDictionary class]]) { [allParams addEntriesFromDictionary:params]; }
    [self startRequestWithParams:allParams completionHandler:NULL];
}

- (void)startRequest {
    [self startRequestWithParams:nil completionHandler:NULL];
}

- (void)startRequestWithParams:(NSDictionary *)params {
    [self startRequestWithParams:params completionHandler:NULL];
}

- (void)startRequestWithParams:(NSDictionary *)params completionHandler:(XMNAFNetworkCompletionHandler)completionHandler {
    
    /** 1. 判断serviceIdentifier methodName 是否存在 */
    NSAssert(self.service, @"service should not be nil");
    NSAssert(self.methodName, @"you must implements methodName in your class :%@",NSStringFromClass([self class]));
    
    __weak typeof(self) wSelf = self;
    dispatch_async(self.service.sessionManager.completionQueue, ^{
        
        __strong typeof(wSelf) self = wSelf;
        
        /** 2. 判断当前网络是否可用, 网络不可用直接返回 */
        if (!self.isReachable) {
            [self requestDidCompletedWithError:kXMNAFNetworkError(NSURLErrorNotConnectedToInternet, @"当前网络不可用,请检查您的网络设置")];
            return;
        }
        
#if kXMNAFReachablityAvailable
        /** 3. 判断当前请求是否允许 */
        if (!self.isAllowsCellularAccess && ![XMNAFReachabilityManager isWifiEnable]) {
            [self requestDidCompletedWithError:kXMNAFNetworkError(NSURLErrorNotConnectedToInternet, @"当前网络不可用,请检查您的网络设置")];
            return;
        }
#endif
        
        if (completionHandler) { self.completionBlock = completionHandler; }
        if (self.isExecuting) { [self cancelRequest]; }
        
        NSMutableDictionary *requestParams = [NSMutableDictionary dictionaryWithDictionary:self.service.commonParams];
        [requestParams addEntriesFromDictionary:params ? : @{}];
        
        if ([self.paramSource respondsToSelector:@selector(paramsForRequest:)]) {
            [requestParams addEntriesFromDictionary:[self.paramSource paramsForRequest:self]];
        }
        
        self.requestParams = [requestParams copy];
        
        if ([self.interceptor respondsToSelector:@selector(request:shouldContinueWithParams:)]) {
            BOOL shouldContinue = [self.interceptor request:self shouldContinueWithParams:requestParams];
            if (!shouldContinue) { return; }
        }
        
#if kXMNAFCacheAvailable
        self.cacheKey = [self.service cacheKeyWithRequest:self];
        
        if (self.cachePolicy == XMNAFNetworkCachePolicyInnoringCacheData) {
            [self.service startRequest:self];
        } else {
            __weak typeof(self) wSelf = self;
            [self loadResponseObjectFromCacheWithCompletionHandler:^(XMNAFCacheMeta *meta, NSError *error) {
                __strong typeof(wSelf) self = wSelf;
                switch (self.cachePolicy) {
                    case XMNAFNetworkCachePolicyReturnCacheDataDontLoad:
                        [self requestDidCompletedWithCachedMeta:meta error:error];
                        break;
                    case XMNAFNetworkCachePolicyReturnCacheDataElseLoad:
                    case XMNAFNetworkCachePolicyReturnAndRefreshCacheData:
                    {
                        BOOL shouldContinue = YES;
                        if (meta && !error) {
                            shouldContinue = self.cachePolicy != XMNAFNetworkCachePolicyReturnCacheDataElseLoad;
                            [self requestDidCompletedWithCachedMeta:meta error:nil];
                        }
                        if (shouldContinue) [self.service startRequest:self];
                    }
                        break;
                    default:
                        [self.service startRequest:self];
                        break;
                }
            }];
        }
#else
        [self.service startRequest:self];
#endif
    });
}

- (void)cancelRequest {
    
    dispatch_async(self.service.sessionManager.completionQueue, ^{
        [self.datatask cancel];
#if kXMNAFCacheAvailable
        if (self.downloadPath.length) { [self.service.cache.diskCache removeObjectForKey:self.cacheKey]; }
#endif
    });
}

- (void)suspendRequest {
    
    dispatch_async(self.service.sessionManager.completionQueue, ^{
        if ([self.datatask isKindOfClass:[NSURLSessionDownloadTask class]]) {
#if kXMNAFCacheAvailable
            __weak typeof(self) wSelf = self;
            [(NSURLSessionDownloadTask *)self.datatask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                __strong typeof(wSelf) self = wSelf;
                dispatch_async(self.service.sessionManager.completionQueue, ^{
                    __strong typeof(wSelf) self = wSelf;
                    if (resumeData != nil) {
                        [self.service.cache.diskCache setObject:resumeData forKey:self.cacheKey];
                    }
                });
            }];
#endif
        } else {
            [self.datatask cancel];
        }
    });
}

#pragma mark - Private

- (void)requestDidCompletedWithError:(NSError *)error {
    
    self.error = error;
    
#if kXMNAFCacheAvailable
    if (self.error == nil) {
        BOOL shouldCache = self.shouldCache;
        
        if (self.interceptor && [self.interceptor respondsToSelector:@selector(requestShouldCache:)]) {
            shouldCache = shouldCache && [self.interceptor requestShouldCache:self];
        }
        
        if (self.responseInterceptor && [self.responseInterceptor respondsToSelector:@selector(requestShouldCacheResponse:)]) {
            shouldCache = shouldCache && [self.responseInterceptor requestShouldCacheResponse:self];
        }
        
        if (shouldCache) {
            XMNAFCacheMeta *meta = [XMNAFCacheMeta cacheMetaWithRequest:self];
            [self.service.cache setObject:meta forKey:self.cacheKey];
        }
    }
    
#endif
    
    if (self.responseInterceptor && [self.responseInterceptor respondsToSelector:@selector(responseObjectForRequest:error:)]) {
        self.responseObject = [self.responseInterceptor responseObjectForRequest:self error:self.error];
    }

    self.fromCache = NO;
    if (self.ignoredCancelledRequest && self.isCancelled) {
#if DEBUG
        NSLog(@"%@ is ignored request", self);
#endif
        return;
    }
    [self requestCallBackOnMainThread];
}

#if kXMNAFCacheAvailable

- (void)requestDidCompletedWithCachedMeta:(XMNAFCacheMeta *)meta error:(NSError *)error {
    
    self.error = error;
    self.responseObject = [meta.cachedData yy_modelToJSONObject];
    if (self.responseInterceptor && [self.responseInterceptor respondsToSelector:@selector(responseObjectForRequest:error:)]) {
        self.responseObject = [self.responseInterceptor responseObjectForRequest:self error:self.error];
    }
    self.fromCache = YES;
    [self requestCallBackOnMainThread];
}

#endif

- (void)requestCallBackOnMainThread {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.completionBlock ? self.completionBlock(self, self.error) : nil;
        if ([self.delegate respondsToSelector:@selector(requestDidCompleted:)]) {
            [self.delegate requestDidCompleted:self];
        }
    });
}

#pragma mark - Setter

- (void)setAllowsCellularAccess:(BOOL)allowsCellularAccess {
    @synchronized (self) { _allowsCellularAccess = allowsCellularAccess; }
}

#pragma mark - Getters

- (BOOL)isReachable {
    
#if kXMNAFReachablityAvailable
    if ([XMNAFReachabilityManager sharedManager].isMonitoring) return [XMNAFReachabilityManager isNetworkEnable];
    return YES;
#else
    return YES;
#endif
}

- (BOOL)isExecuting {
    
    if (self.datatask != nil && self.datatask.state == NSURLSessionTaskStateRunning) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)isCancelled {
    
    if (self.error != nil && self.error.code == NSURLErrorCancelled) {
        return YES;
    } else if (self.datatask != nil && self.datatask.state == NSURLSessionTaskStateCanceling) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)isAllowsCellularAccess {
    BOOL ret = YES;
    @synchronized(self) { ret = _allowsCellularAccess; }
    return ret;
}

- (XMNAFService *)service {
    if (!_service) {  _service = [XMNAFService serviceWithIdentifier:self.serviceIdentifier]; }
    return _service;
}

@end


@implementation XMNAFNetworkRequest (Convenient)
- (NSURLRequest *)currentRequest { return self.datatask.currentRequest; }
- (NSURLRequest *)originalRequest { return self.datatask.originalRequest; }
- (NSHTTPURLResponse *)response { return (NSHTTPURLResponse *)self.datatask.response; }
- (NSInteger)responseCode { return self.response.statusCode; }
- (NSDictionary *)responseHeaders { return self.response.allHeaderFields; }
@end

@implementation XMNAFNetworkRequest (Response)
- (BOOL)isFromCache { return _fromCache; }
@end
