//
//  CCAudioDecoder.h
//  001-Demo
//
//  Created on 2021年2/16.
//  Copyright © 2021年. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
@class WMAudioConfig;

/**AAC解码回调代理*/
@protocol WMAudioDecoderDelegate <NSObject>
- (void)audioDecodeCallback:(NSData *)pcmData;
@end

@interface WMAudioDecoder : NSObject
@property (nonatomic, strong) WMAudioConfig *config;
@property (nonatomic, weak) id<WMAudioDecoderDelegate> delegate;

//初始化 传入解码配置
- (instancetype)initWithConfig:(WMAudioConfig *)config;

/**解码aac*/
- (void)decodeAudioAACData: (NSData *)aacData;
@end
