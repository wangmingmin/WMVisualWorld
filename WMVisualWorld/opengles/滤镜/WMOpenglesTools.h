//
//  WMOpenglesTools.h
//  WMVisualWorld
//
//  Created by wangmm on 2021/8/10.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>


NS_ASSUME_NONNULL_BEGIN
//SenceVertex 结构体
typedef struct {
    GLKVector3 positionCoord; //顶点坐标;
    GLKVector2 textureCoord;  //纹理坐标;
} WMSenceVertex;

@interface WMOpenglesTools : NSObject

//从帧缓存区中获取纹理图片文件; 获取当前的渲染结果
- (UIImage *)createResult_withVertex:(WMSenceVertex *)vertex
                    andVerticesCount:(int)verticesCount
                    vertexShaderName:(NSString *)vertexShaderName
                  fragmentShaderName:(NSString *)fragmentShaderName
                               image:(UIImage *)image;

//保存图片至系统相册
- (void)saveImage:(UIImage *)image
       andFinised:( void(^ _Nullable )(BOOL success))finish;

- (UIImage *)imageFromTextureWithWidth:(int)width height:(int)height andFrameBuffer:(GLuint)frameBuffer;
@end

NS_ASSUME_NONNULL_END
