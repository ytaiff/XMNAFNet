//
//  XMNAFNetworkConfiguration.h
//  XMNAFNetworkDemo
//
//  Created by XMFraker on 16/4/22.
//  Copyright © 2016年 XMFraker. All rights reserved.
//

#ifndef XMNAFNetworkConfiguration_h
#define XMNAFNetworkConfiguration_h

#if DEBUG
    #ifndef XMNLog
        #define XMNLog(FORMAT,...) fprintf(stderr,"==============================================================\n=           com.XMFraker.XMNLog                              =\n==============================================================\n\n\n%s %d :\n       %s\n\n\n==============================================================\n=           com.XMFraker.XMNLog End                          =\n==============================================================\n\n\n\n",[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
    #endif
#else
    #ifndef XMNLog
        #define XMNLog(FORMAT,...);
    #endif
#endif

#define XMNLocalizedString(key, comment) \
[[NSBundle bundleWithIdentifier:@"com.XMFraker.XMNAFNetworkFramework"] localizedStringForKey:(key) value:@"" table:nil]

FOUNDATION_EXTERN NSString * _Nullable XMNAF_MD5(NSString * _Nonnull str);

/** 默认请求最长时间 */
static NSTimeInterval kXMNAFNetworkTimeoutSeconds = 20.0f;

/** 默认Request是否缓存 */
static BOOL kXMNAFNetworkRequestShouldCache = NO;
/** 默认Request缓存时长 */
static NSTimeInterval kXMNAFNetowrkRequestCacheOutdateTimeSeconds = 300;
/** 最大缓存Request最大数量 */
static NSUInteger kXMNAFNetworkCacheCountLimit = 1000; // 最多1000条cache

// 在调用成功之后的params字典里面，用这个key可以取出requestID
FOUNDATION_EXTERN NSString * _Nonnull const kXMNAFNetworkRequestIDKey;

FOUNDATION_EXTERN NSString * _Nonnull const kXMNAFNetworkErrorDomain;

#endif /* XMNAFNetworkConfiguration_h */
