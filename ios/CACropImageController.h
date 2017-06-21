//
//  CACropImageController.h
//  RNSmImagepicker
//
//  Created by zzx on 2017/6/21.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#ifndef CACropImageController_h
#define CACropImageController_h

#import <UIKit/UIKit.h>
#import "TOCropViewController.h"
#if __has_include("RCTBridgeModule.h")
#import "RCTBridgeModule.h"
#else
#import <React/RCTBridgeModule.h>
#endif

@interface CACropImageController : NSObject<UINavigationControllerDelegate,UIImagePickerControllerDelegate,TOCropViewControllerDelegate>
{
    UIStatusBarStyle _UIStatusBarStyle;
}

@property (nonatomic, copy) RCTResponseSenderBlock mCallback;
@property int compressedPixel;
@property double quality;
@property BOOL isEdit;

-(void)openCropImageView:(NSString *)url compressedPixel:(int)compressedPixel quality:(double)quality callback:(RCTResponseSenderBlock)callback;
@end
#endif /* CACropImageController_h */
