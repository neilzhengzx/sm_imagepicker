//
//  CAAlbumController.h
//  LocationTest
//
//  Created by lh on 14-5-29.
//
//

#ifndef __LocationTest__CAAlbumController__
#define __LocationTest__CAAlbumController__

#import <UIKit/UIKit.h>
#import "TOCropViewController.h"
#if __has_include("RCTBridgeModule.h")
#import "RCTBridgeModule.h"
#else
#import <React/RCTBridgeModule.h>
#endif

@interface CAAlbumController : NSObject<UINavigationControllerDelegate,UIImagePickerControllerDelegate,TOCropViewControllerDelegate>
{
    UIStatusBarStyle _UIStatusBarStyle;
}

@property (nonatomic, copy) RCTResponseSenderBlock mCallback;
@property int compressedPixel;
@property double quality;
@property BOOL isEdit;

-(void)openAlbumView:(BOOL)allowEdit compressedPixel:(int)compressedPixel quality:(double)quality callback:(RCTResponseSenderBlock)callback;
@end
#endif /* defined(__LocationTest__CAAlbumController__) */
