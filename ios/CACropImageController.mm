//
//  CACropImageController.m
//  RNSmImagepicker
//
//  Created by zzx on 2017/6/21.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#include "CACropImageController.h"


@interface CACropImageController ()
{
    UIImage *_image;
}

@end

@implementation CACropImageController

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    NSLog(@"%@",error.domain);
}

-(void)openCropImageView:(NSString *)url compressedPixel:(int)compressedPixel quality:(double)quality callback:(RCTResponseSenderBlock)callback
{
    if(url.length == 0){
        callback(@[@{@"paths":@"", @"initialPaths":@"", @"number":@0}]);
        return;
    }
    _mCallback = callback;
    NSURL *imageUrl = [NSURL URLWithString: url];
    UIImage *imagea = [UIImage imageWithData: [NSData dataWithContentsOfURL:imageUrl]];
    
    TOCropViewController *cropViewController = [[TOCropViewController alloc] initWithImage:imagea];
    cropViewController.delegate = self;
    _UIStatusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
    [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleLightContent];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:cropViewController animated:YES completion:nil];
}

- (UIImage *) scaleFromImage: (UIImage *) image toSize: (CGSize) size
{
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

#pragma mark - Cropper Delegate -
- (void)cropViewController:(TOCropViewController *)cropViewController didCropToImage:(UIImage *)image withRect:(CGRect)cropRect angle:(NSInteger)angle
{
    [cropViewController dismissViewControllerAnimated:YES completion:^{
        [self getEndImage:image];
        [[UIApplication sharedApplication] setStatusBarStyle:_UIStatusBarStyle];
    }];
}

- (void)cropViewController:(nonnull TOCropViewController *)cropViewController didFinishCancelled:(BOOL)cancelled
{
    if(_mCallback == nil) return;
    _mCallback(@[@{@"paths":@"", @"initialPaths":@"", @"number":@0}]);
    _mCallback = nil;
    [cropViewController dismissViewControllerAnimated:YES completion:^{
        [[UIApplication sharedApplication] setStatusBarStyle:_UIStatusBarStyle];
    }];
}

- (void)getEndImage:(UIImage*)newfixImage
{
    CGSize size ;
    if ([newfixImage size].width>[newfixImage size].height)
    {
        size = CGSizeMake(_compressedPixel, _compressedPixel*([newfixImage size].height/[newfixImage size].width));
    }
    else
    {
        size = CGSizeMake(_compressedPixel*([newfixImage size].width/[newfixImage size].height), _compressedPixel);
    }
    
    UIImage *fiximage = [self scaleFromImage:newfixImage toSize:size];
    
    NSData *data = UIImageJPEGRepresentation(fiximage,_quality);
    NSData *initialData = UIImageJPEGRepresentation(newfixImage,1.0);
    if (size.width * size.height > [newfixImage size].width * [newfixImage size].height)
    {
        data = initialData;
    }
    
    NSString *str = [NSTemporaryDirectory()stringByStandardizingPath];
    NSString *name = [self createUUID];
    NSString *initailname = [self createUUID];
    
    NSString * path = [[NSString alloc] initWithFormat:@"%@/%@%@", str, name, @".jpg" ];
    [data writeToFile:path atomically:YES];
    
    NSString * initialpath = [[NSString alloc] initWithFormat:@"%@/%@%@", str, initailname, @".jpg" ];
    [initialData writeToFile:initialpath atomically:YES];
    
    [[UIApplication sharedApplication] setStatusBarStyle:_UIStatusBarStyle];
    
    if(_mCallback == nil) return;
    _mCallback(@[@{@"paths":path, @"initialPaths":initialpath, @"number":@1}]);
    _mCallback = nil;
}

- (NSString *)createUUID
{
    // Create universally unique identifier (object)
    CFUUIDRef uuidObject = CFUUIDCreate(kCFAllocatorDefault);
    
    // Get the string representation of CFUUID object.
    NSString *uuidStr = (NSString *)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuidObject));
    
    NSMutableString *mstr=[NSMutableString stringWithString:uuidStr];
    
    CFRelease(uuidObject);
    
    NSString *search=@"-";
    NSString *replace=@"";
    
    NSRange substr;
    substr=[mstr rangeOfString:search];
    
    while (substr.location!=NSNotFound) {
        [mstr replaceCharactersInRange:substr withString:replace];
        substr=[mstr rangeOfString:search];
    }
    
    uuidStr = [NSString stringWithString:mstr];
    
    return uuidStr;
}

@end
