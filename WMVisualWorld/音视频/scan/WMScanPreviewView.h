
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@interface WMScanPreviewView : UIView
@property (strong, nonatomic) AVCaptureSession *session;//ζζδΌθ―
- (void)didDetectCodes:(NSArray *)codes;
-(void)removeCodeLayer;
@end
