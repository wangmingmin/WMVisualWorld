//
//  CCImage.m
//  002-BasicTexture
//
//  Created by on 2021/8/15.
//  Copyright © 2021年. All rights reserved.
//
//实现一个简单的图像数据容器
#import "WMMetalImageTool.h"
#include <simd/simd.h>

@implementation WMMetalImageTool
//通过加载一个简单的TGA文件初始化这个图像.只支持32bit的TGA文件
-(nullable instancetype) initWithTGAFileAtLocation:(nonnull NSURL *)location
{
    self = [super init];
    if(self)
    {
        NSString *fileExtension = location.pathExtension;
        
        //判断文件后缀是否为tga
        if(!([fileExtension caseInsensitiveCompare:@"TGA"] == NSOrderedSame))
        {
            NSLog(@"此CCImage只加载TGA文件");
            return nil;
            
        }
        
        //定义一个TGA文件的头.
        typedef struct __attribute__ ((packed)) TGAHeader
        {
            uint8_t  IDSize;         // ID信息
            uint8_t  colorMapType;   // 颜色类型
            uint8_t  imageType;      // 图片类型 0=none, 1=indexed, 2=rgb, 3=grey, +8=rle packed
            
            int16_t  colorMapStart;  // 调色板中颜色映射的偏移量
            int16_t  colorMapLength; // 在调色板的颜色数
            uint8_t  colorMapBpp;    // 每个调色板条目的位数
            
            uint16_t xOffset;        // 图像开始右方的像素数
            uint16_t yOffset;        // 图像开始向下的像素数
            uint16_t width;          // 像素宽度
            uint16_t height;         // 像素高度
            uint8_t  bitsPerPixel;   // 每像素的位数 8,16,24,32
            uint8_t  descriptor;     // bits描述 (flipping, etc)
            
        }TGAHeader;
        
        NSError *error;
        
        //将TGA文件中整个复制到此变量中
        NSData *fileData = [[NSData alloc]initWithContentsOfURL:location options:0x0 error:&error];
        
        if(fileData == nil)
        {
            NSLog(@"打开TGA文件失败:%@",error.localizedDescription);
            return nil;
        }
        
        //定义TGAHeader对象
        TGAHeader *tgaInfo = (TGAHeader *)fileData.bytes;
        _width = tgaInfo->width;
        _height = tgaInfo->height;
        
        //计算图像数据的字节大小,因为我们把图像数据存储为/每像素32位BGRA数据.
        NSUInteger dataSize = _width * _height * 4;
        
        if(tgaInfo->bitsPerPixel == 24)
        {
            //Metal是不能理解一个24-BPP格式的图像.所以我们必须转化成TGA数据.从24比特BGA格式到32比特BGRA格式.(类似MTLPixelFormatBGRA8Unorm)
            NSMutableData *mutableData = [[NSMutableData alloc] initWithLength:dataSize];
            
            //TGA规范,图像数据是在标题和ID之后立即设置指针到文件的开头+头的大小+ID的大小.初始化源指针,源代码数据为BGR格式
            uint8_t *srcImageData = ((uint8_t*)fileData.bytes +
                                     sizeof(TGAHeader) +
                                     tgaInfo->IDSize);
            
            //初始化将存储转换后的BGRA图像数据的目标指针
            uint8_t *dstImageData = mutableData.mutableBytes;
            
            //图像的每一行
            for(NSUInteger y = 0; y < _height; y++)
            {
                //对于当前行的每一列
                for(NSUInteger x = 0; x < _width; x++)
                {
                    //计算源和目标图像中正在转换的像素的第一个字节的索引.
                    NSUInteger srcPixelIndex = 3 * (y * _width + x);
                    NSUInteger dstPixelIndex = 4 * (y * _width + x);
                    
                    //将BGR信道从源复制到目的地,将目标像素的alpha通道设置为255
                    dstImageData[dstPixelIndex + 0] = srcImageData[srcPixelIndex + 0];
                    dstImageData[dstPixelIndex + 1] = srcImageData[srcPixelIndex + 1];
                    dstImageData[dstPixelIndex + 2] = srcImageData[srcPixelIndex + 2];
                    dstImageData[dstPixelIndex + 3] = 255;
                }
            }
            _data = mutableData;
            
        }else
        {
        
            uint8_t *srcImageData = ((uint8_t*)fileData.bytes +
                                     sizeof(TGAHeader) +
                                     tgaInfo->IDSize);

            _data = [[NSData alloc] initWithBytes:srcImageData
                                           length:dataSize];
            
        }
        
    }
    return self;
    
}


//从UIImage 中读取Byte 数据返回，UIImage的数据需要转成二进制才能上传，且不用jpg、png的NSData
+(Byte *)loadPNGJPGImageByte:(UIImage *)image {
    // 1.获取图片的CGImageRef
    CGImageRef spriteImage = image.CGImage;
    
    // 2.读取图片的大小
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
   
    //3.计算图片大小.rgba共4个byte
    Byte * spriteData = (Byte *) calloc(width * height * 4, sizeof(Byte));
    
    //4.创建画布
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    //5.在CGContextRef上绘图
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    //6.图片翻转过来
    CGRect rect = CGRectMake(0, 0, width, height);
    CGContextTranslateCTM(spriteContext, rect.origin.x, rect.origin.y);
    CGContextTranslateCTM(spriteContext, 0, rect.size.height);
    CGContextScaleCTM(spriteContext, 1.0, -1.0);
    CGContextTranslateCTM(spriteContext, -rect.origin.x, -rect.origin.y);
    CGContextDrawImage(spriteContext, rect, spriteImage);
    
    //7.释放spriteContext
    CGContextRelease(spriteContext);
    
    return spriteData;
}

@end
