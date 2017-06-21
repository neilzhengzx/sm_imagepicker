//
//  CAAlbumController.cpp
//  LocationTest
//
//  Created by lh on 14-5-29.
//
//

#import "CAAlbumController.h"
#import <AssetsLibrary/AssetsLibrary.h>


@interface CAAlbumController ()
{
    UIImage *_image;
}

@end

@implementation CAAlbumController

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    NSLog(@"%@",error.domain);
}

-(void)openAlbumView:(BOOL)allowEdit compressedPixel:(int)compressedPixel quality:(double)quality callback:(RCTResponseSenderBlock)callback
{
    _mCallback = callback;
    ALAuthorizationStatus author = [ALAssetsLibrary authorizationStatus];
    if (author == ALAuthorizationStatusAuthorized || author == ALAuthorizationStatusNotDetermined)
    {
        _compressedPixel = compressedPixel;
        _quality = quality;
        _isEdit = allowEdit;
        
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        
        imagePicker.delegate = self;
        
        _UIStatusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
        [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleDefault];
        
        imagePicker.navigationBar.barStyle = UIBarStyleBlackTranslucent;
        
        imagePicker.navigationBar.barTintColor = [UIColor colorWithRed:20.f/255.0 green:24.0/255.0 blue:38.0/255.0 alpha:1];
        
        imagePicker.navigationBar.tintColor = [UIColor whiteColor];
        
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:imagePicker animated:YES completion:nil];
    }
    else
    {
        _mCallback(@[@{@"paths":@"", @"initialPaths":@"", @"number":@0}]);
        UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"提示"
                                                       message:@"请在设置中开启应用相册权限"
                                                      delegate:self
                                             cancelButtonTitle: @"确定"
                                             otherButtonTitles:nil];
        [alert show];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *imageType;
    imageType = [NSString stringWithFormat:@"UIImagePickerControllerOriginalImage"];
    UIImage *image = [info objectForKey:imageType];
    UIImage *newfixImage = [self fixOrientation:image];
    
    if(_isEdit){
        TOCropViewController *cropViewController = [[TOCropViewController alloc] initWithImage:newfixImage];
        cropViewController.delegate = self;
        [picker dismissViewControllerAnimated:YES completion:^{
            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:cropViewController animated:YES completion:nil];
        }];
    }else{
        [self getEndImage:newfixImage];
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
}

- (UIImage *) scaleFromImage: (UIImage *) image toSize: (CGSize) size
{
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [[UIApplication sharedApplication] setStatusBarStyle:_UIStatusBarStyle];
    
    _mCallback(@[@{@"paths":@"", @"initialPaths":@"", @"number":@0}]);
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (UIImage *)fixOrientation:(UIImage *)srcImg {
    if (srcImg.imageOrientation == UIImageOrientationUp) return srcImg;
    CGAffineTransform transform = CGAffineTransformIdentity;
    switch (srcImg.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, srcImg.size.width, srcImg.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, srcImg.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, srcImg.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }
    
    switch (srcImg.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, srcImg.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, srcImg.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    
    CGContextRef ctx = CGBitmapContextCreate(NULL, srcImg.size.width, srcImg.size.height,
                                             CGImageGetBitsPerComponent(srcImg.CGImage), 0,
                                             CGImageGetColorSpace(srcImg.CGImage),
                                             CGImageGetBitmapInfo(srcImg.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (srcImg.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            CGContextDrawImage(ctx, CGRectMake(0,0,srcImg.size.height,srcImg.size.width), srcImg.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,srcImg.size.width,srcImg.size.height), srcImg.CGImage);
            break;
    }
    
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
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
