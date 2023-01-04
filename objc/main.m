//
//  main.m
//  MP4Parser
//
//  Created by Alex Restrepo on 2/11/16.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#import "MP4File.h"
#import "DebugLog.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {

        if (argc < 2) {
            NSLog(@"Missing filename.");
            return 0;
        }

        NSString *path = [NSString stringWithUTF8String:argv[1]];
        MP4File *file = [MP4File mp4WithFileAtPath:path];
        if (!file) {
            return NO;
        }

        printf("File read: '%s'\n%s\n", 
            [[path lastPathComponent] UTF8String],
            [[file descriptionWithPadding:@""] UTF8String]
        );

//        NSTimeInterval time = CACurrentMediaTime();
//        if ([SpatialMetaInjector injectMetadataToFileAtPath:@"test.mp4"]) {
//            NSLog(@"we gucci");
//        } else {
//            NSLog(@"we ng");
//        }
//        NSLog(@"%fms", (CACurrentMediaTime() - time) * 1000.0f);
    }
    return 0;
}
