//
//  AAPLEAGLLayer.h
//  001-Demo
//
//  Created on 2021年2/16.
//  Copyright © 2021年. All rights reserved.
//

#include <QuartzCore/QuartzCore.h>
#include <CoreVideo/CoreVideo.h>

/*
 CAEAGLLayer(CoreAnimation 框架)
 openGL ES 只负责核心的渲染动作，不负责显示，不同的操作系统提供不同的图层渲染（layer/UIView等），iOS提供给开发者是用layer（CAEAGLLayer）来显示，这也是openGl ES 可以跨平台的核心。
 CAEAGLLayer 是iOS/Mac OS 提供给开发者专用于渲染 OpenGL ES 的图层，继承自CALayer
 */
@interface WMAAPLEAGLLayer : CAEAGLLayer
@property CVPixelBufferRef pixelBuffer;
- (id)initWithFrame:(CGRect)frame;
- (void)resetRenderBuffer;
@end
