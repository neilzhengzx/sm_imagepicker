//
//  CACameraController.h
//  iBook
//
//  Created by lh on 14-5-5.
//
//

#import <UIKit/UIKit.h>
#import "TOCropViewController.h"
#if __has_include("RCTBridgeModule.h")
#import "RCTBridgeModule.h"
#else
#import <React/RCTBridgeModule.h>
#endif

@interface CACameraController : NSObject<UINavigationControllerDelegate,UIImagePickerControllerDelegate,TOCropViewControllerDelegate>
{
    UIStatusBarStyle _UIStatusBarStyle;
}
@property (nonatomic, copy) RCTResponseSenderBlock mCallback;
@property int compressedPixel;
@property double quality;
@property int videoQuality;
@property BOOL isEdit;

typedef NS_ENUM(NSInteger, ImagePickerType) {
    ImagePickerImageAlbum,
    ImagePickerImageCamera,
    ImagePickerVideoAlbum,
    ImagePickerVideoCamera
};

- (UIImage *)fixOrientation:(UIImage *)image;

-(void)openCameraView:(ImagePickerType)type allowEdit:(BOOL)allowEdit videoQuality:(int)videoQuality durationLimit:(int)durationLimit compressedPixel:(int)compressedPixel quality:(double)quality callback:(RCTResponseSenderBlock)callback;
@end
