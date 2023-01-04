//
//  RyloUUIDAtom.h
//  MP4Parser
//
//  Created by Alex Restrepo on 12/5/18.
//

#import "MP4Atom.h"

@interface RyloUUIDAtom : MP4Atom

@property (nonatomic, strong, readonly) NSUUID *uuid;

@end
