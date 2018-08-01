//
//  XMNAFService.m
//  XMNAFNetworkDemo
//
//  Created by XMFraker on 16/4/22.
//  Copyright © 2016年 XMFraker. All rights reserved.
//

#import "XMNAFNetworkPrivate.h"
#import "XMNAFNetworkConfiguration.h"

#import <pthread.h>
#import <AFNetworking/AFNetworking.h>
#import <CommonCrypto/CommonCrypto.h>


static AFHTTPSessionManager *kAFHTTPSessionManager;

static pthread_mutex_t kXMNAFMutexLock;

/** 记录当前所有可用的service */
static NSMutableDictionary<NSString *, __kindof XMNAFService *> *kXMNAFSeriviceDictionaryM;

NSString * _Nullable XMNAF_MD5(NSString * _Nonnull str) {
    
    if (!str || str.length == 0) {
        return nil;
    }
    NSData* inputData = [str dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char outputData[CC_MD5_DIGEST_LENGTH];
    CC_MD5([inputData bytes], (unsigned int)[inputData length], outputData);
    
    NSMutableString* hashStr = [NSMutableString string];
    int i = 0;
    for (i = 0; i < CC_MD5_DIGEST_LENGTH; ++i)
        [hashStr appendFormat:@"%02x", outputData[i]];
    
    return hashStr;
}

NSError *__nonnull kXMNAFNetworkError(NSInteger code, NSString * __nullable message) {
    return [NSError errorWithDomain:kXMNAFNetworkErrorDomain code:code userInfo: message ? @{@"message" :message} : nil];
}

@implementation XMNAFService
{
    pthread_mutex_t _lock;
}
#if kXMNAFCacheAvailable
@synthesize cache = _cache;
@synthesize cachePath = _cachePath;
#endif
@synthesize serviceMode = _serviceMode;
@synthesize requestMappers = _requestMappers;
@synthesize sessionManager = _sessionManager;

+ (void)initialize {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pthread_mutex_init(&kXMNAFMutexLock, NULL);
        kXMNAFSeriviceDictionaryM = [NSMutableDictionary dictionary];
    });
}

#pragma mark - Life Cycle

- (instancetype)init {
    return [self initWithConfiguration:nil];
}

- (instancetype)initWithConfiguration:(NSURLSessionConfiguration *)configuration {
    
    if (self = [super init]) {
        
        pthread_mutex_init(&_lock, NULL);
        _requestMappers = [NSMutableDictionary dictionary];
        _sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:nil
                                                   sessionConfiguration:configuration ? : [NSURLSessionConfiguration defaultSessionConfiguration]];
        _sessionManager.session.configuration.HTTPMaximumConnectionsPerHost = 4;

        _sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
        _sessionManager.requestSerializer.timeoutInterval = 10.f;
        _sessionManager.requestSerializer.cachePolicy = NSURLRequestUseProtocolCachePolicy;
        _sessionManager.requestSerializer.HTTPShouldHandleCookies = YES;
        _sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
#if kXMNAFCacheAvailable
        _cache = [YYCache cacheWithPath:self.cachePath];
#endif
        _sessionManager.completionQueue = self.completionQueue;
    }
    return self;
}

#pragma mark - Public

- (void)performThreadSafeHandler:(dispatch_block_t)handler {
    
    pthread_mutex_lock(&_lock);
    if (handler) { handler(); }
    pthread_mutex_unlock(&_lock);
}

#pragma mark - Setter

- (void)setRequestSerializerType:(XMNAFRequestSerializerType)type {

    if (type == XMNAFRequestSerializerJSON) {
        _sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
    } else {
        _sessionManager.requestSerializer = [AFHTTPRequestSerializer serializer];
    }
    _sessionManager.requestSerializer.timeoutInterval = 10.f;
    _sessionManager.requestSerializer.cachePolicy = NSURLRequestUseProtocolCachePolicy;
    _sessionManager.requestSerializer.HTTPShouldHandleCookies = YES;
}

- (void)setResponseSerializerType:(XMNAFResponseSerializerType)type {

    switch (type) {
        case XMNAFResponseSerializerJSON:
            _sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
            break;
        case XMNAFResponseSerializerXML:
            _sessionManager.responseSerializer = [AFXMLParserResponseSerializer serializer];
            break;
        default:
            _sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
            break;
    }
}

- (void)setSecurityPolicy:(AFSecurityPolicy *)securityPolicy {
    _sessionManager.securityPolicy = securityPolicy;
}

#pragma mark - Getters

- (NSString *)apiBaseURL { return @""; }

- (NSString *)apiVersion { return @"0.1.0"; }

- (NSDictionary *)commonParams { return nil; }

- (NSDictionary *)commonHeaders { return nil; }

#if kXMNAFCacheAvailable

- (NSString *)cachePath {
    
    NSString *cachePath = _cachePath;
    if (cachePath.length) return cachePath;
    
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    if (self.apiBaseURL.length) {
        NSURL *url = [NSURL URLWithString:self.apiBaseURL];
        cachePath = [NSString stringWithFormat:@"%@/com.xmfraker.xmafnetwork/caches/%@", documentPath, url.host.length ? url.host : @"default"];
    } else {
        cachePath = [NSString stringWithFormat:@"%@/com.xmfraker.xmafnetwork/caches/default", documentPath];
    }
    _cachePath = cachePath;
    return cachePath;
}

#endif

- (dispatch_queue_t)serviceQueue {
    return dispatch_queue_create("com.xmfraker.network.complete.queue", DISPATCH_QUEUE_SERIAL);
}

- (XMNAFRequestSerializerType)requestSerializerType {

    XMNAFRequestSerializerType serializerType = XMNAFRequestSerializerHTTP;
    id<AFURLRequestSerialization> serialization = _sessionManager.requestSerializer;
    if ([serialization isKindOfClass:[AFJSONResponseSerializer class]]) {
        serializerType = XMNAFRequestSerializerJSON;
    }
    return serializerType;
}

- (XMNAFResponseSerializerType)responseSerializerType {
    
    XMNAFResponseSerializerType serializerType = XMNAFResponseSerializerHTTP;
    id<AFURLResponseSerialization> serialization = _sessionManager.responseSerializer;
    if ([serialization isKindOfClass:[AFJSONResponseSerializer class]]) {
        serializerType = XMNAFResponseSerializerJSON;
    } else if ([serialization isKindOfClass:[AFXMLParserResponseSerializer class]]) {
        serializerType = XMNAFResponseSerializerXML;
    }
    return serializerType;
}

- (AFSecurityPolicy *)securityPolicy { return _sessionManager.securityPolicy; }

@end

@implementation XMNAFService (ManageService)

+ (void)storeService:(XMNAFService *)service forIdentifier:(NSString *)identifier {
    
    if (!identifier.length) { return; }
    pthread_mutex_lock(&kXMNAFMutexLock);
    if (!service) {
        [kXMNAFSeriviceDictionaryM removeObjectForKey:identifier];
    } else {
        [kXMNAFSeriviceDictionaryM setObject:service forKey:identifier];
    }
    pthread_mutex_unlock(&kXMNAFMutexLock);
}

+ (XMNAFService *)serviceWithIdentifier:(NSString *)identifier {
    
    if (!identifier.length) { return nil; }
    pthread_mutex_lock(&kXMNAFMutexLock);
    XMNAFService *service = [kXMNAFSeriviceDictionaryM  objectForKey:identifier];
    pthread_mutex_unlock(&kXMNAFMutexLock);
    return service;
}

+ (NSArray <XMNAFService *> *)storedServices {
    
    pthread_mutex_lock(&kXMNAFMutexLock);
    NSArray<XMNAFService *> *services = [kXMNAFSeriviceDictionaryM allValues];
    pthread_mutex_unlock(&kXMNAFMutexLock);
    return services;
}

+ (void)configServiceModeForStoredServices:(XMNAFServiceMode)mode {
    
    for (XMNAFService *service in [self storedServices]) {
        service.serviceMode = mode;
    }
}

@end
