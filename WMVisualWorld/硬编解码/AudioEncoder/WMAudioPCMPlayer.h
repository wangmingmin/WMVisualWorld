//
//  CCAudioPCMPlayer.h
//  001-Demo
//
//  Created on 2021年2/16.
//  Copyright © 2021年. All rights reserved.
//

#import <Foundation/Foundation.h>
@class WMAudioConfig;
@interface WMAudioPCMPlayer : NSObject

- (instancetype)initWithConfig:(WMAudioConfig *)config;
/**播放pcm*/
- (void)playPCMData:(NSData *)data;
/** 设置音量增量 0.0 - 1.0 */
- (void)setupVoice:(Float32)gain;
/**销毁 */
- (void)dispose;

@end
