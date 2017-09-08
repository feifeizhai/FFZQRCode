//
//  FFZRecordToolsView.m
//  FFZQRCode
//
//  Created by 景格_徐薛波 on 2017/8/31.
//  Copyright © 2017年 非非宅. All rights reserved.
//

#import "FFZRecordToolsView.h"
#define BASE_FOCUS_TARGET_WIDTH 60
#define BASE_FOCUS_TARGET_HEIGHT 60
#define kDefaultMinZoomFactor 1.6
#define kDefaultMaxZoomFactor 8

@interface FFZRecordToolsView()
{
    UITapGestureRecognizer *_tapToFocusGesture;
    UITapGestureRecognizer *_doubleTapToResetFocusGesture;
    UIPinchGestureRecognizer *_pinchZoomGesture;
    CGFloat _zoomAtStart;
}

@property (assign, nonatomic) BOOL isShrink;

@end
@implementation FFZRecordToolsView
static char *ContextAdjustingFocus = "AdjustingFocus";
static char *ContextAdjustingExposure = "AdjustingExposure";
static char *ContextDidChangeDevice = "DidChangeDevice";


- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        [self commonInit];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self commonInit];
    }
    
    return self;
}

- (void)dealloc {
    self.recorder = nil;
}

- (void)commonInit {
    _minZoomFactor = kDefaultMinZoomFactor;
    _maxZoomFactor = kDefaultMaxZoomFactor;
    _zoomFactor = kDefaultMinZoomFactor;
    self.showsFocusAnimationAutomatically = YES;

    
    self.focusTargetSize = CGSizeMake(BASE_FOCUS_TARGET_WIDTH, BASE_FOCUS_TARGET_HEIGHT);
    
    _tapToFocusGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToAutoFocus:)];
    [self addGestureRecognizer:_tapToFocusGesture];
    
    _doubleTapToResetFocusGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToContinouslyAutoFocus:)];
    _doubleTapToResetFocusGesture.numberOfTapsRequired = 2;
    [_tapToFocusGesture requireGestureRecognizerToFail:_doubleTapToResetFocusGesture];
    
    [self addGestureRecognizer:_doubleTapToResetFocusGesture];
    
    _pinchZoomGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchToZoom:)];
    
    [self addGestureRecognizer:_pinchZoomGesture];
   
}

- (void)showFocusAnimation {
    //[self adjustFocusView];
   
}

- (void)hideFocusAnimation {
}

- (void)layoutSubviews {
    
    [super layoutSubviews];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == ContextAdjustingFocus) {
        if (self.showsFocusAnimationAutomatically) {
            if (self.recorder.isAdjustingFocus) {
                [self showFocusAnimation];
            } else {
                [self hideFocusAnimation];
            }
        }
    } else if (context == ContextAdjustingExposure) {
        if (self.showsFocusAnimationAutomatically && !self.recorder.focusSupported) {
            if (self.recorder.isAdjustingExposure) {
                [self showFocusAnimation];
            } else {
                [self hideFocusAnimation];
            }
        }
    } else if (context == ContextDidChangeDevice) {
        [self hideFocusAnimation];
    }
}

// Auto focus at a particular point. The focus mode will change to locked once the auto focus happens.
- (void)tapToAutoFocus:(UIGestureRecognizer *)gestureRecognizer {
    FFZRecorder *recorder = self.recorder;
    
    CGPoint tapPoint = [gestureRecognizer locationInView:recorder.previewView];
    CGPoint convertedFocusPoint = [recorder convertToPointOfInterestFromViewCoordinates:tapPoint];
    
    NSLog(@"%f %f", tapPoint.x, tapPoint.y);
    
    
    [recorder autoFocusAtPoint:convertedFocusPoint];
    
    id<FFZRecorderToolsViewDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(recorderToolsView:didTapToFocusWithGestureRecognizer:)]) {
        [delegate recorderToolsView:self didTapToFocusWithGestureRecognizer:gestureRecognizer];
    }
}

// Change to continuous auto focus. The camera will constantly focus at the point choosen.
- (void)tapToContinouslyAutoFocus:(UIGestureRecognizer *)gestureRecognizer {
    
     if (self.recorder.videoZoomFactor != _maxZoomFactor && !_isShrink) {
         [self setVideoZoom:_maxZoomFactor isShrink:NO];
     }else {
         [self setVideoZoom:_minZoomFactor isShrink:YES];
     }

}

- (void)pinchToZoom:(UIPinchGestureRecognizer *)gestureRecognizer {
    FFZRecorder *strongRecorder = self.recorder;
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        _zoomAtStart = strongRecorder.videoZoomFactor;
    }
    
    CGFloat newZoom = gestureRecognizer.scale * _zoomAtStart;
    
    if (newZoom > _maxZoomFactor) {
        newZoom = _maxZoomFactor;
    } else if (newZoom < _minZoomFactor) {
        newZoom = _minZoomFactor;
    }
    if (newZoom != _maxZoomFactor) {
        _isShrink = NO;
    }
    strongRecorder.videoZoomFactor = newZoom;
    _zoomFactor = newZoom;
}

- (void)autoZoomWithVideoZoom:(CGFloat)videoZoom {
    if (videoZoom > _maxZoomFactor) {
        videoZoom = _maxZoomFactor;
    }
    [self setVideoZoom:videoZoom isShrink:NO];
}

- (void)setVideoZoom:(CGFloat)videoZoom isShrink:(BOOL)isShrink {
    
    FFZRecorder *recorder = self.recorder;
    
    NSTimeInterval period = 0.01; //设置时间间隔
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_source_t _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    
    dispatch_source_set_timer(_timer, dispatch_walltime(NULL, 0), period * NSEC_PER_SEC, 0);
    _isShrink = isShrink;
    dispatch_source_set_event_handler(_timer, ^{
        
        if (!_isShrink) {
            
            CGFloat zoomFactot = recorder.videoZoomFactor + 0.08;
            if (zoomFactot>= videoZoom) {
                zoomFactot = videoZoom;
                recorder.videoZoomFactor = zoomFactot;
                dispatch_source_cancel(_timer);
            }
            recorder.videoZoomFactor = zoomFactot;
            _zoomFactor = zoomFactot;
          
        }else {
            _isShrink = YES;
            CGFloat zoomFactot = recorder.videoZoomFactor - 0.08;
            if (zoomFactot <= videoZoom) {
                zoomFactot = videoZoom;
                recorder.videoZoomFactor = zoomFactot;
                dispatch_source_cancel(_timer);
                _isShrink = NO;
            }
            recorder.videoZoomFactor = zoomFactot;
            _zoomFactor = zoomFactot;
        
        }

    });
    
    dispatch_resume(_timer);
}


- (void)setFocusTargetSize:(CGSize)focusTargetSize {
 
    
  //  [self adjustFocusView];
}



- (BOOL)tapToFocusEnabled {
    return _tapToFocusGesture.enabled;
}

- (void)setTapToFocusEnabled:(BOOL)tapToFocusEnabled {
    _tapToFocusGesture.enabled = tapToFocusEnabled;
}

- (BOOL)doubleTapToResetFocusEnabled {
    return _doubleTapToResetFocusGesture.enabled;
}

- (void)setDoubleTapToResetFocusEnabled:(BOOL)doubleTapToResetFocusEnabled {
    _doubleTapToResetFocusGesture.enabled = doubleTapToResetFocusEnabled;
}

- (BOOL)pinchToZoomEnabled {
    return _pinchZoomGesture.enabled;
}

- (void)setPinchToZoomEnabled:(BOOL)pinchToZoomEnabled {
    _pinchZoomGesture.enabled = pinchToZoomEnabled;
}

- (void)setRecorder:(FFZRecorder *)recorder {
    FFZRecorder *oldRecorder = _recorder;
    
    if (oldRecorder != nil) {
        [oldRecorder removeObserver:self forKeyPath:@"isAdjustingFocus"];
        [oldRecorder removeObserver:self forKeyPath:@"isAdjustingExposure"];
        [oldRecorder removeObserver:self forKeyPath:@"device"];
    }
    
    _recorder = recorder;
    
    if (recorder != nil) {
        [recorder addObserver:self forKeyPath:@"isAdjustingFocus" options:NSKeyValueObservingOptionNew context:ContextAdjustingFocus];
        [recorder addObserver:self forKeyPath:@"isAdjustingExposure" options:NSKeyValueObservingOptionNew context:ContextAdjustingExposure];
        [recorder addObserver:self forKeyPath:@"device"  options:NSKeyValueObservingOptionNew context:ContextDidChangeDevice];
    }
}




/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
