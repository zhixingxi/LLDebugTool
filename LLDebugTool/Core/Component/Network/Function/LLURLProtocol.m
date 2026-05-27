//
//  LLURLProtocol.m
//
//  Copyright (c) 2018 LLDebugTool Software Foundation (https://github.com/HDB-Li/LLDebugTool)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

#import "LLURLProtocol.h"

#import "LLStorageManager.h"
#import "LLFormatterTool.h"
#import "LLAppInfoHelper.h"
#import "LLNetworkMockManager.h"
#import "LLNetworkMockModel.h"
#import "LLNetworkModel.h"
#import "LLConfig.h"
#import "LLTool.h"

#import "NSHTTPURLResponse+LL_Utils.h"
#import "NSInputStream+LL_Utils.h"
#import "NSData+LL_Utils.h"

static NSString *const HTTPHandledIdentifier = @"HttpHandleIdentifier";

@interface LLURLProtocol () <NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSessionDataTask *dataTask;
@property (nonatomic, strong) NSURLSession         *session;
@property (nonatomic, strong) NSURLResponse        *response;
@property (nonatomic, strong) NSMutableData        *data;
@property (nonatomic, strong) NSDate               *startDate;
@property (nonatomic, strong) NSError              *error;
@property (nonatomic, assign) BOOL mocked;
@property (nonatomic, assign) BOOL saved;

@end

@implementation LLURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    if (![request.URL.scheme isEqualToString:@"http"] &&
        ![request.URL.scheme isEqualToString:@"https"]) {
        return NO;
    }
    
    if ([NSURLProtocol propertyForKey:HTTPHandledIdentifier inRequest:request] ) {
        return NO;
    }
    
    if ([LLConfig shared].observerdHosts.count > 0) {
        NSString *url = [request.URL.absoluteString lowercaseString];
        for (NSString *_url in [LLConfig shared].observerdHosts) {
            if ([url rangeOfString:[_url lowercaseString]].location != NSNotFound)
                return YES;
        }
        return NO;
    }
    
    if ([LLConfig shared].ignoredHosts.count > 0) {
        NSString *url = [request.URL.absoluteString lowercaseString];
        for (NSString *_url in [LLConfig shared].ignoredHosts) {
            if ([url rangeOfString:[_url lowercaseString]].location != NSNotFound)
                return NO;
        }
    }
    
    return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    
    NSMutableURLRequest *mutableReqeust = [request mutableCopy];
    [NSURLProtocol setProperty:@YES
                        forKey:HTTPHandledIdentifier
                     inRequest:mutableReqeust];
//    return [mutableReqeust copy];
    return mutableReqeust;
}

- (void)startLoading {
    self.startDate                                        = [NSDate date];
    self.data                                             = [NSMutableData data];
    __weak typeof(self) weakSelf = self;
    [[LLNetworkMockManager shared] mockModelForRequest:self.request complete:^(LLNetworkMockModel * _Nullable model) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }
        if (model.isEnabled) {
            [strongSelf loadMockModel:model];
        } else {
            [strongSelf loadOriginRequest];
        }
    }];
}

- (void)loadOriginRequest {
    NSURLSessionConfiguration *configuration              = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.session                                          = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    self.dataTask                                         = [self.session dataTaskWithRequest:self.request];
    [self.dataTask resume];
}

- (void)loadMockModel:(LLNetworkMockModel *)mockModel {
    self.mocked = YES;
    NSData *bodyData = mockModel.bodyData ?: [NSData data];
    NSString *mimeType = mockModel.mimeType.length ? mockModel.mimeType : @"application/json";
    NSDictionary *headers = @{@"Content-Type" : mimeType};
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL statusCode:[mockModel statusCodeValue] HTTPVersion:@"HTTP/1.1" headerFields:headers];
    self.response = response;
    self.data = [bodyData mutableCopy];
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    if (bodyData.length) {
        [self.client URLProtocol:self didLoadData:bodyData];
    }
    [self.client URLProtocolDidFinishLoading:self];
    [self saveMockNetworkModelWithMockModel:mockModel];
}

- (void)stopLoading {
    if (self.mocked) {
        return;
    }
    [self.dataTask cancel];
    self.dataTask           = nil;
    [self saveCurrentNetworkModel];
}

- (void)saveCurrentNetworkModel {
    if (self.saved) {
        return;
    }
    self.saved = YES;
    LLNetworkModel *model = [[LLNetworkModel alloc] init];
    model.startDate = [LLFormatterTool stringFromDate:self.startDate style:FormatterToolDateStyle1];
    // Request
    model.url = self.request.URL;
    model.method = self.request.HTTPMethod;
    model.headerFields = [self.request.allHTTPHeaderFields mutableCopy];
    
    NSData *data = [self.request.HTTPBody copy];
    if (data == nil) {
        NSInputStream *stream = self.request.HTTPBodyStream;
        if (stream) {
            data = [stream LL_toData];
        }
    }
    if (data && [data length] > 0) {
        model.requestBody = [data LL_toJsonString];
    }
    
    // Response
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)self.response;
    model.stateLine = httpResponse.LL_stateLine;
    model.mimeType = self.response.MIMEType;
    if (model.mimeType.length == 0) {
        NSString *absoluteString = self.request.URL.absoluteString.lowercaseString;
        if ([absoluteString hasSuffix:@".jpg"] || [absoluteString hasSuffix:@".jpeg"] || [absoluteString hasSuffix:@".png"]) {
            model.isImage = YES;
        } else if ([absoluteString hasSuffix:@".gif"]) {
            model.isGif = YES;
        }
    }
    model.statusCode = [NSString stringWithFormat:@"%d",(int)httpResponse.statusCode];
    model.responseData = self.data;
    model.responseHeaderFields = [httpResponse.allHeaderFields mutableCopy];
    model.totalDuration = [NSString stringWithFormat:@"%fs",[[NSDate date] timeIntervalSinceDate:self.startDate]];
    model.error = self.error;
    [[LLStorageManager shared] saveModel:model complete:nil];
    [[LLNetworkMockManager shared] saveMockDraftWithNetworkModel:model];
    [[LLAppInfoHelper shared] updateRequestDataTraffic:model.requestDataTrafficValue responseDataTraffic:model.responseDataTrafficValue];
}

- (void)saveMockNetworkModelWithMockModel:(LLNetworkMockModel *)mockModel {
    LLNetworkModel *model = [[LLNetworkModel alloc] init];
    model.startDate = [LLFormatterTool stringFromDate:self.startDate style:FormatterToolDateStyle1];
    model.url = self.request.URL;
    model.method = self.request.HTTPMethod;
    model.headerFields = [self.request.allHTTPHeaderFields mutableCopy];
    model.stateLine = [NSString stringWithFormat:@"HTTP/1.1 %ld", (long)[mockModel statusCodeValue]];
    model.mimeType = mockModel.mimeType.length ? mockModel.mimeType : @"application/json";
    model.statusCode = [NSString stringWithFormat:@"%ld", (long)[mockModel statusCodeValue]];
    model.responseData = mockModel.bodyData;
    model.responseHeaderFields = @{@"Content-Type" : model.mimeType};
    model.totalDuration = [NSString stringWithFormat:@"%fs",[[NSDate date] timeIntervalSinceDate:self.startDate]];
    [[LLStorageManager shared] saveModel:model complete:nil];
    [[LLAppInfoHelper shared] updateRequestDataTraffic:model.requestDataTrafficValue responseDataTraffic:model.responseDataTrafficValue];
}

#pragma mark - NSURLSessionDelegate
// This method ignores certificate validation to resolve some untrusted HTTP requests that fail, and is recommended only in debug mode.
-(void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {

    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    __block NSURLCredential *credential = nil;

    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        if (credential) {
            disposition = NSURLSessionAuthChallengeUseCredential;
        } else {
            disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        }
    } else {
        disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    }

    if (completionHandler) {
        completionHandler(disposition, credential);
    }
}

#pragma mark - NSURLSessionTaskDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (!error) {
        [self.client URLProtocolDidFinishLoading:self];
    } else if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled) {
        
    } else {
        [self.client URLProtocol:self didFailWithError:error];
    }
    self.error = error;
    self.dataTask = nil;
    [self.session finishTasksAndInvalidate];
    self.session = nil;
    [self saveCurrentNetworkModel];
}

#pragma mark - NSURLSessionDataDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    [self.data appendData:data];
    [self.client URLProtocol:self didLoadData:data];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
    completionHandler(NSURLSessionResponseAllow);
    self.response = response;
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    if (response != nil){
        self.response = response;
        [[self client] URLProtocol:self wasRedirectedToRequest:request redirectResponse:response];
    }
}

@end
