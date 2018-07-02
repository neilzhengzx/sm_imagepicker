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
@property int imageCount;
@property int numberLimit;
@property NSString *imagePaths;
@property NSString *initalImagePaths;

- (UIImage *)fixOrientation:(UIImage *)image;

-(void)openCameraView:(int)numberLimit compressedPixel:(int)compressedPixel quality:(double)quality callback:(RCTResponseSenderBlock)callback;
@end
