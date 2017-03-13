//
//  NSDictionary+XMNAFJSON.h
//  XMNAFNetworkDemo
//
//  Created by XMFraker on 16/4/22.
//  Copyright © 2016年 XMFraker. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (XMNAFJSON)

/**
 *  使用NSJSONSerialization序列化NSDictionary实例 成为json字符串
 *
 *  @return json格式字符串
 */
- (NSString * _Nullable)XMNAF_jsonString;

/**
 *  将NSDictionary=>NSArray=>NSString
 *
 *  @param isForSignature 是否转义特殊字符串
 *
 *  @return 转以后的字符串
 */
- (NSString * _Nullable)XMNAF_urlParamsStringSignature:(BOOL)isForSignature;

/**
 *  转义NSDictionary=>NSArray
 *
 *  @param isForSignature 是否需要转义特殊字符串
 *
 *  @return 转以后的NSArray
 */
- (NSArray * _Nullable)XMNAF_transformedUrlParamsArraySignature:(BOOL)isForSignature;

@end
