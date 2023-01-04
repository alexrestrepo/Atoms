//
//  STCOAtom.m
//  MP4Parser
//
//  Created by Alex Restrepo on 11/16/17.
//

#import "STCOAtom.h"
#import "TRAKAtom.h"

@implementation STCOAtom

+ (void)load {
    [MP4Atom registerAtom:self];
}

+ (uint32_t)atomClassType {
    return 'stco';
}

- (void)updateEntriesWithDelta:(int32_t)delta {
    if (delta == 0) {
        return;
    }

    // move all chunk offsets by the given delta
    uint32_t *tableData = (uint32_t *)[self chunkData];
    uint32_t entryCount = [self entryCount];

    for (int i = 0; i < entryCount; i++) {
        uint32_t offset = tableData[i];
        offset = CFSwapInt32BigToHost(offset);
        offset += delta;
        tableData[i] = CFSwapInt32HostToBig(offset);
    }

    self.offsetInFile = -1; // force a save
}

@end
