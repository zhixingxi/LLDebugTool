//
//  LLNetworkMockModel.m
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

#import "LLNetworkMockModel.h"

#import "LLFormatterTool.h"
#import "LLNetworkModel.h"

@implementation LLNetworkMockModel

+ (NSString *)mockIdentityForRequest:(NSURLRequest *)request {
    return [self mockIdentityWithMethod:request.HTTPMethod URL:request.URL];
}

+ (NSString *)mockIdentityWithMethod:(NSString *)method URL:(NSURL *)URL {
    NSString *normalMethod = method.length ? method.uppercaseString : @"GET";
    NSString *host = URL.host.length ? URL.host.lowercaseString : @"";
    NSString *path = URL.path.length ? URL.path : @"/";
    return [NSString stringWithFormat:@"%@ %@%@", normalMethod, host, path];
}

+ (instancetype)mockModelWithNetworkModel:(LLNetworkModel *)networkModel {
    LLNetworkMockModel *model = [[LLNetworkMockModel alloc] init];
    model.method = networkModel.method.length ? networkModel.method.uppercaseString : @"GET";
    model.host = networkModel.url.host.lowercaseString ?: @"";
    model.path = networkModel.url.path.length ? networkModel.url.path : @"/";
    model.mockIdentity = [self mockIdentityWithMethod:model.method URL:networkModel.url];
    model.enabled = NO;
    model.customized = NO;
    model.bodyData = networkModel.responseData;
    model.mimeType = networkModel.mimeType.length ? networkModel.mimeType : @"application/json";
    model.statusCode = networkModel.statusCode.length ? networkModel.statusCode : @"200";
    model.updatedAt = [LLFormatterTool stringFromDate:[NSDate date] style:FormatterToolDateStyle1];
    return model;
}

- (NSString *)storageIdentity {
    return self.mockIdentity ?: @"";
}

- (NSInteger)statusCodeValue {
    NSInteger status = self.statusCode.integerValue;
    return status > 0 ? status : 200;
}

- (NSString *)bodyString {
    if (self.bodyData.length == 0) {
        return @"";
    }
    NSString *string = [[NSString alloc] initWithData:self.bodyData encoding:NSUTF8StringEncoding];
    return string ?: @"";
}

- (NSString *)editableBodyString {
    if (self.bodyData.length == 0) {
        return @"";
    }

    id json = [NSJSONSerialization JSONObjectWithData:self.bodyData options:0 error:NULL];
    if (json && [NSJSONSerialization isValidJSONObject:json]) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:NULL];
        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        return [self stringByDecodingUnicodeEscapes:string] ?: @"";
    }

    return [self stringByDecodingUnicodeEscapes:[self bodyString]];
}

- (void)updateBodyString:(NSString *)bodyString {
    self.bodyData = [bodyString ?: @"" dataUsingEncoding:NSUTF8StringEncoding];
    self.customized = YES;
    self.updatedAt = [LLFormatterTool stringFromDate:[NSDate date] style:FormatterToolDateStyle1];
}

- (NSString *)stringByDecodingUnicodeEscapes:(NSString *)string {
    if (string.length == 0 || [string rangeOfString:@"\\u"].location == NSNotFound) {
        return string;
    }

    NSMutableString *result = [NSMutableString stringWithCapacity:string.length];
    NSUInteger index = 0;
    while (index < string.length) {
        unichar character = [string characterAtIndex:index];
        if (character == '\\' && index + 5 < string.length && [string characterAtIndex:index + 1] == 'u') {
            NSInteger value = 0;
            BOOL validUnicodeEscape = YES;
            for (NSUInteger offset = 2; offset <= 5; offset++) {
                NSInteger hexValue = [self hexValueOfCharacter:[string characterAtIndex:index + offset]];
                if (hexValue < 0) {
                    validUnicodeEscape = NO;
                    break;
                }
                value = value * 16 + hexValue;
            }

            if (validUnicodeEscape) {
                [result appendFormat:@"%C", (unichar)value];
                index += 6;
                continue;
            }
        }

        [result appendFormat:@"%C", character];
        index++;
    }
    return result;
}

- (NSInteger)hexValueOfCharacter:(unichar)character {
    if (character >= '0' && character <= '9') {
        return character - '0';
    }
    if (character >= 'a' && character <= 'f') {
        return character - 'a' + 10;
    }
    if (character >= 'A' && character <= 'F') {
        return character - 'A' + 10;
    }
    return -1;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"[LLNetworkMockModel] identity:%@, enabled:%@, customized:%@, mimeType:%@, statusCode:%@, updatedAt:%@", self.mockIdentity, self.enabled ? @"YES" : @"NO", self.customized ? @"YES" : @"NO", self.mimeType, self.statusCode, self.updatedAt];
}

@end
