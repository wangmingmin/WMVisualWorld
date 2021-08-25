//
//  WMTestKView.m
//  001--CClhDemo
//
//  Created by wangmm on 2021/8/16.
//  Copyright © 2021  . All rights reserved.
//

#import "WMOpenglesCreateImageTool.h"
#import <Photos/Photos.h>

// 顶点数量
static NSInteger const kVerticesCount = 4;

//SenceVertex 结构体
typedef struct {
    GLKVector3 positionCoord; //顶点坐标;
    GLKVector2 textureCoord;  //纹理坐标;
} SenceVertex;


@interface WMOpenglesCreateImageTool ()
@property(nonatomic,strong) EAGLContext *context;
//顶点;
@property (nonatomic, assign) SenceVertex *vertices;

//临时创建的帧缓存和纹理缓存
@property (nonatomic, assign) GLuint tmpFrameBuffer;
@property (nonatomic, assign) GLuint tmpTexture;

//@property (nonatomic, strong) UIButton *saveImage;

@property (nonatomic, strong) UIImage *imageTmp;

@property (nonatomic, copy) NSString *vertexShaderName;//自定义顶点着色器名称
@property (nonatomic, copy) NSString *fragmentShaderName;//自定义片元着色器名称
@property (nonatomic, copy) NSString *positionSlot;//顶点着色器中定义的顶点坐标名称（attribute vec4 Position）
@property (nonatomic, copy) NSString *textureCoordsSlot;//顶点着色器中定义的纹理坐标名称（attribute vec2 TextureCoords）
@property (nonatomic, copy) NSString *textureSlot;//片元着色器中定义的纹理名称（uniform sampler2D Texture）

@end

@implementation WMOpenglesCreateImageTool

//销毁
- (void)dealloc {
    
    //销毁context
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    //销毁_vertices
    if (_vertices) {
        free(_vertices);
        _vertices = nil;
    }
    //销毁帧缓存区
    if (_tmpFrameBuffer) {
        glDeleteFramebuffers(1, &_tmpFrameBuffer);
        _tmpFrameBuffer = 0;
    }
    //销毁纹理
    if (_tmpTexture) {
        glDeleteTextures(1, &_tmpTexture);
        _tmpTexture = 0;
    }
}

//初始化
- (instancetype)init {
    
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}


//初始化
- (void)commonInit {
    //1.初始化vertices,context
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:self.context];
    glClearColor(0, 0, 0, 0);
}

#pragma mark - Public
-(UIImage *)createImage:(UIImage *)image vertexShader:(NSString *)vertextShader fragmentShader:(NSString *)fragmentShader positionSlot:(NSString *)positionSlot textureCoordsSlot:(NSString *)textureCoordsSlot textureSlot:(NSString *)textureSlot
{
    self.imageTmp = image;
    self.vertexShaderName = vertextShader?vertextShader:@"";
    self.fragmentShaderName = fragmentShader?fragmentShader:@"";
    self.positionSlot = positionSlot;
    self.textureCoordsSlot = textureCoordsSlot;
    self.textureSlot = textureSlot;
    if (!image || self.vertexShaderName.length==0 || self.fragmentShaderName.length==0) {
        return nil;
    }
    UIImage *newImage = [self createResult];
    return newImage;
}

#pragma mark -
//从帧缓存区中获取纹理图片文件; 获取当前的渲染结果
- (UIImage *)createResult {
    //1.GLKTextureInfo 设置纹理参数
    NSDictionary *options = @{GLKTextureLoaderOriginBottomLeft : @(YES)};
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithCGImage:[self.imageTmp CGImage]
                                                               options:options
                                                                 error:NULL];
    self.tmpTexture = textureInfo.name;
    
    //1. 根据屏幕上显示结果, 重新获取顶点/纹理坐标
    [self resetTextureWithOriginWidth:self.imageTmp.size.width
                         originHeight:self.imageTmp.size.height];
    
    //2.绑定帧缓存区;
    glBindFramebuffer(GL_FRAMEBUFFER, self.tmpFrameBuffer);
    //4.从帧缓存中获取拉伸后的图片;
    UIImage *image = [self imageFromTextureWithWidth:self.imageTmp.size.width height:self.imageTmp.size.height];
    //5. 将帧缓存绑定0,清空;
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    //6. 返回拉伸后的图片
    return image;
}

-(UIImage *)imageTmp
{
    if (!_imageTmp) {
        _imageTmp = [[UIImage alloc] init];
    }
    return _imageTmp;
}

#pragma mark - Private
/**
 根据当前屏幕上的显示，来重新创建纹理
 
 @param originWidth 纹理的原始实际宽度
 @param originHeight 纹理的原始实际高度
 */
- (void)resetTextureWithOriginWidth:(CGFloat)originWidth
                       originHeight:(CGFloat)originHeight {
    //1.新的纹理尺寸(新纹理图片的宽高)
    GLsizei newTextureWidth = originWidth;
    GLsizei newTextureHeight = originHeight;
    
    //4.创建顶点数组与纹理数组
    SenceVertex *tmpVertices = malloc(sizeof(SenceVertex) * kVerticesCount);
    tmpVertices[0] = (SenceVertex){{1, -1, 0.0},    {1.0, 0.0}}; //右下
    tmpVertices[1] = (SenceVertex){{1, 1,  0.0},    {1.0, 1.0}}; //右上
    tmpVertices[2] = (SenceVertex){{-1, -1, 0.0},   {0.0, 0.0}}; //左下
    tmpVertices[3] = (SenceVertex){{-1, 1, 0.0},    {0.0, 1.0}}; //左上

    
    //下面开始渲染到纹理的流程

    //1. 生成帧缓存区;
    GLuint frameBuffer;
    //glGenFramebuffers 生成帧缓存区对象名称;
    glGenFramebuffers(1, &frameBuffer);
    //glBindFramebuffer 绑定一个帧缓存区对象;
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    
    //2. 生成纹理ID,绑定纹理;
    GLuint texture;
    //glGenTextures 生成纹理ID
    glGenTextures(1, &texture);
    //glBindTexture 将一个纹理绑定到纹理目标上;
    glBindTexture(GL_TEXTURE_2D, texture);
    //glTexImage2D 指定一个二维纹理图像;
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, newTextureWidth, newTextureHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    
    //3. 设置纹理相关参数
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    
    //4. 将纹理图像加载到帧缓存区对象上;
    /*
     glFramebufferTexture2D (GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level)
     target: 指定帧缓冲目标,符合常量必须是GL_FRAMEBUFFER;
     attachment: 指定附着纹理对象的附着点GL_COLOR_ATTACHMENT0
     textarget: 指定纹理目标, 符合常量:GL_TEXTURE_2D
     teture: 指定要附加图像的纹理对象;
     level: 指定要附加的纹理图像的mipmap级别，该级别必须为0。
     */
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture, 0);
    
    //5. 设置视口尺寸
    glViewport(0, 0, newTextureWidth, newTextureHeight);
    
    //6. 获取着色器程序
    GLuint program = [self programWith_vertexShaderName:self.vertexShaderName andfragmentShaderName:self.fragmentShaderName];
    glUseProgram(program);
    
    //7. 获取参数ID
//    GLuint positionSlot = glGetAttribLocation(program, "Position");
//    GLuint textureSlot = glGetUniformLocation(program, "Texture");
//    GLuint textureCoordsSlot = glGetAttribLocation(program, "TextureCoords");
    GLuint positionSlot = glGetAttribLocation(program, self.positionSlot.UTF8String);
    GLuint textureSlot = glGetUniformLocation(program, self.textureSlot.UTF8String);
    GLuint textureCoordsSlot = glGetAttribLocation(program, self.textureCoordsSlot.UTF8String);

    //8. 传值
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, self.tmpTexture);
    glUniform1i(textureSlot, 0);
    
    
    //9.初始化缓存区
    //根据步长计算出缓存区的大小 stride * count
    GLsizeiptr bufferSizeBytes = sizeof(SenceVertex) * kVerticesCount;
    //生成缓存区对象的名称;
    GLuint glName;
    glGenBuffers(1, &glName);
    //将_glName 绑定到对应的缓存区;
    glBindBuffer(GL_ARRAY_BUFFER, glName);
    //创建并初始化缓存区对象的数据存储;
    glBufferData(GL_ARRAY_BUFFER, bufferSizeBytes, tmpVertices, GL_STATIC_DRAW);

    
    //10.准备绘制,将纹理/顶点坐标传递进去
    //默认顶点属性是关闭的,所以使用前要手动打开;
    glEnableVertexAttribArray(positionSlot);
    //定义顶点属性传递的方式;
    glVertexAttribPointer(positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(SenceVertex), NULL + offsetof(SenceVertex, positionCoord));
    
    //默认顶点属性是关闭的,所以使用前要手动打开;
    glEnableVertexAttribArray(textureCoordsSlot);
    //定义顶点属性传递的方式;
    glVertexAttribPointer(textureCoordsSlot, 2, GL_FLOAT, GL_FALSE, sizeof(SenceVertex), NULL + offsetof(SenceVertex, textureCoord));

    
    //11. 绘制
    glDrawArrays(GL_TRIANGLE_STRIP, 0, kVerticesCount);

    //12.解绑缓存
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    //13.释放顶点数组
    free(tmpVertices);
    
    //14.保存临时的纹理对象/帧缓存区对象;
    self.tmpFrameBuffer = frameBuffer;
}

// 返回某个纹理对应的 UIImage，调用前先绑定对应的帧缓存
- (UIImage *)imageFromTextureWithWidth:(int)width height:(int)height {
    
    //1.绑定帧缓存区;
    glBindFramebuffer(GL_FRAMEBUFFER, self.tmpFrameBuffer);
    
    //2.将帧缓存区内的图片纹理绘制到图片上;
    int size = width * height * 4;
    GLubyte *buffer = malloc(size);
    
    /*
     
     glReadPixels (GLint x, GLint y, GLsizei width, GLsizei height, GLenum format, GLenum type, GLvoid* pixels);
     @功能: 读取像素(理解为将已经绘制好的像素,从显存中读取到内存中;)
     @参数解读:
     参数x,y,width,height: xy坐标以及读取的宽高;
     参数format: 颜色格式; GL_RGBA;
     参数type: 读取到的内容保存到内存所用的格式;GL_UNSIGNED_BYTE 会把数据保存为GLubyte类型;
     参数pixels: 指针,像素数据读取后, 将会保存到该指针指向的地址内存中;
     
     注意: pixels指针,必须保证该地址有足够的可以使用的空间, 以容纳读取的像素数据; 例如一副256 * 256的图像,如果读取RGBA 数据, 且每个数据保存在GLUbyte. 总大小就是 256 * 256 * 4 = 262144字节, 即256M;
     int size = width * height * 4;
     GLubyte *buffer = malloc(size);
     */
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
    
    //使用data和size 数组来访问buffer数据;
    /*
     CGDataProviderRef CGDataProviderCreateWithData(void *info, const void *data, size_t size, CGDataProviderReleaseDataCallback releaseData);
     @功能: 新的数据类型, 方便访问二进制数据;
     @参数:
     参数info: 指向任何类型数据的指针, 或者为Null;
     参数data: 数据存储的地址,buffer
     参数size: buffer的数据大小;
     参数releaseData: 释放的回调,默认为空;
     
     */
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer, size, NULL);
    //每个组件的位数;
    int bitsPerComponent = 8;
    //像素占用的比特数4 * 8 = 32;
    int bitsPerPixel = 32;
    //每一行的字节数
    int bytesPerRow = 4 * width;
    //颜色空间格式;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    //位图图形的组件信息 - 默认的
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    //颜色映射
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    //3.将帧缓存区里像素点绘制到一张图片上;
    /*
     CGImageCreate(size_t width, size_t height,size_t bitsPerComponent, size_t bitsPerPixel, size_t bytesPerRow,CGColorSpaceRef space, CGBitmapInfo bitmapInfo, CGDataProviderRef provider,const CGFloat decode[], bool shouldInterpolate,CGColorRenderingIntent intent);
     @功能:根据你提供的数据创建一张位图;
     注意:size_t 定义的是一个可移植的单位,在64位机器上为8字节,在32位机器上是4字节;
     参数width: 图片的宽度像素;
     参数height: 图片的高度像素;
     参数bitsPerComponent: 每个颜色组件所占用的位数, 比如R占用8位;
     参数bitsPerPixel: 每个颜色的比特数, 如果是RGBA则是32位, 4 * 8 = 32位;
     参数bytesPerRow :每一行占用的字节数;
     参数space:颜色空间模式,CGColorSpaceCreateDeviceRGB
     参数bitmapInfo:kCGBitmapByteOrderDefault 位图像素布局;
     参数provider: 图片数据源提供者, 在CGDataProviderCreateWithData ,将buffer 转为 provider 对象;
     参数decode: 解码渲染数组, 默认NULL
     参数shouldInterpolate: 是否抗锯齿;
     参数intent: 图片相关参数;kCGRenderingIntentDefault
     
     */
    CGImageRef imageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, YES, renderingIntent);
    
    //4. 此时的 imageRef 是上下颠倒的，调用 CG 的方法重新绘制一遍，刚好翻转过来
    //创建一个图片context
    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    CGContextRef context = UIGraphicsGetCurrentContext();
    //将图片绘制上去
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    //从context中获取图片
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    //结束图片context处理
    UIGraphicsEndImageContext();
    
    //释放buffer
    free(buffer);
    //返回图片
    return image;
}

#pragma mark - Custom Accessor
- (void)setTmpFrameBuffer:(GLuint)tmpFrameBuffer {
    if (_tmpFrameBuffer) {
        glDeleteFramebuffers(1, &_tmpFrameBuffer);
    }
    _tmpFrameBuffer = tmpFrameBuffer;
}

#pragma mark - 加载自定义着色器
// 将一个顶点着色器和一个片段着色器挂载到一个着色器程序上，并返回程序的 id
- (GLuint)programWith_vertexShaderName:(NSString *)vertexShaderName andfragmentShaderName:(NSString *)fragmentShaderName{
    
    //1.编译两个着色器
    GLuint vertexShader = [self compileShaderWithName:vertexShaderName type:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShaderWithName:fragmentShaderName type:GL_FRAGMENT_SHADER];
    
    //2. 加载 shader 到 program 上
    GLuint program = glCreateProgram();
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    
    //3. 链接 program
    glLinkProgram(program);
    
    //4. 检查链接是否成功
    GLint linkSuccess;
    glGetProgramiv(program, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(program, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSAssert(NO, @"program链接失败：%@", messageString);
        exit(1);
    }
    return program;
}

// 编译一个 shader，并返回 shader 的 id
- (GLuint)compileShaderWithName:(NSString *)name type:(GLenum)shaderType {
    // 查找 shader 文件
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:name ofType:shaderType == GL_VERTEX_SHADER ? @"vsh" : @"fsh"]; // 根据不同的类型确定后缀名
    NSError *error;
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSAssert(NO, @"读取shader失败");
        exit(1);
    }
    
    // 创建一个 shader 对象
    GLuint shader = glCreateShader(shaderType);
    
    // 获取 shader 的内容
    const char *shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = (int)[shaderString length];
    glShaderSource(shader, 1, &shaderStringUTF8, &shaderStringLength);
    
    // 编译shader
    glCompileShader(shader);
    
    // 查询 shader 是否编译成功
    GLint compileSuccess;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shader, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSAssert(NO, @"shader编译失败：%@", messageString);
        exit(1);
    }
    
    return shader;
}

#pragma mark - 保存图片到相册
- (void)saveImage:(UIImage *)image andFinised:(void(^)(BOOL success))finish{
    //将图片通过PHPhotoLibrary保存到系统相册
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromImage:image];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (finish) {
            dispatch_async(dispatch_get_main_queue(), ^{
                //主线程
                finish(success);
            });
        }
        NSLog(@"success = %d, error = %@ 图片已保存到相册", success, error);
    }];
}

@end
