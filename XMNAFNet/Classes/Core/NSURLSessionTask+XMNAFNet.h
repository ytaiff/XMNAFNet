//
//  NSURLSessionTask+XMNAFNet.h
//  LCWelfareMall
//
//  Created by XMFraker on 16/9/1.
//  Copyright © 2016年 XMFraker. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLSessionTask (XMNAFNet)

/** dataTask 的唯一标识 */
@property (copy, nonatomic)   NSString *identifier;

/** 请求时用户手动传入的参数 */
@property (copy, nonatomic) NSDictionary *requestParams;

@end
