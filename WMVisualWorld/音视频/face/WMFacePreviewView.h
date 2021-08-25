
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@interface WMFacePreviewView : UIView

@property (strong, nonatomic) AVCaptureSession *session;
- (void)didDetectFaces:(NSArray *)faces;
-(void)removeFaceLayer;
@end
