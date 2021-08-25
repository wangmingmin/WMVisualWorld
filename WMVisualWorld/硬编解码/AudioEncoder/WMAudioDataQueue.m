//
//  CCAudioDataQueue.m
//  001-Demo
//
//  Created on 2021年2/16.
//  Copyright © 2021年. All rights reserved.
//

#import "WMAudioDataQueue.h"

@interface WMAudioDataQueue ()
@property (nonatomic, strong) NSMutableArray *bufferArray;
@end

@implementation WMAudioDataQueue
@synthesize count;
static WMAudioDataQueue *_instance = nil;

+(instancetype) shareInstance
{
    static dispatch_once_t onceToken ;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    }) ;
    return _instance ;
}

- (instancetype)init{
    if (self = [super init]) {
        _bufferArray = [NSMutableArray array];
        count = 0;
    }
    return self;
}

-(void)addData:(id)obj{
    @synchronized (_bufferArray) {
        [_bufferArray addObject:obj];
        count = (int)_bufferArray.count;
    }
}

- (id)getData{
    @synchronized (_bufferArray) {
        id obj = nil;
        if (count) {
            obj = [_bufferArray firstObject];
            [_bufferArray removeObject:obj];
            count = (int)_bufferArray.count;
        }
        return obj;
    }
}
@end
