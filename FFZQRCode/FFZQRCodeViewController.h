//
//  FFZQRCodeViewController.h
//  FFZQRCode
//
//  Created by 景格_徐薛波 on 2017/8/28.
//  Copyright © 2017年 非非宅. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void(^FFZQRCodeScanResultBlock)(NSString *result);

@interface FFZQRCodeViewController : UIViewController
@property (copy, nonatomic) FFZQRCodeScanResultBlock scanResult;

- (id)initWithFFZQRCodeScanResultBlock:(FFZQRCodeScanResultBlock) scanResult;
- (void)stopRun;
- (void)startRun;

@end
