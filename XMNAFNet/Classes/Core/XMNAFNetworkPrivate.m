//  XMNAFNetworkPrivate.m
//  Pods
//
//  Created by  XMFraker on 2018/5/21
//  Copyright © XMFraker All rights reserved. (https://github.com/ws00801526)
//  @class      XMNAFNetworkPrivate
//  @version    <#class version#>
//  @abstract   <#class description#>

#import "XMNAFNetworkPrivate.h"
#import "XMNAFNetworkConfiguration.h"

static inline NSStringEncoding kXMNAFNetworkEncodingFromRequest(__kindof XMNAFNetworkRequest *request) {
    // From AFNetworking 2.6.3
    NSStringEncoding stringEncoding = NSUTF8StringEncoding;
    if (request.response.textEncodingName) {
        CFStringEncoding encoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)request.response.textEncodingName);
        if (encoding != kCFStringEncodingInvalidId) {
            stringEncoding = CFStringConvertEncodingToNSStringEncoding(encoding);
        }
    }
    return stringEncoding;
}

static inline NSURL * XMNAFNetworkCreateDownloadPath(NSString * downloadPath) {
    
    NSString *dirPath = [[NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"com.xmfraker.xmafnetwork/download"];
    
    NSString *filename = downloadPath;
    if ([downloadPath componentsSeparatedByString:@"/"].count) {
        
        NSArray<NSString *> *prefixDirs = [[downloadPath componentsSeparatedByString:@"/"] subarrayWithRange:NSMakeRange(0, [downloadPath componentsSeparatedByString:@"/"].count - 1)];
        if (prefixDirs.count) {
            dirPath = [dirPath stringByAppendingPathComponent:[prefixDirs componentsJoinedByString:@"/"]];
        }
        filename = [[downloadPath componentsSeparatedByString:@"/"] lastObject];
    }
    
    BOOL isDir = YES;
    if (![[NSFileManager defaultManager] fileExistsAtPath:dirPath isDirectory:&isDir] || !isDir) {
        XMNLog(@"downDir is not exists or is not a dir :%@, will recreate downDir", ((isDir == NO) ? @"YES" : @"NO"));
        NSError *error = nil;
        if (!isDir) { [[NSFileManager defaultManager] removeItemAtPath:dirPath error:&error]; }
        [[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:&error];
        XMNLog(@"create dir error :%@", error);
    }
    
    XMNLog(@"downDir is :%@",dirPath);
    NSString *absolutePath = [dirPath stringByAppendingPathComponent:filename];
    if ([[NSFileManager defaultManager] fileExistsAtPath:absolutePath]) {
        XMNLog(@"downPath is exists some object, will remove object");
        [[NSFileManager defaultManager] removeItemAtPath:absolutePath error:nil];
    }
    XMNLog(@"downPath is :%@",absolutePath);
    return [NSURL fileURLWithPath:absolutePath];
}


@implementation XMNAFService (Private)

- (void)startRequest:(__kindof XMNAFNetworkRequest *)request {
    
    NSParameterAssert(request != nil);
    NSDictionary *params = nil;
    NSString *URLString = [self absoluteURLStringWithRequest:request params:&params];
    
    __kindof AFHTTPRequestSerializer *serializer = self.sessionManager.requestSerializer;
    serializer.allowsCellularAccess = request.allowsCellularAccess;
    serializer.timeoutInterval = request.timeoutInterval;
    if (request.authorizationHeaderFields.count == 2) {
        [serializer setAuthorizationHeaderFieldWithUsername:[request.authorizationHeaderFields firstObject]
                                                   password:[request.authorizationHeaderFields lastObject]];
    }
    
    NSError *error;
    __kindof NSURLSessionTask *datatask = nil;
    switch (request.requestMode) {
        case XMNAFNetworkRequestPOST:
            datatask = [self dataTaskWithHTTPMethod:@"POST" URLString:URLString params:params progressHandler:request.progressHandler constructingHandler:request.constuctingHandler error:&error];
            break;
        case XMNAFNetworkRequestPUT:
            datatask = [self dataTaskWithHTTPMethod:@"PUT" URLString:URLString params:params progressHandler:nil constructingHandler:nil error:&error];
            break;
        case XMNAFNetworkRequestDELETE:
            datatask = [self dataTaskWithHTTPMethod:@"DELETE" URLString:URLString params:params progressHandler:nil constructingHandler:nil error:&error];
            break;
        case XMNAFNetworkRequestPATCH:
            datatask = [self dataTaskWithHTTPMethod:@"PATCH" URLString:URLString params:params progressHandler:nil constructingHandler:nil error:&error];
            break;
        case XMNAFNetworkRequestHEAD:
            datatask = [self dataTaskWithHTTPMethod:@"HEAD" URLString:URLString params:params progressHandler:nil constructingHandler:nil error:&error];
            break;
        case XMNAFNetworkRequestGET:
        {
            if (request.downloadPath.length) {
                NSData *resumeData = nil;
#if kXMNAFCacheAvailable
                NSString *cacheKey = [self cacheKeyWithRequest:request];
                if ([self.cache.diskCache containsObjectForKey:cacheKey]) {
                    resumeData = (NSData *)[self.cache.diskCache objectForKey:cacheKey];
                }
#endif
                if (resumeData) {
                    datatask = [self downloadTaskWithResumeData:resumeData downloadPath:request.downloadPath progressHandler:request.progressHandler];
                } else {
                    datatask = [self downloadTaskWithDownloadPath:request.downloadPath URLString:URLString params:params progressHandler:request.progressHandler error:&error];
                }
            } else {
                datatask = [self dataTaskWithHTTPMethod:@"GET" URLString:URLString params:params progressHandler:request.progressHandler constructingHandler:nil error:&error];
            }
        }
            break;
    }
    
    if (error) {
        [request requestDidCompletedWithError:error];
    } else {
        datatask.priority = request.priority;
        request.datatask = datatask;
        [datatask resume];
        __weak typeof(self) wSelf = self;
        [self performThreadSafeHandler:^{
            __strong typeof(wSelf) self = wSelf;
            [self.requestMappers setObject:request forKey:@(datatask.taskIdentifier)];
        }];
    }
}

- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                                       URLString:(NSString *)URLString
                                          params:(nullable NSDictionary *)params
                                 progressHandler:(nullable XMNAFNetworkProgressHandler)progressHandler
                             constructingHandler:(nullable XMNAFNetworkConstructingHandler)constructingHandler
                                           error:(NSError * _Nullable __autoreleasing *)error {
    
    NSMutableURLRequest *request = nil;
    if (constructingHandler) {
        request = [self.sessionManager.requestSerializer multipartFormRequestWithMethod:method URLString:URLString parameters:params constructingBodyWithBlock:constructingHandler error:error];
    } else {
        request = [self.sessionManager.requestSerializer requestWithMethod:method URLString:URLString parameters:params error:error];
    }
    __weak typeof(self) wSelf = self;
    __block NSURLSessionDataTask *task = [self.sessionManager dataTaskWithRequest:request uploadProgress:progressHandler downloadProgress:progressHandler completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        __strong typeof(wSelf) self = wSelf;
        [self handleRequestResultWithDatatask:task responseObject:responseObject error:error];
    }];
    return task;
}

- (NSURLSessionDownloadTask *)downloadTaskWithDownloadPath:(nullable NSString *)downloadPath
                                                 URLString:(nonnull NSString *)URLString
                                                    params:(nullable NSDictionary *)params
                                           progressHandler:(nullable XMNAFNetworkProgressHandler)progressHandler
                                                     error:(NSError * _Nullable __autoreleasing *)error {
    
    __weak typeof(self) wSelf = self;
    NSMutableURLRequest *request = [self.sessionManager.requestSerializer requestWithMethod:@"GET" URLString:URLString parameters:params error:error];
    __block NSURLSessionDownloadTask *downloadTask = [self.sessionManager downloadTaskWithRequest:request progress:^(NSProgress *progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            progressHandler ? progressHandler(progress) : nil;
        });
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return XMNAFNetworkCreateDownloadPath(downloadPath);
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        __strong typeof(wSelf) self = wSelf;
        [self handleRequestResultWithDatatask:downloadTask responseObject:filePath error:error];
    }];
    return downloadTask;
}

- (NSURLSessionDownloadTask *)downloadTaskWithResumeData:(nonnull NSData *)resumeData
                                            downloadPath:(nonnull NSString *)downloadPath
                                         progressHandler:(nullable XMNAFNetworkProgressHandler)progressHandler {
    
    NSAssert(resumeData, @"resumeData should not be nil");
    __weak typeof(self) wSelf = self;
    __block NSURLSessionDownloadTask *downloadTask = [self.sessionManager downloadTaskWithResumeData:resumeData progress:^(NSProgress *progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            progressHandler ? progressHandler(progress) : nil;
        });
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return XMNAFNetworkCreateDownloadPath(downloadPath);
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        __strong typeof(wSelf) self = wSelf;
        [self handleRequestResultWithDatatask:downloadTask responseObject:filePath error:error];
    }];
    return downloadTask;
}

- (void)handleRequestResultWithDatatask:(nonnull __kindof NSURLSessionTask *)datatask
                         responseObject:(nullable id)responseObject
                                  error:(nullable NSError *)error {
    
    __weak typeof(self) wSelf = self;
    [self performThreadSafeHandler:^{
        __strong typeof(wSelf) self = wSelf;
        XMNAFNetworkRequest *request = [self.requestMappers objectForKey:@(datatask.taskIdentifier)];
        if (request == nil) return; // 此处选择忽略所有不存在请求
        
        if ([responseObject isKindOfClass:[NSData class]]) {
            request.responseObject = request.responseData = responseObject;
            request.responseString = [[NSString alloc] initWithData:responseObject encoding:kXMNAFNetworkEncodingFromRequest(request)];
        } else if ([NSJSONSerialization isValidJSONObject:responseObject]) {
            request.responseObject = request.responseJSONObject = responseObject;
            request.responseData = [NSJSONSerialization dataWithJSONObject:responseObject options:NSJSONWritingPrettyPrinted error:nil];
            request.responseString = [[NSString alloc] initWithData:request.responseData encoding:kXMNAFNetworkEncodingFromRequest(request)];
        } else if ([responseObject isKindOfClass:[NSURL class]]) {
            // 处理
            request.responseObject = responseObject;
            request.responseString = [(NSURL *)responseObject absoluteString];
        } else {
            request.responseObject = responseObject;
        }
        
        [request requestDidCompletedWithError:error];
        [self.requestMappers removeObjectForKey:@(datatask.taskIdentifier)];
    }];
}

- (NSString *)cacheKeyWithRequest:(__kindof XMNAFNetworkRequest *)request {
    
    NSMutableString *ret = [NSMutableString stringWithString:[self absoluteURLStringWithRequest:request params:nil]];
    if (ret.length && [NSURL URLWithString:ret]) {
        
        NSArray<NSHTTPCookie *> *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:ret]];
        NSMutableArray<NSString *> *cookieMD5s = [NSMutableArray arrayWithCapacity:cookies.count];
        for (NSHTTPCookie *cookie in cookies) {
            NSData *cookieData = [NSJSONSerialization dataWithJSONObject:[cookie properties] options:NSJSONWritingPrettyPrinted error:nil];
            NSString *cookieMD5 = XMNAF_MD5([[NSString alloc] initWithData:cookieData encoding:NSUTF8StringEncoding]);
            if (cookieMD5.length) [cookieMD5s addObject:cookieMD5];
        }
        [cookieMD5s sortUsingSelector:@selector(compare:)];
        NSString *cookieMD5 = [cookieMD5s componentsJoinedByString:@","];
        if (cookieMD5 && cookieMD5.length) {
            [ret appendFormat:@"Cookie :%@\n",cookies];
        }
    }
    [ret appendFormat:@"Method :%lu\n",(unsigned long)request.methodName];
    [ret appendFormat:@"Params :%@\n",request.requestParams ? : @{}];
    return XMNAF_MD5(ret);
}

- (NSString *)absoluteURLStringWithRequest:(__kindof XMNAFNetworkRequest *)request
                                    params:(NSDictionary *__nullable *__nullable)params {
    
    __block NSString *requestPath = request.methodName;
    NSMutableDictionary *remainParams = [NSMutableDictionary dictionaryWithDictionary:request.requestParams];
    NSMutableArray *removedKeys = [NSMutableArray array];
    [request.requestParams enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        
        NSString *pathKey = [NSString stringWithFormat:@"{%@}",key];
        if ([requestPath containsString:pathKey]) {
            requestPath = [requestPath stringByReplacingOccurrencesOfString:pathKey withString:[NSString stringWithFormat:@"%@",obj]];
            [removedKeys addObject:key];
        }
        
        pathKey = [NSString stringWithFormat:@":%@",key];
        if ([requestPath containsString:pathKey]) {
            requestPath = [requestPath stringByReplacingOccurrencesOfString:pathKey withString:[NSString stringWithFormat:@"%@",obj]];
            [removedKeys addObject:key];
        }
    }];
    removedKeys.count ? [remainParams removeObjectsForKeys:removedKeys] : nil;
    params ? *params = [remainParams copy] : nil;
    return [NSURL URLWithString:requestPath relativeToURL:[NSURL URLWithString:self.apiBaseURL]].absoluteString;
}

@end
