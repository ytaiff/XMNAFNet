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


@class AFHTTPSessionManager;
@interface XMNAFService : NSObject

/** service mode */
@property (nonatomic, assign) XMNAFServiceMode serviceMode;

/// ========================================
/// @name   以下属性均需要通过XMNAFService子类重写
/// ========================================

/** api基本请求路径 */
@property (nonatomic, copy, readonly)   NSString *apiBaseURL;
/** api版本号 */
@property (nonatomic, copy, readonly)   NSString *apiVersion;

/** api的一些基本通用参数 */
@property (nonatomic, copy, readonly)   NSDictionary *commonParams;
/** api的一些通用headers */
@property (nonatomic, copy, readonly)   NSDictionary *commonHeaders;

/** 是否打印日志 */
@property (nonatomic, assign, readonly) BOOL shouldLog;

@property (nonatomic, strong, readonly) AFHTTPSessionManager *sessionManager;

+ (void)storeService:(XMNAFService *)aService ForIdentifier:(NSString *)aIdentifier;

+ (XMNAFService *)serviceWithIdentifier:(NSString *)aIdentifier;

@end


#pragma mark - RequestMethod
@class XMNAFNetworkResponse;
@interface XMNAFService (RequestMethod)

- (NSString *)requestWithMode:(int)aMode
                       params:(NSDictionary *)aParams
                   methodName:(NSString *)aMethodName
              completionBlock:(void(^)(XMNAFNetworkResponse *response,NSError *error))aCompletionBlock;

+ (NSString *)generateRequestKeyWithURLString:(NSString *)URLString
                                       params:(NSDictionary *)params;
+ (void)cancelTaskWithIdentifier:(NSString *)aID;
+ (void)cancelTasksWithIdentifiers:(NSArray *)aIDs;
+ (NSURLSessionDataTask *)taskWithIdentifier:(NSString *)aID;

@end

