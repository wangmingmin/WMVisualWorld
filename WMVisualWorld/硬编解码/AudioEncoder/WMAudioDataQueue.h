//
//  CCAudioDataQueue.h
//  001-Demo
//
//  Created on 2021年2/16.
//  Copyright © 2021年. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WMAudioDataQueue : NSObject
@property (nonatomic, readonly) int count;

+(instancetype) shareInstance;

- (void)addData:(id)obj;

- (id)getData;
@end
