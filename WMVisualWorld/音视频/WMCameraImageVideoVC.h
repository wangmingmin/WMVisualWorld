//
//  WMCameraImageVideoVC.h
//  WMVisualWorld
//
//  Created by wangmm on 2021/7/20.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef enum : NSUInteger {
    stillImageType,//获取图片
    videoType,//视频
} WMCameraImageVideoVCType;

@interface WMCameraImageVideoVC : UIViewController
@property (assign, nonatomic) WMCameraImageVideoVCType type;
@end

NS_ASSUME_NONNULL_END
