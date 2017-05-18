//
//  CAMultiAlbumViewController.h
//  Smobiler
//
//  Created by zzx on 16/8/1.
//
//

#ifndef CAMultiAlbumViewController_h
#define CAMultiAlbumViewController_h
#import <UIKit/UIKit.h>
#if __has_include("RCTBridgeModule.h")
#import "RCTBridgeModule.h"
#else
#import <React/RCTBridgeModule.h>
#endif


@interface CAMultiAlbumViewController : NSObject
@property (nonatomic, copy) RCTResponseSenderBlock mCallback;
@property int compressedPixel;
@property double quality;

-(void)pushImagePickerController:(int)_index compressedPixel:(int)compressedPixel quality:(double)quality callback:(RCTResponseSenderBlock)callback;
@end

#endif /* CAMultiAlbumViewController_h */
