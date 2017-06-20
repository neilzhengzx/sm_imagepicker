
#import "RNSmImagepicker.h"
#import "CAAlbumController.h"
#import "CACameraController.h"
#import "CAMultiAlbumViewController.h"

@implementation RNSmImagepicker

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE()


      
RCT_EXPORT_METHOD(imageFromCamera:(NSDictionary *)params callback:(RCTResponseSenderBlock)callback)
{
    BOOL isEdit = false;
    int compressedPixel = 1280;
    double quality = 0.6;
    if(params[@"isEdit"]){
        isEdit = [params[@"isEdit"] boolValue];
    }
    if(params[@"compressedPixel"]){
        compressedPixel = [params[@"compressedPixel"] intValue];
    }
    if(params[@"quality"]){
        quality = [params[@"quality"] doubleValue] / 100;
    }
    static CACameraController *camera = nil;
    if(!camera){
        camera = [[CACameraController alloc] init];
    }
    [camera openCameraView:isEdit compressedPixel:compressedPixel quality:quality callback:callback];
  //imageFromCamera 实现, 需要回传结果用callback(@[XXX]), 数组参数里面就一个NSDictionary元素即可
}
      
RCT_EXPORT_METHOD(imageFromCameraAlbum:(NSDictionary *)params callback:(RCTResponseSenderBlock)callback)
{
  //imageFromCameraAlbum 实现, 需要回传结果用callback(@[XXX]), 数组参数里面就一个NSDictionary元素即可
    BOOL isEdit = false;
    int compressedPixel = 1280;
    double quality = 0.6;
    if(params[@"isEdit"]){
        isEdit = [params[@"isEdit"] boolValue];
    }
    if(params[@"compressedPixel"]){
        compressedPixel = [params[@"compressedPixel"] intValue];
    }
    if(params[@"quality"]){
        quality = [params[@"quality"] doubleValue] / 100;
    }
    static CAAlbumController *album = nil;
    if(!album){
        album = [[CAAlbumController alloc] init];
    }
    
    [album openAlbumView:isEdit compressedPixel:compressedPixel quality:quality callback:callback];
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

@end
  
