//
//  FFZRecorder.h
//  FFZQRCode
//
//  Created by 景格_徐薛波 on 2017/8/31.
//  Copyright © 2017年 非非宅. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "FFZRecorderDelegate.h"
#import "FFZPhotoConfiguration.h"
#import "FFZRecoderTools.h"
#define kDefaultMinZoomFactor 1.5
#define kDefaultMaxZoomFactor 5.0
@interface FFZRecorder : NSObject<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureMetadataOutputObjectsDelegate>

@property (readonly, nonatomic) FFZPhotoConfiguration *__nonnull photoConfiguration;


@property (assign, nonatomic) AVCaptureDevicePosition device;

@property (strong, nonatomic) UIImage * _Nonnull myImage;
/**
 The zoom factor applied to the video.
 */
@property (assign, nonatomic) CGFloat videoZoomFactor;

/**
 The max zoom factor for the current device
 */
@property (assign, nonatomic) CGFloat maxVideoZoomFactor;



/**
 Get the current focus mode used by the camera device
 */
@property (readonly, nonatomic) AVCaptureFocusMode focusMode;

/**
 Will be true if the camera is adjusting the focus.
 This property is KVO observable.
 */
@property (readonly, nonatomic) BOOL isAdjustingFocus;

/**
 Will be true if the camera is adjusting exposure.
 This property is KVO observable.
 */
@property (readonly, nonatomic) BOOL isAdjustingExposure;

/**
 The session preset used for the AVCaptureSession
 */
@property (copy, nonatomic) NSString *__nonnull captureSessionPreset;

/**
 The value of this property defaults to YES, causing the capture session to automatically configure the app’s shared AVAudioSession instance for optimal recording.
 
 If you set this property’s value to NO, your app is responsible for selecting appropriate audio session settings. Recording may fail if the audio session’s settings are incompatible with the capture session.
 */
@property (assign, nonatomic) BOOL automaticallyConfiguresApplicationAudioSession;

/**
 The captureSession. This will be null until prepare or startRunning has
 been called. Calling unprepare will set this property to null again.
 */
@property (readonly, nonatomic) AVCaptureSession *__nullable captureSession;

/**
 Whether the recorder has been prepared.
 */
@property (readonly, nonatomic) BOOL isPrepared;

/**
 The preview layer used for the video preview
 */
@property (readonly, nonatomic) AVCaptureVideoPreviewLayer *__nonnull previewLayer;

/**
 Convenient way to set a view inside the preview layer
 */
@property (strong, nonatomic) UIView *__nullable previewView;
/**
 Set the delegate used to receive messages for the SCRecorder
 */
@property (weak, nonatomic) id<FFZRecorderDelegate> __nullable delegate;

/**
 The record session to which the recorder will flow the camera/microphone buffers
 */
/**
 @property (strong, nonatomic) FFZRecordSession *__nullable session;
 
 The video orientation. This is automatically set if autoSetVideoOrientation is enabled
 */
@property (assign, nonatomic) AVCaptureVideoOrientation videoOrientation;

/**
 The video stabilization mode to use.
 Default is AVCaptureVideoStabilizationModeStandard
 */
@property (assign, nonatomic) AVCaptureVideoStabilizationMode videoStabilizationMode;

/**
 If true, the videoOrientation property will be set automatically
 depending on the current device orientation
 Default is NO
 */
@property (assign, nonatomic) BOOL autoSetVideoOrientation;
@property (readonly, nonatomic) BOOL isRecording;
/**
 The frameRate for the video
 */
@property (assign, nonatomic) CMTimeScale frameRate;

/**
 The maximum record duration. When the record session record duration
 reaches this bound, the recorder will automatically pause the recording,
 end the current record segment and send recorder:didCompletesession: on the
 delegate.
 */
@property (assign, nonatomic) CMTime maxRecordDuration;

/**
 Whether the fast recording method should be enabled.
 Enabling this will disallow pretty much every features provided
 by SCVideoConfiguration and SCAudioConfiguration. It will internally
 uses a AVCaptureMovieFileOutput that provides no settings. If you have
 some performance issue, you can try enabling this.
 Default is NO.
 */
@property (assign, nonatomic) BOOL fastRecordMethodEnabled;

/**
 If maxRecordDuration is not kCMTimeInvalid,
 this will contains a float between 0 and 1 representing the
 recorded ratio on the current record session, 1 being fully recorded.
 */
@property (readonly, nonatomic) CGFloat ratioRecorded;

/**
 If enabled, the recorder will initialize the session and create the record segments
 when asking to record. Otherwise it will do it as soon as possible.
 Default is YES
 */
@property (assign, nonatomic) BOOL initializeSessionLazily;

/**
 If enabled, flips the video about its vertical axis and produce a mirror-image effect,
 when recording with the front camera.
 */
@property (assign, nonatomic) BOOL mirrorOnFrontCamera;

/**
 If enabled, mirrored video buffers like when using a front camera
 will be written also as mirrored.
 */
@property (assign, nonatomic) BOOL keepMirroringOnWrite;

/**
 Whether adjusting exposure is supported on the current camera device
 */
@property (readonly, nonatomic) BOOL exposureSupported;

/**
 The current exposure point of interest
 */
@property (readonly, nonatomic) CGPoint exposurePointOfInterest;

/**
 Whether the focus is supported on the current camera device
 */
@property (readonly, nonatomic) BOOL focusSupported;

/**
 The current focus point of interest
 */
@property (readonly, nonatomic) CGPoint focusPointOfInterest;

/**
 Will be true if the recorder is currently performing a focus because
 the subject area changed.
 */
@property (readonly, nonatomic) BOOL subjectAreaChanged;

/**
 Will contains an error if an error occured while reconfiguring
 the underlying AVCaptureSession.
 */
@property (readonly, nonatomic) NSError *__nullable error;

/*
 The underlying AVCaptureStillImageOutput
 */
@property (readonly, nonatomic) AVCaptureStillImageOutput *__nullable photoOutput;

/**
 The dispatch queue that the SCRecorder uses for sending messages to the attached
 SCRecordSession.
 */
@property (readonly, nonatomic) dispatch_queue_t __nonnull sessionQueue;

/**
 Create a recorder
 @return the newly created recorder
 */
+ (FFZRecorder *__nonnull)recorder;

/**
 Create the AVCaptureSession
 Calling this method will set the captureSesion and configure it properly.
 If an error occured during the creation of the captureSession, this methods will return NO.
 */
- (BOOL)prepare:(NSError *__nullable *__nullable)error;


/**
 Start the flow of inputs in the AVCaptureSession.
 prepare will be called if it wasn't prepared before.
 Calling this method will block until it's done.
 If it returns NO, an error will be set in the "error" property.
 */
- (BOOL)startRunning;

/**
 End the flow of inputs in the AVCaptureSession
 This wont destroy the AVCaptureSession.
 */
- (void)stopRunning;

/**
 Offer a way to configure multiple things at once.
 You can call beginSessionConfiguration multiple times.
 Only the latest most outer commitSessionConfiguration will effectively commit
 the configuration
 */

- (void)distroy;

- (void)beginConfiguration;

/**
 Commit the session configuration after beginSessionConfiguration has been called
 */
- (void)commitConfiguration;

/**
 Switch between the camera devices
 */
- (void)switchCaptureDevices;

/**
 Convert a point from the previewView coordinates into a point of interest
 @return a point of interest usable in the focus methods
 */
- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates;

/**
 Convert the point of interest into a point from the previewView coordinates
 */
- (CGPoint)convertPointOfInterestToViewCoordinates:(CGPoint)pointOfInterest;

/**
 Focus automatically at the given point of interest.
 Once the focus is completed, the camera device will goes to locked mode
 and won't try to do any further focus
 @param point A point of interest between 0,0 and 1,1
 */
- (void)autoFocusAtPoint:(CGPoint)point;

/**
 Continously focus at a point. The camera device detects when it needs to focus
 and focus automatically when needed.
 @param point A point of interest between 0,0 and 1,1,
 */
- (void)continuousFocusAtPoint:(CGPoint)point;

/**
 Focus at the center then switch back to a continuous focus at the center.
 */
- (void)focusCenter;

/**
 Refocus at the current position
 */
- (void)refocus;

/**
 Lock the current focus and prevent any new further focus
 */
- (void)lockFocus;


/**
 Disallow the recorder to append the sample buffers inside the current setted session.
 If a record segment has started, this will be either canceled or completed depending on
 if it is empty or not.
 */
- (void)pause;

/**
 Disallow the recorder to append the sample buffers inside the current setted session.
 If a record segment has started, this will be either canceled or completed depending on
 if it is empty or not.
 @param completionHandler called on the main queue when the recorder is ready to record again.
 */
- (void)pause:( void(^ __nullable)(void)) completionHandler;

/**
 Signal to the recorder that the previewView frame has changed.
 This will make the previewLayer to matches the size of the previewView.
 */
- (void)previewViewFrameChanged;

/**
 Returns whether the current queue is the record session queue.
 */
+ (BOOL)isSessionQueue;


@end
