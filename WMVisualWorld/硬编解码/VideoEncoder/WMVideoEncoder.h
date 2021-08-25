//
//  WMVideoEncoder.h
//  001-Demo
//
//  Created on 2021年2/16.
//  Copyright © 2021年. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "WMAVConfig.h"

/**h264编码回调代理*/
@protocol WMVideoEncoderDelegate <NSObject>
//Video-H264数据编码完成回调
- (void)videoEncodeCallback:(NSData *)h264Data;
//Video-SPS&PPS数据编码回调
- (void)videoEncodeCallbacksps:(NSData *)sps pps:(NSData *)pps;
@end

/**h264硬编码器 (编码和回调均在异步队列执行)*/
@interface WMVideoEncoder : NSObject
@property (nonatomic, strong) WMVideoConfig *config;
@property (nonatomic, weak) id<WMVideoEncoderDelegate> delegate;

- (instancetype)initWithConfig:(WMVideoConfig*)config;
/**编码*/
-(void)encodeVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer;

//重新开始编码前的准备工作
-(void)reEncodePrepare;
@end
