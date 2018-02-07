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
    /** wifi */
    XMNAFReachablityStatusWifi,
    /** 移动网络 */
    XMNAFReachablityStatusWWAN,
    /** 2G网络 */
    XMNAFReachablityStatus2G,
    /** 3G网络 */
    XMNAFReachablityStatus3G,
    /** 4G网络 */
    XMNAFReachablityStatus4G
};

FOUNDATION_EXPORT NSString *kXMNAFReachabilityStatusChangedNotification;
FOUNDATION_EXPORT NSString *kXMNAFReachabilityStatusKey;
FOUNDATION_EXPORT NSString *kXMNAFReachabilityStatusStringKey;

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
@property (nonatomic, copy)   void(^statusDidChangedBlock)(XMNAFReachablityStatus status);


+ (instancetype)sharedManager;

- (void)startMonitoring;
- (void)startMonitoringWithURL:(NSURL *)URL;

- (void)startMonitorWithURL:(NSURL *)URL
                   delegate:(id<XMNAFReachabilityDelegate>)delegate;

- (void)startMonitoringWithURL:(NSURL *)URL
         statusDidChangedBlock:(void(^)(XMNAFReachablityStatus status))block;

- (void)stopMonitoring;


#pragma mark - Class Methods

/// ========================================
/// @name   以下方法均为直接操作[XMNAFReachabilityManager sharedManager]
/// ========================================

/**
 *  @brief 获取当前的网络状态
 *
 *  @return 当前网络状态
 */
+ (XMNAFReachablityStatus)currentStatus;

/**
 *  @brief 获取当前网络状态对应字符串
 *
 *  @return 当前状态字符创
 */
+ (NSString *)currentStatusString;

/**
 *  @brief 开始检测网络状态
 */
+ (void)startMonitoring;

/**
 *  @brief 开始检测网络状态
 *
 *  @param URL 测试连接的网络地址
 */
+ (void)startMonitoringWithURL:(NSURL *)URL;

/**
 *  @brief 开始检测网络状态
 *
 *  @param URL   测试连接的网络地址
 *  @param block block回调
 */
+ (void)startMonitoringWithURL:(NSURL *)URL
         statusDidChangedBlock:(void(^)(XMNAFReachablityStatus status))block;

/**
 *  @brief 开始检测网络状态
 *
 *  @param URL   测试连接的网络地址
 *  @param delegate delegate方式回调
 */
+ (void)startMonitoringWithURL:(NSURL *)URL
                      delegate:(id<XMNAFReachabilityDelegate>)delegate;

/**
 *  @brief 停止监听网络状态
 */
+ (void)stopMonitoring;

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
