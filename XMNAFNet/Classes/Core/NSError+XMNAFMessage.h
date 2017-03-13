//
//  NSError+XMNAFMessage.h
//  XMNAFNetworkDemo
//
//  Created by XMFraker on 16/9/13.
//  Copyright © 2016年 XMFraker. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSError (XMNAFMessage)

/** 从NSError对象中获取错误信息
 *  优先获取error.userInfo{@"message"} 字段
 **/
@property (nonatomic, copy, readonly)   NSString *errorMessage;

@end
