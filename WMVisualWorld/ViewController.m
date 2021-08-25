//
//  ViewController.m
//  WMVisualWorld
//
//  Created by wangmm on 2021/7/13.
//

#import "ViewController.h"
#import "WMCameraVC.h"
#import "WMCodeVideoVC.h"
#import "WMOpenGLESVC.h"
#import "WMMetalVC.h"

@interface ViewController ()
@property (nonatomic, strong) NSArray *titlesArray;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"welcome";
    [self wm_setupUI];
}

-(void)wm_setupUI
{
    self.titlesArray = @[@"音视频",@"硬编解码",@"openGLES",@"metal"];
    int i = 0;
    CGFloat size = (UIScreen.mainScreen.bounds.size.width - 40 - 40)/2.0;
    for (NSString *titleString in self.titlesArray) {
        UIButton * button = [[UIButton alloc] initWithFrame:CGRectMake(20 + (i%2)*(size+40), 84 + 50 + (i/2)*(size+40), size, size)];
        [button setTitle:titleString forState:UIControlStateNormal];
        button.backgroundColor = UIColor.lightGrayColor;
        button.tag = i;
        [button addTarget:self action:@selector(wm_gotoSomeWhere:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
        i++;
    }
}

-(void)wm_gotoSomeWhere:(UIButton *)sender
{
    NSInteger tag = sender.tag;
    if (tag==0) {        
        WMCameraVC *camera = [[WMCameraVC alloc] init];
        [self.navigationController pushViewController:camera animated:YES];
    }
    if (tag==1) {
        WMCodeVideoVC *coderVC = [[WMCodeVideoVC alloc] init];
        [self.navigationController pushViewController:coderVC animated:YES];
    }
    if (tag==2) {
        WMOpenGLESVC *openglesVC = [[WMOpenGLESVC alloc] init];
        [self.navigationController pushViewController:openglesVC animated:YES];
    }
    if (tag==3) {
        WMMetalVC *metalVC = [[WMMetalVC alloc] init];
        [self.navigationController pushViewController:metalVC animated:YES];
    }

}
@end
