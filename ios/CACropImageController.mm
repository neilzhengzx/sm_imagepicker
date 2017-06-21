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
    [self getEndImage:image];
    [cropViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)cropViewController:(nonnull TOCropViewController *)cropViewController didFinishCancelled:(BOOL)cancelled
{
    [[UIApplication sharedApplication] setStatusBarStyle:_UIStatusBarStyle];
    
    _mCallback(@[@{@"paths":@"", @"initialPaths":@"", @"number":@0}]);
    [cropViewController dismissViewControllerAnimated:YES completion:nil];
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
    
    NSString * path = [[NSTemporaryDirectory()stringByStandardizingPath] stringByAppendingPathComponent:@"photo.jpg"];
    [data writeToFile:path atomically:YES];
    NSString * initialpath = [[NSTemporaryDirectory()stringByStandardizingPath] stringByAppendingPathComponent:@"initialphoto.jpg"];
    [initialData writeToFile:initialpath atomically:YES];
    
    [[UIApplication sharedApplication] setStatusBarStyle:_UIStatusBarStyle];
    
    _mCallback(@[@{@"paths":path, @"initialPaths":initialpath, @"number":@1}]);
}

@end
