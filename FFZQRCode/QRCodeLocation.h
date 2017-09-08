//
//  QRCodeLocation.h
//  FFZQRCode
//
//  Created by 景格_徐薛波 on 2017/8/29.
//  Copyright © 2017年 非非宅. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>
@interface QRCodeLocation : NSObject
+ (QRCodeLocation *)share;
+ (CGRect)opencvScanQRCode:(UIImage *)image;
+ (UIImage *)imageOpencvScanQRCode:(UIImage *)img;
@end
