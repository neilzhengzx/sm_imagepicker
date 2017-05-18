#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

typedef enum : NSUInteger {
    TZAssetCellTypePhoto = 0,
    TZAssetCellTypeLivePhoto,
    TZAssetCellTypeVideo,
    TZAssetCellTypeAudio,
} TZAssetCellType;

@class TZAssetModel;
@interface TZAssetCell : UICollectionViewCell

@property (weak, nonatomic) UIButton *selectPhotoButton;
@property (nonatomic, strong) TZAssetModel *model;
@property (nonatomic, copy) void (^didSelectPhotoBlock)(BOOL);
@property (nonatomic, assign) TZAssetCellType type;
@property (nonatomic, copy) NSString *representedAssetIdentifier;
@property (nonatomic, assign) PHImageRequestID imageRequestID;
@end


@class TZAlbumModel;

@interface TZAlbumCell : UITableViewCell

@property (nonatomic, strong) TZAlbumModel *model;
@property (weak, nonatomic) UIButton *selectedCountButton;

@end


@interface TZAssetCameraCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;

@end