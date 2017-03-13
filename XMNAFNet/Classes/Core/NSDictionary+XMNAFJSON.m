//
//  NSDictionary+XMNAFJSON.m
//  XMNAFNetworkDemo
//
//  Created by XMFraker on 16/4/22.
//  Copyright © 2016年 XMFraker. All rights reserved.
//

#import "NSDictionary+XMNAFJSON.h"
#import "NSArray+XMNAFJSON.h"

@implementation NSDictionary (XMNAFJSON)

/** 字符串前面是没有问号的，如果用于POST，那就不用加问号，如果用于GET，就要加个问号 */
- (NSString *)XMNAF_urlParamsStringSignature:(BOOL)isForSignature {
    
    NSArray *sortedArray = [self XMNAF_transformedUrlParamsArraySignature:isForSignature];
    return [sortedArray XMNAF_paramsString];
}

- (NSString *)XMNAF_jsonString {
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:NULL];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

/** 转义参数 */
- (NSArray *)XMNAF_transformedUrlParamsArraySignature:(BOOL)isForSignature
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (![obj isKindOfClass:[NSString class]]) {
            obj = [NSString stringWithFormat:@"%@", obj];
        }
        if (!isForSignature) {
            
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_7_0
            obj = [obj stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
#else
            obj = [obj stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"!*'();:@&;=+$,/?%#[]"]];
#endif
        }
        /** 修复可以传入参数值为空值 */
        [result addObject:[NSString stringWithFormat:@"%@=%@", key, obj]];

    }];
    NSArray *sortedResult = [result sortedArrayUsingSelector:@selector(compare:)];
    return sortedResult;
}
@end
