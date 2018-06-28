//
//  CACameraController.m
//  iBook
//
//  Created by lh on 14-5-5.
//
//

#import "CAMultiCameraController.h"
#import <AVFoundation/AVCaptureDevice.h>
#import <AVFoundation/AVMediaFormat.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface CAMultiCameraController ()
{
    UIImage *_image;
}

@property (strong, nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (strong, nonatomic) UIImagePickerController *imagepickerController;

@end

@implementation CAMultiCameraController

-(void)openCameraView:(RCTResponseSenderBlock)callback
{
    _mCallback = callback;
    
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePicker.mediaTypes = @[(NSString *)kUTTypeImage];
    
    imagePicker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
    imagePicker.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
    imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
    imagePicker.showsCameraControls = NO;
    imagePicker.navigationBarHidden = YES;
    imagePicker.toolbarHidden = YES;
    
    CALayer *viewLayer = imagePicker.view.layer;
    [viewLayer setBounds:CGRectMake(0.0, 0.0, 125.0, 132.0)];
    [viewLayer setBackgroundColor:[UIColor blueColor].CGColor];
    [viewLayer setContentsRect:CGRectMake(0.0, 0.0, 115.0, 112.0)];
    [viewLayer setBorderWidth:.0];
    [viewLayer setBorderColor:[UIColor whiteColor].CGColor];
    
    //设置图层的frame
    CGFloat ScreenW = imagePicker.cameraOverlayView.frame.size.width;
    CGFloat ScreenH = imagePicker.cameraOverlayView.frame.size.height;
    UIView *overlayView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenW, ScreenH)];
    
    UIView *headView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenW, 40)];
    headView.backgroundColor = [UIColor blackColor];

    //切换镜头按钮
    UIButton *changeButton = [[UIButton alloc] initWithFrame:CGRectMake(ScreenW - 60, 0, 60, 40)];
    [changeButton addTarget:self action:@selector(clickchangeButton) forControlEvents:UIControlEventTouchUpInside];
    UIImage *changeImage= [UIImage imageNamed:[@"TZImagePickerController.bundle" stringByAppendingPathComponent:@"camera-switch.png"]];
    [changeButton setImage:changeImage forState:UIControlStateNormal];
    [headView addSubview:changeButton];
    //闪光灯
    UIButton *lightButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 40)];
    [lightButton addTarget:self action:@selector(clickLightButton:) forControlEvents:UIControlEventTouchUpInside];
    UIImage *lightImage= [UIImage imageNamed:[@"TZImagePickerController.bundle" stringByAppendingPathComponent:@"flashOffIcon.png"]];
    [lightButton setImage:lightImage forState:UIControlStateNormal];
    [headView addSubview:lightButton];
    [overlayView addSubview:headView];
    
    CGRect rect = CGRectMake(0, ScreenH - 100, ScreenW, 100);
    UIView *bottomView = [[UIView alloc] initWithFrame:rect];
    bottomView.backgroundColor = [UIColor blackColor];
    [imagePicker.cameraOverlayView addSubview:bottomView];
    //拍摄按钮
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(ScreenW/2 - 30, 20, 60, 60)];
    UIImage *clickImage= [UIImage imageNamed:[@"TZImagePickerController.bundle" stringByAppendingPathComponent:@"btn_prisma_takephoto.png"]];
    [button setImage:clickImage forState:UIControlStateNormal];
    [button addTarget:self action:@selector(clickPHOTO) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:button];
    //取消按钮
    UIButton *cancleButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 0, 60, 100)];
    [cancleButton addTarget:self action:@selector(clickBackButton) forControlEvents:UIControlEventTouchUpInside];
    [cancleButton setTitle:@"取消" forState:UIControlStateNormal];
    [cancleButton setTintColor:[UIColor whiteColor]];
    [bottomView addSubview:cancleButton];
    //完成按钮
    UIButton *completeButton = [[UIButton alloc] initWithFrame:CGRectMake(ScreenW - 80, 0, 60, 100)];
    [completeButton addTarget:self action:@selector(clickBackButton) forControlEvents:UIControlEventTouchUpInside];
    [completeButton setTitle:@"完成" forState:UIControlStateNormal];
    [completeButton setTintColor:[UIColor whiteColor]];
    [bottomView addSubview:completeButton];
    
    [overlayView addSubview:bottomView];
    
    imagePicker.cameraOverlayView = overlayView;
    
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
    
    [self checkCameraPermissions:^(BOOL granted) {
        if (!granted) {
            [self permissionNotGranted];
            return;
        }
        showPickerViewController();
    }];
}

#pragma mark -取消按钮
- (void) clickBackButton {
    if(_mCallback == nil) return;
    _mCallback(@[@{@"paths":@"", @"initialPaths":@"", @"number":@0}]);
    _mCallback = nil;
    [ _imagepickerController dismissViewControllerAnimated:YES completion:^{
        if(_UIStatusBarStyle != [[UIApplication sharedApplication] statusBarStyle]){
            [[UIApplication sharedApplication] setStatusBarStyle:_UIStatusBarStyle];
        }
    }];
}

#pragma mark -完成按钮
- (void)clickCompleteButton {
    if(_mCallback == nil) return;
    _mCallback(@[@{@"paths":@"", @"initialPaths":@"", @"number":@0}]);
    _mCallback = nil;
    [ _imagepickerController dismissViewControllerAnimated:YES completion:^{
        if(_UIStatusBarStyle != [[UIApplication sharedApplication] statusBarStyle]){
            [[UIApplication sharedApplication] setStatusBarStyle:_UIStatusBarStyle];
        }
    }];
}

#pragma mark -镜头切换
- (void) clickchangeButton {
    if(_imagepickerController.cameraDevice == UIImagePickerControllerCameraDeviceRear){
        _imagepickerController.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    }else{
        _imagepickerController.cameraDevice = UIImagePickerControllerCameraDeviceRear;
    }
}

#pragma mark - 闪光灯的状态
- (void) clickLightButton:(UIButton *)sender {
    switch (_imagepickerController.cameraFlashMode) {
        case UIImagePickerControllerCameraFlashModeOff:{
            _imagepickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeAuto;
            UIImage *clickImage1= [UIImage imageNamed:[@"TZImagePickerController.bundle" stringByAppendingPathComponent:@"flashAutoIcon.png"]];
            [sender setImage:clickImage1 forState:UIControlStateNormal];
            break;
        }
        case UIImagePickerControllerCameraFlashModeAuto:{
            _imagepickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeOn;
            UIImage *clickImage2 = [UIImage imageNamed:[@"TZImagePickerController.bundle" stringByAppendingPathComponent:@"flashOnIcon.png"]];
            [sender setImage:clickImage2 forState:UIControlStateNormal];
            break;
        }
        case UIImagePickerControllerCameraFlashModeOn:{
            _imagepickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
            UIImage *clickImage3 = [UIImage imageNamed:[@"TZImagePickerController.bundle" stringByAppendingPathComponent:@"flashOffIcon.png"]];
            [sender setImage:clickImage3 forState:UIControlStateNormal];
            break;
        }
        default:{
            _imagepickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
            UIImage *clickImage4 = [UIImage imageNamed:[@"TZImagePickerController.bundle" stringByAppendingPathComponent:@"flashOffIcon.png"]];
            [sender setImage:clickImage4 forState:UIControlStateNormal];
            break;
        }
    }
}

#pragma mark -拍照按钮
- (void)clickPHOTO {
    [_imagepickerController takePicture];
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
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        UIImage *newfixImage = [self fixOrientation:image];
        
        UIImageWriteToSavedPhotosAlbum(newfixImage, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    }
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    NSLog(@"image = %@, error = %@, contextInfo = %@", image, error, contextInfo);
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
@end
