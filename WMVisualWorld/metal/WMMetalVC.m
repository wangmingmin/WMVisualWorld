//
//  WMMetalVC.m
//  WMVisualWorld
//
//  Created by wangmm on 2021/8/9.
//

#import "WMMetalVC.h"
#import "WMMetalTriangleVC.h"
#import "WMMetalMuchVerVC.h"
#import "WMMetalPhotoVC.h"
#import "WMMetalVideoShowVC.h"
#import "WMMetalPlayVideoVC.h"

@interface WMMetalVC ()<UITableViewDelegate,UITableViewDataSource>
@property (nonatomic, strong) NSArray *dataArray;
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation WMMetalVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"metal";
    self.view.backgroundColor = [UIColor whiteColor];
    [self setupUI];
}

-(void)setupUI
{
    [self.view addSubview:self.tableView];
    [self.tableView reloadData];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row==0) {
        WMMetalTriangleVC *triangleVC = [[WMMetalTriangleVC alloc]init];
        [self.navigationController pushViewController:triangleVC animated:YES];
    }
    if (indexPath.row==1) {
        WMMetalMuchVerVC *muchVerVC = [[WMMetalMuchVerVC alloc]init];
        [self.navigationController pushViewController:muchVerVC animated:YES];
    }
    if (indexPath.row==2) {
        WMMetalPhotoVC *photoVC = [[WMMetalPhotoVC alloc]init];
        [self.navigationController pushViewController:photoVC animated:YES];
    }
    if (indexPath.row==3) {
        WMMetalPhotoVC *photoVC = [[WMMetalPhotoVC alloc]init];
        photoVC.showScroll = YES;
        [self.navigationController pushViewController:photoVC animated:YES];
    }
    if (indexPath.row==4) {
        WMMetalVideoShowVC *videoShowVC = [[WMMetalVideoShowVC alloc]init];
        [self.navigationController pushViewController:videoShowVC animated:YES];
    }
    if (indexPath.row==5) {
        WMMetalPlayVideoVC *playVideoVC = [[WMMetalPlayVideoVC alloc]init];
        [self.navigationController pushViewController:playVideoVC animated:YES];
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
        _dataArray = @[@"三角形",@"渲染多顶点",@"渲染图片",@"图片滤镜",@"视频捕捉(metal自带边缘检测滤镜)",@"渲染本地视频文件"];
    }
    return _dataArray;
}
@end
