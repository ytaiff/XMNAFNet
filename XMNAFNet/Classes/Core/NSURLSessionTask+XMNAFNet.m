//
//  NSURLSessionTask+XMNAFNet.m
//  LCWelfareMall
//
//  Created by XMFraker on 16/9/1.
//  Copyright © 2016年 XMFraker. All rights reserved.
//

#import "NSURLSessionTask+XMNAFNet.h"
#import <objc/runtime.h>

@implementation NSURLSessionTask (XMNAFNet)

#pragma mark - Setter

- (void)setIdentifier:(NSString *)identifier {
    
    __weak typeof(*&self) wSelf = self;
    dispatch_barrier_async(dispatch_get_global_queue(0, 0), ^{
        __strong typeof(*&wSelf) self = wSelf;
        objc_setAssociatedObject(self, @selector(identifier), identifier, OBJC_ASSOCIATION_COPY);
    });
}

- (void)setRequestParams:(NSDictionary *)requestParams {
    
    __weak typeof(*&self) wSelf = self;
    dispatch_barrier_async(dispatch_get_global_queue(0, 0), ^{
        __strong typeof(*&wSelf) self = wSelf;
        objc_setAssociatedObject(self, @selector(requestParams), requestParams, OBJC_ASSOCIATION_COPY);
    });
}

#pragma mark - Getter

- (NSDictionary *)requestParams {
    
    __block NSDictionary *params;
    dispatch_sync(dispatch_get_global_queue(0, 0), ^{
        params = objc_getAssociatedObject(self, _cmd);
    });
    return params;
}

- (NSString *)identifier {
    
    __block NSString *identifier;
    dispatch_sync(dispatch_get_global_queue(0, 0), ^{
        identifier = objc_getAssociatedObject(self, _cmd);
    });
    return identifier;

}

@end
