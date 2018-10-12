//
//  CACameraController.m
//  iBook
//
//  Created by lh on 14-5-5.
//
//

#import "CACameraController.h"
#import <AVFoundation/AVCaptureDevice.h>
#import <AVFoundation/AVMediaFormat.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface CACameraController ()
{
    UIImage *_image;
}

@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (strong, nonatomic) UIImagePickerController *imagepickerController;

@end

@implementation CACameraController

-(void)openCameraView:(ImagePickerType)type allowEdit:(BOOL)allowEdit videoQuality:(int)videoQuality durationLimit:(int)durationLimit compressedPixel:(int)compressedPixel quality:(double)quality callback:(RCTResponseSenderBlock)callback
{
    _mCallback = callback;
 
    _compressedPixel = compressedPixel;
    _quality = quality;
    _isEdit = allowEdit;
    _videoQuality = videoQuality;
    
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    
    _statusBarHidden = [UIApplication sharedApplication].statusBarHidden;
    _UIStatusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
    if(type == ImagePickerImageCamera || type == ImagePickerVideoCamera){
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        
        if(type == ImagePickerVideoCamera){
            imagePicker.videoQuality = UIImagePickerControllerQualityTypeHigh;
            if(durationLimit > 0) imagePicker.videoMaximumDuration = durationLimit;
            imagePicker.mediaTypes = @[(NSString *)kUTTypeMovie];
        }else{
            imagePicker.mediaTypes = @[(NSString *)kUTTypeImage];
        }
    }else if(type == ImagePickerImageAlbum || type == ImagePickerVideoAlbum){
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        
        if(type == ImagePickerVideoAlbum) imagePicker.mediaTypes = @[(NSString *)kUTTypeMovie];
        else imagePicker.mediaTypes = @[(NSString *)kUTTypeImage];
        
        [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleDefault];
        
        imagePicker.navigationBar.barStyle = UIBarStyleBlackTranslucent;
        
        imagePicker.navigationBar.barTintColor = [UIColor colorWithRed:20.f/255.0 green:24.0/255.0 blue:38.0/255.0 alpha:1];
        
        imagePicker.navigationBar.tintColor = [UIColor whiteColor];
    }
    
    imagePicker.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePicker.delegate= self;
    
    _imagepickerController = imagePicker;
    self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:imagePicker.view.bounds];
    self.activityIndicatorView.center = imagePicker.view.center;
    [self.activityIndicatorView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.activityIndicatorView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    
    // Check permissions
    void (^showPickerViewController)() = ^void() {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:imagePicker animated:YES completion:^{
                if(_UIStatusBarStyle != [[UIApplication sharedApplication] statusBarStyle]){
                    [[UIApplication sharedApplication] setStatusBarStyle:_UIStatusBarStyle];
                }
            }];
        });
    };
    
    if (type == ImagePickerVideoCamera || type == ImagePickerImageCamera) {
        [self checkCameraPermissions:^(BOOL granted) {
            if (!granted) {
                [self permissionNotGranted];
                return;
            }
            showPickerViewController();
        }];
    }
    else { // RNImagePickerTargetLibrarySingleImage
        [self checkPhotosPermissions:^(BOOL granted) {
            if (!granted) {
                [self permissionNotGranted];
                return;
            }
            showPickerViewController();
        }];
    }
}

- (void)permissionNotGranted
{
    if(_mCallback == nil) return;
    _mCallback(@[@{@"paths":@"", @"initialPaths":@"", @"number":@0}]);
    _mCallback = nil;
    UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"提示"
                                                   message:@"请在设置中开启应用相册权限"
                                                  delegate:self
                                         cancelButtonTitle: @"确定"
                                         otherButtonTitles:nil];
    [alert show];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if([mediaType isEqualToString:(NSString *)kUTTypeImage]){
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        UIImage *newfixImage = [self fixOrientation:image];
        
        if(_isEdit){
            KKImageEditorViewController *editor = [[KKImageEditorViewController alloc] initWithImage:image delegate:self];
            [picker pushViewController:editor animated:YES];
        }else{
            [self getEndImage:newfixImage];
            [picker dismissViewControllerAnimated:YES completion:^{
                if(_UIStatusBarStyle != [[UIApplication sharedApplication] statusBarStyle]){
                    [[UIApplication sharedApplication] setStatusBarStyle:_UIStatusBarStyle];
                }
            }];
        }
    }else{
        NSURL *videoURL = info[UIImagePickerControllerMediaURL];
        [self loadActivityIndicatorView];
        [self getEndVideo:videoURL completion:^(NSString *savedPath, NSString *initPath){
            [self removeActivityIndicatorView];
            if(_mCallback != nil){
                _mCallback(@[@{@"paths":savedPath, @"initialPaths":initPath, @"number":@1}]);
                _mCallback = nil;
            }
            [picker dismissViewControllerAnimated:YES completion:^{
                if(_UIStatusBarStyle != [[UIApplication sharedApplication] statusBarStyle]){
                    [[UIApplication sharedApplication] setStatusBarStyle:_UIStatusBarStyle];
                }
            }];
        }];
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
    if(_mCallback == nil) return;
    _mCallback(@[@{@"paths":@"", @"initialPaths":@"", @"number":@0}]);
    _mCallback = nil;
    [picker dismissViewControllerAnimated:YES completion:^{
        if(_UIStatusBarStyle != [[UIApplication sharedApplication] statusBarStyle]){
            [[UIApplication sharedApplication] setStatusBarStyle:_UIStatusBarStyle];
        }
    }];
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

#pragma mark - EditImage Delegate -
- (void)imageDidFinishEdittingWithImage:(UIImage*)image
{
    [self getEndImage:image];
    
    if(_statusBarHidden != [UIApplication sharedApplication].statusBarHidden){
        [UIApplication sharedApplication].statusBarHidden = _statusBarHidden;
    }
    if(_UIStatusBarStyle != [[UIApplication sharedApplication] statusBarStyle]){
        [[UIApplication sharedApplication] setStatusBarStyle:_UIStatusBarStyle];
    }
}

- (void)imageDidFinishEdittingCancel:(UIImage*)image
{
    if(_statusBarHidden != [UIApplication sharedApplication].statusBarHidden){
        [UIApplication sharedApplication].statusBarHidden = _statusBarHidden;
    }
    if(_UIStatusBarStyle != [[UIApplication sharedApplication] statusBarStyle]){
        [[UIApplication sharedApplication] setStatusBarStyle:_UIStatusBarStyle];
    }
    if(_mCallback == nil) return;
    _mCallback(@[@{@"paths":@"", @"initialPaths":@"", @"number":@0}]);
    _mCallback = nil;
}

#pragma mark - getImage -
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
    
    if(_mCallback == nil) return;
    _mCallback(@[@{@"paths":path, @"initialPaths":initialpath, @"number":@1}]);
    _mCallback = nil;
}

- (void)getEndVideo:(NSURL*)videoURL completion:(void (^)(NSString *savedPath, NSString *initPath))completion
{
    NSData *data = [NSData dataWithContentsOfURL:videoURL];
    
    NSString *str = [NSTemporaryDirectory()stringByStandardizingPath];
    NSString *name = [self createUUID];
    NSString *initailname = [self createUUID];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSString * initialpath = [[NSString alloc] initWithFormat:@"%@/%@%@", str, initailname, @".mp4" ];
    [fm createFileAtPath:initialpath contents:data attributes:nil];
    [data writeToFile:initialpath atomically:YES];
    
    if(_videoQuality == 0){
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(initialpath, initialpath);
            }
        });
        return;
    }
    
    NSString * path = [[NSString alloc] initWithFormat:@"%@/%@%@", str, name, @".mp4" ];
    
    AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:videoAsset  presetName:[self getVideoQulity]];
    session.outputURL = [NSURL fileURLWithPath:path];
    session.shouldOptimizeForNetworkUse = true;
    NSArray *supportedTypeArray = session.supportedFileTypes;
    if ([supportedTypeArray containsObject:AVFileTypeMPEG4]) {
        session.outputFileType = AVFileTypeMPEG4;
    } else if (supportedTypeArray.count == 0) {
        NSLog(@"No supported file types");
        return;
    } else {
        session.outputFileType = [supportedTypeArray objectAtIndex:0];
    }
    
    [session exportAsynchronouslyWithCompletionHandler:^{
        if ([session status] == AVAssetExportSessionStatusCompleted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion([session.outputURL path], initialpath);
                }
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(initialpath, initialpath);
                }
            });
        }
    }];
    
}

- (NSString *)getVideoQulity
{
    switch (_videoQuality) {
        case 1:
            return AVAssetExportPresetLowQuality;
        case 2:
            return AVAssetExportPresetMediumQuality;
        case 3:
            return AVAssetExportPresetHighestQuality;
        case 4:
            return AVAssetExportPreset640x480;
        case 5:
            return AVAssetExportPreset960x540;
        case 6:
            return AVAssetExportPreset1280x720;
        case 7:
            return AVAssetExportPreset1920x1080;
        default:
            return AVAssetExportPreset1280x720;
    }
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

- (void)checkCameraPermissions:(void(^)(BOOL granted))callback
{
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusAuthorized) {
        callback(YES);
        return;
    } else if (status == AVAuthorizationStatusNotDetermined){
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            callback(granted);
            return;
        }];
    } else {
        callback(NO);
    }
}

- (void)checkPhotosPermissions:(void(^)(BOOL granted))callback
{
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusAuthorized) {
        callback(YES);
        return;
    } else if (status == PHAuthorizationStatusNotDetermined) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (status == PHAuthorizationStatusAuthorized) {
                callback(YES);
                return;
            }
            else {
                callback(NO);
                return;
            }
        }];
    }
    else {
        callback(NO);
    }
}

// 加载视频转码的动画
- (void)loadActivityIndicatorView {
    if ([self.activityIndicatorView isAnimating]) {
        [self.activityIndicatorView stopAnimating];
        [self.activityIndicatorView removeFromSuperview];
    }
    
    [_imagepickerController.view addSubview:self.activityIndicatorView];
    [self.activityIndicatorView startAnimating];
}

// 移除视频转码的动画
- (void)removeActivityIndicatorView {
    [self.activityIndicatorView removeFromSuperview];
    [self.activityIndicatorView stopAnimating];
}
@end
