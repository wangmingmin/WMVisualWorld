//
//  WM3DPyramidVC.m
//  WMVisualWorld
//
//  Created by wangmm on 2021/8/3.
//

#import "WM3DPyramidVC.h"
#import "WM3DPyramidView.h"

@interface WM3DPyramidVC ()
@property(nonatomic,strong)WM3DPyramidView *myView;
@end

@implementation WM3DPyramidVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"3DPyramid";
    self.view = self.myView;
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    //结束后删除缓存,特别是定时器要关掉
    [self.myView deallocCache];
}

-(WM3DPyramidView *)myView
{
    if (!_myView) {
        _myView = [[WM3DPyramidView alloc] initWithFrame:self.view.bounds];
    }
    return _myView;
}
@end
