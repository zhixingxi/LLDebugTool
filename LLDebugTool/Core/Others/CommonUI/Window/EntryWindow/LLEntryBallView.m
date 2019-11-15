//
//  LLEntryBallView.m
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

#import "LLEntryBallView.h"

#import "LLImageNameConfig.h"
#import "LLThemeManager.h"
#import "LLFactory.h"
#import "LLConfig.h"

#import "UIView+LL_Utils.h"

@interface LLEntryBallView ()

@property (nonatomic, strong) UIImageView *logoImageView;

@property (nonatomic , strong) UILabel *memoryLabel;

@property (nonatomic , strong) UILabel *CPULabel;

@property (nonatomic , strong) UILabel *FPSLabel;

@property (nonatomic , strong) UIView *lineView;

@property (nonatomic , assign) CGFloat sBallWidth;

@end

static NSString * const LLAppInfoHelperCPUKey = @"LLAppInfoHelperCPUKey";
static NSString * const LLAppInfoHelperMemoryUsedKey = @"LLAppInfoHelperMemoryUsedKey";
static NSString * const LLAppInfoHelperFPSKey = @"LLAppInfoHelperFPSKey";

@implementation LLEntryBallView

#pragma mark - Over write
- (void)initUI {
    [super initUI];
    _sBallWidth = self.contentView.LL_width;
    self.overflow = YES;
    
    self.contentView.backgroundColor = [LLThemeManager shared].backgroundColor;
    [self.contentView LL_setBorderColor:[LLThemeManager shared].primaryColor borderWidth:2];
    [self.contentView LL_setCornerRadius:self.contentView.LL_width / 2];
    
//    self.logoImageView = [LLFactory getImageView:self.contentView frame:CGRectMake(self.LL_width / 4.0, self.LL_height / 4.0, self.LL_width / 2.0, self.LL_height / 2.0) image:[UIImage LL_imageNamed:kLogoImageName color:[LLThemeManager shared].primaryColor]];
    // Create memoryLabel
       self.memoryLabel.frame = CGRectMake(_sBallWidth / 8.0, _sBallWidth / 4.0, _sBallWidth * 3 / 4.0, _sBallWidth / 4.0);
       [self.contentView addSubview:self.memoryLabel];
       
       // Create CPULabel
       self.CPULabel.frame = CGRectMake(_sBallWidth / 8.0, _sBallWidth / 2.0, _sBallWidth * 3 / 4.0, _sBallWidth / 4.0);
       [self.contentView addSubview:self.CPULabel];
       
       // Create FPSLabel
       self.FPSLabel.frame = CGRectMake(0, 0, 20, 20);
       self.FPSLabel.center = CGPointMake(_sBallWidth * 0.85 + self.contentView.frame.origin.x, _sBallWidth * 0.15 + self.contentView.frame.origin.y);
       self.FPSLabel.layer.cornerRadius = self.FPSLabel.frame.size.height / 2.0;
       [self addSubview:self.FPSLabel];
       
       // Create Line
       self.lineView.frame = CGRectMake(_sBallWidth / 8.0, _sBallWidth / 2.0 - 0.5, _sBallWidth * 3 / 4.0, 1);
       [self.contentView addSubview:self.lineView];
    
}

- (void)primaryColorChanged {
    [super primaryColorChanged];
    self.contentView.layer.borderColor = [LLThemeManager shared].primaryColor.CGColor;
    self.logoImageView.image = [UIImage LL_imageNamed:kLogoImageName color:[LLThemeManager shared].primaryColor];
}

- (void)backgroundColorChanged {
    [super backgroundColorChanged];
    self.contentView.backgroundColor = [LLThemeManager shared].backgroundColor;
    self.logoImageView.backgroundColor = [LLThemeManager shared].backgroundColor;
}

- (void)appInfoChanged:(NSNotification *)notifi {
    NSDictionary *userInfo = notifi.userInfo;
    CGFloat cpu = [userInfo[LLAppInfoHelperCPUKey] floatValue];
    CGFloat usedMemory = [userInfo[LLAppInfoHelperMemoryUsedKey] floatValue];
    CGFloat fps = [userInfo[LLAppInfoHelperFPSKey] floatValue];
    self.memoryLabel.text = [NSString stringWithFormat:@"%@",[NSByteCountFormatter stringFromByteCount:usedMemory countStyle:NSByteCountFormatterCountStyleMemory]];
    self.CPULabel.text = [NSString stringWithFormat:@"CPU:%.2f%%",cpu];
    self.FPSLabel.text = [NSString stringWithFormat:@"%ld",(long)fps];
}



- (UILabel *)memoryLabel {
    if (!_memoryLabel) {
        _memoryLabel = [[UILabel alloc] init];
        _memoryLabel.textAlignment = NSTextAlignmentCenter;
        _memoryLabel.textColor = [LLThemeManager shared].primaryColor;
        _memoryLabel.font = [UIFont systemFontOfSize:12];
        _memoryLabel.adjustsFontSizeToFitWidth = YES;
        _memoryLabel.text = @"loading";
    }
    return _memoryLabel;
}

- (UILabel *)CPULabel {
    if (!_CPULabel) {
        _CPULabel = [[UILabel alloc] init];
        _CPULabel.textAlignment = NSTextAlignmentCenter;
        _CPULabel.textColor = [LLThemeManager shared].primaryColor;
        _CPULabel.font = [UIFont systemFontOfSize:12];
        _CPULabel.adjustsFontSizeToFitWidth = YES;
        _CPULabel.text = @"loading";
    }
    return _CPULabel;
}

- (UILabel *)FPSLabel {
    if (!_FPSLabel) {
        _FPSLabel = [[UILabel alloc] init];
        _FPSLabel.textAlignment = NSTextAlignmentCenter;
        _FPSLabel.backgroundColor = [LLThemeManager shared].primaryColor;
        _FPSLabel.textColor = [LLThemeManager shared].backgroundColor;
        _FPSLabel.font = [UIFont systemFontOfSize:12];
        _FPSLabel.adjustsFontSizeToFitWidth = YES;
        _FPSLabel.text = @"60";
        _FPSLabel.layer.masksToBounds = YES;
    }
    return _FPSLabel;
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc] init];
        _lineView.backgroundColor = [LLThemeManager shared].primaryColor;
    }
    return _lineView;
}

@end
