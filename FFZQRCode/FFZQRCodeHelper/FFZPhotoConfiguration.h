//
//  FFZPhotoConfiguration.h
//  FFZQRCode
//
//  Created by 景格_徐薛波 on 2017/8/31.
//  Copyright © 2017年 非非宅. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FFZPhotoConfiguration : NSObject
/**
 Whether the photo output is enabled or not.
 Changing this value after the session has been opened
 on the SCRecorder has no effect.
 */
@property (assign, nonatomic) BOOL enabled;

/**
 If set, every other properties but "enabled" will be ignored
 and this options dictionary will be used instead.
 */
@property (copy, nonatomic) NSDictionary *__nullable options;

/**
 Returns the output settings for the
 */
- (NSDictionary *__nonnull)createOutputSettings;
@end
