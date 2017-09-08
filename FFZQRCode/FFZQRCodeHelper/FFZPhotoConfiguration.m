//
//  FFZPhotoConfiguration.m
//  FFZQRCode
//
//  Created by 景格_徐薛波 on 2017/8/31.
//  Copyright © 2017年 非非宅. All rights reserved.
//

#import "FFZPhotoConfiguration.h"
#import <AVFoundation/AVFoundation.h>
@implementation FFZPhotoConfiguration

- (id)init {
    self = [super init];
    
    if (self) {
        _enabled = YES;
    }
    
    return self;
}

- (void)setOptions:(NSDictionary *)options {
    [self willChangeValueForKey:@"options"];
    
    _options = options;
    
    [self didChangeValueForKey:@"options"];
}

- (NSDictionary *)createOutputSettings {
    
    if (_options == nil) {
        return @{AVVideoCodecKey : AVVideoCodecJPEG};
    } else {
        return _options;
    }
}

@end
