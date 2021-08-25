//
//  WMFaceOrScanCameraManger.h
//  WMVisualWorld
//
//  Created by wangmm on 2021/7/19.
//

#import "WMCameraManger.h"
NS_ASSUME_NONNULL_BEGIN
@protocol WMFaceDetectionDelegate <NSObject>
@optional
- (void)didDetectFaces:(NSArray *)faces;
@end

@interface WMFaceCameraManger : WMCameraManger
- (BOOL)setupSessionOutputs:(NSError **)error;
@property (weak, nonatomic) id <WMFaceDetectionDelegate> faceDetectionDelegate;
@end

NS_ASSUME_NONNULL_END
