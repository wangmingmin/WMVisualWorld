//
//  WMCameraVC.m
//  WMVisualWorld
//
//  Created by wangmm on 2021/7/13.
//

#import "WMCameraVC.h"
#import "WMCameraImageVideoVC.h"
#import "WMCameraFaceVC.h"
#import "WMCameraScanVC.h"

@interface WMCameraVC ()

@end

@implementation WMCameraVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self wm_setupUI];
}

-(void)wm_setupUI
{
    NSArray * titlesArray = @[@"拍照",@"视频录制",@"人脸识别",@"扫码"];
    int i = 0;
    CGFloat size = (UIScreen.mainScreen.bounds.size.width - 40 - 40)/2.0;
    for (NSString *titleString in titlesArray) {
        UIButton * button = [[UIButton alloc] initWithFrame:CGRectMake(20 + (i%2)*(size+40), 84 + 50 + (i/2)*(size+40), size, size)];
        [button setTitle:titleString forState:UIControlStateNormal];
        button.backgroundColor = UIColor.lightGrayColor;
        button.tag = i;
        [button addTarget:self action:@selector(wm_gotoCamera:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
        i++;
    }
}

-(void)wm_gotoCamera:(UIButton *)sender
{
    if (sender.tag == 0) {
        [self cameraImage];
    }
    if (sender.tag == 1) {
        [self cameraVideo];
    }
    if (sender.tag == 2) {
        [self scanFace];
    }
    if (sender.tag == 3) {
        [self scanCode];
    }

}

#pragma mark -
-(void)cameraImage
{
    WMCameraImageVideoVC *imageCamera = [[WMCameraImageVideoVC alloc] init];
    imageCamera.type = stillImageType;
    imageCamera.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:imageCamera animated:YES completion:nil];
}

#pragma mark -
-(void)cameraVideo
{
    WMCameraImageVideoVC *videoCamera = [[WMCameraImageVideoVC alloc] init];
    videoCamera.type = videoType;
    videoCamera.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:videoCamera animated:YES completion:nil];
}

#pragma mark -
-(void)scanFace
{
    WMCameraFaceVC *faceCamera = [[WMCameraFaceVC alloc] init];
    [self presentViewController:faceCamera animated:YES completion:nil];
}

#pragma mark -
-(void)scanCode
{
    WMCameraScanVC *scanCamera = [[WMCameraScanVC alloc] init];
    [self presentViewController:scanCamera animated:YES completion:nil];
}
@end
