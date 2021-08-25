//
//  WMCameraManger.m
//  WMVisualWorld
//
//  Created by wangmm on 2021/7/13.
//

#import "WMCameraManger.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "NSFileManager+WMAdditions.h"
@import Photos;

NSString *const THThumbnailCreatedNotification2 = @"THThumbnailCreated";

@interface WMCameraManger()<AVCapturePhotoCaptureDelegate,AVCaptureFileOutputRecordingDelegate>
@property (strong, nonatomic) dispatch_queue_t videoQueue; //视频队列
@property (weak, nonatomic) AVCaptureDeviceInput *activeVideoInput;//输入
@property (strong, nonatomic) AVCapturePhotoOutput *imageOutput;
@property (strong, nonatomic) AVCaptureMovieFileOutput *movieOutput;
@property (nonatomic, assign) NSUInteger cameraCount;
@property (nonatomic, strong) AVCapturePhotoSettings *photoSetting;
@property (strong, nonatomic) NSURL *outputURL;
@end

@implementation WMCameraManger
-(BOOL)setupSession:(NSError **)error {
    //创建捕捉会话。AVCaptureSession是捕捉场景的中心，一切的开始
    self.captureSession = [[AVCaptureSession alloc]init];
    
    //AVCaptureSessionPreset分辨率，有多种选择，任君挑选
    self.captureSession.sessionPreset = [self sessionPreset];
    
    {
        //视频捕捉设备 默认返回后置摄像头
        AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        //给会话添加设备，需要事先将设备封装到AVCaptureDeviceInput对象中
        AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:error];
        
        if (videoInput) {
            //先测试是否能被添加到会话中
            if ([self.captureSession canAddInput:videoInput]) {
                [self.captureSession addInput:videoInput];
                self.activeVideoInput = videoInput;
            }
        }else {
            return NO;
        }
    }
    
    {
        //音频设备
        AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        
        //为这个设备创建一个捕捉设备输入
        AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:error];

        if (audioInput) {
            //canAddInput：测试是否能被添加到会话中
            if ([self.captureSession canAddInput:audioInput])
            {
                //将audioInput 添加到 captureSession中
                [self.captureSession addInput:audioInput];
            }
        }else {
            return NO;
        }
    }
    
    
    {
        //iOS10.0之前使用AVCaptureStillImageOutput
//        //AVCaptureStillImageOutput 实例 从摄像头捕捉静态图片
//        self.imageOutput = [[AVCaptureStillImageOutput alloc]init];
//        //配置字典：希望捕捉到JPEG格式的图片
//        self.imageOutput.outputSettings = @{AVVideoCodecKey:AVVideoCodecJPEG};

        //配置字典：希望捕捉到JPEG格式的图片
        self.photoSetting = [AVCapturePhotoSettings photoSettingsWithFormat:@{AVVideoCodecKey:AVVideoCodecTypeJPEG}];
        //是否启用自动图像稳定
        if (@available(iOS 13.0, *)) {
            self.photoSetting.photoQualityPrioritization = YES;
        } else {
            self.photoSetting.autoStillImageStabilizationEnabled = YES;
        }

        //AVCaptureStillImageOutput 实例 从摄像头捕捉静态图片
        self.imageOutput = [[AVCapturePhotoOutput alloc]init];
        [self.imageOutput setPhotoSettingsForSceneMonitoring:self.photoSetting];
        
        //输出连接 判断是否可用，可用则添加到输出连接中去
        if ([self.captureSession canAddOutput:self.imageOutput])
        {
            [self.captureSession addOutput:self.imageOutput];
        }
        [self.imageOutput.connections.lastObject setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];

    }
    
    
    //创建一个AVCaptureMovieFileOutput 实例，用于将Quick Time 电影录制到文件系统
    self.movieOutput = [[AVCaptureMovieFileOutput alloc]init];
    
    //输出连接 判断是否可用，可用则添加到输出连接中去
    if ([self.captureSession canAddOutput:self.movieOutput])
    {
        [self.captureSession addOutput:self.movieOutput];
    }

    return YES;
}

-(BOOL)setupSessionAVInput:(NSError **)error {
    //创建捕捉会话。AVCaptureSession是捕捉场景的中心，一切的开始
    //只设置了视频捕捉输入，没有设置输出,
    self.captureSession = [[AVCaptureSession alloc]init];
    
    //AVCaptureSessionPreset分辨率，有多种选择，任君挑选
    self.captureSession.sessionPreset = [self sessionPreset];
    
    {
        //视频捕捉设备 默认返回后置摄像头
        AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        //给会话添加设备，需要事先将设备封装到AVCaptureDeviceInput对象中
        AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:error];
        
        if (videoInput) {
            //先测试是否能被添加到会话中
            if ([self.captureSession canAddInput:videoInput]) {
                [self.captureSession addInput:videoInput];
                self.activeVideoInput = videoInput;
            }
        }else {
            return NO;
        }
    }

    return YES;
}

-(dispatch_queue_t)videoQueue
{
    if (!_videoQueue) {
        _videoQueue = dispatch_queue_create("wm.VideoQueue", NULL);
    }
    return _videoQueue;
}

- (NSString *)sessionPreset {
    return AVCaptureSessionPresetHigh;
}

-(void)startSession {
    //检查是否处于运行状态
    if (![self.captureSession isRunning]) {
        //使用同步调用会损耗一定的时间，则用异步的方式处理
        dispatch_async(self.videoQueue, ^{
            [self.captureSession startRunning];
        });
    }
}

- (void)stopSession {
    //检查是否处于运行状态
    if ([self.captureSession isRunning])
    {
        //使用异步方式，停止运行
        dispatch_async(self.videoQueue, ^{
            [self.captureSession stopRunning];
        });
    }
}

#pragma mark - Device Configuration   配置摄像头支持的方法
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position {
    //获取可用视频设备
    NSArray *devicess = [self getCameraDevices];
    //遍历可用的视频设备 并返回position 参数值
    for (AVCaptureDevice *device in devicess)
    {
        if (device.position == position) {
            return device;
        }
    }
    return nil;
}

//返回当前未激活的摄像头
- (AVCaptureDevice *)inactiveCamera {

    //通过查找当前激活摄像头的反向摄像头获得，如果设备只有1个摄像头，则返回nil
       AVCaptureDevice *device = nil;
      if (self.cameraCount > 1)
      {
          if ([self activeCamera].position == AVCaptureDevicePositionBack) {
               device = [self cameraWithPosition:AVCaptureDevicePositionFront];
         }else
         {
             device = [self cameraWithPosition:AVCaptureDevicePositionBack];
         }
     }
    return device;
}

- (AVCaptureDevice *)activeCamera {
    //返回当前捕捉会话对应的摄像头的device 属性
    return self.activeVideoInput.device;
}

//判断是否有超过1个摄像头可用
- (BOOL)canSwitchCameras {
    return self.cameraCount > 1;
}

-(NSUInteger)cameraCount
{
    NSArray<AVCaptureDevice *> *device = [self getCameraDevices];
    if (device) {
        return device.count;
    }
    return 0;
}

-(NSArray<AVCaptureDevice *> *)getCameraDevices
{
    if (@available(iOS 10.0, *)) {
        /**
         builtInMicrophone    内置麦克风。
         builtInWideAngleCamera    内置广角相机。
         builtInTelephotoCamera    内置摄像头设备的焦距比广角摄像头更长。
         builtInUltraWideCamera    内置相机的焦距比广角相机的焦距短。
         builtInDualCamera    广角相机和远摄相机的组合
         builtInDualWideCamera    一种设备，包括两个固定焦距的相机，一个超广角和一个广角
         builtInTripleCamera    一种设备，该设备由三个固定焦距的相机，一个超广角，一个广角和一个长焦相机组成。
         builtInTrueDepthCamera    相机和其他传感器的组合，可创建能够进行照片，视频和深度捕捉的捕捉设备。
         builtInDuoCamera    iOS 10.2 之后不推荐使用
         */
        NSArray<AVCaptureDeviceType> *deviceType = @[AVCaptureDeviceTypeBuiltInWideAngleCamera];
        
        //unspecified    未指定
        //back    后置摄像头
        //front    前置摄像头
        AVCaptureDeviceDiscoverySession *deviceDiscoverySession =  [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:deviceType mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified];
        
        //获取 devices
        NSArray<AVCaptureDevice *> *devices = deviceDiscoverySession.devices;
        return devices;
    } else {
        //[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]//10.2之前
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        NSArray<AVCaptureDevice *> *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        return devices;
#pragma clang diagnostic pop
    }
    return nil;
}

//切换摄像头
-(BOOL)switchCameras {
    //判断是否有多个摄像头
    if (![self canSwitchCameras])
    {
        return NO;
    }
    //获取当前设备的反向设备
    NSError *error;
    AVCaptureDevice *videoDevice = [self inactiveCamera];
    
    //将输入设备封装成AVCaptureDeviceInput
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    
    //判断videoInput 是否为nil
    if (videoInput)
    {
        //标注原配置变化开始
        [self.captureSession beginConfiguration];
        
        //将捕捉会话中，原本的捕捉输入设备移除
        [self.captureSession removeInput:self.activeVideoInput];
        
        //判断新的设备是否能加入
        if ([self.captureSession canAddInput:videoInput])
        {
            //能加入成功，则将videoInput 作为新的视频捕捉设备
            [self.captureSession addInput:videoInput];
            
            //将获得设备 改为 videoInput
            self.activeVideoInput = videoInput;
        }else
        {
            //如果新设备，无法加入。则将原本的视频捕捉设备重新加入到捕捉会话中
            [self.captureSession addInput:self.activeVideoInput];
        }
        
        //配置完成后， AVCaptureSession commitConfiguration 会分批的将所有变更整合在一起。
        [self.captureSession commitConfiguration];
    }else
    {
        //创建AVCaptureDeviceInput 出现错误，则通知委托来处理该错误
        [self.delegate deviceConfigurationFailedWithError:error];
        return NO;
    }

    return YES;
}


#pragma mark -
/*
    AVCapture Device 定义了很多方法，让开发者控制ios设备上的摄像头。可以独立调整和锁定摄像头的焦距、曝光、白平衡。对焦和曝光可以基于特定的兴趣点进行设置，使其在应用中实现点击对焦、点击曝光的功能。
    还可以让你控制设备的LED作为拍照的闪光灯或手电筒的使用
    
    每当修改摄像头设备时，一定要先测试修改动作是否能被设备支持。并不是所有的摄像头都支持所有功能，例如牵制摄像头就不支持对焦操作，因为它和目标距离一般在一臂之长的距离。但大部分后置摄像头是可以支持全尺寸对焦。尝试应用一个不被支持的动作，会导致异常崩溃。所以修改摄像头设备前，需要判断是否支持
 */

#pragma mark - Focus Methods 点击聚焦方法的实现

- (BOOL)cameraSupportsTapToFocus {
    
    //询问激活中的摄像头是否支持兴趣点对焦
    return [[self activeCamera]isFocusPointOfInterestSupported];
}

- (void)focusAtPoint:(CGPoint)point {
    
    AVCaptureDevice *device = [self activeCamera];
    
    //是否支持兴趣点对焦 & 是否自动对焦模式
    if (device.isFocusPointOfInterestSupported && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        
        NSError *error;
        //锁定设备准备配置，如果获得了锁
        if ([device lockForConfiguration:&error]) {
            
            //将focusPointOfInterest属性设置CGPoint
            device.focusPointOfInterest = point;
            
            //focusMode 设置为AVCaptureFocusModeAutoFocus
            device.focusMode = AVCaptureFocusModeAutoFocus;
            
            //释放该锁定
            [device unlockForConfiguration];
        }else{
            //错误时，则返回给错误处理代理
            [self.delegate deviceConfigurationFailedWithError:error];
        }
        
    }
    
}

#pragma mark - Exposure Methods   点击曝光的方法实现

- (BOOL)cameraSupportsTapToExpose {
    
    //询问设备是否支持对一个兴趣点进行曝光
    return [[self activeCamera] isExposurePointOfInterestSupported];
}

static const NSString *THCameraAdjustingExposureContext;

- (void)exposeAtPoint:(CGPoint)point {

    
    AVCaptureDevice *device = [self activeCamera];
    
    AVCaptureExposureMode exposureMode =AVCaptureExposureModeContinuousAutoExposure;
    
    //判断是否支持 AVCaptureExposureModeContinuousAutoExposure 模式
    if (device.isExposurePointOfInterestSupported && [device isExposureModeSupported:exposureMode]) {
        
        [device isExposureModeSupported:exposureMode];
        
        NSError *error;
        
        //锁定设备准备配置
        if ([device lockForConfiguration:&error])
        {
            //配置期望值
            device.exposurePointOfInterest = point;
            device.exposureMode = exposureMode;
            
            //判断设备是否支持锁定曝光的模式。
            if ([device isExposureModeSupported:AVCaptureExposureModeLocked]) {
                
                //支持，则使用kvo确定设备的adjustingExposure属性的状态。
                [device addObserver:self forKeyPath:@"adjustingExposure" options:NSKeyValueObservingOptionNew context:&THCameraAdjustingExposureContext];
                
            }
            
            //释放该锁定
            [device unlockForConfiguration];
            
        }else
        {
            [self.delegate deviceConfigurationFailedWithError:error];
        }
        
        
    }
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {

    //判断context（上下文）是否为THCameraAdjustingExposureContext
    if (context == &THCameraAdjustingExposureContext) {
        
        //获取device
        AVCaptureDevice *device = (AVCaptureDevice *)object;
        
        //判断设备是否不再调整曝光等级，确认设备的exposureMode是否可以设置为AVCaptureExposureModeLocked
        if(!device.isAdjustingExposure && [device isExposureModeSupported:AVCaptureExposureModeLocked])
        {
            //移除作为adjustingExposure 的self，就不会得到后续变更的通知
            [object removeObserver:self forKeyPath:@"adjustingExposure" context:&THCameraAdjustingExposureContext];
            
            //异步方式调回主队列，
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *error;
                if ([device lockForConfiguration:&error]) {
                    
                    //修改exposureMode
                    device.exposureMode = AVCaptureExposureModeLocked;
                    
                    //释放该锁定
                    [device unlockForConfiguration];
                    
                }else
                {
                    [self.delegate deviceConfigurationFailedWithError:error];
                }
            });
            
        }
        
    }else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    
    
}

//重新设置对焦&曝光
- (void)resetFocusAndExposureModes {

    
    AVCaptureDevice *device = [self activeCamera];
    
    
    
    AVCaptureFocusMode focusMode = AVCaptureFocusModeContinuousAutoFocus;
    
    //获取对焦兴趣点 和 连续自动对焦模式 是否被支持
    BOOL canResetFocus = [device isFocusPointOfInterestSupported]&& [device isFocusModeSupported:focusMode];
    
    AVCaptureExposureMode exposureMode = AVCaptureExposureModeContinuousAutoExposure;
    
    //确认曝光度可以被重设
    BOOL canResetExposure = [device isFocusPointOfInterestSupported] && [device isExposureModeSupported:exposureMode];
    
    //回顾一下，捕捉设备空间左上角（0，0），右下角（1，1） 中心点则（0.5，0.5）
    CGPoint centPoint = CGPointMake(0.5f, 0.5f);
    
    NSError *error;
    
    //锁定设备，准备配置
    if ([device lockForConfiguration:&error]) {
        
        //焦点可设，则修改
        if (canResetFocus) {
            device.focusMode = focusMode;
            device.focusPointOfInterest = centPoint;
        }
        
        //曝光度可设，则设置为期望的曝光模式
        if (canResetExposure) {
            device.exposureMode = exposureMode;
            device.exposurePointOfInterest = centPoint;
            
        }
        
        //释放锁定
        [device unlockForConfiguration];
        
    }else
    {
        [self.delegate deviceConfigurationFailedWithError:error];
    }
    
    
    
    
}



#pragma mark - Flash and Torch Modes    闪光灯 & 手电筒

//判断是否有闪光灯
- (BOOL)cameraHasFlash {

    return [[self activeCamera]hasFlash];

}

//闪光灯模式
- (AVCaptureFlashMode)flashMode {
    if (@available(iOS 10.0, *)) {
//        return self.photoSetting.flashMode;
        return self.imageOutput.photoSettingsForSceneMonitoring.flashMode;
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [[self activeCamera]flashMode];
#pragma clang diagnostic pop
}

//设置闪光灯
- (void)setFlashMode:(AVCaptureFlashMode)flashMode {

    //获取会话
    AVCaptureDevice *device = [self activeCamera];
    if (@available(iOS 10.0, *)) {
        //判断是否支持闪光灯模式
        NSArray *flashModes = self.imageOutput.supportedFlashModes;//AVCaptureFlashMode
        if ([flashModes containsObject:@(flashMode)]) {
            //如果支持，则锁定设备
            NSError *error;
            if ([device lockForConfiguration:&error]) {
                //修改闪光灯模式
                self.photoSetting.flashMode = flashMode;
                //修改完成，解锁释放设备
                [device unlockForConfiguration];
            }else {
                [self.delegate deviceConfigurationFailedWithError:error];
            }
        }
    }else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        if ([device isFlashModeSupported:flashMode]) {
            //如果支持，则锁定设备
            NSError *error;
            if ([device lockForConfiguration:&error]) {
                //修改闪光灯模式
                device.flashMode = flashMode;
                //修改完成，解锁释放设备
                [device unlockForConfiguration];
            }else {
                [self.delegate deviceConfigurationFailedWithError:error];
            }
        }
#pragma clang diagnostic pop
    }
    
    
}

//是否支持手电筒
- (BOOL)cameraHasTorch {

    return [[self activeCamera]hasTorch];
}

//手电筒模式
- (AVCaptureTorchMode)torchMode {

    return [[self activeCamera]torchMode];
}


//设置是否打开手电筒
- (void)setTorchMode:(AVCaptureTorchMode)torchMode {

    
    AVCaptureDevice *device = [self activeCamera];
    
    if ([device isTorchModeSupported:torchMode]) {
        
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            
            device.torchMode = torchMode;
            [device unlockForConfiguration];
        }else
        {
            [self.delegate deviceConfigurationFailedWithError:error];
        }

    }
    
}


#pragma mark - Image Capture Methods 拍摄静态图片
/*
    AVCaptureStillImageOutput 是AVCaptureOutput的子类。用于捕捉图片
 */
- (void)captureStillImage {
    {
        //iOS10.0之前使用AVCaptureStillImageOutput
        //获取连接
//        AVCaptureConnection *connection = [self.imageOutput connectionWithMediaType:AVMediaTypeVideo];
//        //程序只支持纵向，但是如果用户横向拍照时，需要调整结果照片的方向
//        //判断是否支持设置视频方向
//        if (connection.isVideoOrientationSupported) {
//            //获取方向值
//            connection.videoOrientation = [self currentVideoOrientation];
//        }
//        //定义一个handler 块，会返回1个图片的NSData数据
//        id handler = ^(CMSampleBufferRef sampleBuffer,NSError *error)
//        {
//            if (sampleBuffer != NULL) {
//                NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:sampleBuffer];
//                UIImage *image = [[UIImage alloc]initWithData:imageData];
//
//                //重点：捕捉图片成功后，将图片传递出去
//                [self writeImageToAssetsLibrary:image];
//            }else
//            {
//                NSLog(@"NULL sampleBuffer:%@",[error localizedDescription]);
//            }
//        };
//        //捕捉静态图片
//        [self.imageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:handler];
    }
        
    AVCapturePhotoSettings *newPhotoSetting = [AVCapturePhotoSettings photoSettingsFromPhotoSettings:self.photoSetting];
    //You need to call [self.session addOutput:]; before [self.photoOutput capturePhotoWithSettings:delegate:];
    //capturePhotoWithSettings:delegate:此方法一调用即拍照
    [self.imageOutput capturePhotoWithSettings:newPhotoSetting delegate:self];

    //[AVCapturePhotoSettings photoSettings]默认返回AVFileTypeJPEG
    //    [self.imageOutput capturePhotoWithSettings:[AVCapturePhotoSettings photoSettings] delegate:self];

}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error  API_AVAILABLE(ios(11.0)){
    if (!error) {
        CGImageRef ref = [photo CGImageRepresentation];
        //这里是用的是生成图片时的设备方向，如果需要按照拍照时的设备方向，可以在capureOutput:willCapturePhotoForResolvedSettings:中保存
        UIImageOrientation orientation = [self getUIImageOrientationFromDevice];
        UIImage *tempImage = [UIImage imageWithCGImage:ref scale:1.0 orientation:orientation];
        [self writeImageToAssetsLibrary:tempImage];
    }
}

// 这个方法可以放在UIDeviceOrientation的Category中统一定义
- (UIImageOrientation)getUIImageOrientationFromDevice {
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    switch (orientation) {
        case UIDeviceOrientationPortrait:
        case UIDeviceOrientationFaceUp:
            return UIImageOrientationRight;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
        case UIDeviceOrientationFaceDown:
            return UIImageOrientationLeft;
        case UIDeviceOrientationLandscapeLeft:
            return UIImageOrientationUp;
        case UIDeviceOrientationLandscapeRight:
            return UIImageOrientationDown;
        default:
            return UIImageOrientationUp;
            break;
    }
}


/*
    Assets Library 框架
    用来让开发者通过代码方式访问iOS photo
    注意：会访问到相册，需要修改plist 权限。否则会导致项目崩溃
 */
- (void)writeImageToAssetsLibrary:(UIImage *)image {

//    //创建ALAssetsLibrary  实例
//    ALAssetsLibrary *library = [[ALAssetsLibrary alloc]init];
//    //参数1:图片（参数为CGImageRef 所以image.CGImage）
//    //参数2:方向参数 转为NSUInteger
//    //参数3:写入成功、失败处理
//    [library writeImageToSavedPhotosAlbum:image.CGImage
//                              orientation:(NSUInteger)image.imageOrientation
//                          completionBlock:^(NSURL *assetURL, NSError *error) {
//        //成功后，发送捕捉图片通知。用于绘制程序的左下角的缩略图
//        if (!error)
//        {
//            [self postThumbnailNotifification:image];
//        }else
//        {
//            //失败打印错误信息
//            id message = [error localizedDescription];
//            NSLog(@"%@",message);
//        }
//    }];
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromImage:image];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        //成功后，发送捕捉图片通知。用于绘制程序的左下角的缩略图
        if (success)
        {
            [self postThumbnailNotifification:image];
        }else {
            //失败打印错误信息
            id message = [error localizedDescription];
            NSLog(@"%@",message);
        }
    }];

}

//发送缩略图通知
- (void)postThumbnailNotifification:(UIImage *)image {
    
    //回到主队列
    dispatch_async(dispatch_get_main_queue(), ^{
        //发送请求
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:THThumbnailCreatedNotification2 object:image];
    });
}

#pragma mark -
//获取方向值
- (AVCaptureVideoOrientation)currentVideoOrientation {
    
    AVCaptureVideoOrientation orientation;
    
    //获取UIDevice 的 orientation
    switch ([UIDevice currentDevice].orientation) {
        case UIDeviceOrientationPortrait:
            orientation = AVCaptureVideoOrientationPortrait;
            break;
        case UIDeviceOrientationLandscapeRight:
            orientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            orientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        default:
            orientation = AVCaptureVideoOrientationLandscapeRight;
            break;
    }
    
    return orientation;

    return 0;
}

#pragma mark - Video Capture Methods 捕捉视频

//判断是否录制状态
- (BOOL)isRecording {

    return self.movieOutput.isRecording;
}

//开始录制
- (void)startRecording {

    if (![self isRecording]) {
        
        //获取当前视频捕捉连接信息，用于捕捉视频数据配置一些核心属性
        AVCaptureConnection * videoConnection = [self.movieOutput connectionWithMediaType:AVMediaTypeVideo];
        
        //判断是否支持设置videoOrientation 属性。
        if([videoConnection isVideoOrientationSupported])
        {
            //支持则修改当前视频的方向
            videoConnection.videoOrientation = [self currentVideoOrientation];
            
        }
        
//        //判断是否支持视频稳定 可以显著提高视频的质量。只会在录制视频文件涉及，与防抖一样
//        if([videoConnection isVideoStabilizationSupported])
//        {
//            videoConnection.enablesVideoStabilizationWhenAvailable = YES;
//        }
        
        AVCaptureDevice *device = [self activeCamera];

        // 判断是否支持光学防抖
        if ([device.activeFormat isVideoStabilizationModeSupported:AVCaptureVideoStabilizationModeCinematic]) {
            // 如果支持防抖就打开防抖
            videoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeCinematic;
        }
        
        
        //摄像头可以进行平滑对焦模式操作。即减慢摄像头镜头对焦速度。当用户移动拍摄时摄像头会尝试快速自动对焦。
        if (device.isSmoothAutoFocusEnabled) {
            NSError *error;
            if ([device lockForConfiguration:&error]) {
                
                device.smoothAutoFocusEnabled = YES;
                [device unlockForConfiguration];
            }else
            {
                [self.delegate deviceConfigurationFailedWithError:error];
            }
        }
        
        //查找写入捕捉视频的唯一文件系统URL.
        self.outputURL = [self uniqueURL];
        
        //在捕捉输出上调用方法 参数1:录制保存路径  参数2:代理
        [self.movieOutput startRecordingToOutputFileURL:self.outputURL recordingDelegate:self];
        
    }
    
    
}

- (CMTime)recordedDuration {
    
    return self.movieOutput.recordedDuration;
}


//写入视频唯一文件系统URL
- (NSURL *)uniqueURL {

    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    //temporaryDirectoryWithTemplateString  可以将文件写入的目的创建一个唯一命名的目录；
    NSString *dirPath = [fileManager temporaryDirectoryWithTemplateString:@"wmvideo.XXXXXX"];
    
    if (dirPath) {
        
        NSString *filePath = [dirPath stringByAppendingPathComponent:@"wmvideo_movie.mov"];
        return  [NSURL fileURLWithPath:filePath];
        
    }
    
    return nil;
    
}

//停止录制
- (void)stopRecording {

    //是否正在录制
    if ([self isRecording]) {
        [self.movieOutput stopRecording];
    }
}

#pragma mark - AVCaptureFileOutputRecordingDelegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput
didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
      fromConnections:(NSArray *)connections
                error:(NSError *)error {

    //错误
    if (error) {
        [self.delegate mediaCaptureFailedWithError:error];
    }else
    {
        //写入
        [self writeVideoToAssetsLibrary:[self.outputURL copy]];
        
    }
    
    self.outputURL = nil;
    

}

//写入捕捉到的视频
- (void)writeVideoToAssetsLibrary:(NSURL *)videoURL {
    
//    //ALAssetsLibrary 实例 提供写入视频的接口
//    ALAssetsLibrary *library = [[ALAssetsLibrary alloc]init];
//
//    //写资源库写入前，检查视频是否可被写入 （写入前尽量养成判断的习惯）
//    if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:videoURL]) {
//
//        //创建block块
//        ALAssetsLibraryWriteVideoCompletionBlock completionBlock;
//        completionBlock = ^(NSURL *assetURL,NSError *error)
//        {
//            if (error) {
//
//                [self.delegate assetLibraryWriteFailedWithError:error];
//            }else
//            {
//                //用于界面展示视频缩略图
//                [self generateThumbnailForVideoAtURL:videoURL];
//            }
//        };
//        //执行实际写入资源库的动作
//        [library writeVideoAtPathToSavedPhotosAlbum:videoURL completionBlock:completionBlock];
//    }
    
    BOOL videoCompatible = UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(videoURL.absoluteString);
    if (videoCompatible) {
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:videoURL];
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                //用于界面展示视频缩略图
                [self generateThumbnailForVideoAtURL:videoURL];
            }else {
                [self.delegate assetLibraryWriteFailedWithError:error];
            }
        }];
    }

}

//获取视频左下角缩略图
- (void)generateThumbnailForVideoAtURL:(NSURL *)videoURL {

    //在videoQueue 上，
    dispatch_async(self.videoQueue, ^{
        
        //建立新的AVAsset & AVAssetImageGenerator
        AVAsset *asset = [AVAsset assetWithURL:videoURL];
        
        AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
        
        //设置maximumSize 宽为100，高为0 根据视频的宽高比来计算图片的高度
        imageGenerator.maximumSize = CGSizeMake(100.0f, 0.0f);
        
        //捕捉视频缩略图会考虑视频的变化（如视频的方向变化），如果不设置，缩略图的方向可能出错
        imageGenerator.appliesPreferredTrackTransform = YES;
        
        //获取CGImageRef图片 注意需要自己管理它的创建和释放
        CGImageRef imageRef = [imageGenerator copyCGImageAtTime:kCMTimeZero actualTime:NULL error:nil];
        
        //将图片转化为UIImage
        UIImage *image = [UIImage imageWithCGImage:imageRef];
        
        //释放CGImageRef imageRef 防止内存泄漏
        CGImageRelease(imageRef);
        
        //回到主线程
        dispatch_async(dispatch_get_main_queue(), ^{
            
            //发送通知，传递最新的image
            [self postThumbnailNotifification:image];
            
        });
        
    });
    
}

@end
