//
//  UUIDAtom.m
//  MP4Parser
//
//  Created by Alex Restrepo on 2/12/16.
//

#import "UUIDAtom.h"

NSString *const SphericalUUID = @"ffcc8263-f855-4a93-8814-587a02521fdd";

@implementation UUIDAtom

+ (void)load {
    [MP4Atom registerAtom:self];
}

+ (uint32_t)atomClassType {
    return 'uuid';
}

- (instancetype)initWithUUIDString:(NSString *)uuid {
    self = [super init];
    if (self) {
        _uuid = [[NSUUID alloc] initWithUUIDString:uuid];
    }
    return self;
}

- (instancetype)init {
    return [self initWithUUIDString:SphericalUUID];
}

- (void)processData:(NSFileHandle *)fileHandle {
    off_t uuidOffset = self.offsetInFile + self.headerSize;
    
    // uuid
    unsigned char uuid[16];
    [fileHandle he_getBytes:&uuid range:NSMakeRange(uuidOffset, sizeof(uuid))];
    _uuid = [[NSUUID alloc] initWithUUIDBytes:uuid];
    
    // payload
    off_t payloadSize = self.dataSize - 16; // subtracting the uuid
    if (payloadSize > 0) {
        _contents = [fileHandle he_dataWithRange:NSMakeRange(uuidOffset + 16, payloadSize)];
    }
}

- (NSString *)description {
    NSString *description = [super description];
    return [description stringByAppendingFormat:@" [%@]", [_uuid UUIDString]];
}

- (void)setContents:(NSData *)contents {
    _contents = contents;
    self.size = 16 + [_contents length] + self.headerSize;
    self.offsetInFile = -1;
}

- (NSInteger)appendContentsToStream:(NSOutputStream *)stream {
    NSInteger bytesWritten = 0;
    unsigned char uuid[16];
    [_uuid getUUIDBytes:uuid];
    bytesWritten += [stream write:uuid maxLength:sizeof(uuid)];
    bytesWritten += [stream write:_contents.bytes maxLength:_contents.length];
    
    return bytesWritten;
}

@end
