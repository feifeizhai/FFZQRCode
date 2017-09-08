//
//  FFZRecorderDelegate.h
//  FFZQRCode
//
//  Created by 景格_徐薛波 on 2017/8/31.
//  Copyright © 2017年 非非宅. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "FFZRecorder.h"
@class FFZRecorder;
typedef NS_ENUM(NSInteger, SCFlashMode) {
    FFZFlashModeOff  = AVCaptureFlashModeOff,
    FFZFlashModeOn   = AVCaptureFlashModeOn,
    FFZFlashModeAuto = AVCaptureFlashModeAuto,
    FFZFlashModeLight
};
@protocol FFZRecorderDelegate <NSObject>
@optional

/**
 Called when the recorder has reconfigured the videoInput
 */
- (void)recorder:(FFZRecorder *__nonnull)recorder didReconfigureVideoInput:(NSError *__nullable)videoInputError;

/**
 Called when the recorder has reconfigured the audioInput
 */
- (void)recorder:(FFZRecorder *__nonnull)recorder didReconfigureAudioInput:(NSError *__nullable)audioInputError;

/**
 Called when the flashMode has changed
 */
- (void)recorder:(FFZRecorder *__nonnull)recorder didChangeFlashMode:(SCFlashMode)flashMode error:(NSError *__nullable)error;

/**
 Called when the recorder has lost the focus. Returning true will make the recorder
 automatically refocus at the center.
 */
- (BOOL)recorderShouldAutomaticallyRefocus:(FFZRecorder *__nonnull)recorder;

/**
 Called before the recorder will start focusing
 */
- (void)recorderWillStartFocus:(FFZRecorder *__nonnull)recorder;

/**
 Called when the recorder has started focusing
 */
- (void)recorderDidStartFocus:(FFZRecorder *__nonnull)recorder;

/**
 Called when the recorder has finished focusing
 */
- (void)recorderDidEndFocus:(FFZRecorder *__nonnull)recorder;

/**
 Called before the recorder will start adjusting exposure
 */
- (void)recorderWillStartAdjustingExposure:(FFZRecorder *__nonnull)recorder;

/**
 Called when the recorder has started adjusting exposure
 */
- (void)recorderDidStartAdjustingExposure:(FFZRecorder *__nonnull)recorder;

/**
 Called when the recorder has finished adjusting exposure
 */
- (void)recorderDidEndAdjustingExposure:(FFZRecorder *__nonnull)recorder;

/**
 Gives an opportunity to the delegate to create an info dictionary for a record segment.
 */
- (NSDictionary *__nullable)createSegmentInfoForRecorder:(FFZRecorder *__nonnull)recorder;


- (void)recorder:(FFZRecorder *__nonnull)recorder didFinishQRScanWithResoult:(NSString *_Nonnull)resoult;



@end

