//
//  UUIDAtom.h
//  MP4Parser
//
//  Created by Alex Restrepo on 2/12/16.
//

#import "MP4Atom.h"

extern NSString *const SphericalUUID;

@interface UUIDAtom : MP4Atom

@property (nonatomic, copy) NSUUID *uuid;
@property (nonatomic, copy) NSData *contents;

- (instancetype)initWithUUIDString:(NSString *)uuid;

@end
