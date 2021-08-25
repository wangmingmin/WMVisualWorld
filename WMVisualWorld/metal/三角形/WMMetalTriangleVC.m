//
//  WMMetalVC.m
//  WMVisualWorld
//
//  Created by wangmm on 2021/8/6.
//

#import "WMMetalTriangleVC.h"
//导入MetalKit 工具类
@import MetalKit;
#import "WMMetalTriangleRender.h"

@interface WMMetalTriangleVC ()
{
    MTKView *_view;
    
    WMMetalTriangleRender *_renderer;
    
}
@end

@implementation WMMetalTriangleVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"triangle";
    self.view.backgroundColor = [UIColor whiteColor];
    _view = [[MTKView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:_view];

    _view.device = MTLCreateSystemDefaultDevice();
    
    if(!_view.device)
    {
        NSLog(@"Metal is not supported on this device");
        return;
    }
    
    _renderer = [[WMMetalTriangleRender alloc] initWithMetalKitView:_view];
    
    if(!_renderer)
    {
        NSLog(@"Renderer failed initialization");
        return;
    }
    
    // Initialize our renderer with the view size
    [_renderer mtkView:_view drawableSizeWillChange:_view.drawableSize];
    
    _view.delegate = _renderer;


}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}
@end
