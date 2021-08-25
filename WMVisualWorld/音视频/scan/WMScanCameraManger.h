//
//  WMScanCameraManger.h
//  WMVisualWorld
//
//  Created by wangmm on 2021/7/20.
//

#import "WMCameraManger.h"

NS_ASSUME_NONNULL_BEGIN
@protocol WMCodeDetectionDelegate <NSObject>
@optional
- (void)didDetectCodes:(NSArray *)codes;
@end

@interface WMScanCameraManger : WMCameraManger
- (BOOL)setupSessionOutputs:(NSError **)error;
@property (weak, nonatomic) id <WMCodeDetectionDelegate> codeDetectionDelegate;
@end

NS_ASSUME_NONNULL_END
