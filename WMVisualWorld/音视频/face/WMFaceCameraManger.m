//
//  WMFaceOrScanCameraManger.m
//  WMVisualWorld
//
//  Created by wangmm on 2021/7/19.
//

#import "WMFaceCameraManger.h"
#import <AVFoundation/AVFoundation.h>

NSString *const WMCameraErrorDomain = @"com.wmm.WMCameraErrorDomain";
NSInteger const WMMetadataOutputNotification = 201;

@interface WMFaceCameraManger ()<AVCaptureMetadataOutputObjectsDelegate>
@property(nonatomic,strong)AVCaptureMetadataOutput  *metadataOutput;
@end

@implementation WMFaceCameraManger

- (BOOL)setupSessionOutputs:(NSError **)error {
    
    if (![self setupSessionAVInput:nil]) {
        return NO;
    }
    
    self.metadataOutput = [[AVCaptureMetadataOutput alloc]init];
    
    //为捕捉会话添加设备
    if ([self.captureSession canAddOutput:self.metadataOutput]){
        [self.captureSession addOutput:self.metadataOutput];
        
        
        //获得人脸属性
        NSArray *metadatObjectTypes = @[AVMetadataObjectTypeFace];
        
        //设置metadataObjectTypes 指定对象输出的元数据类型。
        /*
         限制检查到元数据类型集合的做法是一种优化处理方法。可以减少我们实际感兴趣的对象数量
         支持多种元数据。这里只保留对人脸元数据感兴趣
         */
        self.metadataOutput.metadataObjectTypes = metadatObjectTypes;
        
        //创建主队列： 因为人脸检测用到了硬件加速，而且许多重要的任务都在主线程中执行，所以需要为这次参数指定主队列。
        dispatch_queue_t mainQueue = dispatch_get_main_queue();
        
        
        //通过设置AVCaptureVideoDataOutput的代理，就能获取捕获到一帧一帧数据
        [self.metadataOutput setMetadataObjectsDelegate:self queue:mainQueue];
     
        return YES;
    }else {
        //报错
        if (error) {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey:@"Failed to still image output"};
            
            *error = [NSError errorWithDomain:WMCameraErrorDomain code:WMMetadataOutputNotification userInfo:userInfo];
            
        }
        return NO;
    }

}


//捕捉数据
-(void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    //捕捉的人脸数据有可能是重复的
    //使用循环，打印人脸数据
    for (AVMetadataFaceObject *face in metadataObjects) {
        
        NSLog(@"Face detected with ID:%li",(long)face.faceID);
        NSLog(@"Face bounds:%@",NSStringFromCGRect(face.bounds));
        
    }
    
    
    //元数据
    if ([self.faceDetectionDelegate respondsToSelector:@selector(didDetectFaces:)]) {
        [self.faceDetectionDelegate didDetectFaces:metadataObjects];
    }

}
@end
