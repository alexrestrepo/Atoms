//
//  SpatialMetaInjector.m
//  MP4Parser
//
//  Created by Alex Restrepo on 11/18/17.
//

#import "SpatialMetaInjector.h"
#import <QuartzCore/QuartzCore.h>

#import "MP4File.h"
#import "UUIDAtom.h"

@implementation SpatialMetaInjector

+ (BOOL)injectMetadataToFileAtPath:(NSString *)filePath {
    NSTimeInterval time = CACurrentMediaTime();

    MP4File *file = [MP4File mp4WithFileAtPath:filePath];
    if (!file) {
        return NO;
    }

    printf("File read: %s\n%s\n\n", [[filePath lastPathComponent] UTF8String], [[file descriptionWithPadding:@""] UTF8String]);

    // metadata needs to be attached to the video track
    TRAKAtom *videoTrack = [file videoTrackAtom];

    // is there metadata already?
    UUIDAtom *uuid = [videoTrack atomsWithType:'uuid'].firstObject;
    if (uuid) {
        // remove it if so.
        [videoTrack.children removeObject:uuid];
    }

    // this xml was extracted from the uuid atom of a rylo file processed by google's metadata injector.
    // Don't modify the formatting as it seems to matter for some reason. The only change was renaming the stitching sw.
    NSString *sphericalXML =
    @"<?xml version=\"1.0\"?><rdf:SphericalVideo\nxmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"\nxmlns:GSpherical=\"http://ns.google.com/videos/1.0/spherical/\"><GSpherical:Spherical>true</GSpherical:Spherical><GSpherical:Stitched>true</GSpherical:Stitched><GSpherical:StitchingSoftware>Rylo for iPhone</GSpherical:StitchingSoftware><GSpherical:ProjectionType>equirectangular</GSpherical:ProjectionType></rdf:SphericalVideo>";

    uuid = [[UUIDAtom alloc] init];
    uuid.contents = [sphericalXML dataUsingEncoding:NSUTF8StringEncoding];
    [videoTrack appendAtom:uuid];

    BOOL success = [file save];
    printf("\n\nAFTER SAVE: %s\n\n", [[file descriptionWithPadding:@""] UTF8String]);
    printf("process time: %fms", (CACurrentMediaTime() - time) * 1000.0f);

    return success;
}

@end
