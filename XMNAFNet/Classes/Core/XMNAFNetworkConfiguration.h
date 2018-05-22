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
FOUNDATION_EXTERN NSError * _Nonnull kXMNAFNetworkError(NSInteger code, NSString * __nullable message);
FOUNDATION_EXPORT NSString *__nonnull const kXMNAFNetworkErrorDomain;

#endif /* XMNAFNetworkConfiguration_h */
