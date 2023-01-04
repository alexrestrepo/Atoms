//
//  RyloUUIDAtom.m
//  MP4Parser
//
//  Created by Alex Restrepo on 12/5/18.
//

#import "RyloUUIDAtom.h"

@implementation RyloUUIDAtom

+ (void)load {
    [MP4Atom registerAtom:self];
}

+ (uint32_t)atomClassType {
    return 'Uuid';
}

- (void)processData:(NSFileHandle *)fileHandle {
    off_t uuidOffset = self.offsetInFile + self.headerSize;

    // uuid
    uuid_t uuid = {0};
    [fileHandle he_getBytes:&uuid range:NSMakeRange(uuidOffset, sizeof(uuid))];
    _uuid = [[NSUUID alloc] initWithUUIDBytes:uuid];
}

- (NSString *)description {
    NSString *description = [super description];
    return [description stringByAppendingFormat:@" Video UUID: %@", [_uuid UUIDString]];
}

@end
