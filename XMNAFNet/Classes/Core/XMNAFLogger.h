//
//  XMNAFLog.h
//  XMNAFNetworkDemo
//
//  Created by XMFraker on 16/4/22.
//  Copyright © 2016年 XMFraker. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "XMNAFNetworkConfiguration.h"

@class XMNAFService;
@class XMNAFNetworkResponse;


@interface XMNAFLogger : NSObject

/**
 打印请求信息

 @param urlString 请求地址
 @param params 请求参数
 @param method 请求方法
 @param dataTask 请求对应的task
 @param service 请求处理的service
 */
+ (void)logRequestInfo:(NSString * _Nonnull)urlString
                params:(NSDictionary * _Nullable)params
                method:(NSString * _Nonnull)method
              dataTask:(NSURLSessionDataTask * _Nonnull)dataTask
            forService:(XMNAFService * _Nonnull)service;

/**
 *  打印返回Response信息

 *  @param aResponse       返回response
 *  @param aResponseString 返回的response字符串
 *  @param aRequest        返回对应的请求
 *  @param aError          返回错误信息
 *  @param aRequestParams  请求的参数
 *  @param aService        请求所使用的服务
 */
+ (void)logResponseInfoWithResponse:(NSHTTPURLResponse * _Nonnull)aResponse
                     responseString:(NSString * _Nullable)aResponseString
                            request:(NSURLRequest * _Nonnull)aRequest
                              error:(NSError * _Nullable)aError
                             params:(NSDictionary * _Nullable)aRequestParams
                         forService:(XMNAFService * _Nonnull)aService;

/**
 *  打印从cache中获取的Response
 *
 *  @param aResponse   返回response
 *  @param aMethodName 请求方法
 *  @param aService    对应的服务
 */
+ (void)logCacheResponseInfoWithResposne:(XMNAFNetworkResponse * _Nonnull)aResponse
                              methodName:(NSString * _Nullable)aMethodName
                              forService:(XMNAFService * _Nonnull)aService;

@end
