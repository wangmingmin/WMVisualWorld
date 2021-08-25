//
//  WMOpenglesCreateImageTool.h
//  001
//
//  Created by wangmm on 2021/8/16.
//  Copyright © 2021 wangmm. All rights reserved.
//

#import <GLKit/GLKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMOpenglesCreateImageTool : NSObject
- (UIImage *)createImage:(UIImage *)image
            vertexShader:(NSString *)vertextShader
          fragmentShader:(NSString *)fragmentShader
            positionSlot:(NSString *)positionSlot
       textureCoordsSlot:(NSString *)textureCoordsSlot
             textureSlot:(NSString *)textureSlot;

//保存图片至系统相册
- (void)saveImage:(UIImage *)image
       andFinised:( void(^ _Nullable )(BOOL success))finish;
@end
NS_ASSUME_NONNULL_END
