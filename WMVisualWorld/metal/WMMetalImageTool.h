//
//  WMMetalImageTool.h
//  002-BasicTexture
//
//  Created on 2021/8/15.
//  Copyright © 2021年. All rights reserved.
//

#import <Foundation/Foundation.h>
@import UIKit;

@interface WMMetalImageTool : NSObject

//图片的宽高,以像素为单位
@property(nonatomic,readonly)NSUInteger width;
@property(nonatomic,readonly)NSUInteger height;

//图片数据每像素32bit,以BGRA形式的图像数据(相当于MTLPixelFormatBGRA8Unorm)
@property(nonatomic,readonly)NSData * _Nullable data;

//通过加载一个简单的TGA文件初始化这个图像.只支持32bit的TGA文件
-(nullable instancetype) initWithTGAFileAtLocation:(nonnull NSURL *)location;
//获取PNG或JPG等格式bytes
+(Byte *_Nonnull)loadPNGJPGImageByte:(UIImage *_Nullable)image;
@end
