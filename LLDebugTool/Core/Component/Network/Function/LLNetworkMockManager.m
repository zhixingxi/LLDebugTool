//
//  LLNetworkMockManager.m
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

#import "LLNetworkMockManager.h"

#import "LLNetworkMockModel.h"
#import "LLNetworkModel.h"
#import "LLStorageManager.h"

static LLNetworkMockManager *_instance = nil;

@implementation LLNetworkMockManager

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[LLNetworkMockManager alloc] init];
    });
    return _instance;
}

- (void)mockModelForRequest:(NSURLRequest *)request complete:(LLNetworkMockModelBlock)complete {
    NSString *identity = [LLNetworkMockModel mockIdentityForRequest:request];
    [self mockModelWithIdentity:identity complete:complete];
}

- (void)mockModelForNetworkModel:(LLNetworkModel *)networkModel complete:(LLNetworkMockModelBlock)complete {
    NSString *identity = [LLNetworkMockModel mockIdentityWithMethod:networkModel.method URL:networkModel.url];
    [self mockModelWithIdentity:identity complete:complete];
}

- (void)saveMockDraftWithNetworkModel:(LLNetworkModel *)networkModel {
    if (networkModel.url == nil) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [self mockModelForNetworkModel:networkModel complete:^(LLNetworkMockModel * _Nullable model) {
        if (model == nil) {
            LLNetworkMockModel *mockModel = [LLNetworkMockModel mockModelWithNetworkModel:networkModel];
            [weakSelf saveMockModel:mockModel complete:nil];
            return;
        }
        model.method = networkModel.method.length ? networkModel.method.uppercaseString : model.method;
        model.host = networkModel.url.host.lowercaseString ?: model.host;
        model.path = networkModel.url.path.length ? networkModel.url.path : model.path;
        model.mimeType = model.mimeType.length ? model.mimeType : (networkModel.mimeType.length ? networkModel.mimeType : @"application/json");
        model.statusCode = model.statusCode.length ? model.statusCode : (networkModel.statusCode.length ? networkModel.statusCode : @"200");
        if (!model.isCustomized && networkModel.responseData.length) {
            model.bodyData = networkModel.responseData;
        }
        [weakSelf saveMockModel:model complete:nil];
    }];
}

- (void)saveMockModel:(LLNetworkMockModel *)model complete:(LLNetworkMockBoolBlock)complete {
    [self mockModelWithIdentity:model.mockIdentity complete:^(LLNetworkMockModel * _Nullable existModel) {
        if (existModel) {
            [[LLStorageManager shared] updateModel:model complete:complete];
        } else {
            [[LLStorageManager shared] saveModel:model complete:complete];
        }
    }];
}

- (void)updateMockEnabled:(BOOL)enabled networkModel:(LLNetworkModel *)networkModel complete:(LLNetworkMockBoolBlock)complete {
    __weak typeof(self) weakSelf = self;
    [self mockModelForNetworkModel:networkModel complete:^(LLNetworkMockModel * _Nullable model) {
        LLNetworkMockModel *mockModel = model ?: [LLNetworkMockModel mockModelWithNetworkModel:networkModel];
        mockModel.enabled = enabled;
        [weakSelf saveMockModel:mockModel complete:complete];
    }];
}

- (void)closeAllMocksWithComplete:(LLNetworkMockBoolBlock)complete {
    [[LLStorageManager shared] getModels:[LLNetworkMockModel class] launchDate:nil storageIdentity:nil complete:^(NSArray<LLStorageModel *> * _Nullable result) {
        __block BOOL finalResult = YES;
        dispatch_group_t group = dispatch_group_create();
        for (LLNetworkMockModel *model in result) {
            if (model.isEnabled) {
                model.enabled = NO;
                dispatch_group_enter(group);
                [self saveMockModel:model complete:^(BOOL ret) {
                    finalResult = finalResult && ret;
                    dispatch_group_leave(group);
                }];
            }
        }
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            if (complete) {
                complete(finalResult);
            }
        });
    }];
}

#pragma mark - Primary
- (void)mockModelWithIdentity:(NSString *)identity complete:(LLNetworkMockModelBlock)complete {
    if (identity.length == 0) {
        if (complete) {
            complete(nil);
        }
        return;
    }
    [[LLStorageManager shared] getModels:[LLNetworkMockModel class] launchDate:nil storageIdentity:identity complete:^(NSArray<LLStorageModel *> * _Nullable result) {
        if (complete) {
            complete((LLNetworkMockModel *)result.firstObject);
        }
    }];
}

@end
