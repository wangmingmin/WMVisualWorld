//
//  WMVideoDecoder.h
//  001-Demo
//
//  Created on 2021年2/16.
//  Copyright © 2021年. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "WMAVConfig.h"

/**h264解码回调代理*/
@protocol WMVideoDecoderDelegate <NSObject>
//解码后H264数据回调，CVPixelBufferRef保存的是解码前（未编码）的数据，也就是源数据，通过opengles或metal转化成RGB展示
- (void)videoDecodeCallback:(CVPixelBufferRef)imageBuffer;
@end

@interface WMVideoDecoder : NSObject
@property (nonatomic, strong) WMVideoConfig *config;
@property (nonatomic, weak) id<WMVideoDecoderDelegate> delegate;

/**初始化解码器**/
- (instancetype)initWithConfig:(WMVideoConfig*)config;

/**解码h264数据*/
- (void)decodeNaluData:(NSData *)frame;
@end
