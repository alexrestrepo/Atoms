//
//  COAtom.h
//  Helios
//
//  Created by Alex Restrepo on 12/22/17.
//

#import "MP4Atom.h"

// base clase for chunk offset atoms: stco + co64
@interface COAtom : MP4Atom

- (uint32_t)entryCount;
- (void *)chunkData;
- (void)updateEntriesWithDelta:(int32_t)delta;

@end
