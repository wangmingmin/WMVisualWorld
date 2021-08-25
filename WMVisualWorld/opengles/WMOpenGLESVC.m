//
//  WMOpenGLESVC.m
//  WMVisualWorld
//
//  Created by wangmm on 2021/8/2.
//

#import "WMOpenGLESVC.h"
#import "WMGLKitTextureVC.h"
#import "WMGLSLTextureVC.h"
#import "WM3DBoxVC.h"
#import "WM3DPyramidVC.h"
#import "WMPictureFilterVC.h"
#import "WMOpenglesTools.h"

@interface WMOpenGLESVC ()<UITableViewDelegate,UITableViewDataSource>
@property (nonatomic, strong) NSArray *dataArray;
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation WMOpenGLESVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"opengl es";
    self.view.backgroundColor = [UIColor whiteColor];
    [self setupUI];
    
    

}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSString *imagePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"monika.jpeg"];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    WMOpenglesTools * tools = [[WMOpenglesTools alloc] init];
    
    WMSenceVertex *tmpVertices = malloc(sizeof(WMSenceVertex) * 4);
    tmpVertices[0] = (WMSenceVertex){{-1, 1, 0}, {0, 1}};
    tmpVertices[1] = (WMSenceVertex){{-1, -1, 0}, {0, 0}};
    tmpVertices[2] = (WMSenceVertex){{1, 1, 0}, {1, 1}};
    tmpVertices[3] = (WMSenceVertex){{1, -1, 0}, {1, 0}};

    UIImage * frameBufferImage = [tools createResult_withVertex:tmpVertices andVerticesCount:4 vertexShaderName:@"SplitScreen_4" fragmentShaderName:@"SplitScreen_4" image:image];

}

-(void)setupUI
{
    [self.view addSubview:self.tableView];
    [self.tableView reloadData];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row==0) {
        WMGLKitTextureVC *kitVC = [[WMGLKitTextureVC alloc]init];
        [self.navigationController pushViewController:kitVC animated:YES];
    }
    if (indexPath.row==1) {
        WMGLSLTextureVC *glslVC = [[WMGLSLTextureVC alloc]init];
        [self.navigationController pushViewController:glslVC animated:YES];
    }
    if (indexPath.row==2) {
        WM3DBoxVC *boxVC = [[WM3DBoxVC alloc]init];
        [self.navigationController pushViewController:boxVC animated:YES];
    }
    if (indexPath.row==3) {
        WM3DPyramidVC *pyramidVC = [[WM3DPyramidVC alloc]init];
        [self.navigationController pushViewController:pyramidVC animated:YES];
    }
    if (indexPath.row==4) {
        WMPictureFilterVC *pictureFilterVC = [[WMPictureFilterVC alloc]init];
        [self.navigationController pushViewController:pictureFilterVC animated:YES];
    }

}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    NSString *titleMsg = self.dataArray[indexPath.row];
    cell.textLabel.text = titleMsg;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

-(UITableView *)tableView
{
    if (!_tableView) {
        CGSize size = UIScreen.mainScreen.bounds.size;
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
        _tableView.backgroundColor = [UIColor whiteColor];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    }
    return _tableView;
}

-(NSArray *)dataArray {
    if (!_dataArray) {
        _dataArray = @[@"GLKit加载图片纹理",@"自定义着色器加载图片纹理",@"3DBox",@"3D金字塔(索引绘图)",@"滤镜"];
    }
    return _dataArray;
}
@end
