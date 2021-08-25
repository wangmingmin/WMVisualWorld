//
//  CCRenderer.m
//  002-BasicTexture
//
//  Created by on 2021/8/15.
//  Copyright © 2021年. All rights reserved.
//

#import "WMMetalPhotoRenderer.h"
#import "WMMetalImageTool.h"
#import "WMShaderTypes.h"

#import <MetalPerformanceShaders/MetalPerformanceShaders.h>
@import simd;
@import MetalKit;

@implementation WMMetalPhotoRenderer
{
    // 我们用来渲染的设备(又名GPU)
    id<MTLDevice> _device;
    
    // 我们的渲染管道有顶点着色器和片元着色器 它们存储在.metal shader 文件中
    id<MTLRenderPipelineState> _pipelineState;
    
    // 命令队列,从命令缓存区获取
    id<MTLCommandQueue> _commandQueue;
    
    // Metal 纹理对象
    id<MTLTexture> _texture;
    
    // 存储在 Metal buffer 顶点数据
    id<MTLBuffer> _vertices;
    
    // 顶点个数
    NSUInteger _numVertices;
    
    // 当前视图大小,这样我们才可以在渲染通道使用这个视图
    vector_uint2 _viewportSize;
    
    MTKView *wmMTKView;
    
    id<MTLTexture> _destTexture;
    CVMetalTextureCacheRef _textureCache;
    CVPixelBufferRef _renderPixelBuffer;
    MTLRenderPassDescriptor *_renderPassDescriptor;
    UIImage *_imagemonika;
}

- (instancetype)initWithMetalKitView:(MTKView *)mtkView
{
    self = [super init];
    if(self)
    {
        //允许读写操作(否则无法获取图片)
        mtkView.framebufferOnly = NO;

        //1.获取GPU设备
        _device = mtkView.device;
        wmMTKView = mtkView;
        _viewportSize = (vector_uint2){wmMTKView.drawableSize.width, wmMTKView.drawableSize.height};

        self.vertexName = @"vertexPhotoShader";
        self.fragmentName = @"fragmentPhotoShader2";//两个纹理

        //2.设置顶点相关操作
        [self setupVertex];
        //3.设置渲染管道相关操作
        [self setupPipeLine];
        //4.加载纹理TGA 文件
//        [self setupTexture];
        //4.加载PNG/JPG 图片文件
        [self setupTexturePNG];
        
        [self setupRenderTarget];

    }
    return self;
}

#pragma mark -- init setUp

-(void)setupTexture
{
    //1.获取tag的路径
    NSURL *imageFileLocation = [[NSBundle mainBundle] URLForResource:@"tagImage"withExtension:@"tga"];
    //将tag文件->WMMetalImageTool对象
    WMMetalImageTool *image = [[WMMetalImageTool alloc]initWithTGAFileAtLocation:imageFileLocation];
    //判断图片是否转换成功
    if(!image)
    {
        NSLog(@"Failed to create the image from:%@",imageFileLocation.absoluteString);
        
    }
    
    //2.创建纹理描述对象
    MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc]init];
    //表示每个像素有蓝色,绿色,红色和alpha通道.其中每个通道都是8位无符号归一化的值.(即0映射成0,255映射成1);
    textureDescriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
    //设置纹理的像素尺寸
    textureDescriptor.width = image.width;
    textureDescriptor.height = image.height;
    //使用描述符从设备中创建纹理
    _texture = [_device newTextureWithDescriptor:textureDescriptor];
    //计算图像每行的字节数
    NSUInteger bytesPerRow = 4 * image.width;
    
    /*
     typedef struct
     {
     MTLOrigin origin; //开始位置x,y,z
     MTLSize   size; //尺寸width,height,depth
     } MTLRegion;
     */
    //MLRegion结构用于标识纹理的特定区域。 demo使用图像数据填充整个纹理；因此，覆盖整个纹理的像素区域等于纹理的尺寸。
    //3. 创建MTLRegion 结构体
    MTLRegion region = {
        {0,0,0},
        {image.width,image.height,1}
    };
    
    //4.复制图片数据到texture
    [_texture replaceRegion:region mipmapLevel:0 withBytes:image.data.bytes bytesPerRow:bytesPerRow];
    
    
}

-(void)setupTexturePNG
{
    //1.获取图片
    //获取处理的图片路径
    NSString *imagePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"monika.jpeg"];
    //读取图片
    _imagemonika = [UIImage imageWithContentsOfFile:imagePath];
    UIImage *image = _imagemonika;
    //2.纹理描述符
    MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
    //表示每个像素有蓝色,绿色,红色和alpha通道.其中每个通道都是8位无符号归一化的值.(即0映射成0,255映射成1);
    textureDescriptor.pixelFormat = MTLPixelFormatRGBA8Unorm;
    //设置纹理的像素尺寸
    textureDescriptor.width = image.size.width;
    textureDescriptor.height = image.size.height;
    textureDescriptor.usage = MTLTextureUsageShaderRead; // 原图片只需要读取

    //3.使用描述符从设备中创建纹理
    _texture = [_device newTextureWithDescriptor:textureDescriptor];
    
    /*
     typedef struct
     {
     MTLOrigin origin; //开始位置x,y,z
     MTLSize   size; //尺寸width,height,depth
     } MTLRegion;
     */
    //MLRegion结构用于标识纹理的特定区域。 demo使用图像数据填充整个纹理；因此，覆盖整个纹理的像素区域等于纹理的尺寸。
    //4. 创建MTLRegion 结构体  [纹理上传的范围]
    MTLRegion region = {{ 0, 0, 0 }, {image.size.width, image.size.height, 1}};
    
    //5.获取图片数据
    Byte *imageBytes = [self loadImage:image];
    
    //6.UIImage的数据需要转成二进制才能上传，且不用jpg、png的NSData
    if (imageBytes) {
        [_texture replaceRegion:region
                        mipmapLevel:0
                          withBytes:imageBytes
                        bytesPerRow:4 * image.size.width];
        free(imageBytes);
        imageBytes = NULL;
    }
    
}

//从UIImage 中读取Byte 数据返回
- (Byte *)loadImage:(UIImage *)image {
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

-(void)refreshRender
{
    [self setupPipeLine];
}

-(void)setupPipeLine
{
    //1.创建我们的渲染通道
    //从项目中加载.metal文件,创建一个library
    id<MTLLibrary>defalutLibrary = [_device newDefaultLibrary];
    //从库中加载顶点函数
    id<MTLFunction>vertexFunction = [defalutLibrary newFunctionWithName:self.vertexName?self.vertexName:@"vertexPhotoShader"];
    //从库中加载片元函数
    id<MTLFunction> fragmentFunction = [defalutLibrary newFunctionWithName:self.fragmentName?self.fragmentName:@"fragmentPhotoShader2"];
    
    //2.配置用于创建管道状态的管道
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    //管道名称
    pipelineStateDescriptor.label = @"Texturing Pipeline";
    //可编程函数,用于处理渲染过程中的各个顶点
    pipelineStateDescriptor.vertexFunction = vertexFunction;
    //可编程函数,用于处理渲染过程总的各个片段/片元
    pipelineStateDescriptor.fragmentFunction = fragmentFunction;
    //设置管道中存储颜色数据的组件格式
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = wmMTKView.colorPixelFormat;
    pipelineStateDescriptor.colorAttachments[1].pixelFormat = MTLPixelFormatBGRA8Unorm;

    //3.同步创建并返回渲染管线对象
    NSError *error = NULL;
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    //判断是否创建成功
    if (!_pipelineState)
    {
        NSLog(@"Failed to created pipeline state, error %@", error);
    }
    
    //4.使用_device创建commandQueue
    _commandQueue = [_device newCommandQueue];
    
    
    _renderPassDescriptor = [MTLRenderPassDescriptor new];
    _renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.1, 0.2, 0.3, 1);
    _renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    _renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    
    _renderPassDescriptor.colorAttachments[1].clearColor = MTLClearColorMake(0.1, 0.1, 0.2, 0.5);
    _renderPassDescriptor.colorAttachments[1].loadAction = MTLLoadActionClear;
    _renderPassDescriptor.colorAttachments[1].storeAction = MTLStoreActionStore;

}

-(void)setupVertex
{
    //1.根据顶点/纹理坐标建立一个MTLBuffer
    static const WMTextureVertex quadVertices[] = {
        //像素坐标,纹理坐标
        { {  300,  -300 },  { 1.f, 0.f } },
        { { -300,  -300 },  { 0.f, 0.f } },
        { { -300,   300 },  { 0.f, 1.f } },
        
        { {  300,  -300 },  { 1.f, 0.f } },
        { { -300,   300 },  { 0.f, 1.f } },
        { {  300,   300 },  { 1.f, 1.f } },
        
    };
    
    //2.创建我们的顶点缓冲区，并用我们的Qualsits数组初始化它
    _vertices = [_device newBufferWithBytes:quadVertices
                                     length:sizeof(quadVertices)
                                    options:MTLResourceStorageModeShared];
    //3.通过将字节长度除以每个顶点的大小来计算顶点的数目
    _numVertices = sizeof(quadVertices) / sizeof(WMTextureVertex);
}

#pragma mark -- MTKView Delegate
//每当视图改变方向或调整大小时调用
-(void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{
    // 保存可绘制的大小，因为当我们绘制时，我们将把这些值传递给顶点着色器
    _viewportSize.x = size.width;
    _viewportSize.y = size.height;
    
}

- (void)drawInMTKView:(MTKView *)view
{
    //1.为当前渲染的每个渲染传递创建一个新的命令缓冲区
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    //指定缓存区名称
    commandBuffer.label = @"MyCommand";
    
    //2.currentRenderPassDescriptor描述符包含currentDrawable's的纹理、视图的深度、模板和sample缓冲区和清晰的值。
//    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;

    if(_renderPassDescriptor != nil)
    {
        _renderPassDescriptor.colorAttachments[0].texture = wmMTKView.currentDrawable.texture;
        _renderPassDescriptor.colorAttachments[1].texture = _destTexture;

        //3.创建渲染命令编码器,这样我们才可以渲染到something
        id<MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:_renderPassDescriptor];
        //渲染器名称
        renderEncoder.label = @"MyRenderEncoder";
        
        //4.设置我们绘制的可绘制区域
        /*
         typedef struct {
         double originX, originY, width, height, znear, zfar;
         } MTLViewport;
         */
        [renderEncoder setViewport:(MTLViewport){0.0, 0.0, _viewportSize.x, _viewportSize.y, -1.0, 1.0 }];
        
        //5.设置渲染管道
        [renderEncoder setRenderPipelineState:_pipelineState];
        
        //6.加载数据
        //将数据加载到MTLBuffer --> 顶点函数
        [renderEncoder setVertexBuffer:_vertices
                                offset:0
                               atIndex:WMVertexInputIndexVertices];
        //将数据加载到MTLBuffer --> 顶点函数
        [renderEncoder setVertexBytes:&_viewportSize
                               length:sizeof(_viewportSize)
                              atIndex:WMVertexInputIndexViewportSize];
        
        //7.设置纹理对象
        [renderEncoder setFragmentTexture:_texture atIndex:WMTextureIndexBaseColor];
        
        //8.绘制
        // @method drawPrimitives:vertexStart:vertexCount:
        //@brief 在不使用索引列表的情况下,绘制图元
        //@param 绘制图形组装的基元类型
        //@param 从哪个位置数据开始绘制,一般为0
        //@param 每个图元的顶点个数,绘制的图型顶点数量
        /*
         MTLPrimitiveTypePoint = 0, 点
         MTLPrimitiveTypeLine = 1, 线段
         MTLPrimitiveTypeLineStrip = 2, 线环
         MTLPrimitiveTypeTriangle = 3,  三角形
         MTLPrimitiveTypeTriangleStrip = 4, 三角型扇
         */
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                          vertexStart:0
                          vertexCount:_numVertices];
        
        //9.表示已该编码器生成的命令都已完成,并且从NTLCommandBuffer中分离
        [renderEncoder endEncoding];
        
        //10.一旦框架缓冲区完成，使用当前可绘制的进度表
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    
    //11.最后,在这里完成渲染并将命令缓冲区推送到GPU
    [commandBuffer commit];
    
}


#pragma mark -
- (void)setupRenderTarget {
    CVMetalTextureCacheCreate(NULL, NULL, wmMTKView.device, NULL, &_textureCache); // 创建纹理缓存
    
    CFDictionaryRef empty; // empty value for attr value.
    CFMutableDictionaryRef attrs;
    empty = CFDictionaryCreate(kCFAllocatorDefault, // our empty IOSurface properties dictionary
                               NULL,
                               NULL,
                               0,
                               &kCFTypeDictionaryKeyCallBacks,
                               &kCFTypeDictionaryValueCallBacks);
    attrs = CFDictionaryCreateMutable(kCFAllocatorDefault,
                                      1,
                                      &kCFTypeDictionaryKeyCallBacks,
                                      &kCFTypeDictionaryValueCallBacks);
    
    CFDictionarySetValue(attrs,
                         kCVPixelBufferIOSurfacePropertiesKey,
                         empty);
    
    CVPixelBufferRef renderTarget;
    CVPixelBufferCreate(kCFAllocatorDefault, _viewportSize.x, _viewportSize.y,
                        kCVPixelFormatType_32BGRA,
                        attrs,
                        &renderTarget);
    // in real life check the error return value of course.
    
    
    // rendertarget
    {
        size_t width = CVPixelBufferGetWidthOfPlane(renderTarget, 0);
        size_t height = CVPixelBufferGetHeightOfPlane(renderTarget, 0);
        MTLPixelFormat pixelFormat = MTLPixelFormatBGRA8Unorm;
        
        CVMetalTextureRef texture = NULL;
        CVReturn status = CVMetalTextureCacheCreateTextureFromImage(NULL, _textureCache, renderTarget, NULL, pixelFormat, width, height, 0, &texture);
        if(status == kCVReturnSuccess)
        {
            _destTexture = CVMetalTextureGetTexture(texture);
            _renderPixelBuffer = renderTarget;
            CFRelease(texture);
        }
        else {
            NSAssert(NO, @"CVMetalTextureCacheCreateTextureFromImage fail");
        }
    }
}


/**
 *  根据CVPixelBufferRef返回图像
 *
 *  @param pixelBufferRef 像素缓存引用
 *
 *  @return UIImage对象
 */
- (UIImage *)lyGetImageFromPixelBuffer:(CVPixelBufferRef)pixelBufferRef {
    CVImageBufferRef imageBuffer =  pixelBufferRef;
    
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    size_t bufferSize = CVPixelBufferGetDataSize(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0); //
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, baseAddress, bufferSize, NULL);
    
    // rgba的时候是kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrderDefault，这样会导致出现蓝色的图片
    CGImageRef cgImage = CGImageCreate(width, height, 8, 32, bytesPerRow, rgbColorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst, provider, NULL, true, kCGRenderingIntentDefault);
    
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    
    CGImageRelease(cgImage);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(rgbColorSpace);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    return image;
}


#pragma mark - image
-(UIImage *)createimagebycache
{
    UIImage *image = [self lyGetImageFromPixelBuffer:_renderPixelBuffer];
    return image;
}

-(UIImage *)createImage
{
#warning fix 未完成
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();

    id<MTLLibrary>defalutLibrary = [device newDefaultLibrary];
    //从库中加载顶点函数
    id<MTLFunction>vertexFunction = [defalutLibrary newFunctionWithName:@"vertexPhotoShader2"];
    //从库中加载片元函数
    id<MTLFunction> fragmentFunction = [defalutLibrary newFunctionWithName:self.fragmentName?self.fragmentName:@"fragmentPhotoShader"];

    //2.配置用于创建管道状态的管道
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    //管道名称
    pipelineStateDescriptor.label = @"Texturing Pipeline wm";
    //可编程函数,用于处理渲染过程中的各个顶点
    pipelineStateDescriptor.vertexFunction = vertexFunction;
    //可编程函数,用于处理渲染过程总的各个片段/片元
    pipelineStateDescriptor.fragmentFunction = fragmentFunction;
    //设置管道中存储颜色数据的组件格式
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;

    pipelineStateDescriptor.rasterSampleCount = 1;

    //3.同步创建并返回渲染管线对象
    NSError *error = NULL;
    id<MTLRenderPipelineState> pipelineState = [device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];

    //判断是否创建成功
    if (!pipelineState)
    {
        NSLog(@"Failed to created pipeline state, error %@", error);
    }





    //1.获取图片
    //获取处理的图片路径
    NSString *imagePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"feng.jpeg"];
    //读取图片
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    //2.纹理描述符
    MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
    //表示每个像素有蓝色,绿色,红色和alpha通道.其中每个通道都是8位无符号归一化的值.(即0映射成0,255映射成1);
    textureDescriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
    //设置纹理的像素尺寸
    textureDescriptor.width = image.size.width;
    textureDescriptor.height = image.size.height;
    textureDescriptor.usage = MTLTextureUsageRenderTarget|MTLTextureUsageShaderWrite|MTLTextureUsageShaderRead;

    //3.使用描述符从设备中创建纹理
    id<MTLTexture> nowtextureTmp = [device newTextureWithDescriptor:textureDescriptor];
    id<MTLTexture> nowtexture = nowtextureTmp;
    /*
     typedef struct
     {
     MTLOrigin origin; //开始位置x,y,z
     MTLSize   size; //尺寸width,height,depth
     } MTLRegion;
     */
    //MLRegion结构用于标识纹理的特定区域。 demo使用图像数据填充整个纹理；因此，覆盖整个纹理的像素区域等于纹理的尺寸。
    //4. 创建MTLRegion 结构体  [纹理上传的范围]
    MTLRegion region = {{ 0, 0, 0 }, {image.size.width, image.size.height, 1}};

    //5.获取图片数据
    Byte *imageBytes = [self loadImage:image];

    //6.UIImage的数据需要转成二进制才能上传，且不用jpg、png的NSData
    if (imageBytes) {
        [nowtexture replaceRegion:region
                        mipmapLevel:0
                          withBytes:imageBytes
                        bytesPerRow:4 * image.size.width];
        free(imageBytes);
        imageBytes = NULL;
    }






    id<MTLCommandQueue> commandQueue = [device newCommandQueueWithMaxCommandBufferCount:1];

    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
    commandBuffer.label = @"MyCommandwm";
    MTLRenderPassDescriptor *renderPass = [[MTLRenderPassDescriptor alloc] init];
    renderPass.colorAttachments[0].texture = nowtexture;
    renderPass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1);
    renderPass.colorAttachments[0].storeAction = MTLStoreActionStore;
    renderPass.colorAttachments[0].loadAction = MTLLoadActionClear;
//    renderPass.depthAttachment.loadAction = MTLLoadActionClear;
//    renderPass.depthAttachment.clearDepth = 1.0f;

    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPass];

    //5.设置渲染管道
    [renderEncoder setRenderPipelineState:pipelineState];
    [renderEncoder setViewport:(MTLViewport){0.0, 0.0, image.size.width, image.size.height, 0.0, 0.0 }];
    [renderEncoder setFrontFacingWinding:MTLWindingClockwise];
    [renderEncoder setCullMode:MTLCullModeBack];

    //1.根据顶点/纹理坐标建立一个MTLBuffer
    static const WMTextureVertex quadVertices[] = {
        //像素坐标,纹理坐标
        { { -1,  -1 },  { 0.f, 0.f } },
        { { -1,   1 },  { 0.f, 1.f } },
        { {  1,  -1 },  { 1.f, 0.f } },
        { {  1,   1 },  { 1.f, 1.f } },
    };
    vector_uint2 viewportSize;
    viewportSize.x = image.size.width;
    viewportSize.y = image.size.height;

    NSUInteger numVertices = sizeof(quadVertices) / sizeof(WMTextureVertex);
    //2.创建我们的顶点缓冲区，并用我们的Qualsits数组初始化它
    id<MTLBuffer> vertices = [device newBufferWithBytes:quadVertices
                                     length:sizeof(quadVertices)
                                    options:MTLResourceStorageModeShared];
    //将数据加载到MTLBuffer --> 顶点函数
    [renderEncoder setVertexBuffer:vertices
                            offset:0
                           atIndex:WMVertexInputIndexVertices];

    //将数据加载到MTLBuffer --> 顶点函数
    [renderEncoder setVertexBytes:&viewportSize
                           length:sizeof(viewportSize)
                          atIndex:WMVertexInputIndexViewportSize];

    //7.设置纹理对象
    [renderEncoder setFragmentTexture:nowtexture atIndex:WMTextureIndexBaseColor];

    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip
                      vertexStart:0
                      vertexCount:numVertices];


//    MTLCaptureManager *mcaptureManger = [MTLCaptureManager sharedCaptureManager];
//    [mcaptureManger startCaptureWithCommandQueue:commandQueue];
//    [commandBuffer computeCommandEncoder];


    [renderEncoder endEncoding];

    [commandBuffer commit];

    [commandBuffer waitUntilCompleted];


    
    

    
    
    
    float size = nowtexture.width * nowtexture.height * 4;
    void *buffer = malloc(size);
    
    [nowtexture getBytes:buffer bytesPerRow:nowtexture.width * 4 bytesPerImage:0 fromRegion:MTLRegionMake2D(0, 0, nowtexture.width, nowtexture.height) mipmapLevel:0 slice:0];
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
    float bytesPerRow = 4 * nowtexture.width;
    //颜色空间格式;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    //位图图形的组件信息 - 默认的
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    //颜色映射
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;

    //将帧缓存区里像素点绘制到一张图片上;
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
    CGImageRef imageRef = CGImageCreate(nowtexture.width, nowtexture.height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, YES, renderingIntent);

    
    UIGraphicsBeginImageContext(CGSizeMake(nowtexture.width, nowtexture.height));
    CGContextRef context = UIGraphicsGetCurrentContext();
    //将图片绘制上去
    CGContextDrawImage(context, CGRectMake(0, 0, nowtexture.width, nowtexture.height), imageRef);

    CGContextTranslateCTM(context, 0, nowtexture.height);
    CGContextScaleCTM(context, 1.0, -1.0);//y轴缩放-1，即为以y轴翻转
    CGContextTranslateCTM(context, 0, 0);
    CGContextDrawImage(context, CGRectMake(0, 0, nowtexture.width, nowtexture.height), imageRef);

    //从context中获取图片
    UIImage *imagenow = UIGraphicsGetImageFromCurrentImageContext();
    //结束图片context处理
    UIGraphicsEndImageContext();
    
    //释放buffer
    free(buffer);

    return imagenow;
}

@end
