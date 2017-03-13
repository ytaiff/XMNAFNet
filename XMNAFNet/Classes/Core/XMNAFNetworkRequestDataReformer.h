//
//  XMNAFNetworkRequestDataReformer.h
//  XMNAFNetworkDemo
//
//  Created by XMFraker on 16/9/13.
//  Copyright © 2016年 XMFraker. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  @brief 定义经过id<XMNAFNetworkRequestDataReformer> 处理过的Model
 */
@protocol XMNAFReformeredModel <NSObject>

/** 经过id<XMNAFNetworkRequestDataReformer>处理过的 result */
@property (strong, nonatomic, nullable) id result;

/** 具体的业务请求结果 */
@property (assign, nonatomic) NSInteger status;

/** message信息 */
@property (copy, nonatomic, nullable)   NSString *message;
/** 请求的错误 */
@property (strong, nonatomic, nullable) NSError *error;


@required
+ (id<XMNAFReformeredModel> __nonnull)reformeredModelWithOriginData:(id __nullable)aData
                                                               error:(NSError * __nullable)error;

@end

@class XMNAFNetworkRequest;
@protocol XMNAFNetworkRequestDataReformer <NSObject>

@required
- (id<XMNAFReformeredModel> _Nullable)request:(XMNAFNetworkRequest * _Nonnull)aRequest
                           reformerOriginData:(id _Nullable)aData
                                        error:(NSError * _Nullable)aError;
@end
