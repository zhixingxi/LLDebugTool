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

#import "UIView+LL_Utils.h"

@interface LLNetworkMockEditItem : NSObject

@property (nonatomic, strong) NSArray *path;
@property (nonatomic, copy) NSString *pathString;
@property (nonatomic, strong) id value;

@end

@implementation LLNetworkMockEditItem

@end

@interface LLNetworkMockEditViewController () <UITextViewDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@property (nonatomic, strong) UITextField *searchTextField;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *tipsLabel;
@property (nonatomic, strong) id jsonObject;
@property (nonatomic, strong) NSMutableArray<LLNetworkMockEditItem *> *jsonItems;
@property (nonatomic, strong) NSMutableArray<LLNetworkMockEditItem *> *filteredJsonItems;
@property (nonatomic, assign) BOOL jsonModeAvailable;

@end

@implementation LLNetworkMockEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Mock Body";
    [self initNavigationItemWithTitle:@"Save" imageName:nil isLeft:NO];
    [self.view addSubview:self.segmentedControl];
    [self.view addSubview:self.searchTextField];
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.tipsLabel];
    [self.view addSubview:self.textView];
    self.textView.text = [self.mockModel editableBodyString];
    [self reloadJSONEditorWithText:self.textView.text];
    if (self.jsonModeAvailable) {
        self.segmentedControl.selectedSegmentIndex = 1;
    }
    [self updateEditorMode];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat contentWidth = self.view.bounds.size.width - kLLGeneralMargin * 2;
    self.segmentedControl.frame = CGRectMake(kLLGeneralMargin, LL_NAVIGATION_HEIGHT + kLLGeneralMargin, contentWidth, 32);
    self.searchTextField.frame = CGRectMake(kLLGeneralMargin, self.segmentedControl.LL_bottom + kLLGeneralMargin, contentWidth, 34);
    self.tipsLabel.frame = CGRectMake(kLLGeneralMargin, self.searchTextField.LL_bottom + kLLGeneralMargin / 2, contentWidth, 28);
    CGFloat editorY = self.segmentedControl.LL_bottom + kLLGeneralMargin;
    CGFloat editorHeight = self.view.bounds.size.height - editorY - kLLGeneralMargin;
    self.textView.frame = CGRectMake(kLLGeneralMargin, editorY, contentWidth, editorHeight);
    CGFloat tableY = self.tipsLabel.LL_bottom + kLLGeneralMargin / 2;
    self.tableView.frame = CGRectMake(0, tableY, self.view.bounds.size.width, self.view.bounds.size.height - tableY);
}

- (void)rightItemClick:(UIButton *)sender {
    [self.textView resignFirstResponder];
    [self.searchTextField resignFirstResponder];
    NSString *bodyString = self.segmentedControl.selectedSegmentIndex == 1 && self.jsonModeAvailable ? [self serializedJSONString] : self.textView.text;
    if (bodyString.length == 0 && self.segmentedControl.selectedSegmentIndex == 1 && self.jsonModeAvailable) {
        [[LLToastUtils shared] toastMessage:@"Serialize json fail"];
        return;
    }
    [self.mockModel updateBodyString:bodyString];
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

#pragma mark - UITableViewDelegate, UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredJsonItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"LLNetworkMockJSONCellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.font = [UIFont systemFontOfSize:13];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
        cell.detailTextLabel.numberOfLines = 2;
    }
    LLNetworkMockEditItem *item = self.filteredJsonItems[indexPath.row];
    cell.textLabel.text = item.pathString;
    cell.textLabel.textColor = [LLThemeManager shared].primaryColor;
    cell.detailTextLabel.text = [self displayStringWithValue:item.value];
    cell.detailTextLabel.textColor = [LLThemeManager shared].primaryColor;
    cell.backgroundColor = [LLThemeManager shared].containerColor;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    LLNetworkMockEditItem *item = self.filteredJsonItems[indexPath.row];
    [self showEditAlertWithItem:item];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidChange:(UITextField *)textField {
    [self filterJSONItems];
}

#pragma mark - Event response
- (void)segmentedControlValueChanged:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 1) {
        [self reloadJSONEditorWithText:self.textView.text];
        if (!self.jsonModeAvailable) {
            [[LLToastUtils shared] toastMessage:@"Body is not valid JSON"];
            sender.selectedSegmentIndex = 0;
        }
    } else if (self.jsonModeAvailable) {
        NSString *bodyString = [self serializedJSONString];
        if (bodyString.length) {
            self.textView.text = bodyString;
        }
    }
    [self updateEditorMode];
}

#pragma mark - Primary
- (void)reloadJSONEditorWithText:(NSString *)text {
    NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
    id object = data.length ? [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:NULL] : nil;
    if (!object || ![NSJSONSerialization isValidJSONObject:object]) {
        self.jsonModeAvailable = NO;
        self.jsonObject = nil;
        [self.jsonItems removeAllObjects];
        [self.filteredJsonItems removeAllObjects];
        [self.tableView reloadData];
        return;
    }
    self.jsonModeAvailable = YES;
    self.jsonObject = object;
    [self.jsonItems removeAllObjects];
    [self collectEditableItemsFromObject:object path:@[]];
    [self filterJSONItems];
}

- (void)collectEditableItemsFromObject:(id)object path:(NSArray *)path {
    if ([object isKindOfClass:[NSDictionary class]]) {
        NSArray *keys = [[(NSDictionary *)object allKeys] sortedArrayUsingSelector:@selector(compare:)];
        for (NSString *key in keys) {
            [self collectEditableItemsFromObject:object[key] path:[path arrayByAddingObject:key]];
        }
    } else if ([object isKindOfClass:[NSArray class]]) {
        NSArray *array = object;
        for (NSUInteger index = 0; index < array.count; index++) {
            [self collectEditableItemsFromObject:array[index] path:[path arrayByAddingObject:@(index)]];
        }
    } else {
        LLNetworkMockEditItem *item = [[LLNetworkMockEditItem alloc] init];
        item.path = path;
        item.pathString = [self pathStringWithPath:path];
        item.value = object ?: [NSNull null];
        [self.jsonItems addObject:item];
    }
}

- (void)filterJSONItems {
    NSString *keyword = self.searchTextField.text.lowercaseString;
    [self.filteredJsonItems removeAllObjects];
    for (LLNetworkMockEditItem *item in self.jsonItems) {
        if (keyword.length == 0 || [item.pathString.lowercaseString containsString:keyword]) {
            [self.filteredJsonItems addObject:item];
        }
    }
    self.tipsLabel.text = self.jsonModeAvailable ? [NSString stringWithFormat:@"%ld / %ld keys", (long)self.filteredJsonItems.count, (long)self.jsonItems.count] : @"Raw body is not valid JSON";
    [self.tableView reloadData];
}

- (void)updateEditorMode {
    BOOL isJSONMode = self.segmentedControl.selectedSegmentIndex == 1 && self.jsonModeAvailable;
    self.textView.hidden = isJSONMode;
    self.searchTextField.hidden = !isJSONMode;
    self.tableView.hidden = !isJSONMode;
    self.tipsLabel.hidden = !isJSONMode;
}

- (void)showEditAlertWithItem:(LLNetworkMockEditItem *)item {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:item.pathString message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = [self editableStringWithValue:item.value];
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *text = alert.textFields.firstObject.text ?: @"";
        id value = [weakSelf parsedValueWithString:text originalValue:item.value];
        [weakSelf updateJSONObjectWithValue:value path:item.path];
        item.value = value;
        [weakSelf.tableView reloadData];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (NSString *)serializedJSONString {
    if (!self.jsonObject || ![NSJSONSerialization isValidJSONObject:self.jsonObject]) {
        return nil;
    }
    NSData *data = [NSJSONSerialization dataWithJSONObject:self.jsonObject options:NSJSONWritingPrettyPrinted error:NULL];
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return [self stringByDecodingUnicodeEscapes:string] ?: string;
}

- (void)updateJSONObjectWithValue:(id)value path:(NSArray *)path {
    if (path.count == 0) {
        self.jsonObject = value;
        return;
    }
    id container = self.jsonObject;
    for (NSUInteger index = 0; index < path.count - 1; index++) {
        id key = path[index];
        container = [self valueFromContainer:container key:key];
    }
    id lastKey = path.lastObject;
    if ([container isKindOfClass:[NSMutableDictionary class]] && [lastKey isKindOfClass:[NSString class]]) {
        [(NSMutableDictionary *)container setObject:value ?: [NSNull null] forKey:lastKey];
    } else if ([container isKindOfClass:[NSMutableArray class]] && [lastKey isKindOfClass:[NSNumber class]]) {
        NSUInteger index = [(NSNumber *)lastKey unsignedIntegerValue];
        if (index < [(NSMutableArray *)container count]) {
            [(NSMutableArray *)container replaceObjectAtIndex:index withObject:value ?: [NSNull null]];
        }
    }
}

- (id)valueFromContainer:(id)container key:(id)key {
    if ([container isKindOfClass:[NSDictionary class]] && [key isKindOfClass:[NSString class]]) {
        return [(NSDictionary *)container objectForKey:key];
    }
    if ([container isKindOfClass:[NSArray class]] && [key isKindOfClass:[NSNumber class]]) {
        NSUInteger index = [(NSNumber *)key unsignedIntegerValue];
        NSArray *array = container;
        return index < array.count ? array[index] : nil;
    }
    return nil;
}

- (id)parsedValueWithString:(NSString *)string originalValue:(id)originalValue {
    if ([originalValue isKindOfClass:[NSNumber class]]) {
        NSString *lowerString = string.lowercaseString;
        if ([lowerString isEqualToString:@"true"]) {
            return @YES;
        }
        if ([lowerString isEqualToString:@"false"]) {
            return @NO;
        }
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        formatter.numberStyle = NSNumberFormatterDecimalStyle;
        NSNumber *number = [formatter numberFromString:string];
        return number ?: originalValue;
    }
    if ([originalValue isKindOfClass:[NSNull class]] && [string.lowercaseString isEqualToString:@"null"]) {
        return [NSNull null];
    }
    return string ?: @"";
}

- (NSString *)pathStringWithPath:(NSArray *)path {
    NSMutableString *string = [[NSMutableString alloc] init];
    for (id component in path) {
        if ([component isKindOfClass:[NSString class]]) {
            if (string.length) {
                [string appendString:@"."];
            }
            [string appendString:component];
        } else if ([component isKindOfClass:[NSNumber class]]) {
            [string appendFormat:@"[%@]", component];
        }
    }
    return string;
}

- (NSString *)displayStringWithValue:(id)value {
    if ([value isKindOfClass:[NSNull class]]) {
        return @"null";
    }
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    }
    return [value description];
}

- (NSString *)editableStringWithValue:(id)value {
    return [self displayStringWithValue:value];
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

- (UISegmentedControl *)segmentedControl {
    if (!_segmentedControl) {
        _segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Raw", @"JSON"]];
        _segmentedControl.selectedSegmentIndex = 0;
        [_segmentedControl addTarget:self action:@selector(segmentedControlValueChanged:) forControlEvents:UIControlEventValueChanged];
        _segmentedControl.tintColor = [LLThemeManager shared].primaryColor;
    }
    return _segmentedControl;
}

- (UITextField *)searchTextField {
    if (!_searchTextField) {
        _searchTextField = [LLFactory getTextField];
        _searchTextField.placeholder = @"Search key";
        _searchTextField.delegate = self;
        _searchTextField.font = [UIFont systemFontOfSize:14];
        _searchTextField.textColor = [LLThemeManager shared].primaryColor;
        _searchTextField.backgroundColor = [LLThemeManager shared].containerColor;
        _searchTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
        _searchTextField.layer.cornerRadius = 4;
        _searchTextField.layer.masksToBounds = YES;
        _searchTextField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kLLGeneralMargin, 1)];
        _searchTextField.leftViewMode = UITextFieldViewModeAlways;
        [_searchTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    }
    return _searchTextField;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [LLFactory getTableView:self.view frame:CGRectZero delegate:self];
        _tableView.backgroundColor = [LLThemeManager shared].backgroundColor;
        _tableView.tableFooterView = [UIView new];
        _tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    }
    return _tableView;
}

- (UILabel *)tipsLabel {
    if (!_tipsLabel) {
        _tipsLabel = [LLFactory getLabel:nil frame:CGRectZero text:nil font:12 textColor:[LLThemeManager shared].primaryColor];
    }
    return _tipsLabel;
}

- (NSMutableArray<LLNetworkMockEditItem *> *)jsonItems {
    if (!_jsonItems) {
        _jsonItems = [[NSMutableArray alloc] init];
    }
    return _jsonItems;
}

- (NSMutableArray<LLNetworkMockEditItem *> *)filteredJsonItems {
    if (!_filteredJsonItems) {
        _filteredJsonItems = [[NSMutableArray alloc] init];
    }
    return _filteredJsonItems;
}

@end
