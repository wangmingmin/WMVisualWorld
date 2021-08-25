//
//  WMChooseFilterScroll.m
//  WMVisualWorld
//
//  Created by wangmm on 2021/8/3.
//

#import "WMChooseFilterScroll.h"

@implementation WMChooseFilterScroll
-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        NSArray *dataArray = @[@"正常",@"二分屏",@"九分屏",@"灰度",@"六边形马赛克",@"三角形马赛克",@"圆形浴帘马赛克",@"翻转",@"缩放",@"灵魂出窍",@"抖动",@"闪白",@"毛刺",@"幻影"];
        [self setUpUI:dataArray];
    }
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame andData:(NSArray *)dataArray
{
    self = [super initWithFrame:frame];
    if (self) {
        if (!dataArray || dataArray.count==0) {
            return self;
        }
        [self setUpUI:dataArray];
    }
    return self;
}


-(void)setUpUI:(NSArray *)dataArray
{
    NSInteger idx = 0;
    for (NSString * string in dataArray) {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(10 + idx*(60+5), 0, 60, self.frame.size.height)];
        button.backgroundColor = [UIColor orangeColor];
        [button setTitle:string forState:UIControlStateNormal];
        button.tag = idx;
        button.titleLabel.numberOfLines = 0;
        [button addTarget:self action:@selector(onButton:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];
        idx ++;
    }
    self.contentSize = CGSizeMake(10 + dataArray.count*(60+5) + 5, self.frame.size.height);
}

-(void)onButton:(UIButton *)sender
{
    if (self.filterBlock) {
        self.filterBlock(sender.tag);
    }
}
@end
