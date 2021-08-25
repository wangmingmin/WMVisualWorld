//
//  WMCameraForCodeManager.m
//  WMVisualWorld
//
//  Created by wangmm on 2021/7/26.
//

#import "WMCameraForCodeManager.h"


@interface WMCameraForCodeManager ()<AVCaptureAudioDataOutputSampleBufferDelegate,AVCaptureVideoDataOutputSampleBufferDelegate>
/********************控制相关**********/
//是否进行
@property (nonatomic, assign) BOOL isRunning;

/********************公共*************/
//会话
@property (nonatomic, strong) AVCaptureSession *captureSession;
//代理队列
@property (nonatomic, strong) dispatch_queue_t captureQueue;

/********************音频相关**********/
//音频设备
@property (nonatomic, strong) AVCaptureDeviceInput *audioInputDevice;
//输出数据接收
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioDataOutput;
@property (nonatomic, strong) AVCaptureConnection *audioConnection;

/********************视频相关**********/
//当前使用的视频设备
@property (nonatomic, weak) AVCaptureDeviceInput *videoInputDevice;
//前后摄像头
@property (nonatomic, strong) AVCaptureDeviceInput *frontCamera;
@property (nonatomic, strong) AVCaptureDeviceInput *backCamera;
//输出数据接收
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong) AVCaptureConnection *videoConnection;
//预览层
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *preLayer;
@property (nonatomic, assign) CGSize prelayerSize;

@end

@implementation WMCameraForCodeManager{
    //捕捉类型
    WMCameraForCodeManagerType captureType;
}

- (instancetype)initWithType:(WMCameraForCodeManagerType)type {
    self = [super init];
    if (self) {
        captureType = type;
    }
    return self;
}

-(void)prepareAudio {
    [self prepareWithPreviewSize:CGSizeZero];
}

//准备捕获(视频/音频)
- (void)prepareWithPreviewSize:(CGSize)size {
    _prelayerSize = size;
    if (captureType == WMCameraForCodeManagerTypeAudio) {
        [self setupAudio];
    }else if (captureType == WMCameraForCodeManagerTypeVideo) {
        [self setupVideo];
    }else if (captureType == WMCameraForCodeManagerTypeAll) {
        [self setupAudio];
        [self setupVideo];
    }
}

#pragma mark - Control start/stop capture or change camera
- (void)start{
    if (!self.isRunning) {
        self.isRunning = YES;
        [self.captureSession startRunning];
    }
}
- (void)stop{
    if (self.isRunning) {
        self.isRunning = NO;
        [self.captureSession stopRunning];
    }
    
}

- (void)changeCamera{
    [self switchCamera];
}

-(void)switchCamera{
    [self.captureSession beginConfiguration];
    [self.captureSession removeInput:self.videoInputDevice];
    if ([self.videoInputDevice isEqual: self.frontCamera]) {
        self.videoInputDevice = self.backCamera;
    }else{
        self.videoInputDevice = self.frontCamera;
    }
    [self.captureSession addInput:self.videoInputDevice];
    [self.captureSession commitConfiguration];
}

#pragma mark-init Audio/video
- (void)setupAudio{
    //麦克风设备
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    //将audioDevice ->AVCaptureDeviceInput 对象
    self.audioInputDevice = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:nil];
    //音频输出
    self.audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
    //配置
    [self.captureSession beginConfiguration];
    if ([self.captureSession canAddInput:self.audioInputDevice]) {
        [self.captureSession addInput:self.audioInputDevice];
    }
    if([self.captureSession canAddOutput:self.audioDataOutput]){
        [self.captureSession addOutput:self.audioDataOutput];
    }
    [self.captureSession commitConfiguration];
    
    self.audioConnection = [self.audioDataOutput connectionWithMediaType:AVMediaTypeAudio];
}


- (void)setupVideo{
    //所有video设备
    NSArray *videoDevices = [self getVideoDevices];
    //前置摄像头
    self.frontCamera = [AVCaptureDeviceInput deviceInputWithDevice:videoDevices.lastObject error:nil];
    self.backCamera = [AVCaptureDeviceInput deviceInputWithDevice:videoDevices.firstObject error:nil];
    //设置当前设备为前置
    self.videoInputDevice = self.backCamera;
    //视频输出
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    [self.videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    //kCVPixelBufferPixelFormatTypeKey它指定像素的输出格式，这个参数直接影响到生成图像的成功与否
   // kCVPixelFormatType_420YpCbCr8BiPlanarFullRange  YUV420格式.
    
    [self.videoDataOutput setVideoSettings:@{
                                             (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
                                             }];
    //配置
    [self.captureSession beginConfiguration];
    if ([self.captureSession canAddInput:self.videoInputDevice]) {
        [self.captureSession addInput:self.videoInputDevice];
    }
    if([self.captureSession canAddOutput:self.videoDataOutput]){
        [self.captureSession addOutput:self.videoDataOutput];
    }
    //分辨率
    [self setVideoPreset];
    [self.captureSession commitConfiguration];
    //commit后下面的代码才会有效
    self.videoConnection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    //设置视频输出方向
    self.videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    
    //fps
    /*
     FPS是图像领域中的定义，是指画面每秒传输帧数，通俗来讲就是指动画或视频的画面数。
     FPS是测量用于保存、显示动态视频的信息数量。每秒钟帧数愈多，所显示的动作就会越流畅。通常，要避免动作不流畅的最低是30。某些计算机视频格式，每秒只能提供15帧。
     
     */
    [self updateFps:25];
    //设置预览
    [self setupPreviewLayer];
}

-(void)starRecord
{
    //setSampleBufferDelegate:queue:此方法一经调用，即会在录屏时进行代理回调
    //可放在某个按钮的点击事件中，用户点击后方可进行采集回调，未点击前即为视频预览。
    [self.videoDataOutput setSampleBufferDelegate:self queue:self.captureQueue];
    [self.audioDataOutput setSampleBufferDelegate:self queue:self.captureQueue];
}

-(void)stopRecord
{
    [self.videoDataOutput setSampleBufferDelegate:nil queue:nil];
    [self.audioDataOutput setSampleBufferDelegate:nil queue:nil];
}

/**设置分辨率**/
- (void)setVideoPreset{
    if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset1920x1080])  {
        self.captureSession.sessionPreset = AVCaptureSessionPreset1920x1080;
        _witdh = 1080; _height = 1920;
    }else if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
        self.captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
        _witdh = 720; _height = 1280;
    }else{
        self.captureSession.sessionPreset = AVCaptureSessionPreset640x480;
        _witdh = 480; _height = 640;
    }
    
}
-(void)updateFps:(NSInteger) fps{
    //获取当前capture设备
    NSArray *videoDevices = [self getVideoDevices];
    
    //遍历所有设备（前后摄像头）
    for (AVCaptureDevice *vDevice in videoDevices) {
        //获取当前支持的最大fps
        float maxRate = [(AVFrameRateRange *)[vDevice.activeFormat.videoSupportedFrameRateRanges objectAtIndex:0] maxFrameRate];
        //如果想要设置的fps小于或等于做大fps，就进行修改
        if (maxRate >= fps) {
            //实际修改fps的代码
            if ([vDevice lockForConfiguration:NULL]) {
                vDevice.activeVideoMinFrameDuration = CMTimeMake(10, (int)(fps * 10));
                vDevice.activeVideoMaxFrameDuration = vDevice.activeVideoMinFrameDuration;
                [vDevice unlockForConfiguration];
            }
        }
    }
}
/**设置预览层**/
- (void)setupPreviewLayer{
    self.preLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    self.preLayer.frame =  CGRectMake(0, 100, self.prelayerSize.width, self.prelayerSize.height);
    //设置满屏
    self.preLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.preview.layer addSublayer:self.preLayer];
}

#pragma mark-懒加载
- (AVCaptureSession *)captureSession{
    if (!_captureSession) {
        _captureSession = [[AVCaptureSession alloc] init];
    }
    return _captureSession;
}
- (dispatch_queue_t)captureQueue{
    if (!_captureQueue) {
        _captureQueue = dispatch_queue_create("TMCapture Queue", NULL);
    }
    return _captureQueue;
}
- (UIView *)preview{
    if (!_preview) {
        _preview = [[UIView alloc] init];
    }
    return _preview;
}


- (void)dealloc{
    NSLog(@"capture销毁。。。。");
    [self destroyCaptureSession];
}

#pragma mark-销毁会话
-(void) destroyCaptureSession{
    if (self.captureSession) {
        if (captureType == WMCameraForCodeManagerTypeAudio) {
            [self.captureSession removeInput:self.audioInputDevice];
            [self.captureSession removeOutput:self.audioDataOutput];
        }else if (captureType == WMCameraForCodeManagerTypeVideo) {
            [self.captureSession removeInput:self.videoInputDevice];
            [self.captureSession removeOutput:self.videoDataOutput];
        }else if (captureType == WMCameraForCodeManagerTypeAll) {
            [self.captureSession removeInput:self.audioInputDevice];
            [self.captureSession removeOutput:self.audioDataOutput];
            [self.captureSession removeInput:self.videoInputDevice];
            [self.captureSession removeOutput:self.videoDataOutput];
        }
    }
    self.captureSession = nil;
}

#pragma mark - 输出代理
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    if ([_delegate respondsToSelector:@selector(captureSampleBuffer:type:)]) {
        if (connection == self.audioConnection) {
            [_delegate captureSampleBuffer:sampleBuffer type:WMCameraForCodeManagerTypeAudio];
        }else if (connection == self.videoConnection) {
            [_delegate captureSampleBuffer:sampleBuffer type:WMCameraForCodeManagerTypeVideo];
        }
    }
}



#pragma mark - 授权相关
/**
 *  麦克风授权
 *  0 ：未授权 1:已授权 -1：拒绝
 */
+ (int)checkMicrophoneAuthor{
    int result = 0;
    //麦克风
    AVAudioSessionRecordPermission permissionStatus = [[AVAudioSession sharedInstance] recordPermission];
    switch (permissionStatus) {
        case AVAudioSessionRecordPermissionUndetermined:
            //    请求授权
            [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
            }];
            result = 0;
            break;
        case AVAudioSessionRecordPermissionDenied://拒绝
            result = -1;
            break;
        case AVAudioSessionRecordPermissionGranted://允许
            result = 1;
            break;
        default:
            break;
    }
    return result;
    
    
}
/**
 *  摄像头授权
 *  0 ：未授权 1:已授权 -1：拒绝
 */
+ (int)checkCameraAuthor{
    int result = 0;
    AVAuthorizationStatus videoStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (videoStatus) {
        case AVAuthorizationStatusNotDetermined://第一次
            //    请求授权
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                
            }];
            break;
        case AVAuthorizationStatusAuthorized://已授权
            result = 1;
            break;
        default:
            result = -1;
            break;
    }
    return result;
    
}

-(int)test{
    int result = 0;
    AVAuthorizationStatus videoStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    switch (videoStatus) {
        case AVAuthorizationStatusNotDetermined://第一次
            break;
        case AVAuthorizationStatusAuthorized://已授权
            result = 1;
            break;
        default:
            result = -1;
            break;
    }
    return result;
}

-(NSArray<AVCaptureDevice *> *)getVideoDevices
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

@end
