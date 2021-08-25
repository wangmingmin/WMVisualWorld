//
//  WMMetalPhotoRenderer.h
//  002-BasicTexture
//
//  Created by on 2021/8/15.
//  Copyright © 2021年. All rights reserved.
//

#import <Foundation/Foundation.h>
@import MetalKit;

@interface WMMetalPhotoRenderer : NSObject<MTKViewDelegate>

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView;
- (void)refreshRender;//刷新
- (UIImage *_Nullable)createImage;
- (UIImage *_Nullable)createimagebycache;

@property (nonatomic, copy) NSString * _Nonnull fragmentName;//片元名称
@property (nonatomic, copy) NSString * _Nonnull vertexName;//顶点名称

@end
