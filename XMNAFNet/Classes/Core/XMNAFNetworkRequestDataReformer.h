//
//  XMNAFNetworkRequestDataReformer.h
//  XMNAFNetworkDemo
//
//  Created by XMFraker on 16/9/13.
//  Copyright © 2016年 XMFraker. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

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
+ (id<XMNAFReformeredModel>)reformeredModelWithOriginData:(id __nullable)data error:(NSError * __nullable)error;

@end

@class XMNAFNetworkRequest;
@protocol XMNAFNetworkRequestDataReformer <NSObject>

@required
- (id<XMNAFReformeredModel> _Nullable)request:(XMNAFNetworkRequest *)request
                           reformerOriginData:(id _Nullable)data
                                        error:(NSError * _Nullable)error;
@end

NS_ASSUME_NONNULL_END
