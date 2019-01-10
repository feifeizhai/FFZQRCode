//
//  QRCodeLocation.h
//  FFZQRCode
//
//  Created by 景格_徐薛波 on 2017/8/29.
//  Copyright © 2017年 非非宅. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>
@interface QRCodeModel : NSObject;

@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) NSNumber *w;
@property (strong, nonatomic) NSNumber *h;
@property (strong, nonatomic) NSNumber *x;
@property (strong, nonatomic) NSNumber *y;
@end




@interface QRCodeLocation : NSObject


+ (QRCodeLocation *)share;

+ (QRCodeModel *)imageOpencvQRCode:(UIImage *)img;



@end
