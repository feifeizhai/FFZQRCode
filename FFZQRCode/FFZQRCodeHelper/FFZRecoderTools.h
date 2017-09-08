//
//  FFZRecoderTools.h
//  FFZQRCode
//
//  Created by 景格_徐薛波 on 2017/8/31.
//  Copyright © 2017年 非非宅. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
@interface FFZRecoderTools : NSObject
/**
 Returns the best session preset that is compatible with all available video
 devices (front and back camera). It will ensure that buffer output from
 both camera has the same resolution.
 */
+ (NSString *__nonnull)bestCaptureSessionPresetCompatibleWithAllDevices;

/**
 Returns the best captureSessionPreset for a device that is equal or under the max specified size
 */
+ (NSString *__nonnull)bestCaptureSessionPresetForDevice:(AVCaptureDevice *__nonnull)device withMaxSize:(CGSize)maxSize;

/**
 Returns the best captureSessionPreset for a device position that is equal or under the max specified size
 */
+ (NSString *__nonnull)bestCaptureSessionPresetForDevicePosition:(AVCaptureDevicePosition)devicePosition withMaxSize:(CGSize)maxSize;


+ (AVCaptureDevice *__nonnull)videoDeviceForPosition:(AVCaptureDevicePosition)position;



@end
