//
//  CO64Atom.m
//  Helios
//
//  Created by Alex Restrepo on 12/22/17.
//

#import "CO64Atom.h"
#import "TRAKAtom.h"

@implementation CO64Atom

+ (void)load {
    [MP4Atom registerAtom:self];
}

+ (uint32_t)atomClassType {
    return 'co64';
}

- (void)updateEntriesWithDelta:(int32_t)delta {
    if (delta == 0) {
        return;
    }

    // move all chunk offsets by the given delta
    uint64_t *tableData = (uint64_t *)[self chunkData];
    uint32_t entryCount = [self entryCount];
    
    for (int i = 0; i < entryCount; i++) {
        uint64_t offset = tableData[i];
        offset = CFSwapInt64BigToHost(offset);
        offset += delta;
        tableData[i] = CFSwapInt64HostToBig(offset);
    }

    self.offsetInFile = -1; // force a save
}

@end
