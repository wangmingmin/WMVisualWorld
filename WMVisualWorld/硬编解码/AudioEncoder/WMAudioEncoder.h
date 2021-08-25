//
//  CCAudioEncoder.h
//  001-Demo
//
//  Created on 2021年2/16.
//  Copyright © 2021年. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
@class WMAudioConfig;

/**AAC编码器代理*/
@protocol WMAudioEncoderDelegate <NSObject>
- (void)audioEncodeCallback:(NSData *)aacData;
@end

/**AAC硬编码器 (编码和回调均在异步队列执行)*/
@interface WMAudioEncoder : NSObject

/**编码器配置*/
@property (nonatomic, strong) WMAudioConfig *config;
@property (nonatomic, weak) id<WMAudioEncoderDelegate> delegate;
@property (nonatomic, assign) BOOL isWriteToFile;//写入本地

/**初始化传入编码器配置*/
- (instancetype)initWithConfig:(WMAudioConfig*)config;

/**编码*/
- (void)encodeAudioSamepleBuffer: (CMSampleBufferRef)sampleBuffer;

/**直接将CMSampleBufferRef转换成PCM*/
- (NSData *)convertAudioSamepleBufferToPcmData: (CMSampleBufferRef)sampleBuffer;
@end
