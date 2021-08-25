//
//  WMCameraForCodeManager.h
//  WMVisualWorld
//
//  Created by wangmm on 2021/7/26.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN
//捕获类型
typedef NS_ENUM(int,WMCameraForCodeManagerType){
    WMCameraForCodeManagerTypeVideo = 0,
    WMCameraForCodeManagerTypeAudio,
    WMCameraForCodeManagerTypeAll
};


@protocol WMCameraForCodeManagerDelegate <NSObject>
@optional
- (void)captureSampleBuffer:(CMSampleBufferRef)sampleBuffer type: (WMCameraForCodeManagerType)type;
@end



/**捕获音视频*/
@interface WMCameraForCodeManager : NSObject
/**预览层*/
@property (nonatomic, strong) UIView *preview;
@property (nonatomic, weak) id<WMCameraForCodeManagerDelegate> delegate;
/**捕获视频的宽*/
@property (nonatomic, assign, readonly) NSUInteger witdh;
/**捕获视频的高*/
@property (nonatomic, assign, readonly) NSUInteger height;

- (instancetype)initWithType:(WMCameraForCodeManagerType)type;
- (instancetype)init UNAVAILABLE_ATTRIBUTE;

/** 准备工作(只捕获音频时调用)*/
- (void)prepareAudio;
//捕获内容包括视频时调用（预览层大小，添加到view上用来显示）
- (void)prepareWithPreviewSize:(CGSize)size;

/**开始启用*/
- (void)start;
/**结束启用*/
- (void)stop;
/**切换摄像头*/
- (void)changeCamera;


//授权检测
+ (int)checkMicrophoneAuthor;
+ (int)checkCameraAuthor;

//开始录制
- (void)starRecord;
//结束录制
-(void)stopRecord;
@end

NS_ASSUME_NONNULL_END
