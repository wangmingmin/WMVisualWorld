//
//  WMVideoConfig.h
//  001-Demo
//
//  Created on 2021年2/16.
//  Copyright © 2021年. All rights reserved.
//

#import <Foundation/Foundation.h>

/**音频配置*/
@interface WMAudioConfig : NSObject
/**码率*/
@property (nonatomic, assign) NSInteger bitrate;//96000）
/**声道*/
@property (nonatomic, assign) NSInteger channelCount;//（1）
/**采样率*/
@property (nonatomic, assign) NSInteger sampleRate;//(音频默认使用44100)
/**采样点量化*/
@property (nonatomic, assign) NSInteger sampleSize;//(16)

+ (instancetype)defaultConifg;
@end

@interface WMVideoConfig : NSObject
@property (nonatomic, assign) NSInteger width;//可选，系统支持的分辨率，采集分辨率的宽
@property (nonatomic, assign) NSInteger height;//可选，系统支持的分辨率，采集分辨率的高
@property (nonatomic, assign) NSInteger bitrate;//自由设置
@property (nonatomic, assign) NSInteger fps;//自由设置 25
+ (instancetype)defaultConifg;
@end
