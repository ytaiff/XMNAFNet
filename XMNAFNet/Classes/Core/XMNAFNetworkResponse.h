//
//  XMNAFNetworkResponse.h
//  XMNAFNetworkDemo
//
//  Created by XMFraker on 16/4/22.
//  Copyright © 2016年 XMFraker. All rights reserved.
//

#import <Foundation/Foundation.h>

/** XMNAFNetworkResponse返回错误类型,作为底层封装,只考虑超时,无网络连接两种错误情况 */
typedef NS_ENUM(NSUInteger, XMNAFNetworkResponseStatus) {
    /** 返回成功 */
    XMNAFNetworkResponseSuccess = 10000,
    /** 返回超时,失败 */
    XMNAFNetworkResponseTimeoutError = 11000,
    /** 所有400+ 报错以及 解析出错,均认为是 网络链接错误,具体业务请求错误 在reformer中去拆分处理 */
    XMNAFNetworkResponseNetworkError = 11001,
};

@interface XMNAFNetworkResponse : NSObject

@property (nonatomic, copy, readonly)   id responseObject;
@property (nonatomic, copy, readonly)   NSData *responseData;
@property (nonatomic, copy, readonly)   NSString *responseString;

@property (nonatomic, assign, readonly) XMNAFNetworkResponseStatus responseStatus;

@property (nonatomic, assign, readonly) BOOL fromCache;


/**
 *  生成一个XMAFURLResponse实例 默认isCache为NO
 *
 *  @param response  传入的response返回数据,可能是NSData 也可能是NSDictionary
 *  @param error     请求的错误 可能为nil
 *
 *  @return 一个XMAFURLResponse 实例
 */
- (instancetype)initWithResponse:(id)response
                           error:(NSError *)error;

/**
 *  生成一个XMAFURLResponse实例,默认isCache为YES
 *
 *  @param data 传入的数据
 *
 *  @return 一个XMAFURLResponse 实例
 */
- (instancetype)initWithData:(NSData *)data;

@end
