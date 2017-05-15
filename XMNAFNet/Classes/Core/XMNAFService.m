//
//  XMNAFService.m
//  XMNAFNetworkDemo
//
//  Created by XMFraker on 16/4/22.
//  Copyright © 2016年 XMFraker. All rights reserved.
//

#import "XMNAFService.h"

#import "AFNetworking.h"
#import "XMNAFLogger.h"
#import "XMNAFNetworkRequest.h"
#import "XMNAFNetworkResponse.h"

#import "NSDictionary+XMNAFJSON.h"
#import "NSURLSessionTask+XMNAFNet.h"

#import <CommonCrypto/CommonCrypto.h>

static AFHTTPSessionManager *kAFHTTPSessionManager;

/** 记录当前所有可用的service */
static NSMutableDictionary<NSString *, __kindof XMNAFService *> *kXMNAFSeriviceDictionaryM;

/** 记录当前所有正在请求的 dataTask 以 dataTask.hash 为key */
static NSMutableDictionary<NSString *, __kindof NSURLSessionTask *> *kXMNAFRequestIDDictionaryM;

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

@implementation XMNAFService

+ (void)initialize {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"will load XMNAFService");
        
        kXMNAFSeriviceDictionaryM = [NSMutableDictionary dictionary];
        kXMNAFRequestIDDictionaryM = [NSMutableDictionary dictionary];
        
        //创建kAFHTTPSessionManager
        kAFHTTPSessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:nil sessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        kAFHTTPSessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
        kAFHTTPSessionManager.requestSerializer.timeoutInterval = kXMNAFNetworkTimeoutSeconds;
        kAFHTTPSessionManager.requestSerializer.cachePolicy = NSURLRequestUseProtocolCachePolicy;
        kAFHTTPSessionManager.requestSerializer.HTTPShouldHandleCookies = YES;
        NSMutableSet *sets = [NSMutableSet setWithSet:kAFHTTPSessionManager.responseSerializer.acceptableContentTypes];
        [sets addObject:@"text/html"];
        kAFHTTPSessionManager.responseSerializer.acceptableContentTypes = sets;

    });
}


+ (void)storeService:(XMNAFService *)service forIdentifier:(NSString *)identifier {
    
    if (!service || !identifier) {
        return;
    }
    [kXMNAFSeriviceDictionaryM setObject:service forKey:identifier];
}

+ (XMNAFService *)serviceWithIdentifier:(NSString *)identifier {
    
    if (!identifier || !identifier.length) {
        return nil;
    }
    return kXMNAFSeriviceDictionaryM[identifier];
}

+ (NSArray <XMNAFService *> *)storedServices {
    
    return [kXMNAFSeriviceDictionaryM allValues];
}

#pragma mark - Getters

- (NSString *)privateKey {
    
    return @"";
}

- (NSString *)publicKey {
    
    return @"";
}

- (NSString *)apiBaseURL {
    
    return @"";
}

- (NSString *)apiVersion {
    
    return @"v0.0";
}

- (NSDictionary *)commonParams {
    
    return nil;
}

- (NSDictionary *)commonHeaders {
    
    return nil;
}

- (BOOL)shouldSign {
    
    return NO;
}

- (BOOL)shouldLog {
    
#ifdef DEBUG
    return YES;
#else
    return NO;
#endif
}

- (AFHTTPSessionManager *)sessionManager{
    
    //    AFSecurityPolicy *policy = nil;
    //    {
    //        /** 设置HTTPS 证书 */
    //        NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"https" ofType:@"cer"];
    //        NSData * certData =[NSData dataWithContentsOfFile:cerPath];
    //        policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate withPinnedCertificates:[NSSet setWithObjects:certData, nil]];
    //
    //        /** 设置不允许五小证书 */
    //        policy.allowInvalidCertificates = NO;
    //        kAFHTTPSessionManager.securityPolicy = policy;
    //    }
    //    {
    //        /** 使用publickkey 方式 */
    //        NSString *publicKey = @"";
    //        policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey withPinnedCertificates:[NSSet setWithObjects:[publicKey dataUsingEncoding:NSUTF8StringEncoding], nil]];
    //        /** 设置不允许五小证书 */
    //        policy.allowInvalidCertificates = NO;
    //        kAFHTTPSessionManager.securityPolicy = policy;
    //    }
    
    return kAFHTTPSessionManager;
}
@end

@implementation XMNAFService (RequestMethod)


#pragma mark - Method

- (NSString *)requestWithMode:(int)aMode
                       params:(NSDictionary *)aParams
                   methodName:(NSString *)aMethodName
              completionBlock:(void(^)(XMNAFNetworkResponse *response,NSError *error))aCompletionBlock {
    
    //1.获取请求service
    NSAssert(self, @"service not exist !!!");
    
    NSMutableDictionary *allParams = [NSMutableDictionary dictionaryWithDictionary:aParams];
    
    //添加commonParams
    if (self.commonParams) {
        [allParams addEntriesFromDictionary:self.commonParams];
    }
    
    if (self.commonHeaders && self.commonHeaders.allKeys.count > 0) {
        __weak typeof(*&self) wSelf = self;
        [self.commonHeaders enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            __strong typeof(*&wSelf) self = wSelf;
            [self.sessionManager.requestSerializer setValue:obj forHTTPHeaderField:key];
        }];
    }
    
    NSURLSessionDataTask *dataTask;
    NSString *urlString = [self.apiBaseURL stringByAppendingString:aMethodName];
    NSString *requestID = [[self class] generateRequestKeyWithURLString:urlString params:aParams];
    
    __weak typeof(*&self) wSelf = self;
    switch (aMode) {
        case XMNAFNetworkRequestPOST:
        {
            dataTask = [self.sessionManager POST:urlString parameters:allParams progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                
                __strong typeof(*&wSelf) self = wSelf;
                [self handleAFSuccessResponseWithDataTask:task responseObject:responseObject completedBlock:aCompletionBlock];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                
                __strong typeof(*&wSelf) self = wSelf;
                [self handleAFFailedResponseWithDataTask:task error:error completedBlock:aCompletionBlock];
            }];
        }
            break;
        case XMNAFNetworkRequestPUT:
        {
            dataTask = [self.sessionManager PUT:urlString parameters:allParams success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                
                __strong typeof(*&wSelf) self = wSelf;
                [self handleAFSuccessResponseWithDataTask:task responseObject:responseObject completedBlock:aCompletionBlock];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                
                __strong typeof(*&wSelf) self = wSelf;
                [self handleAFFailedResponseWithDataTask:task error:error completedBlock:aCompletionBlock];
            }];
        }
            break;
        case XMNAFNetworkRequestDELETE:
            
        {
            dataTask = [self.sessionManager DELETE:urlString parameters:allParams success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                
                __strong typeof(*&wSelf) self = wSelf;
                [self handleAFSuccessResponseWithDataTask:task responseObject:responseObject completedBlock:aCompletionBlock];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                
                __strong typeof(*&wSelf) self = wSelf;
                [self handleAFFailedResponseWithDataTask:task error:error completedBlock:aCompletionBlock];
            }];
        }
            break;
        case XMNAFNetworkRequestGET:
        default:
        {
            dataTask = [self.sessionManager GET:urlString parameters:allParams progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                
                __strong typeof(*&wSelf) self = wSelf;
                [self handleAFSuccessResponseWithDataTask:task responseObject:responseObject completedBlock:aCompletionBlock];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                
                __strong typeof(*&wSelf) self = wSelf;
                [self handleAFFailedResponseWithDataTask:task error:error completedBlock:aCompletionBlock];
            }];
        }
            break;
    }

    dataTask.identifier = requestID;
    kXMNAFRequestIDDictionaryM[requestID] = dataTask;
    
    /** 添加打印信息 */
    [XMNAFLogger logRequestInfo:urlString
                         params:allParams
                         method:dataTask.currentRequest.HTTPMethod
                       dataTask:dataTask
                     forService:self];
    
    return requestID;
}

- (void)handleAFSuccessResponseWithDataTask:(NSURLSessionDataTask *)dataTask
                             responseObject:(id)responseObject
                             completedBlock:(void(^)(XMNAFNetworkResponse *response,NSError *error))completedBlock {
    
    
    
    XMNAFNetworkResponse *response = [[XMNAFNetworkResponse alloc] initWithResponse:responseObject error:nil];
    
    /** 添加结束日志输出 -> 增加了请求参数的输出 */
    [XMNAFLogger logResponseInfoWithResponse:(NSHTTPURLResponse *)dataTask.response
                              responseString:response.responseString
                                     request:dataTask.currentRequest
                                       error:nil
                                      params:dataTask.requestParams
                                  forService:self];

    
    completedBlock ? completedBlock(response, nil) : nil;
    if ([kXMNAFRequestIDDictionaryM.allValues containsObject:dataTask]) {
        
        [kXMNAFRequestIDDictionaryM removeObjectForKey:dataTask.identifier];
    }else {
        /** 如果请求不在kXMNAFRequestIDDictionaryM 中*/
        XMNLog(@"请求不在队列中");
    }
}


- (void)handleAFFailedResponseWithDataTask:(NSURLSessionDataTask *)dataTask
                                     error:(NSError *)error
                            completedBlock:(void(^)(XMNAFNetworkResponse *response,NSError *error))completedBlock {
    
    XMNAFNetworkResponse *response = [[XMNAFNetworkResponse alloc] initWithResponse:nil error:error];
    
    /** 添加结束日志输出 -> 增加了请求参数的输出 */
    [XMNAFLogger logResponseInfoWithResponse:(NSHTTPURLResponse *)dataTask.response
                              responseString:response.responseString
                                     request:dataTask.currentRequest
                                       error:error
                                      params:dataTask.requestParams
                                  forService:self];
    
    completedBlock ? completedBlock(response, error) : nil;
    if ([kXMNAFRequestIDDictionaryM.allValues containsObject:dataTask]) {
        
        [kXMNAFRequestIDDictionaryM removeObjectForKey:dataTask.identifier];
    }else {
        /** 如果请求不在kXMNAFRequestIDDictionaryM 中*/
        XMNLog(@"请求不在队列中");
    }
}

#pragma mark - Class Method

+ (NSString *)generateRequestKeyWithURLString:(NSString *)URLString
                                       params:(NSDictionary *)params {
    
    NSAssert(URLString, @"URLString 不能为空");
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:params];
    dict[@"URLString"] = URLString;
    NSString *md5Value = XMNAF_MD5([dict XMNAF_jsonString]);
    return md5Value;
}

+ (void)cancelTaskWithIdentifier:(NSString *)aID {
    
    if (!aID) {
        return;
    }
    NSURLSessionDataTask *dataTask = kXMNAFRequestIDDictionaryM[aID];
    [dataTask cancel];
    [kXMNAFRequestIDDictionaryM removeObjectForKey:aID];
}

+ (void)cancelTasksWithIdentifiers:(NSArray *)aIDs {
    
    for (NSString *aID in aIDs) {
        [[self class] cancelTaskWithIdentifier:aID];
    }
}

+ (NSURLSessionDataTask *)taskWithIdentifier:(NSString *)aID {
    
    return kXMNAFRequestIDDictionaryM[aID];
}

@end
