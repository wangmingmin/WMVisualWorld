//
//  WMCameraImageVideoVC.m
//  WMVisualWorld
//
//  Created by wangmm on 2021/7/20.
//

#import "WMCameraImageVideoVC.h"
#import "WMPreviewView.h"
#import "WMCameraManger.h"
#import "WMOverlayView.h"
NSString *const THThumbnailCreatedNotification = @"THThumbnailCreated";

@interface WMCameraImageVideoVC () <WMPreviewViewDelegate,WMOverlayViewDelegate>
@property (strong, nonatomic) WMCameraManger *cameraManger;
@property (strong, nonatomic) WMPreviewView *previewView;
@property (strong, nonatomic) UIButton *thumbnailButton;
@property (strong, nonatomic) WMOverlayView *overlayView;
@end

@implementation WMCameraImageVideoVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateThumbnail:)
                                                 name:THThumbnailCreatedNotification
                                               object:nil];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self wm_gotoCamera];
}

- (void)updateThumbnail:(NSNotification *)notification {
    UIImage *image = notification.object;
    self.thumbnailButton = [[UIButton alloc] initWithFrame:CGRectMake(10, self.view.window.frame.size.height-90-10, 55, 90)];
    [self.view addSubview:self.thumbnailButton];
    [self.thumbnailButton setBackgroundImage:image forState:UIControlStateNormal];
    self.thumbnailButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.thumbnailButton.layer.borderWidth = 1.0f;
    [self.thumbnailButton addTarget:self action:@selector(showCameraRoll) forControlEvents:UIControlEventTouchUpInside];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.5 animations:^{
            CGRect rect = self.thumbnailButton.frame;
            rect.origin.x = -rect.size.width;
            self.thumbnailButton.frame = rect;
        }];
    });
    
    NSTimer *timer = [NSTimer timerWithTimeInterval:4 repeats:NO block:^(NSTimer * _Nonnull timer) {
        [self.thumbnailButton removeFromSuperview];
    }];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}

- (void)showCameraRoll{
    UIImagePickerController *controller = [[UIImagePickerController alloc] init];
    controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    //展示相册的类型，UIImagePickerControllerSourceTypeCamera可返回照片和视频
    NSArray* mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
//    NSString *requiredMediaType = ( NSString *)kUTTypeImage;
//    NSString *requiredMediaType1 = ( NSString *)kUTTypeMovie;
    controller.mediaTypes = mediaTypes;
    [self presentViewController:controller animated:YES completion:nil];
}

-(void)wm_gotoCamera
{
    
    self.previewView = [[WMPreviewView alloc] initWithFrame:CGRectMake(0, 0, self.view.window.frame.size.width , self.view.window.frame.size.height)];
    [self.view addSubview:self.previewView];
    
    self.cameraManger = [[WMCameraManger alloc] init];

    NSError *error;
    if ([self.cameraManger setupSession:&error]) {
        [self.previewView setSession:self.cameraManger.captureSession];
        self.previewView.delegate = self;
        [self.cameraManger startSession];
    } else {
        NSLog(@"Error: %@", [error localizedDescription]);
    }
    
    self.previewView.tapToFocusEnabled = self.cameraManger.cameraSupportsTapToFocus;
    self.previewView.tapToExposeEnabled = self.cameraManger.cameraSupportsTapToExpose;
    
    self.overlayView = [[WMOverlayView alloc] initWithFrame:CGRectMake(0, 0, self.view.window.frame.size.width , self.view.window.frame.size.height)];
    self.overlayView.delegate = self;
    [self.view addSubview:self.overlayView];
    

    if (self.type == stillImageType) {
        self.overlayView.type = stillImage;
    }
    if (self.type == videoType) {
        self.overlayView.type = video;
    }
}

#pragma mark -
-(void)WMOverlayViewDelegateFlash:(BOOL)flash
{
    //闪光灯
    self.cameraManger.flashMode = flash?AVCaptureFlashModeOn:AVCaptureFlashModeOff;
}

-(void)WMOverlayViewDelegateTorch:(BOOL)torch
{
    //手电筒
    self.cameraManger.torchMode = torch?AVCaptureTorchModeOn:AVCaptureTorchModeOff;
}

-(void)WMOverlayViewDelegateStillImage
{
    //拍照
    [self.cameraManger captureStillImage];
}

-(void)WMOverlayViewDelegateVideo
{
    //录制视频
    if (!self.cameraManger.isRecording) {
        dispatch_async(dispatch_queue_create("com.tapharmonic.kamera", NULL), ^{
            [self.cameraManger startRecording];
        });
    } else {
        [self.cameraManger stopRecording];
    }
}

-(void)WMOverlayViewDelegateStopAction
{
    if (self.cameraManger.isRecording) {
        [self.cameraManger stopRecording];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)tappedToFocusAtPoint:(CGPoint)point {
    [self.cameraManger focusAtPoint:point];
}

- (void)tappedToExposeAtPoint:(CGPoint)point {
    [self.cameraManger exposeAtPoint:point];
}

- (void)tappedToResetFocusAndExposure {
    [self.cameraManger resetFocusAndExposureModes];
}
@end
