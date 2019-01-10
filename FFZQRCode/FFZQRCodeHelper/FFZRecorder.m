//
//  FFZRecorder.m
//  FFZQRCode
//
//  Created by 景格_徐薛波 on 2017/8/31.
//  Copyright © 2017年 非非宅. All rights reserved.
//

#import "FFZRecorder.h"
#import "QRCodeLocation.h"

#define kFFZRecorderRecordSessionQueueKey "FFZRecorderRecordSessionQueue"
#define kMinTimeBetweenAppend 0.004
#define kScreenHeight ([[UIScreen mainScreen] bounds].size.height)
#define kScreenWidth ([[UIScreen mainScreen] bounds].size.width)
#define TOP (kScreenHeight-220)/2
#define LEFT (kScreenWidth-220)/2

#define kScanRect CGRectMake(LEFT, TOP, 220, 220)
@interface FFZRecorder() {
    AVCaptureVideoPreviewLayer *_previewLayer;
    AVCaptureSession *_captureSession;
    UIView *_previewView;
    AVCaptureStillImageOutput *_photoOutput;
    
    CIContext *_context;
    BOOL _shouldAutoresumeRecording;
    BOOL _needsSwitchBackToContinuousFocus;
    BOOL _adjustingFocus;
    int _beginSessionConfigurationCount;
    double _lastAppendedVideoTime;
    void(^_pauseCompletionHandler)(void);
    
    size_t _transformFilterBufferWidth;
    size_t _transformFilterBufferHeight;
}

@property (nonatomic, strong) AVCaptureVideoDataOutput *captureVideoDataOutput;

@end
@implementation FFZRecorder

static char* FFZRecorderFocusContext = "FocusContext";
static char* FFZRecorderExposureContext = "ExposureContext";


- (id)init {
    self = [super init];
    
    if (self) {
        _sessionQueue = dispatch_queue_create("me.corsin.SCRecorder.RecordSession", nil);
        
        dispatch_queue_set_specific(_sessionQueue, kFFZRecorderRecordSessionQueueKey, "true", nil);
        dispatch_set_target_queue(_sessionQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
        
        _captureSessionPreset = AVCaptureSessionPresetHigh;
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] init];
        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        _initializeSessionLazily = YES;
        
        _videoOrientation = AVCaptureVideoOrientationPortrait;
        _videoStabilizationMode = AVCaptureVideoStabilizationModeStandard;
        
        [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(_subjectAreaDidChange) name:AVCaptureDeviceSubjectAreaDidChangeNotification  object:nil];
        
        _mirrorOnFrontCamera = NO;
        _automaticallyConfiguresApplicationAudioSession = YES;
        
        self.device = AVCaptureDevicePositionBack;
        
        _photoConfiguration = [FFZPhotoConfiguration new];
        
    }
    
    return self;
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (FFZRecorder*)recorder {
    return [[FFZRecorder alloc] init];
}

- (void)beginConfiguration {
    if (_captureSession != nil) {
        _beginSessionConfigurationCount++;
        if (_beginSessionConfigurationCount == 1) {
            [_captureSession beginConfiguration];
        }
    }
}

- (void)commitConfiguration {
    if (_captureSession != nil) {
        _beginSessionConfigurationCount--;
        if (_beginSessionConfigurationCount == 0) {
            [_captureSession commitConfiguration];
        }
    }
}

- (BOOL)_reconfigureSession {
    NSError *newError = nil;
    
    AVCaptureSession *session = _captureSession;
    
    if (session != nil) {
        [self beginConfiguration];
        //设置扫描区域
        
        ///top 与 left 互换  width 与 height 互换
        
        if (![session.sessionPreset isEqualToString:_captureSessionPreset]) {
            if ([session canSetSessionPreset:_captureSessionPreset]) {
                session.sessionPreset = _captureSessionPreset;
                //[session setSessionPreset:AVCaptureSessionPresetHigh];
            } else {
                newError = [FFZRecorder createError:@"Cannot set session preset"];
            }
        }
        
        
        if (!_captureVideoDataOutput) {
            NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
            NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
            NSDictionary* videoSettings = [NSDictionary
                                           dictionaryWithObject:value forKey:key];
            self.captureVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
            [self.captureVideoDataOutput setVideoSettings:videoSettings];
            dispatch_queue_t queue;
            queue = dispatch_queue_create("cameraQueue", NULL);
            [self.captureVideoDataOutput setSampleBufferDelegate:self queue:queue];
            if (![session.outputs containsObject:_captureVideoDataOutput]) {
                if ([session canAddOutput:_captureVideoDataOutput]) {
                    [session addOutput:_captureVideoDataOutput];
                } else {
                    if (newError == nil) {
                        newError = [FFZRecorder createError:@"Cannot add qrCodeOutput inside the session"];
                    }
                }
            }
        }
        
        [self commitConfiguration];
        
    }
    _error = newError;
    
    return newError == nil;
}

- (BOOL)prepare:(NSError **)error {
    if (_captureSession != nil) {
        [NSException raise:@"SCCameraException" format:@"The session is already opened"];
    }
    
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    session.automaticallyConfiguresApplicationAudioSession = self.automaticallyConfiguresApplicationAudioSession;
    _beginSessionConfigurationCount = 0;
    _captureSession = session;
    
    [self beginConfiguration];
    
    BOOL success = [self _reconfigureSession];
    
    if (!success && error != nil) {
        *error = _error;
    }
    
    _previewLayer.session = session;
    
    [self reconfigureVideoInput:YES audioInput:YES];
    
    [self commitConfiguration];
    
    return success;
}

- (BOOL)startRunning {
    BOOL success = YES;
    if (!self.isPrepared) {
        success = [self prepare:nil];
    }
    
    if (!_captureSession.isRunning) {
        
        self.videoZoomFactor = kDefaultMinZoomFactor;
        [_captureSession startRunning];
    }
    
    return success;
}

- (void)stopRunning {
    [_captureSession stopRunning];
}

- (void)distroy {
    [_captureSession stopRunning];
    for (AVCaptureDeviceInput *input in _captureSession.inputs) {
        [_captureSession removeInput:input];
        if ([input.device hasMediaType:AVMediaTypeVideo]) {
            [self removeVideoObservers:input.device];
        }
    }
    
    for (AVCaptureOutput *output in _captureSession.outputs) {
        [_captureSession removeOutput:output];
    }
    
    _previewLayer.session = nil;
    _captureSession = nil;
    //[self removeVideoObservers:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo]];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    printf("retain count = %ld\n",CFGetRetainCount((__bridge CFTypeRef)(self)));
}


- (void)_subjectAreaDidChange {
    id<FFZRecorderDelegate> delegate = self.delegate;
    
    if (![delegate respondsToSelector:@selector(recorderShouldAutomaticallyRefocus:)] || [delegate recorderShouldAutomaticallyRefocus:self]) {
        [self focusCenter];
    }
}

- (void)pause {
    [self pause:nil];
}

- (void)pause:(void(^)(void))completionHandler {
    _isRecording = NO;
    
    void (^block)(void) = ^{
        
    };
    
    if ([FFZRecorder isSessionQueue]) {
        block();
    } else {
        dispatch_async(_sessionQueue, block);
    }
}

+ (NSError*)createError:(NSString*)errorDescription {
    return [NSError errorWithDomain:@"SCRecorder" code:200 userInfo:@{NSLocalizedDescriptionKey : errorDescription}];
}

- (void)_focusDidComplete {
    //id<FFZRecorderDelegate> delegate = self.delegate;
    
    [self setAdjustingFocus:NO];
    
    
    //    if ([delegate respondsToSelector:@selector(recorderDidEndFocus:)]) {
    //        [delegate recorderDidEndFocus:self];
    //    }
    
    if (_needsSwitchBackToContinuousFocus) {
        _needsSwitchBackToContinuousFocus = NO;
        [self continuousFocusAtPoint:self.focusPointOfInterest];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    id<FFZRecorderDelegate> delegate = self.delegate;
    
    if (context == FFZRecorderFocusContext) {
        BOOL isFocusing = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        if (isFocusing) {
            [self setAdjustingFocus:YES];
            
            if ([delegate respondsToSelector:@selector(recorderDidStartFocus:)]) {
                [delegate recorderDidStartFocus:self];
            }
        } else {
            
            [self _focusDidComplete];
        }
    } else if (context == FFZRecorderExposureContext) {
        BOOL isAdjustingExposure = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        
        [self setAdjustingExposure:isAdjustingExposure];
        
        if (isAdjustingExposure) {
            if ([delegate respondsToSelector:@selector(recorderDidStartAdjustingExposure:)]) {
                [delegate recorderDidStartAdjustingExposure:self];
            }
        } else {
            if ([delegate respondsToSelector:@selector(recorderDidEndAdjustingExposure:)]) {
                [delegate recorderDidEndAdjustingExposure:self];
            }
        }
    }
}
- (void)addVideoObservers:(AVCaptureDevice*)videoDevice {
    [videoDevice addObserver:self forKeyPath:@"adjustingFocus" options:NSKeyValueObservingOptionNew context:FFZRecorderFocusContext];
    [videoDevice addObserver:self forKeyPath:@"adjustingExposure" options:NSKeyValueObservingOptionNew context:FFZRecorderExposureContext];
}

- (void)removeVideoObservers:(AVCaptureDevice*)videoDevice {
    [videoDevice removeObserver:self forKeyPath:@"adjustingFocus"];
    [videoDevice removeObserver:self forKeyPath:@"adjustingExposure"];
}
- (void)configureDevice:(AVCaptureDevice*)newDevice mediaType:(NSString*)mediaType error:(NSError**)error {
    AVCaptureDeviceInput *currentInput = [self currentDeviceInputForMediaType:mediaType];
    AVCaptureDevice *currentUsedDevice = currentInput.device;
    
    if (currentUsedDevice != newDevice) {
        if ([mediaType isEqualToString:AVMediaTypeVideo]) {
            NSError *error;
            if ([newDevice lockForConfiguration:&error]) {
                if (newDevice.isSmoothAutoFocusSupported) {
                    newDevice.smoothAutoFocusEnabled = YES;
                }
                newDevice.subjectAreaChangeMonitoringEnabled = true;
                
                if (newDevice.isLowLightBoostSupported) {
                    newDevice.automaticallyEnablesLowLightBoostWhenAvailable = YES;
                }
                [newDevice unlockForConfiguration];
            } else {
                NSLog(@"Failed to configure device: %@", error);
            }
            
        } else {
            
        }
        
        AVCaptureDeviceInput *newInput = nil;
        
        if (newDevice != nil) {
            newInput = [[AVCaptureDeviceInput alloc] initWithDevice:newDevice error:error];
        }
        
        if (*error == nil) {
            if (currentInput != nil) {
                [_captureSession removeInput:currentInput];
                if ([currentInput.device hasMediaType:AVMediaTypeVideo]) {
                    [self removeVideoObservers:currentInput.device];
                }
            }
            if (newInput != nil) {
                if ([_captureSession canAddInput:newInput]) {
                    [_captureSession addInput:newInput];
                    [self addVideoObservers:newInput.device];
                } else {
                    *error = [FFZRecorder createError:@"Failed to add input to capture session"];
                }
            }
        }
    }
}


- (void)reconfigureVideoInput:(BOOL)shouldConfigureVideo audioInput:(BOOL)shouldConfigureAudio {
    if (_captureSession != nil) {
        [self beginConfiguration];
        
        NSError *videoError = nil;
        if (shouldConfigureVideo) {
            [self configureDevice:[self videoDevice] mediaType:AVMediaTypeVideo error:&videoError];
        }
        [self commitConfiguration];
    }
}

- (void)switchCaptureDevices {
    if (self.device == AVCaptureDevicePositionBack) {
        self.device = AVCaptureDevicePositionFront;
    } else {
        self.device = AVCaptureDevicePositionBack;
    }
}

- (void)previewViewFrameChanged {
    _previewLayer.affineTransform = CGAffineTransformIdentity;
    _previewLayer.frame = _previewView.bounds;
}

#pragma mark - FOCUS

- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates {
    return [self.previewLayer captureDevicePointOfInterestForPoint:viewCoordinates];
}

- (CGPoint)convertPointOfInterestToViewCoordinates:(CGPoint)pointOfInterest {
    return [self.previewLayer pointForCaptureDevicePointOfInterest:pointOfInterest];
}

- (void)lockFocus {
    AVCaptureDevice *device = [self.currentVideoDeviceInput device];
    if ([device isFocusModeSupported:AVCaptureFocusModeLocked]) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            [device setFocusMode:AVCaptureFocusModeLocked];
            [device unlockForConfiguration];
        }
    }
}

- (void)_applyPointOfInterest:(CGPoint)point continuousMode:(BOOL)continuousMode {
    AVCaptureDevice *device = [self.currentVideoDeviceInput device];
    AVCaptureFocusMode focusMode = continuousMode ? AVCaptureFocusModeContinuousAutoFocus : AVCaptureFocusModeAutoFocus;
    AVCaptureExposureMode exposureMode = continuousMode ? AVCaptureExposureModeContinuousAutoExposure : AVCaptureExposureModeAutoExpose;
    AVCaptureWhiteBalanceMode whiteBalanceMode = continuousMode ? AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance : AVCaptureWhiteBalanceModeAutoWhiteBalance;
    
    NSError *error;
    if ([device lockForConfiguration:&error]) {
        BOOL focusing = NO;
        BOOL adjustingExposure = NO;
        
        if (device.isFocusPointOfInterestSupported) {
            device.focusPointOfInterest = point;
        }
        if ([device isFocusModeSupported:focusMode]) {
            device.focusMode = focusMode;
            focusing = YES;
        }
        
        if (device.isExposurePointOfInterestSupported) {
            device.exposurePointOfInterest = point;
        }
        
        if ([device isExposureModeSupported:exposureMode]) {
            device.exposureMode = exposureMode;
            adjustingExposure = YES;
        }
        
        if ([device isWhiteBalanceModeSupported:whiteBalanceMode]) {
            device.whiteBalanceMode = whiteBalanceMode;
        }
        
        device.subjectAreaChangeMonitoringEnabled = !continuousMode;
        
        [device unlockForConfiguration];
        
        id<FFZRecorderDelegate> delegate = self.delegate;
        if (focusMode != AVCaptureFocusModeContinuousAutoFocus && focusing) {
            if ([delegate respondsToSelector:@selector(recorderWillStartFocus:)]) {
                [delegate recorderWillStartFocus:self];
            }
            
            [self setAdjustingFocus:YES];
        }
        
        if (exposureMode != AVCaptureExposureModeContinuousAutoExposure && adjustingExposure) {
            [self setAdjustingExposure:YES];
            
            if ([delegate respondsToSelector:@selector(recorderWillStartAdjustingExposure:)]) {
                [delegate recorderWillStartAdjustingExposure:self];
            }
        }
    }
}


#pragma mark AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef newContext = CGBitmapContextCreate(baseAddress,
                                                    width, height, 8, bytesPerRow, colorSpace,
                                                    kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef newImage = CGBitmapContextCreateImage(newContext);
    
    CGContextRelease(newContext);
    CGColorSpaceRelease(colorSpace);
    
    UIImage *image = [UIImage imageWithCGImage:newImage scale:1 orientation:UIImageOrientationUp];
    
    //UIImage *image = [UIImage imageWithCGImage:newImage];
    CGImageRelease(newImage);
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    self.myImage = image;
    if (self.delegate && [self.delegate respondsToSelector:@selector(recorderDidEndFocus:)]) {
        [self.delegate recorderDidEndFocus:self];
    }
}

// Perform an auto focus at the specified point. The focus mode will automatically change to locked once the auto focus is complete.
- (void)autoFocusAtPoint:(CGPoint)point {
    [self _applyPointOfInterest:point continuousMode:NO];
}

// Switch to continuous auto focus mode at the specified point
- (void)continuousFocusAtPoint:(CGPoint)point {
    [self _applyPointOfInterest:point continuousMode:YES];
}

- (void)focusCenter {
    _needsSwitchBackToContinuousFocus = YES;
    [self autoFocusAtPoint:CGPointMake(0.5, 0.5)];
}

- (void)refocus {
    _needsSwitchBackToContinuousFocus = YES;
    [self autoFocusAtPoint:self.focusPointOfInterest];
}

- (CGPoint)exposurePointOfInterest {
    return [self.currentVideoDeviceInput device].exposurePointOfInterest;
}

- (BOOL)exposureSupported {
    return [self.currentVideoDeviceInput device].isExposurePointOfInterestSupported;
}

- (CGPoint)focusPointOfInterest {
    return [self.currentVideoDeviceInput device].focusPointOfInterest;
}

- (BOOL)focusSupported {
    return [self currentVideoDeviceInput].device.isFocusPointOfInterestSupported;
}

- (AVCaptureDeviceInput*)currentAudioDeviceInput {
    return [self currentDeviceInputForMediaType:AVMediaTypeAudio];
}

- (AVCaptureDeviceInput*)currentVideoDeviceInput {
    return [self currentDeviceInputForMediaType:AVMediaTypeVideo];
}

- (AVCaptureDeviceInput*)currentDeviceInputForMediaType:(NSString*)mediaType {
    for (AVCaptureDeviceInput* deviceInput in _captureSession.inputs) {
        if ([deviceInput.device hasMediaType:mediaType]) {
            return deviceInput;
        }
    }
    return nil;
}

- (AVCaptureDevice*)videoDevice {
    if (!self.photoConfiguration.enabled) {
        return nil;
    }
    
    return [FFZRecoderTools videoDeviceForPosition:_device];
}

- (AVCaptureVideoOrientation)actualVideoOrientation {
    AVCaptureVideoOrientation videoOrientation = _videoOrientation;
    
    if (_autoSetVideoOrientation) {
        UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
        
        switch (deviceOrientation) {
            case UIDeviceOrientationLandscapeLeft:
                videoOrientation = AVCaptureVideoOrientationLandscapeRight;
                break;
            case UIDeviceOrientationLandscapeRight:
                videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
                break;
            case UIDeviceOrientationPortrait:
                videoOrientation = AVCaptureVideoOrientationPortrait;
                break;
            case UIDeviceOrientationPortraitUpsideDown:
                videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
                break;
            default:
                break;
        }
    }
    
    return videoOrientation;
}

- (AVCaptureSession*)captureSession {
    return _captureSession;
}

- (void)setPreviewView:(UIView *)previewView {
    [_previewLayer removeFromSuperlayer];
    
    _previewView = previewView;
    
    if (_previewView != nil) {
        [_previewView.layer insertSublayer:_previewLayer atIndex:0];
        
        [self previewViewFrameChanged];
    }
}

- (UIView*)previewView {
    return _previewView;
}

- (AVCaptureVideoPreviewLayer*)previewLayer {
    return _previewLayer;
}

- (BOOL)isPrepared {
    return _captureSession != nil;
}

- (void)setCaptureSessionPreset:(NSString *)sessionPreset {
    _captureSessionPreset = sessionPreset;
    
    if (_captureSession != nil) {
        [self _reconfigureSession];
        _captureSessionPreset = _captureSession.sessionPreset;
    }
}

- (AVCaptureFocusMode)focusMode {
    return [self currentVideoDeviceInput].device.focusMode;
}

- (BOOL)isAdjustingFocus {
    return _adjustingFocus;
}

- (void)setAdjustingExposure:(BOOL)adjustingExposure {
    if (_isAdjustingExposure != adjustingExposure) {
        [self willChangeValueForKey:@"isAdjustingExposure"];
        
        _isAdjustingExposure = adjustingExposure;
        
        [self didChangeValueForKey:@"isAdjustingExposure"];
    }
}

- (void)setAdjustingFocus:(BOOL)adjustingFocus {
    if (_adjustingFocus != adjustingFocus) {
        [self willChangeValueForKey:@"isAdjustingFocus"];
        
        _adjustingFocus = adjustingFocus;
        
        [self didChangeValueForKey:@"isAdjustingFocus"];
    }
}

/*
 - (AVCaptureStillImageOutput *)photoOutput {
 return _photoOutput;
 }
 */
- (CGFloat)videoZoomFactor {
    AVCaptureDevice *device = [self videoDevice];
    
    if ([device respondsToSelector:@selector(videoZoomFactor)]) {
        return device.videoZoomFactor;
    }
    
    return kDefaultMinZoomFactor;
}
/*
 - (CGFloat)maxVideoZoomFactor {
 return [self maxVideoZoomFactorForDevice:_device];
 }
 
 - (CGFloat)maxVideoZoomFactorForDevice:(AVCaptureDevicePosition)devicePosition
 {
 return [FFZRecoderTools videoDeviceForPosition:devicePosition].activeFormat.videoMaxZoomFactor;
 }
 */
- (void)setVideoZoomFactor:(CGFloat)videoZoomFactor {
    AVCaptureDevice *device = [self videoDevice];
    
    if ([device respondsToSelector:@selector(videoZoomFactor)]) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            if (videoZoomFactor <= device.activeFormat.videoMaxZoomFactor) {
                
                if (videoZoomFactor > 1.0) {
                    device.videoZoomFactor = videoZoomFactor;
                }
                
            } else {
                NSLog(@"Unable to set videoZoom: (max %f, asked %f)", device.activeFormat.videoMaxZoomFactor, videoZoomFactor);
            }
            
            [device unlockForConfiguration];
        } else {
            NSLog(@"Unable to set videoZoom: %@", error.localizedDescription);
        }
    }
}



+ (BOOL)isSessionQueue {
    return dispatch_get_specific(kFFZRecorderRecordSessionQueueKey) != nil;
}

@end
