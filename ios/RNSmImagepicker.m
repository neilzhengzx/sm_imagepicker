
#import "RNSmImagepicker.h"
#import "CACameraController.h"
#import "CAMultiCameraController.h"
#import "CAMultiAlbumViewController.h"
#import "CACropImageController.h"

@implementation RNSmImagepicker

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE()
      
RCT_EXPORT_METHOD(imageFromCamera:(NSDictionary *)params callback:(RCTResponseSenderBlock)callback)
{
  //imageFromCamera 实现, 需要回传结果用callback(@[XXX]), 数组参数里面就一个NSDictionary元素即可
    [self open:ImagePickerImageCamera params:params callback:callback];
}
      
RCT_EXPORT_METHOD(imageFromCameraAlbum:(NSDictionary *)params callback:(RCTResponseSenderBlock)callback)
{
  //imageFromCameraAlbum 实现, 需要回传结果用callback(@[XXX]), 数组参数里面就一个NSDictionary元素即可
    [self open:ImagePickerImageAlbum params:params callback:callback];
}

RCT_EXPORT_METHOD(videoFromCamera:(NSDictionary *)params callback:(RCTResponseSenderBlock)callback)
{
    //videoFromCamera 实现, 需要回传结果用callback(@[XXX]), 数组参数里面就一个NSDictionary元素即可
    [self open:ImagePickerVideoCamera params:params callback:callback];
}

RCT_EXPORT_METHOD(videoFromAlbum:(NSDictionary *)params callback:(RCTResponseSenderBlock)callback)
{
    //videoFromAlbum 实现, 需要回传结果用callback(@[XXX]), 数组参数里面就一个NSDictionary元素即可
    [self open:ImagePickerVideoAlbum params:params callback:callback];
}


RCT_EXPORT_METHOD(imageFromMultiCamera:(NSDictionary *)params callback:(RCTResponseSenderBlock)callback)
{
    //imageFromMultiCamera 实现, 需要回传结果用callback(@[XXX]), 数组参数里面就一个NSDictionary元素即可
    
    int numberLimit = 3;
    int compressedPixel = 1280;
    double quality = 0.6;
    
    if(params[@"numberLimit"]){
        numberLimit = [params[@"numberLimit"] intValue] > 0 ? [params[@"numberLimit"] intValue] : 3;
    }
    if(params[@"compressedPixel"]){
        compressedPixel = [params[@"compressedPixel"] intValue];
    }
    if(params[@"quality"]){
        quality = [params[@"quality"] doubleValue] / 100;
    }
    
    static CAMultiCameraController *camera = nil;
    if(!camera){
        camera = [[CAMultiCameraController alloc] init];
    }
    [camera openCameraView:numberLimit compressedPixel:compressedPixel quality:quality callback:callback];
}

-(void)open:(ImagePickerType)type params:(NSDictionary *)params callback:(RCTResponseSenderBlock)callback
{
    BOOL isEdit = false;
    int compressedPixel = 1280;
    double quality = 0.6;
    int videoQuality = 6;
    int durationLimit = 15;
    BOOL isScale = false;
    int aspectX = 1.0f;
    int aspectY = 1.0f;
    
    if(params[@"isEdit"]){
        isEdit = [params[@"isEdit"] boolValue];
    }
    if(params[@"compressedPixel"]){
        compressedPixel = [params[@"compressedPixel"] intValue];
    }
    if(params[@"quality"]){
        quality = [params[@"quality"] doubleValue] / 100;
    }
    if(params[@"videoQuality"]){
        videoQuality = [params[@"videoQuality"] intValue];
    }
    if(params[@"videoDurationLimit"]){
        durationLimit = [params[@"videoDurationLimit"] intValue];
    }
    if(params[@"isScale"]){
        isScale = [params[@"isScale"] boolValue];
    }
    if(params[@"aspectX"]){
        aspectX = [params[@"aspectX"] intValue];
    }
    if(params[@"aspectY"]){
        aspectY = [params[@"aspectY"] intValue];
    }
    
    static CACameraController *camera = nil;
    if(!camera){
        camera = [[CACameraController alloc] init];
    }
    [camera openCameraView:type allowEdit:isEdit isScale:isScale aspectX:aspectX aspectY:aspectY videoQuality:videoQuality durationLimit:durationLimit compressedPixel:compressedPixel quality:quality callback:callback];
}
      
RCT_EXPORT_METHOD(multiImage:(NSDictionary *)params callback:(RCTResponseSenderBlock)callback)
{
  //multiImage 实现, 需要回传结果用callback(@[XXX]), 数组参数里面就一个NSDictionary元素即可
//    index = index > 0 ? index : 9;
    int number = 9;
    int compressedPixel = 1280;
    double quality = 0.6;
    if(params[@"number"]){
        number = [params[@"number"] intValue] > 0 ? [params[@"number"] intValue] : 9;
    }
    if(params[@"compressedPixel"]){
        compressedPixel = [params[@"compressedPixel"] intValue];
    }
    if(params[@"quality"]){
        quality = [params[@"quality"] doubleValue] / 100;
    }
    static CAMultiAlbumViewController *album = nil;
    if(!album){
        album = [[CAMultiAlbumViewController alloc] init];
    }
    
    [album pushImagePickerController:number compressedPixel:compressedPixel quality:quality callback:callback];
}

RCT_EXPORT_METHOD(cropImage:(NSDictionary *)params callback:(RCTResponseSenderBlock)callback)
{
    int compressedPixel = 1280;
    double quality = 0.6;
    NSString* url = @"";
    BOOL isScale = false;
    int aspectX = 1.0f;
    int aspectY = 1.0f;
    if(params[@"compressedPixel"]){
        compressedPixel = [params[@"compressedPixel"] intValue];
    }
    if(params[@"quality"]){
        quality = [params[@"quality"] doubleValue] / 100;
    }
    if(params[@"url"]){
        url = params[@"url"];
    }
    if(params[@"isScale"]){
        isScale = [params[@"isScale"] boolValue];
    }
    if(params[@"aspectX"]){
        aspectX = [params[@"aspectX"] intValue];
    }
    if(params[@"aspectY"]){
        aspectY = [params[@"aspectY"] intValue];
    }
    
    static  CACropImageController* cropImage = nil;
    if(!cropImage){
        cropImage = [[CACropImageController alloc] init];
    }
    
    [cropImage openCropImageView:url compressedPixel:compressedPixel isScale:isScale aspectX:aspectX aspectY:aspectY quality:quality callback:callback];
}

RCT_EXPORT_METHOD(cleanImage:(NSDictionary *)params callback:(RCTResponseSenderBlock)callback)
{
    NSString * path = [NSTemporaryDirectory()stringByStandardizingPath];
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    if (error) {
        NSLog(@"%@",error);
    }else{
        NSLog(@"清理图片缓存成功");
    }
}

@end
  
