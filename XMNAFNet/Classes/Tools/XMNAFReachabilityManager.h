//
//  XMNAFReachabilityManager.h
//  XMNAFNetworkDemo
//
//  Created by XMFraker on 16/7/13.
//  Copyright © 2016年 XMFraker. All rights reserved.
//

#import <Foundation/Foundation.h>

/** 当前网络状态 */
typedef NS_ENUM(NSUInteger, XMNAFReachablityStatus) {
    /** 未知网络状态 */
    XMNAFReachablityStatusUnknown = 0,
    /** 移动网络 */
    XMNAFReachablityStatusWWAN,
    /** wifi */
    XMNAFReachablityStatusWifi,
    /** 2G网络 */
    XMNAFReachablityStatus2G = 100,
    /** 3G网络 */
    XMNAFReachablityStatus3G,
    /** 4G网络 */
    XMNAFReachablityStatus4G
};

FOUNDATION_EXPORT NSString *kXMNAFReachabilityStatusChangedNotification;
FOUNDATION_EXPORT NSString *kXMNAFReachabilityStatusKey;
FOUNDATION_EXPORT NSString *kXMNAFReachabilityStatusStringKey;

typedef void(^XMNAFReachabilityStatusChangedHandler)(XMNAFReachablityStatus status);

@protocol XMNAFReachabilityDelegate <NSObject>
- (void)statusDidChanged:(XMNAFReachablityStatus)status;
@end

@interface XMNAFReachabilityManager : NSObject

/** 检测的URL */
@property (nonatomic, strong) NSURL *monitorURL;
/** 是否正在监听 */
@property (nonatomic,assign, readonly, getter=isMonitoring) BOOL monitoring;

@property (nonatomic, assign, readonly) XMNAFReachablityStatus status;
@property (nonatomic, assign, readonly) NSString *statusString;

@property (nonatomic, assign, readonly, getter=isWifiEnable) BOOL wifiEnable;
@property (nonatomic, assign, readonly, getter=isNetworkEnable) BOOL networkEnable;
@property (nonatomic, assign, readonly, getter=isHighSpeedNetwork) BOOL highSpeedNetwork;


@property (nonatomic, weak)   id<XMNAFReachabilityDelegate> delegate;
@property (nonatomic, copy)   XMNAFReachabilityStatusChangedHandler statusDidChangedBlock;

- (void)startMonitoring;
- (void)startMonitoringWithURL:(NSURL *)URL;
- (void)startMonitoringWithURL:(NSURL *)URL delegate:(id<XMNAFReachabilityDelegate>)delegate;
- (void)startMonitoringWithURL:(NSURL *)URL handler:(XMNAFReachabilityStatusChangedHandler)handler;

- (void)stopMonitoring;

#pragma mark - Class

+ (instancetype)sharedManager;

/**
 *  @brief wifi是否可用
 *
 */
+(BOOL)isWifiEnable;

/**
 *  @brief 网络是否可用
 *
 *  @return YES or NO
 */
+(BOOL)isNetworkEnable;

/**
 *  @brief 是否有告诉网络可用
 *
 *  @return YES or NO
 */
+(BOOL)isHighSpeedNetwork;

@end
