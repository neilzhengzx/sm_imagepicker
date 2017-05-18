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

@interface CACameraController : NSObject<UINavigationControllerDelegate,UIImagePickerControllerDelegate>
@property (nonatomic, copy) RCTResponseSenderBlock mCallback;
@property int compressedPixel;
@property double quality;

- (UIImage *)fixOrientation:(UIImage *)image;

-(void)openCameraView:(BOOL)allowEdit compressedPixel:(int)compressedPixel quality:(double)quality callback:(RCTResponseSenderBlock)callback;
@end
