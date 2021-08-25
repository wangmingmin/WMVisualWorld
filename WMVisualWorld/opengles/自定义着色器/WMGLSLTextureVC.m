//
//  WMGLSLTextureVC.m
//  WMVisualWorld
//  
//  Created by wangmm on 2021/8/3.
//

#import "WMGLSLTextureVC.h"
#import "WMGLSLTextureView.h"

@interface WMGLSLTextureVC ()
@property(nonatomic,strong)WMGLSLTextureView *myView;
@end

@implementation WMGLSLTextureVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"GLSL";
    self.view = self.myView;
}


-(WMGLSLTextureView *)myView
{
    if (!_myView) {
        _myView = [[WMGLSLTextureView alloc] initWithFrame:self.view.bounds];
    }
    return _myView;
}

@end
