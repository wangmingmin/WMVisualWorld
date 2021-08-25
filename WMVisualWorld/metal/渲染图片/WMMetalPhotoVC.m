//
//  WMMetalPhotoVC.m
//  WMVisualWorld
//
//  Created by wangmm on 2021/8/10.
//

#import "WMMetalPhotoVC.h"
#import "WMMetalPhotoRenderer.h"
#import "WMChooseFilterScroll.h"
@import Photos;

@interface WMMetalPhotoVC ()
{
    MTKView *_view;
}
@property (nonatomic, strong) WMChooseFilterScroll *filterScroll;
@property (nonatomic, strong) WMMetalPhotoRenderer *renderer;
@end

@implementation WMMetalPhotoVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //获取MTKView
    self.title = @"showPhoto";
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

    //创建CCRender
    _renderer = [[WMMetalPhotoRenderer alloc] initWithMetalKitView:_view];

    if(!_renderer)
    {
        NSLog(@"Renderer failed initialization");
        return;
    }

    //用视图大小初始化渲染器
    [_renderer mtkView:_view drawableSizeWillChange:_view.drawableSize];

    //设置MTKView代理
    _view.delegate = _renderer;
    
    if (self.showScroll) {
        [self setUpFilterChooseView];
        [self addRightBtn];
    }
}

- (void)addRightBtn {
    UIBarButtonItem *rightBarItem = [[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStylePlain target:self action:@selector(onClickedSaveBtn)];
    self.navigationItem.rightBarButtonItem = rightBarItem;
}

-(void)onClickedSaveBtn
{
    //保存图片
//    UIImage *image = [_renderer createImage];
    UIImage *image = [_renderer createimagebycache];
    if (image) {
        [self saveImage:image andFinised:^(BOOL success) {
            UIAlertAction *alert = [UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleCancel handler:nil];
            UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"" message:success?@"保存图片成功":@"保存图片失败" preferredStyle:UIAlertControllerStyleAlert];
            [alertVC addAction:alert];
            [self presentViewController:alertVC animated:YES completion:nil];
        }];
    }

}

-(void)setUpFilterChooseView
{
    [self.view addSubview:self.filterScroll];
    typeof(self)__weak weakSelf = self;
    self.filterScroll.filterBlock = ^(NSInteger index) {
        weakSelf.renderer.vertexName = @"vertexPhotoShader";
        if (index==0) {
            weakSelf.renderer.fragmentName = @"fragmentPhotoShader2";
        }
        if (index==1) {
            weakSelf.renderer.fragmentName = @"fragmentSplitScreen6Shader";
        }
        if (index==2) {
            weakSelf.renderer.fragmentName = @"fragmentHexagonMosaicShader";
        }
        [weakSelf.renderer refreshRender];
    };
}

-(WMChooseFilterScroll *)filterScroll
{
    if (!_filterScroll) {
        NSArray *dataArray = @[@"正常",@"六分屏",@"六边形马赛克"];
        _filterScroll = [[WMChooseFilterScroll alloc] initWithFrame:CGRectMake(0, 100+self.view.frame.size.width+20, self.view.frame.size.width, 80) andData:dataArray];
    }
    return _filterScroll;
}

#pragma mark - 保存图片到相册
- (void)saveImage:(UIImage *)image andFinised:(void(^)(BOOL success))finish{
    //将图片通过PHPhotoLibrary保存到系统相册
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromImage:image];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (finish) {
            dispatch_async(dispatch_get_main_queue(), ^{
                //主线程
                finish(success);
            });
        }
        NSLog(@"success = %d, error = %@ 图片已保存到相册", success, error);
    }];
}

@end
