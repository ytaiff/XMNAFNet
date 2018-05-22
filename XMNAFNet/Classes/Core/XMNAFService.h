//
//  XMNAFService.h
//  XMNAFNetworkDemo
//
//  Created by XMFraker on 16/4/22.
//  Copyright © 2016年 XMFraker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

/** XMNAFService使用的服务类型 */
typedef NS_ENUM(NSUInteger, XMNAFServiceMode) {
    /** 未知服务器 */
    XMNAFServiceUnknown = 0,
    /** 自定义服务器 */
    XMNAFServiceCustom,
    /** 开发环境内网服务器 */
    XMNAFServiceDevIn,
    /** 开发环境外网服务器 */
    XMNAFServiceDevOut,
    /** UAT测试预发服务器 */
    XMNAFServiceUAT,
    /** 正式发布服务器 */
    XMNAFServiceDis
};

typedef NS_ENUM(NSUInteger, XMNAFRequestSerializerType) {
    XMNAFRequestSerializerHTTP = 0,
    XMNAFRequestSerializerJSON
};

typedef NS_ENUM(NSUInteger, XMNAFResponseSerializerType) {
    XMNAFResponseSerializerHTTP = 0,
    XMNAFResponseSerializerJSON,
    XMNAFResponseSerializerXML,
};

NS_ASSUME_NONNULL_BEGIN

@class YYCache;
@class AFSecurityPolicy;
@class XMNAFNetworkRequest;
@class AFHTTPSessionManager;
@interface XMNAFService : NSObject

/** service mode */
@property (nonatomic, assign) XMNAFServiceMode serviceMode;
@property (assign, nonatomic) XMNAFRequestSerializerType requestSerializerType;
@property (assign, nonatomic) XMNAFResponseSerializerType responseSerializerType;
/** api HTTPS 请求证书策略配置 */
@property (strong, nonatomic, nullable) AFSecurityPolicy *securityPolicy;

/// ========================================

/** api基本请求路径 */
@property (nonatomic, copy, readonly, nullable)   NSString *apiBaseURL;
/** api版本号 */
@property (nonatomic, copy, readonly, nullable)   NSString *apiVersion;
/** api的一些基本通用参数 */
@property (nonatomic, copy, readonly, nullable)   NSDictionary *commonParams;
/** api的一些通用headers */
@property (nonatomic, copy, readonly, nullable)   NSDictionary *commonHeaders;
/** api请求的缓存地址 默认 @"~/documents/com.xmfraker.xmafnetwork/caches/{self.apiBaseURL.host}" */
@property (copy, nonatomic, readonly)   NSString *cachePath;
/** 请求处理的相关队列 默认自定义串行队列 */
@property (assign, nonatomic, readonly) dispatch_queue_t serviceQueue;

/** 初始化方法 */
- (instancetype)initWithConfiguration:(nullable NSURLSessionConfiguration *)configuration NS_DESIGNATED_INITIALIZER;
/** 执行一个线程安全的handler回调 */
- (void)performThreadSafeHandler:(dispatch_block_t)handler;

@end

/** XMNAFService的相关存储操作, 线程安全 */
@interface XMNAFService (ManageService)

/** 存储一个service, service为nil时尝试清除已经缓存的 */
+ (void)storeService:(nullable XMNAFService *)service forIdentifier:(NSString *)identifier;

/** 获取所有已经配置是XMNAFService */
+ (nullable NSArray <XMNAFService *> *)storedServices;

/** 获取对应identifier的AFService  */
+ (nullable XMNAFService *)serviceWithIdentifier:(NSString *)identifier;

/** 针对已经存储的service配置其serviceMode */
+ (void)configServiceModeForStoredServices:(XMNAFServiceMode)mode;

@end

NS_ASSUME_NONNULL_END
