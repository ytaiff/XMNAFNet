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

#import <AFNetworking/AFNetworking.h>

#import <XMNAFNet/XMNAFService.h>
#import <XMNAFNet/XMNAFNetworkRequest.h>
#import <XMNAFNet/XMNAFNetworkResponse.h>
#import <XMNAFNet/XMNAFNetworkConfiguration.h>
#import <XMNAFNet/NSError+XMNAFMessage.h>

#else

#import <AFNetworking/AFNetworking.h>

#import "XMNAFService.h"
#import "XMNAFNetworkRequest.h"
#import "XMNAFNetworkResponse.h"
#import "XMNAFNetworkConfiguration.h"
#import "NSError+XMNAFMessage.h"

#endif

#endif /* XMNAFNet_h */
