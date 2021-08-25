//
//  WMChooseFilterScroll.h
//  WMVisualWorld
//
//  Created by wangmm on 2021/8/3.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef void(^WMChooseFilterScrollBlock)(NSInteger index);

@interface WMChooseFilterScroll : UIScrollView
-(instancetype)initWithFrame:(CGRect)frame andData:(NSArray *)dataArray;
@property (nonatomic, copy) WMChooseFilterScrollBlock filterBlock;
@end

NS_ASSUME_NONNULL_END
