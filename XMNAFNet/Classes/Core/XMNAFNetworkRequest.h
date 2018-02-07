//
//  XMNAFNetworkRequest.h
//  XMNAFNetworkDemo
//
//  Created by XMFraker on 16/4/22.
//  Copyright © 2016年 XMFraker. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "XMNAFNetworkResponse.h"
#import "XMNAFNetworkRequestDataReformer.h"

/** XMNAFNetworkRequest状态 */
typedef NS_ENUM(NSUInteger, XMNAFNetworkRequestStatus) {
    /** 没有产生过API请求，这个是manager的默认状态。 */
    XMNAFNetworkRequestDefault = 0,
    /** API请求成功且返回数据正确，此时request的数据是可以直接拿来使用的。 */
    XMNAFNetworkRequestSuccess = 10000,
    /** 参数错误，此时manager不会调用API，因为参数验证是在调用API之前做的。 */
    XMNAFNetworkRequestParamsError,
    /** 网络不通。在调用API之前会判断一下当前网络是否通畅，这个也是在调用API之前验证的，和上面超时的状态是有区别的。 */
    XMNAFNetworkRequestUnreachableNetwork
};

/** XMNAFNetworkRequest的请求类型 */
typedef NS_ENUM (NSUInteger, XMNAFNetworkRequestMode) {
    /** GET请求 */
    XMNAFNetworkRequestGET = 0,
    /** POST请求 */
    XMNAFNetworkRequestPOST,
    /** PUT请求 */
    XMNAFNetworkRequestPUT,
    /** DELETE请求 */
    XMNAFNetworkRequestDELETE,
};

@class XMNAFNetworkRequest;
@protocol XMNAFNetworkRequestDelegate <NSObject>

@required
- (void)didSuccess:(XMNAFNetworkRequest * _Nonnull)aRequest;
- (void)didFailed:(XMNAFNetworkRequest * _Nonnull)aRequest;

@end

/** XMNAFNetworkRequest的拦截器 */
@protocol XMNAFNetworkRequestInterceptor <NSObject>

@optional

/**
 *  判断请求是否可以正常发起
 *
 *  @param aRequest 请求示例
 *  @param aParmas  请求的餐厨
 *
 *  @return 是否可以进行请求
 */
- (BOOL)request:(XMNAFNetworkRequest * _Nonnull)aRequest
shouldContinueWithParams:(id _Nullable)aParmas;


/**
 *  判断请求是否需要被缓存
 *  请求完成之后 回调
 *  @param aRequest 请求的示例
 *
 *  @return 是否被缓存
 */
- (BOOL)requestShouldCache:(XMNAFNetworkRequest * _Nonnull)aRequest;

@end


@protocol XMNAFNetworkRequestParamSource <NSObject>

- (NSDictionary * _Nullable)paramsForRequest:(XMNAFNetworkRequest * _Nonnull)request;

@end

/** 进行签名的方法 */
@protocol XMNAFNetworkRequestSignInterceptor <NSObject>

/**
 *  对请求URL,请求参数进行签名
 *
 *  @param URLString 请求路径
 *  @param params    请求参数
 *
 *  @return 签名之后返回的NSDictionary
 */
- (NSDictionary * _Nullable)signParamsWithURLString:(NSString * _Nonnull)URLString
                                             params:(NSDictionary * _Nonnull)params;

@end

@interface XMNAFNetworkRequest : NSObject


#pragma mark - Properties

/// ========================================
/// @name   相关代理
/// ========================================

/** request请求完成回调代理 */
@property (nonatomic, weak, nullable)   id<XMNAFNetworkRequestDelegate> delegate;
/** request请求拦截代理 */
@property (nonatomic, weak, nullable)   id<XMNAFNetworkRequestInterceptor> interceptor;
/** request请求参数代理 */
@property (nonatomic, weak, nullable)   id<XMNAFNetworkRequestParamSource> paramSource;
/** request签名请求 setSignInterceptor, shouldSign = YES*/
@property (nonatomic, weak, nullable)   id<XMNAFNetworkRequestSignInterceptor> signInterceptor;


/// ========================================
/// @name   只读方法
/// ========================================

/*
 baseRequest是不会去设置message的，派生的子类manager可能需要给controller提供错误信息。所以为了统一外部调用的入口，设置了这个变量。
 派生的子类需要通过extension来在保证message在对外只读的情况下使派生的request子类对message具有写权限。
 *
 */
@property (nonatomic, copy, readonly, nullable)   NSString *message;
@property (nonatomic, assign, readonly) XMNAFNetworkRequestStatus requestStatus;

/** 判断request 是否有网络请求 */
@property (nonatomic, assign, readonly) BOOL isReachable;

/** 判断request 是否正在请求 */
@property (nonatomic, assign, readonly) BOOL isLoading;

/** 请求方法,必须由子类重写 */
@property (nonatomic, copy, readonly, nonnull)   NSString *methodName;
/** 请求service的唯一标识  必须由子类重写 */
@property (nonatomic, copy, readonly, nonnull)   NSString *serviceIdentifier;

/** 请求类型, 默认XMNAFNetworkRequestGET请求 */
@property (nonatomic, assign, readonly) XMNAFNetworkRequestMode requestMode;

/** 请求的返回response结构 */
@property (nonatomic, strong, readonly, nullable) XMNAFNetworkResponse *response;

@property (strong, nonatomic, readonly, nullable) NSURLSessionDataTask *dataTask;

@property (copy, nonatomic, readonly, nullable)   NSDictionary *requestParams;

/// ========================================
/// @name   可读,可写方法
/// ========================================

/** 请求超时时间 */
@property (assign, nonatomic) NSTimeInterval timeoutInterval;

/** 缓存时间 默认kXMNAFNetowrkRequestCacheOutdateTimeSeconds*/
@property (nonatomic, assign) NSTimeInterval  cacheTime;

/** 是否缓存  默认 NO*/
@property (nonatomic, assign) BOOL shouldCache;

/** 是否需要签名 默认 NO */
@property (nonatomic, assign) BOOL shouldSign;

/** 请求完成后回调block */
@property (nonatomic, copy, nullable)   void(^completionBlock)(XMNAFNetworkRequest * _Nullable request, NSError * _Nullable error);

/** 请求所带有的额外信息,会在请求完成后 原封不动返回 */
@property (nonatomic, copy, nullable)   NSDictionary *extInfo;

#pragma mark - 提供给子类request实例使用的方法

/**
 *  开始加载数据
 *
 *  @return requestID
 */
- (NSString * _Nullable)loadData;

/**
 *  加载数据
 *
 *  @param params 加载数据 附带的参数
 *
 *  @return request请求ID
 */
- (NSString * _Nullable)loadDataWithParams:(NSDictionary * _Nullable)params;

- (NSString * _Nullable)loadDataWithPathParams:(NSDictionary * _Nullable)pathParams
                                        params:(NSDictionary * _Nullable)params;

/**
 *  清除数据记录
 *  errorMessage,requestStatus
 */
- (void)cleanData;

/**
 *  取消所有的相关请求
 */
- (void)cancelRequest;

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


/**
 *  重新格式化请求参数
 *  默认不格式化 直接返回
 *  @param params 请求参数
 *
 *  @return 格式化后的请求参数
 */
- (NSDictionary * _Nullable)reformParams:(NSDictionary * _Nullable)params;

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
