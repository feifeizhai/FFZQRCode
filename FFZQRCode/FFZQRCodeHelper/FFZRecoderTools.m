//
//  FFZRecoderTools.m
//  FFZQRCode
//
//  Created by 景格_徐薛波 on 2017/8/31.
//  Copyright © 2017年 非非宅. All rights reserved.
//

#import "FFZRecoderTools.h"


@implementation FFZRecoderTools

+ (BOOL)formatInRange:(AVCaptureDeviceFormat*)format frameRate:(CMTimeScale)frameRate {
    CMVideoDimensions dimensions;
    dimensions.width = 0;
    dimensions.height = 0;
    
    return [FFZRecoderTools formatInRange:format frameRate:frameRate dimensions:dimensions];
}

+ (BOOL)formatInRange:(AVCaptureDeviceFormat*)format frameRate:(CMTimeScale)frameRate dimensions:(CMVideoDimensions)dimensions {
    CMVideoDimensions size = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
    
    if (size.width >= dimensions.width && size.height >= dimensions.height) {
        for (AVFrameRateRange *range in format.videoSupportedFrameRateRanges) {
            if (range.minFrameDuration.timescale >= frameRate && range.maxFrameDuration.timescale <= frameRate) {
                return YES;
            }
        }
    }
    
    return NO;
}

+ (CMTimeScale)maxFrameRateForFormat:(AVCaptureDeviceFormat *)format minFrameRate:(CMTimeScale)minFrameRate {
    CMTimeScale lowerTimeScale = 0;
    for (AVFrameRateRange *range in format.videoSupportedFrameRateRanges) {
        if (range.minFrameDuration.timescale >= minFrameRate && (lowerTimeScale == 0 || range.minFrameDuration.timescale < lowerTimeScale)) {
            lowerTimeScale = range.minFrameDuration.timescale;
        }
    }
    
    return lowerTimeScale;
}

+ (AVCaptureDevice *)videoDeviceForPosition:(AVCaptureDevicePosition)position {
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for (AVCaptureDevice *device in videoDevices) {
        if (device.position == (AVCaptureDevicePosition)position) {
            return device;
        }
    }
    
    return nil;
}

+ (NSString *)captureSessionPresetForDimension:(CMVideoDimensions)videoDimension {
    

    if (videoDimension.width >= 1920 && videoDimension.height >= 1080) {
       
        return AVCaptureSessionPreset1920x1080;
    }
    if (videoDimension.width >= 1280 && videoDimension.height >= 720) {
        return AVCaptureSessionPreset1920x1080;
    }
    if (videoDimension.width >= 960 && videoDimension.height >= 540) {
        return AVCaptureSessionPresetiFrame960x540;
    }
    if (videoDimension.width >= 640 && videoDimension.height >= 480) {
        return AVCaptureSessionPreset640x480;
    }
    if (videoDimension.width >= 352 && videoDimension.height >= 288) {
        return AVCaptureSessionPreset352x288;
    }
    
    return AVCaptureSessionPresetLow;
}

+ (NSString *)bestCaptureSessionPresetForDevicePosition:(AVCaptureDevicePosition)devicePosition withMaxSize:(CGSize)maxSize {
    return [FFZRecoderTools bestCaptureSessionPresetForDevice:[FFZRecoderTools videoDeviceForPosition:devicePosition] withMaxSize:maxSize];
}

+ (NSString *)bestCaptureSessionPresetForDevice:(AVCaptureDevice *)device withMaxSize:(CGSize)maxSize {
    CMVideoDimensions highestDeviceDimension;
    highestDeviceDimension.width = 0;
    highestDeviceDimension.height = 0;
    
    for (AVCaptureDeviceFormat *format in device.formats) {
        CMVideoDimensions dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
        
        if (dimension.width <= (int)maxSize.width && dimension.height <= (int)maxSize.height && dimension.width * dimension.height > highestDeviceDimension.width * highestDeviceDimension.height) {
            highestDeviceDimension = dimension;
        }
    }
    
    return [FFZRecoderTools captureSessionPresetForDimension:highestDeviceDimension];
}

+ (NSString *)bestCaptureSessionPresetCompatibleWithAllDevices {
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    CMVideoDimensions highestCompatibleDimension;
    BOOL lowestSet = NO;
    
    for (AVCaptureDevice *device in videoDevices) {
        CMVideoDimensions highestDeviceDimension;
        highestDeviceDimension.width = 0;
        highestDeviceDimension.height = 0;
        
        for (AVCaptureDeviceFormat *format in device.formats) {
            CMVideoDimensions dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
            
            if (dimension.width * dimension.height > highestDeviceDimension.width * highestDeviceDimension.height) {
                highestDeviceDimension = dimension;
            }
        }
        
        if (!lowestSet || (highestCompatibleDimension.width * highestCompatibleDimension.height > highestDeviceDimension.width * highestDeviceDimension.height)) {
            lowestSet = YES;
            highestCompatibleDimension = highestDeviceDimension;
        }
        
    }
    
    return [FFZRecoderTools captureSessionPresetForDimension:highestCompatibleDimension];
}



@end
