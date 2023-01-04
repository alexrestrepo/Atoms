//
//  COAtom.m
//  Helios
//
//  Created by Alex Restrepo on 12/22/17.
//

#import "COAtom.h"
#import "TRAKAtom.h"

@interface COAtom()

@property (nonatomic, strong) NSMutableData *entryTable;

@end

@implementation COAtom

- (uint32_t)entryCount {
    uint32_t entryCount = 0;
    [_entryTable getBytes:&entryCount range:NSMakeRange(4, sizeof(uint32_t))];
    return CFSwapInt32BigToHost(entryCount);
}

- (void *)chunkData {
    // base points to right after the atom type, skip 8 bytes (1 version, 3 flags, 4 count)
    uint32_t *base = (uint32_t *)_entryTable.mutableBytes;
    return (void *)(base + 2);
}

- (NSString *)description {
    NSString *description = [super description];
    return [description stringByAppendingFormat:@" %d entries", [self entryCount]];
}

- (void)processData:(NSFileHandle *)fileHandle {
    /*
     Size
     A 32-bit integer that specifies the number of bytes in this chunk offset atom.
     Type
     A 32-bit integer that identifies the atom type; this field must be set to 'stco'.
     Version
     A 1-byte specification of the version of this chunk offset atom.
     Flags
     A 3-byte space for chunk offset flags. Set this field to 0.
     Number of entries
     A 32-bit integer containing the count of entries in the chunk offset table.
     Chunk offset table
     A chunk offset table consisting of an array of offset values. There is one table entry for each chunk in the media. The offset contains the byte offset from the beginning of the data stream to the chunk. The table is indexed by chunk number—the first table entry corresponds to the first chunk, the second table entry is for the second chunk, and so on.
     */

    _entryTable = [[NSMutableData alloc] initWithData:[fileHandle he_dataWithRange:NSMakeRange(self.offsetInFile + self.headerSize, self.dataSize)]];
    // find the trak and set a ptr to self :)
    MP4Atom *parent = self.parent;
    do {
        if (parent.type == 'trak') {
            if ([parent respondsToSelector:@selector(addCoAtom:)]) {
                [(TRAKAtom *)parent addCoAtom:self];
            }
            break;
        }
        parent = parent.parent;
    } while (parent);
}

- (void)updateEntriesWithDelta:(int32_t)delta {
  // subclass
}

- (NSInteger)appendContentsToStream:(NSOutputStream *)stream {
    return [stream write:_entryTable.bytes maxLength:_entryTable.length];
}

@end
