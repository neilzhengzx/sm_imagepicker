#import <UIKit/UIKit.h>

@class TZAlbumModel;
@interface TZPhotoPickerController : UIViewController

@property (nonatomic, assign) BOOL isFirstAppear;
@property (nonatomic, strong) TZAlbumModel *model;

@property (nonatomic, copy) void (^backButtonClickHandle)(TZAlbumModel *model);

@end
