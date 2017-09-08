//
//  FFZQRCodeViewController.m
//  FFZQRCode
//
//  Created by 景格_徐薛波 on 2017/8/28.
//  Copyright © 2017年 非非宅. All rights reserved.
//

#import "FFZQRCodeViewController.h"
#import <AVFoundation/AVFoundation.h>

#import "FFZRecorder.h"
#import "FFZRecordToolsView.h"
#import "QRCodeLocation.h"


#define kScreenHeight ([[UIScreen mainScreen] bounds].size.height)
#define kScreenWidth ([[UIScreen mainScreen] bounds].size.width)
#define TOP (kScreenHeight-220)/2
#define LEFT (kScreenWidth-220)/2
#define kScanRect CGRectMake(LEFT, TOP, 220, 220)
@interface FFZQRCodeViewController ()<FFZRecorderDelegate>
{
    int num;
    BOOL upOrdown;
    NSTimer * timer;
    CAShapeLayer *cropLayer;
}

@property (nonatomic, strong) UIImageView * line;

@property (strong, nonatomic) UIView *previewView;
@property (strong, nonatomic) UIImage *myImage;
@property (strong, nonatomic) FFZRecorder *recorder;
@property (strong, nonatomic) FFZRecordToolsView *focusView;
@end

@implementation FFZQRCodeViewController

- (void)dealloc {
    
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.recorder distroy];
    [self.focusView removeFromSuperview];
}

- (id) initWithFFZQRCodeScanResultBlock:(FFZQRCodeScanResultBlock) scanResult
{
    self = [super init];
    if (self) {
        self.scanResult = scanResult;
        [self setCropRect:kScanRect];
        self.view.backgroundColor = [UIColor blackColor];
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    _recorder = [FFZRecorder recorder];
    _recorder.captureSessionPreset = [FFZRecoderTools bestCaptureSessionPresetCompatibleWithAllDevices];
    _recorder.delegate = self;
    _recorder.previewView = self.previewView;
    self.focusView = [[FFZRecordToolsView alloc] initWithFrame:_previewView.bounds];
    self.focusView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    self.focusView.recorder = _recorder;
    [_previewView addSubview:self.focusView];
    
   
    
    
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    [_recorder previewViewFrameChanged];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self startRun];
    [self.view addSubview:self.line];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopRun];
}

- (void)setCropRect:(CGRect)cropRect{
    cropLayer = [[CAShapeLayer alloc] init];
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, nil, cropRect);
    CGPathAddRect(path, nil, self.view.bounds);
    
    [cropLayer setFillRule:kCAFillRuleEvenOdd];
    [cropLayer setPath:path];
    [cropLayer setFillColor:[UIColor blackColor].CGColor];
    [cropLayer setOpacity:0.6];
    
    CGPathRelease(path);
    [cropLayer setNeedsDisplay];
    
    [self.view.layer addSublayer:cropLayer];
}

- (void)stopRun
{
    [_recorder stopRunning];
    [timer invalidate];
    timer = nil;
}

- (void)startRun {
    
    [self stopRun];
    [_recorder startRunning];
    timer = [NSTimer scheduledTimerWithTimeInterval:.02 target:self selector:@selector(animation) userInfo:nil repeats:YES];
}

-(void)animation
{
    if (upOrdown == NO) {
        num ++;
        _line.frame = CGRectMake(LEFT, TOP+10+2*num, 220, 2);
        if (2*num == 200) {
            upOrdown = YES;
        }
    }
    else {
        num --;
        _line.frame = CGRectMake(LEFT, TOP+10+2*num, 220, 2);
        if (num == 0) {
            upOrdown = NO;
        }
    }
    
}


- (void)recorderDidEndFocus:(FFZRecorder *__nonnull)recorder {
    
    self.myImage = recorder.myImage;
    if (self.myImage) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            CGRect rect = [QRCodeLocation opencvScanQRCode:self.myImage];
            if (rect.size.width < 90 && rect.size.width != 0) {
                
                CGFloat scale = 90 / rect.size.width;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.focusView autoZoomWithVideoZoom:self.focusView.zoomFactor * scale];
                    if (rect.size.width == 0) {
                        [self.recorder focusCenter];
                    }
                    
                });
                
            }
            NSLog(@"%@", NSStringFromCGRect(rect));
        });
    }
}

- (void)recorder:(FFZRecorder *__nonnull)recorder didFinishQRScanWithResoult:(NSString *_Nonnull)resoult {
    [self stopRun];
    
    if (self.scanResult) {
         self.scanResult(resoult);
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"扫码结果" message:resoult preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self startRun];
    }];
    [alert addAction:action];
    [self presentViewController:alert animated:YES completion:^{
        
    }];
}


- (UIView *)previewView {
    if (!_previewView) {
        _previewView = [[UIView alloc] initWithFrame:self.view.bounds];
        [self.view addSubview:_previewView];
    }
    return _previewView;
}

- (UIImageView *)line {
    if (!_line) {
        upOrdown = NO;
        num = 0;
        _line = [[UIImageView alloc] initWithFrame:CGRectMake(LEFT, TOP+10, 220, 2)];
        _line.image = [self imagesNamedFromCustomBundle:@"line"];
     
        [self.view addSubview:_line];
        UIImageView * imageView = [[UIImageView alloc] initWithFrame:kScanRect];
         imageView.image = [self imagesNamedFromCustomBundle:@"pick_bg"];
        
        [self.view addSubview:imageView];
    }
    return _line;
}


- (UIImage *)imagesNamedFromCustomBundle:(NSString *)imgName
{
    NSString *bundlePath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"FFZQRCodeResourse.bundle"];
    
    NSString *img_path = [bundlePath stringByAppendingPathComponent:imgName];
    NSLog(@"%@", img_path);
    return [UIImage imageWithContentsOfFile:img_path];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
