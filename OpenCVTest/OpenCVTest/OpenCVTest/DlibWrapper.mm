//
//  DlibWrapper.m
//  OpenCVTest
//
//  Created by Hsin Miao on 12/13/17.
//  Copyright © 2017 Hsin Miao. All rights reserved.
//

#import "DlibWrapper.h"
#include <dlib/image_processing.h>
#include <dlib/image_io.h>

@interface DlibWrapper ()

@property (assign) BOOL prepared;

@end

@implementation DlibWrapper {
    dlib::shape_predictor sp;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _prepared = NO;
    }
    return self;
}

- (void)prepare {
    NSString *modelFileName = [[NSBundle mainBundle] pathForResource:@"shape_predictor_68_face_landmarks" ofType:@"dat"];
    std::string modelFileNameCString = [modelFileName UTF8String];

    dlib::deserialize(modelFileNameCString) >> sp;

    // FIXME: test this stuff for memory leaks (cpp object destruction)
    self.prepared = YES;
}

@end
