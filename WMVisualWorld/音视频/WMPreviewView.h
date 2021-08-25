//
//  WMPreviewView.h
//  WMVisualWorld
//
//  Created by wangmm on 2021/7/15.
//
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@protocol WMPreviewViewDelegate <NSObject>
- (void)tappedToFocusAtPoint:(CGPoint)point;//聚焦
- (void)tappedToExposeAtPoint:(CGPoint)point;//曝光
- (void)tappedToResetFocusAndExposure;//点击重置聚焦&曝光
@end

@interface WMPreviewView : UIView
@property (strong, nonatomic) AVCaptureSession *session;
@property (weak, nonatomic) id<WMPreviewViewDelegate> delegate;
@property (nonatomic) BOOL tapToFocusEnabled; //是否聚焦(通过系统方法来判断是否可以聚焦)
@property (nonatomic) BOOL tapToExposeEnabled; //是否曝光(通过系统方法来判断是否可以曝光)
@end

NS_ASSUME_NONNULL_END
