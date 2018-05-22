//
//  XMNAFReachabilityManager.m
//  XMNAFNetworkDemo
//
//  Created by XMFraker on 16/7/13.
//  Copyright © 2016年 XMFraker. All rights reserved.
//

#import "XMNAFReachabilityManager.h"
#import <Reachability/Reachability.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "XMNAFNetworkConfiguration.h"

NSString *kXMNAFReachabilityStatusChangedNotification = @"com.XMFraker.XMNAFNetwork.kXMNAFReachabilityStatusChangedNotification";
NSString *kXMNAFReachabilityStatusKey = @"com.XMFraker.XMNAFNetwork.kXMNAFReachabilityStatusKey";
NSString *kXMNAFReachabilityStatusStringKey = @"com.XMFraker.XMNAFNetwork.kXMNAFReachabilityStatusStringKey";

@interface XMNAFReachabilityManager ()

/** 2G数组 */
@property (nonatomic,strong, readonly) NSArray *technology2GArray;
/** 3G数组 */
@property (nonatomic,strong, readonly) NSArray *technology3GArray;
/** 4G数组 */
@property (nonatomic,strong, readonly) NSArray *technology4GArray;

@property (nonatomic,strong) Reachability *reachability;

@property (nonatomic,strong) CTTelephonyNetworkInfo *telephonyNetworkInfo;

@property (nonatomic,copy, readonly)   NSString *currentRaioAccess;

@property (nonatomic, assign) XMNAFReachablityStatus lastStatus;
/** 是否正在监听 */
@property (nonatomic,assign, getter=isMonitoring) BOOL monitoring;

@end

@implementation XMNAFReachabilityManager

+ (instancetype)sharedManager {
    
    static id manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        manager = [[[self class] alloc] init];
    });
    return manager;
}

+ (void)initialize { [[XMNAFReachabilityManager sharedManager] telephonyNetworkInfo]; }

- (void)dealloc { [self stopMonitoring]; }

#pragma mark - Methods

- (void)startMonitoring {

    [self startMonitoringWithURL:nil
                        delegate:nil
           statusDidChangedBlock:nil];
}

- (void)startMonitoringWithURL:(NSURL *)URL {

    [self startMonitoringWithURL:URL
                        delegate:nil
           statusDidChangedBlock:nil];
}

- (void)startMonitoringWithURL:(NSURL *)URL
         statusDidChangedBlock:(void (^)(XMNAFReachablityStatus status))block {
    
    [self startMonitoringWithURL:URL
                        delegate:nil
           statusDidChangedBlock:block];
}

- (void)startMonitorWithURL:(NSURL *)URL
                   delegate:(id<XMNAFReachabilityDelegate>)delegate {
    
    [self startMonitoringWithURL:URL
                        delegate:delegate
           statusDidChangedBlock:nil];
}

- (void)startMonitoringWithURL:(NSURL *)URL
                      delegate:(id<XMNAFReachabilityDelegate>)delegate
         statusDidChangedBlock:(void (^)(XMNAFReachablityStatus status))block {
    
    
    if (self.isMonitoring) {
        
        XMNLog(@"reachability is monitoring");
        [self stopMonitoring];
    }
    
    self.delegate = delegate;
    self.statusDidChangedBlock = block;
    
    if (URL) {
        self.reachability = [Reachability reachabilityWithHostName:[URL host]];
    } else {
        self.reachability = [Reachability reachabilityForInternetConnection];
    }
    /** 注册监听函数 */
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleStatusChanged:) name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleStatusChanged:) name:CTRadioAccessTechnologyDidChangeNotification object:nil];
    [self.reachability startNotifier];
    self.lastStatus = self.status;
    self.monitoring = YES;
}

- (void)stopMonitoring {
    
    if (!self.isMonitoring) { return; }
    
    /** 移除监听函数 */
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CTRadioAccessTechnologyDidChangeNotification object:nil];
    [self.reachability stopNotifier];
    self.reachability = nil;
    self.monitoring = NO;
}

#pragma mark - Notification Events

- (void)handleStatusChanged:(NSNotification *)notification {

    if (self.lastStatus != self.status) {
        //使用代理回调
        if (self.delegate && [self.delegate respondsToSelector:@selector(statusDidChanged:)]) {
            [self.delegate statusDidChanged:self.status];
        }
        
        //如果状态发生变化,发送通知
        NSDictionary *userInfo = @{kXMNAFReachabilityStatusKey:@(self.status),
                                   kXMNAFReachabilityStatusStringKey:self.statusString};
        [[NSNotificationCenter defaultCenter] postNotificationName:kXMNAFReachabilityStatusChangedNotification object:self userInfo:userInfo];
        

        /** block回调 */
        self.statusDidChangedBlock ? self.statusDidChangedBlock(self.status) : nil;
        
        /** 修改上次的状态 */
        self.lastStatus = self.status;
    }
}

#pragma mark - Getters

- (XMNAFReachablityStatus)status {
    
    XMNAFReachablityStatus status = (XMNAFReachablityStatus)[self.reachability currentReachabilityStatus];
    
    NSString *technology = self.currentRaioAccess;
    
    if (status == XMNAFReachablityStatusWWAN && technology) {
        
        if ([self.technology2GArray containsObject:technology]) {
            return XMNAFReachablityStatus2G;
        }
        if ([self.technology3GArray containsObject:technology]) {
            return XMNAFReachablityStatus3G;
        }
        if ([self.technology4GArray containsObject:technology]) {
            return XMNAFReachablityStatus4G;
        }
    }
    return status;
}

- (NSString *)statusString {
    
    switch (self.status) {
        case XMNAFReachablityStatus2G:
            return @"2G";
        case XMNAFReachablityStatus3G:
            return @"3G";
        case XMNAFReachablityStatus4G:
            return @"4G";
        case XMNAFReachablityStatusWifi:
            return @"WiFi";
        case XMNAFReachablityStatusWWAN:
            return @"WWAN";
        default:
            return @"nonetwork";
    }
}

-(CTTelephonyNetworkInfo *)telephonyNetworkInfo{
    
    if(!_telephonyNetworkInfo){
        _telephonyNetworkInfo = [[CTTelephonyNetworkInfo alloc] init];
    }
    return _telephonyNetworkInfo;
}

- (NSString *)currentRaioAccess {
    
    return self.telephonyNetworkInfo.currentRadioAccessTechnology;
}

/**
 *  @brief 是否正在监听中
 *
 */
- (BOOL)isMonitoring { return _monitoring; }

- (BOOL)isWifiEnable { return self.status == XMNAFReachablityStatusWifi; }

- (BOOL)isNetworkEnable { return self.status != XMNAFReachablityStatusUnknown; }

- (BOOL)isHighSpeedNetwork {
    return self.status == XMNAFReachablityStatus4G || self.status == XMNAFReachablityStatusWifi || self.status == XMNAFReachablityStatus3G;
}

/** @brief 2G数组 */
-(NSArray *)technology2GArray{ return @[CTRadioAccessTechnologyEdge,CTRadioAccessTechnologyGPRS]; }


/** @brief 3G数组 */
-(NSArray *)technology3GArray{
    
    return @[CTRadioAccessTechnologyHSDPA,
            CTRadioAccessTechnologyWCDMA,
            CTRadioAccessTechnologyHSUPA,
            CTRadioAccessTechnologyCDMA1x,
            CTRadioAccessTechnologyCDMAEVDORev0,
            CTRadioAccessTechnologyCDMAEVDORevA,
            CTRadioAccessTechnologyCDMAEVDORevB,
             CTRadioAccessTechnologyeHRPD];
}

/** @brief 4G数组 */
-(NSArray *)technology4GArray{ return @[CTRadioAccessTechnologyLTE]; }

#pragma mark - Class Methods

+ (XMNAFReachablityStatus)currentStatus {
    
    return [XMNAFReachabilityManager sharedManager].status;
}

+ (NSString *)currentStatusString {
    
    return [XMNAFReachabilityManager sharedManager].statusString;
}

+ (void)startMonitoring {
    
    [[XMNAFReachabilityManager sharedManager] startMonitoring];
}

+ (void)startMonitoringWithURL:(NSURL *)URL {
    
    [[XMNAFReachabilityManager sharedManager] startMonitoringWithURL:URL
                                                            delegate:nil
                                               statusDidChangedBlock:nil];
}

+ (void)startMonitoringWithURL:(NSURL *)URL
         statusDidChangedBlock:(void(^)(XMNAFReachablityStatus status))block {
    
    [[XMNAFReachabilityManager sharedManager] startMonitoringWithURL:URL
                                                            delegate:nil
                                               statusDidChangedBlock:block];
}

+ (void)startMonitoringWithURL:(NSURL *)URL
                      delegate:(id<XMNAFReachabilityDelegate>)delegate {
    
    [[XMNAFReachabilityManager sharedManager] startMonitoringWithURL:URL
                                                            delegate:delegate
                                               statusDidChangedBlock:nil];
}

+ (void)stopMonitoring {
    
    [[XMNAFReachabilityManager sharedManager] stopMonitoring];
}

/**
 *  @brief wifi是否可用
 *
 */
+(BOOL)isWifiEnable {
    
    return [XMNAFReachabilityManager sharedManager].isWifiEnable;
}

/**
 *  @brief 网络是否可用
 *
 *  @return YES or NO
 */
+(BOOL)isNetworkEnable {
    
    return [XMNAFReachabilityManager sharedManager].isNetworkEnable;
}

/**
 *  @brief 是否有告诉网络可用
 *
 *  @return YES or NO
 */
+(BOOL)isHighSpeedNetwork {
    
    return [XMNAFReachabilityManager sharedManager].isHighSpeedNetwork;
}
@end
