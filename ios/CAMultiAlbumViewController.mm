//
//  CAMultiAlbumViewController.cpp
//  Smobiler
//
//  Created by zzx on 16/8/1.
//
//

#import "CAMultiAlbumViewController.h"
#import "TZImagePickerController.h"
#import "TZImageManager.h"

@interface CAMultiAlbumViewController ()<TZImagePickerControllerDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate,UIAlertViewDelegate> {
    NSMutableArray *_selectedPhotos;
    NSMutableArray *_selectedAssets;
    BOOL _isSelectOriginalPhoto;
    UIStatusBarStyle _UIStatusBarStyle;

}
@end

@implementation CAMultiAlbumViewController

#pragma mark - TZImagePickerController

- (void)reloadAlbumImages
{
    int index = (int)_selectedPhotos.count;
    int index2 = (int)_selectedAssets.count;
    NSString *initialPaths = @"";
    NSString *paths = @"";
    
    if (index != index2){
        if(_mCallback == nil) return;
        _mCallback(@[@{@"paths":@"", @"initialPaths":@"", @"number":@0}]);
        _mCallback = nil;
        return;
    }

    for(int i = 0; i<index; i++)
    {
        UIImage *newfixImage = _selectedPhotos[i];
        //合成缩略图
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

        //ios9.0可获得图片名称
//        PHAssetResource *resource = [[PHAssetResource assetResourcesForAsset:_selectedAssets[i]] firstObject];
//        NSString *fileName = resource.originalFilename;
        NSString *name = [self createUUID];
        NSString *initailname = [self createUUID];
        
        NSString * path = [[NSString alloc] initWithFormat:@"%@/%@%@", str, name, @".jpg" ];
        [data writeToFile:path atomically:YES];
        
        NSString * initialpath = [[NSString alloc] initWithFormat:@"%@/%@%@", str, initailname, @".jpg" ];
        [initialData writeToFile:initialpath atomically:YES];
        
        paths = [[NSString alloc] initWithFormat:@"%@%@%@", paths, path, @",*"];
        initialPaths = [[NSString alloc] initWithFormat:@"%@%@%@", initialPaths, initialpath, @",*" ];
    }
    
    if(_mCallback == nil) return;
    _mCallback(@[@{@"paths":paths, @"initialPaths":initialPaths, @"number":[NSNumber numberWithInt:index]}]);
    _mCallback = nil;
}

- (void)pushImagePickerController:(int)_index compressedPixel:(int)compressedPixel quality:(double)quality callback:(RCTResponseSenderBlock)callback
{
    _mCallback = callback;
    _selectedPhotos = [NSMutableArray array];
    _selectedAssets = [NSMutableArray array];
    
    _compressedPixel = compressedPixel;
    _quality = quality;
    
    TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:_index delegate:self];
    
#pragma mark - 四类个性化设置，这些参数都可以不传，此时会走默认设置
    imagePickerVc.isSelectOriginalPhoto = _isSelectOriginalPhoto;
    
    // 1.如果你需要将拍照按钮放在外面，不要传这个参数
    imagePickerVc.selectedAssets = _selectedAssets; // optional, 可选的
    imagePickerVc.allowTakePicture = YES; // 在内部显示拍照按钮
    
    // 2. Set the appearance
    // 2. 在这里设置imagePickerVc的外观
    // imagePickerVc.navigationBar.barTintColor = [UIColor greenColor];
    // imagePickerVc.oKButtonTitleColorDisabled = [UIColor lightGrayColor];
    // imagePickerVc.oKButtonTitleColorNormal = [UIColor greenColor];
    
    // 3. Set allow picking video & photo & originalPhoto or not
    // 3. 设置是否可以选择视频/图片/原图
    imagePickerVc.allowPickingVideo = NO;
    imagePickerVc.allowPickingImage = YES;
    imagePickerVc.allowPickingOriginalPhoto = NO;
    
    // 4. 照片排列按修改时间升序
    imagePickerVc.sortAscendingByModificationDate = YES;
#pragma mark - 到这里为止
    
    // You can get the photos by block, the same as by delegate.
    // 你可以通过block或者代理，来得到用户选择的照片.
    [imagePickerVc setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto)
     {
         _selectedPhotos = [NSMutableArray arrayWithArray:photos];
         _selectedAssets = [NSMutableArray arrayWithArray:assets];
         _isSelectOriginalPhoto = isSelectOriginalPhoto;
        [[UIApplication sharedApplication] setStatusBarStyle:_UIStatusBarStyle];

        [self reloadAlbumImages];
    }];
    
    [imagePickerVc setImagePickerControllerDidCancelHandle:^
     {
         [[UIApplication sharedApplication] setStatusBarStyle:_UIStatusBarStyle];
         
         if(_mCallback == nil) return;
         _mCallback(@[@{@"paths":@"", @"initialPaths":@"", @"number":@0}]);
         _mCallback = nil;
     }];
    
    _UIStatusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
    [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleDefault];
    
    imagePickerVc.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    
    imagePickerVc.navigationBar.barTintColor = [UIColor colorWithRed:20.f/255.0 green:24.0/255.0 blue:38.0/255.0 alpha:1];
    
    imagePickerVc.navigationBar.tintColor = [UIColor whiteColor];
    
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:imagePickerVc animated:YES completion:nil];

}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) { // 去设置界面，开启相机访问权限
        if (iOS8Later) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        } else {
            // [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=Privacy&path=Photos"]];
        }
    }
}

#pragma mark - AlbumImageModify

- (UIImage *) scaleFromImage: (UIImage *) image toSize: (CGSize) size
{
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
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
