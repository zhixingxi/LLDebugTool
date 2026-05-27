//
//  LLNetworkMockEditViewController.m
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

#import "LLNetworkMockEditViewController.h"

#import "LLNetworkMockManager.h"
#import "LLNetworkMockModel.h"
#import "LLToastUtils.h"
#import "LLThemeManager.h"
#import "LLFactory.h"
#import "LLMacros.h"
#import "LLConst.h"

@interface LLNetworkMockEditViewController () <UITextViewDelegate>

@property (nonatomic, strong) UITextView *textView;

@end

@implementation LLNetworkMockEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Mock Body";
    [self initNavigationItemWithTitle:@"Save" imageName:nil isLeft:NO];
    [self.view addSubview:self.textView];
    self.textView.text = [self.mockModel bodyString];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.textView.frame = CGRectMake(kLLGeneralMargin, LL_NAVIGATION_HEIGHT + kLLGeneralMargin, self.view.bounds.size.width - kLLGeneralMargin * 2, self.view.bounds.size.height - LL_NAVIGATION_HEIGHT - kLLGeneralMargin * 2);
}

- (void)rightItemClick:(UIButton *)sender {
    [self.textView resignFirstResponder];
    [self.mockModel updateBodyString:self.textView.text];
    [[LLToastUtils shared] loadingMessage:@"Saving"];
    __weak typeof(self) weakSelf = self;
    [[LLNetworkMockManager shared] saveMockModel:self.mockModel complete:^(BOOL result) {
        [[LLToastUtils shared] hide];
        if (result) {
            if (weakSelf.saveBlock) {
                weakSelf.saveBlock(weakSelf.mockModel);
            }
            [weakSelf.navigationController popViewControllerAnimated:YES];
        } else {
            [[LLToastUtils shared] toastMessage:@"Save mock body fail"];
        }
    }];
}

#pragma mark - Getters and setters
- (UITextView *)textView {
    if (!_textView) {
        _textView = [LLFactory getTextView:nil frame:CGRectZero delegate:self];
        _textView.font = [UIFont systemFontOfSize:14];
        _textView.textColor = [LLThemeManager shared].primaryColor;
        _textView.backgroundColor = [LLThemeManager shared].containerColor;
        _textView.alwaysBounceVertical = YES;
        _textView.layer.cornerRadius = 4;
        _textView.layer.masksToBounds = YES;
        _textView.textContainerInset = UIEdgeInsetsMake(kLLGeneralMargin, kLLGeneralMargin, kLLGeneralMargin, kLLGeneralMargin);
    }
    return _textView;
}

@end
