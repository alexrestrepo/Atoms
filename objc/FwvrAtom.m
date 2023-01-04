//
//  FwvrAtom.m
//  MP4Parser
//
//  Created by Alex Restrepo on 9/19/18.
//

#import "FwvrAtom.h"

@implementation FwvrAtom

+ (void)load {
    [MP4Atom registerAtom:self];
}

+ (uint32_t)atomClassType {
    return 'Fwvr';
}

- (NSString *)description {
    NSString *description = [super description];
    return [description stringByAppendingFormat:@" Firmware: \"%@\"", _version];
}

- (void)processData:(NSFileHandle *)fileHandle {
    off_t offset = self.offsetInFile + self.headerSize;
    NSData *data = [fileHandle he_dataWithRange:NSMakeRange(offset, self.dataSize)];
    _version = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end
