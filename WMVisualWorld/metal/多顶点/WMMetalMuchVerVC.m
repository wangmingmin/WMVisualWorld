//
//  WMMetalMuchVerVC.m
//  WMVisualWorld
//
//  Created by wangmm on 2021/8/9.
//

#import "WMMetalMuchVerVC.h"
#import "WMMetalMuchVerRenderer.h"

@interface WMMetalMuchVerVC ()
{
    MTKView *_view;
    WMMetalMuchVerRenderer *_renderer;
}
@end

@implementation WMMetalMuchVerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    //1.获取MTKView
    self.title = @"muchVer";
    self.view.backgroundColor = [UIColor whiteColor];
    _view = [[MTKView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:_view];
    
    //一个MTLDevice 对象就代表这着一个GPU,通常我们可以调用方法MTLCreateSystemDefaultDevice()来获取代表默认的GPU单个对象.
    _view.device = MTLCreateSystemDefaultDevice();
    if(!_view.device)
    {
        NSLog(@"Metal is not supported on this device");
        return;
    }
    
    //2.创建CCRender
    _renderer = [[WMMetalMuchVerRenderer alloc] initWithMetalKitView:_view];
    if(!_renderer)
    {
        NSLog(@"Renderer failed initialization");
        return;
    }
    //用视图大小初始化渲染器
    [_renderer mtkView:_view drawableSizeWillChange:_view.drawableSize];
    //设置MTKView代理
    _view.delegate = _renderer;
}

@end
