//
//  WMMetalTriangleRender.h
//  WMVisualWorld
//
//  Created by wangmm on 2021/8/6.
//

#import <Foundation/Foundation.h>
@import MetalKit;
NS_ASSUME_NONNULL_BEGIN

@interface WMMetalTriangleRender : NSObject <MTKViewDelegate>
//初始化一个MTKView
- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView;

@end

NS_ASSUME_NONNULL_END
