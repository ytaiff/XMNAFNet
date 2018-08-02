//
//  XMNAFNetworkRequestDataReformer.h
//  XMNAFNetworkDemo
//
//  Created by XMFraker on 16/9/13.
//  Copyright © 2016年 XMFraker. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class XMNAFNetworkRequest;
@protocol XMNAFNetworkRequestDataReformer <NSObject>

@required

/**
 格式化接口返回的数据

 @param request 具体的请求结果
 @param data    具体的返回数据 一般为request.responseObject
 @param error   具体的返回错误 一般为http.error
 @return 格式化后的数据
 */
- (id _Nullable)request:(XMNAFNetworkRequest *)request reformerOriginData:(id _Nullable)data error:(NSError * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
