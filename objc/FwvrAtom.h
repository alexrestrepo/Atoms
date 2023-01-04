//
//  FwvrAtom.h
//  MP4Parser
//
//  Created by Alex Restrepo on 9/19/18.
//

#import "MP4Atom.h"

NS_ASSUME_NONNULL_BEGIN

@interface FwvrAtom : MP4Atom

@property (nonatomic, copy, readonly) NSString *version;

@end

NS_ASSUME_NONNULL_END
