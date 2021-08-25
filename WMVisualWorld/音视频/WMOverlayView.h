
#import <UIKit/UIKit.h>
typedef enum : NSUInteger {
    stillImage,//获取图片
    video,//视频
    face,//人脸
    scanCode,//二维码、条形码、商品码、登机码
} WMOverlayViewType;

@protocol WMOverlayViewDelegate <NSObject>
@optional
-(void)WMOverlayViewDelegateStillImage;
-(void)WMOverlayViewDelegateVideo;
//-(void)WMOverlayViewDelegateFace;
//-(void)WMOverlayViewDelegateScanCode;
-(void)WMOverlayViewDelegateStopAction;
-(void)WMOverlayViewDelegateFlash:(BOOL)flash;
-(void)WMOverlayViewDelegateTorch:(BOOL)torch;
@end

@interface WMOverlayView : UIView
@property (nonatomic,weak)id<WMOverlayViewDelegate>delegate;
@property (nonatomic,assign) WMOverlayViewType type;
@end
