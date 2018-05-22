//
//  XMNAFNet.h
//  Pods
//
//  Created by XMFraker on 17/3/13.
//
//

#ifndef XMNAFNet_h
#define XMNAFNet_h


#import <UIKit/UIKit.h>

//! Project version number for XMNAFNet.
FOUNDATION_EXPORT double XMNAFNetVersionNumber;

//! Project version string for XMNAFNet.
FOUNDATION_EXPORT const unsigned char XMNAFNetVersionString[];

#if __has_include(<XMNAFNet/XMNAFNet.h>)
    #import <XMNAFNet/XMNAFService.h>
    #import <XMNAFNet/XMNAFNetworkRequest.h>
    #import <XMNAFNet/XMNAFNetworkConfiguration.h>
    #import <XMNAFNet/NSError+XMNAFMessage.h>
#endif

#if __has_include(<XMNAFNet/XMNAFReachabilityManager.h>)
    #import <XMNAFNet/XMNAFReachabilityManager.h>
    #import <XMNAFNet/XMNAFNetworkUploadManager.h>
    #import <XMNAFNet/XMNAFNetworkDownloadManager.h>
    #ifndef kXMNAFReachablityAvailable
        #define kXMNAFReachablityAvailable 1
    #endif
#endif

#if __has_include(<XMNAFNet/XMNAFNetworkRequest+Cache.h>)
    #import <YYModel/YYModel.h>
    #import <YYCache/YYCache.h>
    #import <XMNAFNet/XMNAFNetworkRequest+Cache.h>
    #ifndef kXMNAFCacheAvailable
        #define kXMNAFCacheAvailable 1
    #endif
#endif

#import <AFNetworking/AFNetworking.h>

#endif /* XMNAFNet_h */
