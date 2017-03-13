//
//  XMNAFLog.m
//  XMNAFNetworkDemo
//
//  Created by XMFraker on 16/4/22.
//  Copyright © 2016年 XMFraker. All rights reserved.
//

#import "XMNAFLogger.h"

#import "XMNAFService.h"
#import "XMNAFNetworkRequest.h"
#import "XMNAFNetworkResponse.h"

#import "NSDictionary+XMNAFJSON.h"

@implementation NSObject (XMNAFEmpty)

- (BOOL)XMNAF_isEmptyObject {
    
    if ([self isEqual:[NSNull null]]) {
        return YES;
    }
    
    if ([self isKindOfClass:[NSString class]]) {
        if ([(NSString *)self length] == 0) {
            return YES;
        }
    }
    
    if ([self isKindOfClass:[NSArray class]]) {
        if ([(NSArray *)self count] == 0) {
            return YES;
        }
    }
    
    if ([self isKindOfClass:[NSDictionary class]]) {
        if ([(NSDictionary *)self count] == 0) {
            return YES;
        }
    }
    
    return NO;
}

- (id)XMNAF_defaultValue:(id)defaultData {

    if ([self XMNAF_isEmptyObject]) {
        return defaultData;
    }
    return self;
}
@end

@implementation NSHTTPCookie (XMNAFAppendCookie)

- (NSString *)cookieDescription {
    
    return [NSString stringWithFormat:@"%@ = %@;path:%@;secure:%@",self.name,self.value,self.domain,self.isSecure ? @"YES" : @"NO"];
}

@end

@implementation NSMutableString (XMNAFAppendRequest)

- (void)appendURLRequest:(NSURLRequest *)request {
    
    [self appendFormat:@"\n\nHTTP URL:\n\t%@", request.URL];
    [self appendFormat:@"\n\nHTTP Header:\n%@", request.allHTTPHeaderFields ? request.allHTTPHeaderFields : @"\t\t\t\t\tN/A"];
    [self appendFormat:@"\n\nHTTP Body:\n\t%@", [[[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding] XMNAF_defaultValue:@"\t\t\t\tN/A"]];
    
    [self appendFormat:@"\n\nCookies :\n\t"];
    NSArray<NSHTTPCookie *> *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:request.URL];
    if (cookies.count > 0) {
        [cookies enumerateObjectsUsingBlock:^(NSHTTPCookie * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            [self appendFormat:@"%@\n\t",[obj cookieDescription]];
        }];
    }else {
        [self appendString:@"\t\t\tN/A\n"];
    }
}

@end


@implementation XMNAFLogger


+ (void)logRequestInfo:(NSString *)urlString
                params:(NSDictionary *)params
                method:(NSString *)method
              dataTask:(NSURLSessionDataTask *)dataTask
            forService:(XMNAFService *)service {
    
    if (service.shouldLog) {
        NSMutableString *logString = [NSMutableString stringWithString:@"\n\n**************************************************************\n*                       Request Start                        *\n**************************************************************\n\n"];
        
        [logString appendFormat:@"API Name:\t\t%@\n", [urlString XMNAF_defaultValue:@"N/A"]];
        [logString appendFormat:@"Method:\t\t\t%@\n", method];
        [logString appendFormat:@"Version:\t\t%@\n", [service.apiVersion XMNAF_defaultValue:@"N/A"]];
        [logString appendFormat:@"Service:\t\t%@\n", [service class]];
        [logString appendFormat:@"Params:\n%@", params];
        [logString appendURLRequest:dataTask.currentRequest];
        [logString appendFormat:@"\n\n**************************************************************\n*                         Request End                        *\n**************************************************************\n\n\n\n"];
        NSLog(@"%@", logString);
    }
}

/**
 *  打印返回Response信息
 *
 *  @param aResponse       返回response
 *  @param aResponseString 返回的response字符串
 *  @param aRequest        返回对应的请求
 *  @param aError          返回错误信息
 *  @param aRequestParams  请求的参数
 *  @param aService        请求所使用的服务
 */
+ (void)logResponseInfoWithResponse:(NSHTTPURLResponse * _Nonnull)aResponse
                     responseString:(NSString * _Nullable)aResponseString
                            request:(NSURLRequest * _Nonnull)aRequest
                              error:(NSError * _Nullable)aError
                             params:(NSDictionary * _Nullable)aRequestParams
                         forService:(XMNAFService * _Nonnull)aService {
    
    
    if (aService.shouldLog) {
        BOOL shouldLogError = aError ? YES : NO;
        
        NSMutableString *logString = [NSMutableString stringWithString:@"\n\n==============================================================\n=                        API Response                        =\n==============================================================\n\n"];
        
        [logString appendFormat:@"Status:\t%ld\t(%@)\n\n", (long)aResponse.statusCode, [NSHTTPURLResponse localizedStringForStatusCode:aResponse.statusCode]];
        [logString appendFormat:@"Content:\n\t%@\n\n", aResponseString];
        if (shouldLogError) {
            [logString appendFormat:@"Error Domain:\t\t\t\t\t\t\t%@\n", aError.domain];
            [logString appendFormat:@"Error Domain Code:\t\t\t\t\t\t%ld\n", (long)aError.code];
            [logString appendFormat:@"Error Localized Description:\t\t\t%@\n", aError.localizedDescription];
            [logString appendFormat:@"Error Localized Failure Reason:\t\t\t%@\n", aError.localizedFailureReason];
            [logString appendFormat:@"Error Localized Recovery Suggestion:\t%@\n\n", aError.localizedRecoverySuggestion];
        }
        
        [logString appendString:@"\n---------------  Related Request Content  --------------\n"];
        
        [logString appendURLRequest:aRequest];
        
        
        [logString appendFormat:@"\n\nRequest Params :\n\t"];
        if (aRequestParams) {
            [logString appendString:[aRequestParams XMNAF_jsonString]];
        }else {
            [logString appendString:@"NULL\n"];
            [logString appendString:@"\t\t\tN/A\n"];
        }
        
        [logString appendFormat:@"\n\n==============================================================\n=                  API   Response End                        =\n==============================================================\n\n\n\n"];
        
        NSLog(@"%@", logString);
    }
}

+ (void)logCacheResponseInfoWithResposne:(XMNAFNetworkResponse *)aResponse
                              methodName:(NSString *)aMethodName
                              forService:(XMNAFService *)aService {
    
    if (aService.shouldLog) {
        NSMutableString *logString = [NSMutableString stringWithString:@"\n\n==============================================================\n=                      Cached Response                       =\n==============================================================\n\n"];
        
        [logString appendFormat:@"API Name:\t\t%@\n", [aMethodName XMNAF_defaultValue:@"N/A"]];
        [logString appendFormat:@"Version:\t\t%@\n", [aService.apiVersion XMNAF_defaultValue:@"N/A"]];
        [logString appendFormat:@"Service:\t\t%@\n", [aService class]];
        [logString appendFormat:@"Method Name:\t%@\n", aMethodName];
        [logString appendFormat:@"Content:\n\t%@\n\n", aResponse.responseString];
        [logString appendFormat:@"\n\n==============================================================\n=                 Cached Response End                        =\n==============================================================\n\n\n\n"];
        NSLog(@"%@", logString);
    }
}
@end

