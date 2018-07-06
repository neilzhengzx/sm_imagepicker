//
//  KKTextTool.m
//  WWImageEdit
//
//  Created by 邬维 on 2017/1/18.
//  Copyright © 2017年 kook. All rights reserved.
//

#import "KKTextTool.h"
#import "KKTextView.h"

@interface KKTextTool()<UITextViewDelegate>

@end

@implementation KKTextTool{

    UIImage *_originalImage;    //原始图片
    UIView *_workingView;       //上层工作区
    UIView *_textMenuView;      //底部工具
    UITextView *_textEditView;  //文字编辑view
    UISlider *_colorSlider;
    
    UIColor *_textColor;
}

#pragma -mark KKImageToolProtocol
+ (UIImage*)defaultIconImage{
    return [UIImage imageNamed:@"ToolText"];
}

+ (NSString*)defaultTitle{
    return @"文本";
}

+ (NSUInteger)orderNum{
    return KKToolIndexNumberFifth;
}

#pragma mark- implementation
- (void)setup
{
    _originalImage = self.editor.imageView.image;
    
    [self.editor fixZoomScaleWithAnimated:YES];
    
    _textMenuView = [[UIView alloc] initWithFrame:self.editor.menuView.frame];
    _textMenuView.backgroundColor = self.editor.menuView.backgroundColor;

    [self.editor.view addSubview:_textMenuView];
    
    _workingView = [[UIView alloc] initWithFrame:[self.editor.view convertRect:self.editor.imageView.frame fromView:self.editor.imageView.superview]];
    _workingView.clipsToBounds = YES;
    [self.editor.view addSubview:_workingView];
    
    self.selectedTextView = nil;
    _textColor = [UIColor blackColor];
    [self setMenu];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeText) name:kTextViewActiveViewDidTapNotification object:nil];
    
    _textMenuView.transform = CGAffineTransformMakeTranslation(0, self.editor.view.height-_textMenuView.top);
    [UIView animateWithDuration:kImageToolAnimationDuration
                     animations:^{
                         _textMenuView.transform = CGAffineTransformIdentity;
                     }];
}

- (void)cleanup
{
    [self.editor resetZoomScaleWithAnimated:YES];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
  
    [_workingView removeFromSuperview];
    [_textEditView removeFromSuperview];
    
    [UIView animateWithDuration:kImageToolAnimationDuration
                     animations:^{
                         _textMenuView.transform = CGAffineTransformMakeTranslation(0, self.editor.view.height-_textMenuView.top);
                     }
                     completion:^(BOOL finished) {
                         [_textMenuView removeFromSuperview];
                     }];
}

- (void)executeWithCompletionBlock:(void (^)(UIImage *, NSError *, NSDictionary *))completionBlock
{
    [KKTextView setActiveTextView:nil];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImage *image = [self buildImage:_originalImage];
            completionBlock(image, nil, nil);
        });
   
}

#pragma mark- click Action
- (void)addNewText
{
    self.selectedTextView = nil;
    [self showTextEditView:@""];
    [self setNavigationItem:YES];
    
}

- (void)changeText{
    [self showTextEditView:[_selectedTextView getLableText]];
    [self setNavigationItem:YES];
}

- (void)textSaveBtn{
    [_textEditView resignFirstResponder];
    [self setNavigationItem:NO];
    
    
    
    //修改还是添加
    if (self.selectedTextView) {
        [_selectedTextView setLableText:_textEditView.text];
    }else{
        if ([_textEditView.text isEqualToString:@""]) {
            return;
        }
        KKTextView *view = [[KKTextView alloc] initWithTool:self];
        view.center = CGPointMake(_workingView.width/2, _workingView.height/2);
        [view setLableText:_textEditView.text];
        [view setLableTextColor:_textColor];
        [_workingView addSubview:view];
        [KKTextView setActiveTextView:view];
        self.selectedTextView = view;
    }    
}

- (void)textCancelBtn{
    [self setNavigationItem:NO];
}

#pragma mark-
- (UIImage*)buildImage:(UIImage*)image
{
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    
    [image drawAtPoint:CGPointZero];
    
    CGFloat scale = image.size.width / _workingView.width;
    CGContextScaleCTM(UIGraphicsGetCurrentContext(), scale, scale);
    [_workingView.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *tmp = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return tmp;
}

- (void)setMenu{
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(20, 20, 40, 40)];
    btn.backgroundColor = [UIColor redColor];
    [btn setTitle:@"添加" forState:UIControlStateNormal];
    btn.titleLabel.textColor = [UIColor whiteColor];
    btn.titleLabel.font = [UIFont systemFontOfSize:15];
    [btn addTarget:self action:@selector(addNewText) forControlEvents:UIControlEventTouchUpInside];
    [_textMenuView addSubview:btn];
    
    CGFloat W = 70;
    
    _colorSlider = [self defaultSliderWithWidth:_textMenuView.width - W - 20];
    _colorSlider.left = 80;
    _colorSlider.top  = 20;
    [_colorSlider addTarget:self action:@selector(colorSliderDidChange:) forControlEvents:UIControlEventValueChanged];
    _colorSlider.backgroundColor = [UIColor colorWithPatternImage:[self colorSliderBackground]];
    _colorSlider.value = 0;
    [_textMenuView addSubview:_colorSlider];
}

- (void)setNavigationItem:(BOOL)isEdit{

    if(isEdit){
        UINavigationItem *item  = self.editor.navigationItem;
        item.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStyleDone target:self action:@selector(textSaveBtn)];
        item.leftBarButtonItem  = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(textCancelBtn)];
        
    }else{
        //修改UINavigationItem
        NSNotification *n = [NSNotification notificationWithName:KTextEditDoneNotification object:self userInfo:nil];
        [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:n waitUntilDone:NO];
        
        [UIView animateWithDuration:kImageToolAnimationDuration
                         animations:^{
                             _textEditView.transform = CGAffineTransformMakeTranslation(0, 600);
                         }
                         completion:^(BOOL finished) {
                             [_textEditView removeFromSuperview];
                         }];
    }
}

//文字编辑view
- (void)showTextEditView:(NSString *)text{
    if (!_textEditView) {
        _textEditView = [[UITextView alloc] initWithFrame:CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width,800)];
        UIColor *textViewBgColor = [UIColor blackColor];
        _textEditView.backgroundColor = [textViewBgColor colorWithAlphaComponent:0.85];
        [_textEditView setTextColor:[UIColor whiteColor]];
        [_textEditView setFont:[UIFont systemFontOfSize:30]];
        [_textEditView setReturnKeyType:UIReturnKeyDone];
        
        _textEditView.delegate = self;
    }
    [_textEditView setText:text];
    [self.editor.view addSubview:_textEditView];
    _textEditView.transform = CGAffineTransformMakeTranslation(0, 600);
    [UIView animateWithDuration:kImageToolAnimationDuration
                     animations:^{
                         _textEditView.transform = CGAffineTransformIdentity;
                     }];
    [_textEditView becomeFirstResponder];
}

#pragma mark- UITextViewDelegate
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"]) {
        [self textSaveBtn];
        return NO;
    }
    return YES;
}

#pragma mark- other

- (UISlider*)defaultSliderWithWidth:(CGFloat)width
{
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, width, 34)];
    
    [slider setMaximumTrackImage:[UIImage new] forState:UIControlStateNormal];
    [slider setMinimumTrackImage:[UIImage new] forState:UIControlStateNormal];
    [slider setThumbImage:[UIImage new] forState:UIControlStateNormal];
    slider.thumbTintColor = [UIColor whiteColor];
    
    return slider;
}

- (UIImage*)colorSliderBackground
{
    CGSize size = _colorSlider.frame.size;
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect frame = CGRectMake(5, (size.height-10)/2, size.width-10, 5);
    CGPathRef path = [UIBezierPath bezierPathWithRoundedRect:frame cornerRadius:5].CGPath;
    CGContextAddPath(context, path);
    CGContextClip(context);
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGFloat components[] = {
        0.0f, 0.0f, 0.0f, 1.0f,
        1.0f, 1.0f, 1.0f, 1.0f,
        1.0f, 0.0f, 0.0f, 1.0f,
        1.0f, 1.0f, 0.0f, 1.0f,
        0.0f, 1.0f, 0.0f, 1.0f,
        0.0f, 1.0f, 1.0f, 1.0f,
        0.0f, 0.0f, 1.0f, 1.0f
    };
    
    size_t count = sizeof(components)/ (sizeof(CGFloat)* 4);
    CGFloat locations[] = {0.0f, 0.9/3.0, 1/3.0, 1.5/3.0, 2/3.0, 2.5/3.0, 1.0};
    
    CGPoint startPoint = CGPointMake(5, 0);
    CGPoint endPoint = CGPointMake(size.width-5, 0);
    
    CGGradientRef gradientRef = CGGradientCreateWithColorComponents(colorSpaceRef, components, locations, count);
    
    CGContextDrawLinearGradient(context, gradientRef, startPoint, endPoint, kCGGradientDrawsAfterEndLocation);
    
    UIImage *tmp = UIGraphicsGetImageFromCurrentImageContext();
    
    CGGradientRelease(gradientRef);
    CGColorSpaceRelease(colorSpaceRef);
    
    UIGraphicsEndImageContext();
    
    return tmp;
}

- (UIColor*)colorForValue:(CGFloat)value
{
    if(value<1/3.0){
        return [UIColor colorWithWhite:value/0.3 alpha:1];
    }
    return [UIColor colorWithHue:((value-1/3.0)/0.7)*2/3.0 saturation:1 brightness:1 alpha:1];
}

- (void)colorSliderDidChange:(UISlider*)sender
{
    _textColor = [self colorForValue:_colorSlider.value];
    _colorSlider.thumbTintColor = _textColor;
    if (self.selectedTextView) {
        [_selectedTextView setLableTextColor:_textColor];
    }
}

@end
