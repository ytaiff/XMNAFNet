//
//  XMNAFNetworkRequest.h
//  XMNAFNetworkDemo
//
//  Created by XMFraker on 16/4/22.
//  Copyright © 2016年 XMFraker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XMNAFNet/XMNAFNetworkRequestDataReformer.h>

/** XMNAFNetworkRequest的请求类型 */
typedef NS_ENUM (NSUInteger, XMNAFNetworkRequestMode) {
    /** GET请求 */
    XMNAFNetworkRequestGET = 0,
    /** POST请求 */
    XMNAFNetworkRequestPOST,
    /** HEAD请求 */
    XMNAFNetworkRequestHEAD,
    /** PUT请求 */
    XMNAFNetworkRequestPUT,
    /** DELETE请求 */
    XMNAFNetworkRequestDELETE,
    /** PATCH请求 */
    XMNAFNetworkRequestPATCH
};

@class XMNAFService;
@class XMNAFNetworkRequest;
@protocol XMNAFNetworkRequestDelegate <NSObject>

@required
- (void)requestDidCompleted:(XMNAFNetworkRequest * _Nonnull)request;

@end

/** XMNAFNetworkRequest的拦截器 */
@protocol XMNAFNetworkRequestInterceptor <NSObject>

@optional

/**
 *  判断请求是否可以正常发起
 *
 *  @param request 请求示例
 *  @param params  请求的餐厨
 *
 *  @return 是否可以进行请求
 */
- (BOOL)request:(XMNAFNetworkRequest * _Nonnull)request shouldContinueWithParams:(id _Nullable)params;

/**
 *  判断请求是否需要被缓存
 *  请求完成之后 回调
 *  @param request 请求的示例
 *
 *  @return 是否被缓存
 */
- (BOOL)requestShouldCache:(XMNAFNetworkRequest * _Nonnull)request;

@end


@protocol XMNAFNetworkRequestParamSource <NSObject>

- (NSDictionary * _Nullable)paramsForRequest:(XMNAFNetworkRequest * _Nonnull)request;

@end

@protocol XMNAFNetworkResponseInterceptor <NSObject>
@optional

/**
 请求完成后, 根据请求结果用户可以自己决定是否缓存当前request请求结果
 可以根据业务结果选择是否缓存请求结果
 
 @param request 具体请求对象
 @return YES or NO
 */
- (BOOL)requestShouldCacheResponse:(nonnull __kindof XMNAFNetworkRequest *)request;

@required

/**
 对request.responseObject进行重新赋值操作
 可以自行处理解析responseObject等操作
 
 @param request NNRequest对象
 @param error   处理报错, 可能是网络请求的错误信息, 或者缓存相关错误
 @return 解析后的responseObject or nil
 */
- (nullable id)responseObjectForRequest:(nonnull __kindof XMNAFNetworkRequest *)request error:(nullable NSError *)error;

@end

@protocol AFMultipartFormData;

typedef void(^XMNAFNetworkCompletionHandler)(__kindof XMNAFNetworkRequest *__nonnull request, NSError *__nullable error);
typedef void(^XMNAFNetworkConstructingHandler)(id<AFMultipartFormData> __nonnull formData);
typedef void(^XMNAFNetworkProgressHandler)(NSProgress *__nullable progress);

@interface XMNAFNetworkRequest : NSObject


#pragma mark - Properties

/// ========================================
/// @name   相关代理
/// ========================================

/** request请求完成回调代理 */
@property (atomic, weak, nullable)   id<XMNAFNetworkRequestDelegate> delegate;
/** request请求拦截代理 */
@property (atomic, weak, nullable)   id<XMNAFNetworkRequestInterceptor> interceptor;
/** request请求参数代理 */
@property (atomic, weak, nullable)   id<XMNAFNetworkRequestParamSource> paramSource;
/** request相关返回请求的代理 */
@property (atomic, weak, nullable)   id<XMNAFNetworkResponseInterceptor> responseInterceptor;

/// ========================================
/// @name   只读方法
/// ========================================

/** api 请求的请求路径 */
@property (copy, nonatomic, readonly, nullable)   NSString *methodName;
/** api 请求的管理service对应的identifier */
@property (copy, nonatomic, readonly, nullable)   NSString *serviceIdentifier;
/** api 请求的请求类型 默认GET */
@property (assign, nonatomic, readonly) XMNAFNetworkRequestMode requestMode;
/** api 请求的datatask实例 */
@property (strong, nonatomic, readonly, nullable) NSURLSessionDataTask *datatask;
/** api 请求的请求参数 */
@property (copy, nonatomic, readonly, nullable)   NSDictionary *requestParams;
/** api 请求的错误信息 */
@property (strong, nonatomic, readonly, nullable) NSError *error;
/** api 请求状态, 判断当前网络有网络链接 包含WiFi,蜂窝网络 */
@property (nonatomic, assign, readonly) BOOL isReachable;
/** api 请求状态, 是否正在请求中 */
@property (assign, nonatomic, readonly) BOOL isExecuting;
/** api 请求状态, 是否是被取消的请求 */
@property (assign, nonatomic, readonly) BOOL isCancelled;

/// ========================================
/// @name   可读,可写方法
/// ========================================

/** api 请求的优先级 默认 NSURLSessionTaskPriorityDefault */
@property (assign, atomic) float priority;
/** api 请求相关头部授权信息 默认 nil */
@property (copy, atomic, nullable)   NSArray<NSString *> *authorizationHeaderFields;
/** api 请求是否允许使用蜂窝网络, 默认YES */
@property (assign, atomic, getter=isAllowsCellularAccess) BOOL allowsCellularAccess;
/** api 请求回调是否忽略被取消的请求, 被取消的请求不会触发completionBlock 及 delegate相关方法 默认YES */
@property (assign, atomic) BOOL ignoredCancelledRequest;
/** api 请求的超时时间 默认10s */
@property (assign, atomic) NSTimeInterval timeoutInterval;
/** api 请求进度回调handler */
@property (copy, atomic, nullable)   XMNAFNetworkProgressHandler progressHandler;
/** api 请求完成后回调handler */
@property (copy, atomic, nullable)   XMNAFNetworkCompletionHandler completionBlock;
/** api 请求构造体handler */
@property (copy, atomic, nullable)   XMNAFNetworkConstructingHandler constuctingHandler;
/** api 请求带有的额外信息 请求过程中不做任何处理 */
@property (copy, atomic, nullable)   NSDictionary *userInfo;
/** api 请求的下载存储路径 默认 com.xmfraker.xmafnetwork/download */
@property (copy, atomic, nullable)   NSString *downloadPath;

#pragma mark - 提供给子类request实例使用的方法

/**
 开始请求
 @warnings 推荐后续使用startRequest
 */
- (void)loadData;
- (void)loadDataWithParams:(nullable NSDictionary *)params;
- (void)loadDataWithPathParams:(nullable NSDictionary *)pathParams params:(nullable NSDictionary *)params;
/** 开始请求 */
- (void)startRequest;
- (void)startRequestWithParams:(nullable NSDictionary *)params;
- (void)startRequestWithParams:(nullable NSDictionary *)params
             completionHandler:(nullable XMNAFNetworkCompletionHandler)completionHandler;

/** 取消相关请求 */
- (void)cancelRequest;
/** 暂停相关请求 */
- (void)suspendRequest;

/**
 *  格式化获取的数据
 *
 *  @param reformer 数据格式化工厂对象
 *
 *  @return 格式化后的数据
 */
- (_Nullable id)fetchDataWithReformer:(_Nullable id<XMNAFNetworkRequestDataReformer>)reformer;
- (_Nullable id)fetchDataWithReformer:(_Nullable id<XMNAFNetworkRequestDataReformer>)reformer
                                error:(NSError * __nullable)error;

#pragma mark - Life Cycle

/**
 *  初始化方法
 *
 *  @param identifier  service标识
 *  @param methodName  请求方法名
 *  @param requestMode 请求类型
 *
 *  @return XMNAFNetworkRequest实例 or nil
 */
- (instancetype _Nullable)initWithServiceIdentifier:(NSString * _Nonnull)identifier
                                         methodName:(NSString * _Nonnull)methodName
                                        requestMode:(XMNAFNetworkRequestMode)requestMode;

@end

@interface XMNAFNetworkRequest (Response)
/** 此responseObject 可能是经过responseInterceptor 处理过的responseObject **/
@property (strong, nonatomic, readonly, nullable) id responseObject;
/** api 请求返回的Data 数据 */
@property (copy, nonatomic, readonly, nullable)   NSData *responseData;
/** api 请求返回的字符串数组 */
@property (copy, nonatomic, readonly, nullable)   NSString *responseString;
/** api 请求返回的JSON数据 */
@property (strong, nonatomic, readonly, nullable) id responseJSONObject;
/** api 请求的返回错误信息 */
@property (strong, nonatomic, readonly, nullable) NSError *error;
/** api 请求结果是否是从缓存中获取的结果 */
@property (assign, nonatomic, readonly, getter=isFromCache) BOOL fromCache;
@end

@interface XMNAFNetworkRequest (Convenient)

/** datatask.response.statusCode 快捷方式 */
@property (assign, nonatomic, readonly)           NSInteger responseCode;
/** datatask.currentRequest 快捷方式 */
@property (strong, nonatomic, readonly, nullable) NSURLRequest *currentRequest;
/** datatask.originalRequest 快捷方式 */
@property (strong, nonatomic, readonly, nullable) NSURLRequest *originalRequest;
/** datatask.response 快捷方式 */
@property (strong, nonatomic, readonly, nullable) NSHTTPURLResponse *response;
/** response.allHeaderFields 快捷方式 */
@property (copy, nonatomic, readonly, nullable)   NSDictionary *responseHeaders;

@end
