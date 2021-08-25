//
//  WMVideoConfig.m
//  001-Demo
//
//  Created on 2021年2/16.
//  Copyright © 2021年. All rights reserved.
//

#import "WMAVConfig.h"

@implementation WMAudioConfig

+ (instancetype)defaultConifg {
    return  [[WMAudioConfig alloc] init];
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.bitrate = 96000;
        self.channelCount = 1;
        self.sampleSize = 16;
        self.sampleRate = 44100;
    }
    return self;
}
@end
@implementation WMVideoConfig

+ (instancetype)defaultConifg {
    return [[WMVideoConfig alloc] init];
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.width = 480;
        self.height = 640;
        self.bitrate = 640*1000;
        self.fps = 25;
    }
    return self;
}
@end

