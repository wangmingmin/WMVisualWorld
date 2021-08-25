
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@interface WMScanPreviewView : UIView
@property (strong, nonatomic) AVCaptureSession *session;//捕捉会话
- (void)didDetectCodes:(NSArray *)codes;
-(void)removeCodeLayer;
@end
