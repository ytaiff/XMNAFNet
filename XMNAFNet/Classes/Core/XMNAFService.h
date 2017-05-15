//
//  XMNAFService.h
//  XMNAFNetworkDemo
//
//  Created by XMFraker on 16/4/22.
//  Copyright © 2016年 XMFraker. All rights reserved.
//

#import <Foundation/Foundation.h>

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

NS_ASSUME_NONNULL_BEGIN

@class AFHTTPSessionManager;
@interface XMNAFService : NSObject

/** service mode */
@property (nonatomic, assign) XMNAFServiceMode serviceMode;

/// ========================================
/// @name   以下属性均需要通过XMNAFService子类重写
/// ========================================

/** api基本请求路径 */
@property (nonatomic, copy, readonly, nullable)   NSString *apiBaseURL;
/** api版本号 */
@property (nonatomic, copy, readonly, nullable)   NSString *apiVersion;

/** api的一些基本通用参数 */
@property (nonatomic, copy, readonly, nullable)   NSDictionary *commonParams;
/** api的一些通用headers */
@property (nonatomic, copy, readonly, nullable)   NSDictionary *commonHeaders;

/** 是否打印日志 */
@property (nonatomic, assign, readonly) BOOL shouldLog;

@property (nonatomic, strong, readonly) AFHTTPSessionManager *sessionManager;

/**
 保存一个service

 @param service            需要保存的service
 @param identifier         需要保存的service对应的identifier
 */
+ (void)storeService:(XMNAFService *)service forIdentifier:(NSString *)identifier;


/**
 获取所有已经配置是AFService

 @return NSArray or nil
 */
+ (nullable NSArray <XMNAFService *> *)storedServices;


/**
 获取对应identifier的AFService

 @param identifier 对应的identifier
 @return XMNAFService or nil
 */
+ (nullable XMNAFService *)serviceWithIdentifier:(NSString *)identifier;

@end


#pragma mark - RequestMethod
@class XMNAFNetworkResponse;
@interface XMNAFService (RequestMethod)

- (NSString *)requestWithMode:(int)aMode
                       params:(nullable NSDictionary *)aParams
                   methodName:(NSString *)aMethodName
              completionBlock:(void(^)(XMNAFNetworkResponse *response,NSError *error))aCompletionBlock;

+ (NSString *)generateRequestKeyWithURLString:(NSString *)URLString
                                       params:(nullable NSDictionary *)params;
+ (void)cancelTaskWithIdentifier:(NSString *)aID;
+ (void)cancelTasksWithIdentifiers:(NSArray *)aIDs;
+ (nullable NSURLSessionDataTask *)taskWithIdentifier:(NSString *)aID;

@end

NS_ASSUME_NONNULL_END
