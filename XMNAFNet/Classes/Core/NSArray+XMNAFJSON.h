//
//  NSArray+XMNAFJSON.h
//  XMNAFNetworkDemo
//
//  Created by XMFraker on 16/4/22.
//  Copyright © 2016年 XMFraker. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (XMNAFJSON)

/**
 *  将NSArray实例中元素拼接成字符串
 *  拼接格式 key1=value1&key2=value2...
 *  @return 拼接的字符串
 */
- (NSString * _Nullable)XMNAF_paramsString;

/**
 *  使用NSJSONSerialization序列化NSArray实例 成为json字符串
 *
 *  @return json格式字符串
 */
- (NSString * _Nullable)XMNAF_jsonString;

@end
