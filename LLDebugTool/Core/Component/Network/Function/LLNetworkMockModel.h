//
//  LLNetworkMockModel.h
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

#import "LLStorageModel.h"

@class LLNetworkModel;

NS_ASSUME_NONNULL_BEGIN

/// Mock model for a captured network request.
@interface LLNetworkMockModel : LLStorageModel

@property (nonatomic, copy) NSString *mockIdentity;
@property (nonatomic, copy, nullable) NSString *method;
@property (nonatomic, copy, nullable) NSString *host;
@property (nonatomic, copy, nullable) NSString *path;
@property (nonatomic, assign, getter=isEnabled) BOOL enabled;
@property (nonatomic, assign, getter=isCustomized) BOOL customized;
@property (nonatomic, strong, nullable) NSData *bodyData;
@property (nonatomic, copy, nullable) NSString *mimeType;
@property (nonatomic, copy, nullable) NSString *statusCode;
@property (nonatomic, copy, nullable) NSString *updatedAt;

+ (NSString *)mockIdentityForRequest:(NSURLRequest *)request;
+ (NSString *)mockIdentityWithMethod:(NSString *_Nullable)method URL:(NSURL *_Nullable)URL;
+ (instancetype)mockModelWithNetworkModel:(LLNetworkModel *)networkModel;

- (NSInteger)statusCodeValue;
- (NSString *)bodyString;
- (NSString *)editableBodyString;
- (void)updateBodyString:(NSString *)bodyString;

@end

NS_ASSUME_NONNULL_END
