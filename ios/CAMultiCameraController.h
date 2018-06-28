//
//  CACameraController.h
//  iBook
//
//  Created by lh on 14-5-5.
//
//

#import <UIKit/UIKit.h>
#if __has_include("RCTBridgeModule.h")
#import "RCTBridgeModule.h"
#else
#import <React/RCTBridgeModule.h>
#endif

@interface CAMultiCameraController : NSObject<UINavigationControllerDelegate,UIImagePickerControllerDelegate>
{
    UIStatusBarStyle _UIStatusBarStyle;
}
@property (nonatomic, copy) RCTResponseSenderBlock mCallback;
@property int compressedPixel;
@property double quality;
@property int videoQuality;
@property BOOL isEdit;

- (UIImage *)fixOrientation:(UIImage *)image;

-(void)openCameraView:(RCTResponseSenderBlock)callback;
@end
