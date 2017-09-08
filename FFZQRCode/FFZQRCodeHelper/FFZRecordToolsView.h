//
//  FFZRecordToolsView.h
//  FFZQRCode
//
//  Created by 景格_徐薛波 on 2017/8/31.
//  Copyright © 2017年 非非宅. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FFZRecorder.h"
@class FFZRecordToolsView;
@protocol FFZRecorderToolsViewDelegate <NSObject>

@optional

- (void)recorderToolsView:(FFZRecordToolsView *__nonnull)recorderToolsView didTapToFocusWithGestureRecognizer:(UIGestureRecognizer *__nonnull)gestureRecognizer;

@end
@interface FFZRecordToolsView : UIView
@property (nonatomic, weak) __nullable id<FFZRecorderToolsViewDelegate> delegate;

/**
 The instance of the SCRecorder to use.
 */
@property (strong, nonatomic) FFZRecorder *__nullable recorder;

/**
 The outside image used when focusing.
 */
@property (strong, nonatomic) UIImage *__nullable outsideFocusTargetImage;

/**
 The inside image used when focusing.
 */
@property (strong, nonatomic) UIImage *__nullable insideFocusTargetImage;

/**
 The size of the focus target.
 */
@property (assign, nonatomic) CGSize focusTargetSize;

/**
 The minimum zoom allowed for the pinch to zoom.
 Default is 1
 */
@property (assign, nonatomic) CGFloat minZoomFactor;

/**
 The maximum zoom allowed for the pinch to zoom.
 Default is 4
 */
@property (assign, nonatomic) CGFloat maxZoomFactor;


@property (assign, nonatomic, readonly) CGFloat zoomFactor;
/**
 Whether the tap to focus should be enabled.
 */
@property (assign, nonatomic) BOOL tapToFocusEnabled;

/**
 Whether the double tap to reset the focus should be enabled.
 */
@property (assign, nonatomic) BOOL doubleTapToResetFocusEnabled;

/**
 Whether the pinch to zoom should be enabled.
 */
@property (assign, nonatomic) BOOL pinchToZoomEnabled;

@property (assign, nonatomic) BOOL showsFocusAnimationAutomatically;

///**
// When the SCRecorderToolsView should show the focus animation
// when the focusing state changes. If set to Never, you will have to call
// "showFocusAnimation" and "hideFocusAnimation" yourself.
//
// Default is OnlyOnSubjectChange
// */
//@property (assign, nonatomic) SCRecorderToolsViewShowFocusMode showFocusMode;

/**
 Manually show the focus animation.
 This method is called automatically if showsFocusAnimationAutomatically
 is set to YES.
 */
- (void)showFocusAnimation;

/**
 Manually hide the focus animation.
 This method is called automatically if showsFocusAnimationAutomatically
 is set to YES.
 */
- (void)hideFocusAnimation;


- (void)autoZoomWithVideoZoom:(CGFloat)videoZoom;


@end
