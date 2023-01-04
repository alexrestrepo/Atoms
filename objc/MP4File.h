//
//  MP4File.h
//  MP4Parser
//
//  Created by Alex Restrepo on 2/11/16.
//

#import <Foundation/Foundation.h>

#import "MP4Atom.h"
#import "TRAKAtom.h"

@interface MP4File : MP4Atom

+ (MP4File *)mp4WithFileAtPath:(NSString *)filePath;

- (instancetype)initWithFileAtPath:(NSString *)filePath;
- (TRAKAtom *)videoTrackAtom;
- (BOOL)save;

@end
