//
//  WMCodeVideoVC.m
//  WMVisualWorld
//
//  Created by wangmm on 2021/7/26.
//

#import "WMCodeVideoVC.h"
#import "WMCameraForCodeManager.h"
#import "WMVideoEncoder.h"
#import "WMVideoDecoder.h"
#import "WMAAPLEAGLLayer.h"

#import "WMAudioEncoder.h"
#import "WMAudioDecoder.h"
#import "WMAudioPCMPlayer.h"
#import "WMAVConfig.h"

//#import "WMBluetoothPeripheral.h"
//#import "WMBluetoothCentral.h"

@interface WMCodeVideoVC () <WMCameraForCodeManagerDelegate,WMVideoEncoderDelegate,WMVideoDecoderDelegate,WMAudioDecoderDelegate,WMAudioEncoderDelegate>
@property (nonatomic, strong) WMCameraForCodeManager *capture;
@property (nonatomic, strong) WMVideoEncoder *videoEncoder;
@property (nonatomic, strong) WMVideoDecoder *videoDecoder;
@property (nonatomic, strong) WMAAPLEAGLLayer *displayLayer;

@property (nonatomic, strong) WMAudioEncoder *audioEncoder;
@property (nonatomic, strong) WMAudioDecoder *audioDecoder;
@property (nonatomic, strong) WMAudioPCMPlayer *pcmPlayer;

@property (nonatomic, strong) NSFileHandle *handleVideo;
@property (nonatomic, copy) NSString *pathVideo;
@property (nonatomic, strong) NSFileHandle *handleAudio;
@property (nonatomic, copy) NSString *pathAudio;

@property (nonatomic, strong) UIButton *starButton;
@property (nonatomic, strong) UIButton *playButton;

//@property (nonatomic, strong) UIButton *bluetoothPeripheralButton;
//@property (nonatomic, strong) UIButton *bluetoothCentralButton;
//@property (nonatomic, strong) WMBluetoothPeripheral *managerP;
//@property (nonatomic, strong) WMBluetoothCentral *managerC;
@end

@implementation WMCodeVideoVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"硬编解码";
    self.view.backgroundColor = [UIColor whiteColor];
//    [self.view addSubview:self.playButton];
    [self.view addSubview:self.starButton];
//    [self.view addSubview:self.bluetoothPeripheralButton];
//    [self.view addSubview:self.bluetoothCentralButton];
    
    [self checkVideo];
    [self checkAudio];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self startCapture];
}

-(void)checkVideoPath
{
    //测试写入文件
    _pathVideo = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"wmh264test.h264"];
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:_pathVideo]) {
        if ([manager removeItemAtPath:_pathVideo error:nil]) {
            NSLog(@"删除成功");
            if ([manager createFileAtPath:_pathVideo contents:nil attributes:nil]) {
                NSLog(@"创建文件");
            }
        }
    }else {
        if ([manager createFileAtPath:_pathVideo contents:nil attributes:nil]) {
            NSLog(@"创建文件");
        }
    }
    NSLog(@"%@", _pathVideo);

    _handleVideo = [NSFileHandle fileHandleForWritingAtPath:_pathVideo];
}

-(void)checkAudioPath
{
    //测试写入文件
    _pathAudio = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"wmacctest.aac"];
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:_pathAudio]) {
        if ([manager removeItemAtPath:_pathAudio error:nil]) {
            NSLog(@"删除成功");
            if ([manager createFileAtPath:_pathAudio contents:nil attributes:nil]) {
                NSLog(@"创建文件");
            }
        }
    }else {
        if ([manager createFileAtPath:_pathAudio contents:nil attributes:nil]) {
            NSLog(@"创建文件");
        }
    }
    NSLog(@"%@", _pathAudio);

    _handleAudio = [NSFileHandle fileHandleForWritingAtPath:_pathAudio];
}

-(void)checkVideo
{
    //测试写入文件
    [self checkVideoPath];
    
    //检查权限
    [WMCameraForCodeManager checkCameraAuthor];

    //捕获媒体
    _capture = [[WMCameraForCodeManager alloc] initWithType:WMCameraForCodeManagerTypeAll];//这是我只捕获了视频
    CGSize size = CGSizeMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
    [_capture prepareWithPreviewSize:size];  //捕获视频时传入预览层大小
    _capture.preview.frame = CGRectMake(0, 0, size.width, size.height);
    [self.view addSubview:_capture.preview];
    self.capture.delegate = self;

    WMVideoConfig *config = [WMVideoConfig defaultConifg];
    config.width = _capture.witdh;
    config.height = _capture.height;
    config.bitrate = config.height * config.width * 5;
    
    _videoEncoder = [[WMVideoEncoder alloc] initWithConfig:config];
    _videoEncoder.delegate = self;
    
    _videoDecoder = [[WMVideoDecoder alloc] initWithConfig:config];
    _videoDecoder.delegate = self;
    
    _displayLayer = [[WMAAPLEAGLLayer alloc] initWithFrame:CGRectMake(size.width, 100, size.width, size.height)];
    [self.view.layer addSublayer:_displayLayer];

}

-(void)checkAudio
{
    //测试写入文件
    [self checkAudioPath];
    
    //检查权限
    [WMCameraForCodeManager checkMicrophoneAuthor];

    //aac编码器
    _audioEncoder = [[WMAudioEncoder alloc] initWithConfig:[WMAudioConfig defaultConifg]];
    _audioEncoder.delegate = self;
    
    _audioDecoder = [[WMAudioDecoder alloc]initWithConfig:[WMAudioConfig defaultConifg]];
    _audioDecoder.delegate = self;
    
    _pcmPlayer = [[WMAudioPCMPlayer alloc]initWithConfig:[WMAudioConfig defaultConifg]];
}
//开始捕捉
- (void)startCapture {
     [self.capture start];
}

//结束捕捉
- (void)stopCapture:(id)sender {
    [self.capture stop];
}

//关闭文件
- (void)closeFile:(id)sender {
    [_handleVideo closeFile];
    [_handleAudio closeFile];
}

#pragma mark - delegate
//捕获音视频回调
- (void)captureSampleBuffer:(CMSampleBufferRef)sampleBuffer type: (WMCameraForCodeManagerType)type {
    if (type == WMCameraForCodeManagerTypeVideo) {
        [_videoEncoder encodeVideoSampleBuffer:sampleBuffer];
    }else if (type == WMCameraForCodeManagerTypeAudio) {
        //音频数据
        //1.可以直接播放PCM数据，测试效果(边录音边播放会有回音)
//         NSData *pcmData = [_audioEncoder convertAudioSamepleBufferToPcmData:sampleBuffer];
//         [_pcmPlayer playPCMData:pcmData];
        //2.AAC编码
//        _audioEncoder.isWriteToFile = YES;//写入本地文件（需要添加头）
        [_audioEncoder encodeAudioSamepleBuffer:sampleBuffer];
    }else {
        
    }
}

#pragma mark - CCAudioEncoder/Decoder Delegate
//aac编码回调
- (void)audioEncodeCallback:(NSData *)aacData {
 
     //1.写入文件
    //将pcm转换成AAC的过程即是编码
//     [_handleAudio seekToEndOfFile];
//     [_handleAudio writeData:aacData];

    //AAC文件本身可以直接播放(如果只是录制和播放，并没有传输，可以考虑不做解码)，这里将AAC文件转换成PCM音频裸流的过程即是解码
    //2.直接解码
    [_audioDecoder decodeAudioAACData:aacData];
    
}


-(void)audioDecodeCallback:(NSData *)pcmData
{
    //同一个设备，音频数据(边录音边播放会有回音)
    //1.直接播放PCM数据
    [_pcmPlayer playPCMData:pcmData];
}


#pragma mark - h264编码回调（sps/pps）
- (void)videoEncodeCallbacksps:(NSData *)sps pps:(NSData *)pps {
    
    //    测试写入文件
//    [_handleVideo seekToEndOfFile];
//    [_handleVideo writeData:sps];
//    [_handleVideo seekToEndOfFile];
//    [_handleVideo writeData:pps];

    //解码（sps和pps不能直接合在一起解码）
    //测试一下解码，编码完成直接解码
    [_videoDecoder decodeNaluData:sps];
    [_videoDecoder decodeNaluData:pps];
    
}
//h264编码回调 （流数据）
- (void)videoEncodeCallback:(NSData *)h264Data {
    //    测试写入文件
//    [_handleVideo seekToEndOfFile];
//    [_handleVideo writeData:h264Data];
    
    //编码
    //测试一下解码，编码完成直接解码
    [_videoDecoder decodeNaluData:h264Data];
}

//h264解码回调
- (void)videoDecodeCallback:(CVPixelBufferRef)imageBuffer {
    //显示
    /*
     CVPixelBufferRef -> 显示到屏幕上
     openGL ES 图形渲染/图片渲染（纹理）
     我们把CVPixelBufferRef 当做纹理来处理
     openGL ES 默认RGB颜色体系，需要把YUV（CVPixelBufferRef）转成RGB
     （直接使用YUV展示也是可以的，只不过显示的是黑白的，没有颜色，加上UV才会变成彩色）
     所以这里涉及到2个纹理：Y图层纹理+UV图层纹理
     */
    if (imageBuffer) {
        _displayLayer.pixelBuffer = imageBuffer;
    }
    
}


#pragma mark - 按钮
-(UIButton *)starButton
{
    if (!_starButton) {
        _starButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2.0 - 55, self.view.bounds.size.height-100, 50, 50)];
        _starButton.backgroundColor = [UIColor purpleColor];
        [_starButton setTitle:@"开始" forState:UIControlStateNormal];
        [_starButton setTitle:@"停止" forState:UIControlStateSelected];
        [_starButton addTarget:self action:@selector(onStarButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _starButton;
}

-(void)onStarButton:(UIButton *)sender
{
    sender.selected = !sender.selected;
    if (sender.selected) {
        [_videoEncoder reEncodePrepare];
        [self checkVideoPath];
        [self checkAudioPath];
        [self.capture starRecord];
        self.playButton.userInteractionEnabled = NO;
        self.playButton.backgroundColor = [UIColor redColor];
    }else {
        [self.capture stopRecord];
        self.playButton.userInteractionEnabled = YES;
        self.playButton.backgroundColor = [UIColor greenColor];
    }
}

-(UIButton *)playButton
{
    if (!_playButton) {
        _playButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2.0 + 5, self.view.bounds.size.height-100, 50, 50)];
        _playButton.backgroundColor = [UIColor greenColor];
        [_playButton setTitle:@"播放" forState:UIControlStateNormal];
        [_playButton addTarget:self action:@selector(onPlayButton) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playButton;
}

-(void)onPlayButton
{
    NSData* videoData = [NSData dataWithContentsOfFile:_pathVideo];
    NSData* audioData = [NSData dataWithContentsOfFile:_pathAudio];

    
    if (!audioData) {
        NSLog(@"there is no audioData!");
    }
    if (!videoData) {
        NSLog(@"there is no videoData!");
    }
    if (!audioData && !videoData) {
        NSLog(@"there is nothing data for Decode!");
        return;
    }
//    [_audioDecoder decodeAudioAACData:audioData];
        

    uint8_t *frame = (uint8_t *)videoData.bytes;
    [self wmdecodeNaluData:frame size:(uint32_t)videoData.length block:^(NSInteger orgPointer, NSInteger rangeLength) {
        NSData *naluData = [videoData subdataWithRange:NSMakeRange(orgPointer, rangeLength-orgPointer)];//数据
//        [self->_videoDecoder decodeNaluData:naluData];
    }];
    
}

#define H264_START_CODE 0x000001
- (void)wmdecodeNaluData:(uint8_t *)pBuf size:(uint32_t)bufLen block:(void(^)(NSInteger orgPointer,NSInteger rangeLength))block
{
    if (!block || pBuf == NULL) {
        return;
    }
    NSInteger orgPointer = 0;

    uint32_t val;
    uint32_t offset;
    
    offset = 0;
    
    if (pBuf[0] == 0 && pBuf[1] == 0 && pBuf[2] == 0 && pBuf[3] == 1) {
        pBuf += 4;
        offset = 4;
    } else if (pBuf[0] == 0 && pBuf[1] == 0 && pBuf[2] == 1) {
        pBuf += 3;
        offset = 3;
    }
    val = 0xffffffff;
    while (offset < bufLen - 3) {
        val <<= 8;
        val |= *pBuf++;
        offset++;
        if (val == H264_START_CODE) {
            NSInteger totalLength = offset-4;//找到下一个起始位时的位置
            block(orgPointer,totalLength);
            orgPointer = offset-4;
        }
//        if ((val & 0x00ffffff) == H264_START_CODE) {
//            NSInteger totalLength = offset-3;//找到下一个起始位时的位置
//            block(orgPointer,totalLength);
//            orgPointer = offset-3;
//        }
    }
}

#pragma mark -
//-(UIButton *)bluetoothPeripheralButton
//{
//    if (!_bluetoothPeripheralButton) {
//        _bluetoothPeripheralButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2.0 + 55, self.view.bounds.size.height-100, 50, 50)];
//        _bluetoothPeripheralButton.backgroundColor = [UIColor greenColor];
//        [_bluetoothPeripheralButton setTitle:@"外围" forState:UIControlStateNormal];
//        [_bluetoothPeripheralButton addTarget:self action:@selector(onBluetoothPeripheralButton) forControlEvents:UIControlEventTouchUpInside];
//    }
//    return _bluetoothPeripheralButton;
//
//}
//
//-(void)onBluetoothPeripheralButton
//{
//    self.managerP = [[WMBluetoothPeripheral alloc] init];
//}
//
//-(UIButton *)bluetoothCentralButton
//{
//    if (!_bluetoothCentralButton) {
//        _bluetoothCentralButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width/2.0 + 105, self.view.bounds.size.height-100, 50, 50)];
//        _bluetoothCentralButton.backgroundColor = [UIColor greenColor];
//        [_bluetoothCentralButton setTitle:@"中心" forState:UIControlStateNormal];
//        [_bluetoothCentralButton addTarget:self action:@selector(onBluetoothCentralButton) forControlEvents:UIControlEventTouchUpInside];
//    }
//    return _bluetoothCentralButton;
//
//}
//
//-(void)onBluetoothCentralButton
//{
//    self.managerC = [[WMBluetoothCentral alloc] init];
//}

@end
