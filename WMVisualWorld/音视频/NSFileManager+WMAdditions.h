//
//  NSFileManager+WMAdditions.h
//  WMVisualWorld
//
//  Created by wangmm on 2021/7/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSFileManager (WMAdditions)

- (NSString *)temporaryDirectoryWithTemplateString:(NSString *)templateString;

@end

NS_ASSUME_NONNULL_END
