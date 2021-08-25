//
//  WMAssetReader.h
//  002--MetalRenderMOV
//
//  Created by   on 2021年5/7.
//  Copyright © 2021年  . All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
@interface WMAssetReader : NSObject

//初始化
- (instancetype)initWithUrl:(NSURL *)url;

//从MOV文件读取CMSampleBufferRef 数据
- (CMSampleBufferRef)readBuffer;

@end
