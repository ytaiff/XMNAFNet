//
//  NSError+XMNAFMessage.m
//  XMNAFNetworkDemo
//
//  Created by XMFraker on 16/9/13.
//  Copyright © 2016年 XMFraker. All rights reserved.
//

#import "NSError+XMNAFMessage.h"

@implementation NSError (XMNAFMessage)

- (NSString *)errorMessage {

    /** 1. 过滤掉用户取消的请求 */
    if (self.code == NSURLErrorCancelled) {
        
        return nil;
    }
    
    /** 2. 网络请求超时 */
    if (self.code == NSURLErrorTimedOut) {
        return @"网络请求超时";
    }

    /** 3. 从userInfo中解析具体错误信息 */
    if (self.userInfo && [self.userInfo isKindOfClass:[NSDictionary class]]) {
        
        for (NSString *key in [NSError messageKeys]) {
            
            NSString *message = [self messageWithKey:key];
            if (message && message.length) {
                return message;
            }
        }
    }
    
    return @"网络请求失败";
}

- (NSString *)messageWithKey:(NSString *)key {
    
    NSString *message = [self.userInfo objectForKey:key];
    
    /** message不存在 或者 message 是NSNull */
    if (!message || [message isKindOfClass:[NSNull class]]) {
        return @"网络请求失败";
    }
    
    if ([message isKindOfClass:[NSString class]] && message.length > 0 && ![message isEqualToString:@"null"] && ![message isEqualToString:@"<null>"]) {
        return message;
    }
    return nil;
}

+ (NSArray<NSString *> *)messageKeys {
    
    return @[@"message",@"msg"];
}

@end
