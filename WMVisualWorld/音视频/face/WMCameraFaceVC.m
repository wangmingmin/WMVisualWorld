//
//  WMCameraFaceVC.m
//  WMVisualWorld
//
//  Created by wangmm on 2021/7/19.
//

#import "WMCameraFaceVC.h"
#import "WMFaceCameraManger.h"
#import "WMFacePreviewView.h"

@interface WMCameraFaceVC () <WMFaceDetectionDelegate>
@property (nonatomic, strong) WMFaceCameraManger *cameraManager;
@property (strong, nonatomic) WMFacePreviewView *previewView;
@property (nonatomic, strong) UIButton * actionButton;
@end

@implementation WMCameraFaceVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setupCamera];
}

-(void)setupCamera
{
    self.previewView = [[WMFacePreviewView alloc] initWithFrame:CGRectMake(0, 0, self.view.window.frame.size.width , self.view.window.frame.size.height)];
    [self.view addSubview:self.previewView];
    

    self.cameraManager = [[WMFaceCameraManger alloc] init];
    self.cameraManager.faceDetectionDelegate = self;
    NSError *error;
    if ([self.cameraManager setupSessionOutputs:&error]) {
        [self.cameraManager switchCameras];
        [self.previewView setSession:self.cameraManager.captureSession];
        [self.cameraManager startSession];
    } else {
        NSLog(@"Error: %@", [error localizedDescription]);
    }
    
    CGSize screenRect = [[UIScreen mainScreen] bounds].size;
    self.actionButton = [[UIButton alloc] initWithFrame:CGRectMake(screenRect.width/2.0 - 25, screenRect.height-50-50, 50, 50)];
    self.actionButton.backgroundColor = [UIColor whiteColor];
    self.actionButton.layer.cornerRadius = 25.0;
    [self.actionButton addTarget:self action:@selector(onActionButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.actionButton];

}

-(void)onActionButton:(UIButton *)sender
{
    sender.selected = !sender.selected;
    [self.cameraManager switchCameras];
    [self.previewView removeFaceLayer];
}

-(void)didDetectFaces:(NSArray *)faces
{
    [self.previewView didDetectFaces:faces];    
}

-(void)dealloc
{
    [self.cameraManager stopSession];
}
@end
