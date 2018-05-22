//  XMNAFNetworkPrivate.h
//  Pods
//
//  Created by  XMFraker on 2018/5/21
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      XMNAFNetworkPrivate
//  @version    <#class version#>
//  @abstract   <#class description#>


#import <XMNAFNet/XMNAFService.h>
#import <XMNAFNet/XMNAFNetworkRequest.h>

#if __has_include(<XMNAFNet/XMNAFNetworkRequest+Cache.h>)
    #import <YYModel/YYModel.h>
    #import <YYCache/YYCache.h>
    #import <XMNAFNet/XMNAFCacheMeta.h>
    #import <XMNAFNet/XMNAFNetworkRequest+Cache.h>
    #ifndef kXMNAFCacheAvailable
        #define kXMNAFCacheAvailable 1
    #endif
#endif

#if __has_include(<XMNAFNet/XMNAFReachabilityManager.h>)
    #import <XMNAFNet/XMNAFReachabilityManager.h>
    #import <XMNAFNet/XMNAFNetworkUploadManager.h>
    #import <XMNAFNet/XMNAFNetworkDownloadManager.h>
    #ifndef kXMNAFReachablityAvailable
        #define kXMNAFReachablityAvailable 1
    #endif
#endif


NS_ASSUME_NONNULL_BEGIN
@interface XMNAFNetworkRequest ()

/** 此responseObject 可能是经过responseInterceptor 处理过的responseObject **/
@property (strong, nonatomic, nullable) id responseObject;
/** api 请求返回的Data 数据 */
@property (copy, nonatomic, nullable)   NSData *responseData;
/** api 请求返回的字符串数组 */
@property (copy, nonatomic, nullable)   NSString *responseString;
/** api 请求返回的JSON数据 */
@property (strong, nonatomic, nullable) id responseJSONObject;
/** api 请求的返回错误信息 */
@property (strong, nonatomic, nullable) NSError *error;
/** api 请求结果是否是从缓存中获取的结果 */
@property (assign, nonatomic) BOOL fromCache;
/** api 请求的相关参数 */
@property (copy, nonatomic, nullable)  NSDictionary *requestParams;
/** api 请求对应的datatask */
@property (strong, nonatomic, nonnull) NSURLSessionDataTask *datatask;
/** api 请求的管理类 */
@property (strong, nonatomic, nonnull) XMNAFService *service;

- (void)requestDidCompletedWithError:(nullable NSError *)error;
@end

@interface XMNAFService ()

#if kXMNAFCacheAvailable
/** api请求的缓存管理器 */
@property (strong, nonatomic, readonly) YYCache *cache;
#endif

@property (strong, nonatomic, readonly) NSMutableDictionary<NSNumber *, XMNAFNetworkRequest *> *requestMappers;
@property (strong, nonatomic, readonly) AFHTTPSessionManager *sessionManager;
@end

@interface XMNAFService (Private)

/** 开始一个request */
- (void)startRequest:(__kindof XMNAFNetworkRequest *)request;

- (NSString *)cacheKeyWithRequest:(__kindof XMNAFNetworkRequest *)request;
- (NSString *)absoluteURLStringWithRequest:(__kindof XMNAFNetworkRequest *)request
                                    params:(NSDictionary *__nullable *__nullable)params;

@end

NS_ASSUME_NONNULL_END
