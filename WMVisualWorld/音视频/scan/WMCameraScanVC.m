//
//  WMCameraScanVC.m
//  WMVisualWorld
//
//  Created by wangmm on 2021/7/20.
//

#import "WMCameraScanVC.h"
#import "WMScanCameraManger.h"
#import "WMScanPreviewView.h"

@interface WMCameraScanVC ()<WMCodeDetectionDelegate>
@property (nonatomic, strong) WMScanCameraManger *cameraManager;
@property (strong, nonatomic) WMScanPreviewView *previewView;
@end

@implementation WMCameraScanVC
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
    self.previewView = [[WMScanPreviewView alloc] initWithFrame:CGRectMake(0, 0, self.view.window.frame.size.width , self.view.window.frame.size.height)];
    [self.view addSubview:self.previewView];
    

    self.cameraManager = [[WMScanCameraManger alloc] init];
    self.cameraManager.codeDetectionDelegate = self;
    NSError *error;
    if ([self.cameraManager setupSessionOutputs:&error]) {
        [self.cameraManager switchCameras];
        [self.previewView setSession:self.cameraManager.captureSession];
        [self.cameraManager startSession];
    } else {
        NSLog(@"Error: %@", [error localizedDescription]);
    }

}

-(void)didDetectCodes:(NSArray *)codes
{
    [self.previewView didDetectCodes:codes];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //模拟一下，3秒后显示最后一个code的信息
        AVMetadataMachineReadableCodeObject *code = codes.lastObject;
        if (code) {
            [self showCodeStringValue:code.stringValue];
            [self.cameraManager stopSession];
        }
    });
}


-(void)showCodeStringValue:(NSString *)stringValue
{
    if (stringValue && stringValue.length>0) {
        UIAlertAction *alert = [UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [self.previewView removeCodeLayer];
            [self.cameraManager startSession];
        }];
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"" message:stringValue preferredStyle:UIAlertControllerStyleAlert];
        [alertVC addAction:alert];
        [self presentViewController:alertVC animated:YES completion:nil];
    }
}

-(void)dealloc
{
    [self.cameraManager stopSession];
}
@end
