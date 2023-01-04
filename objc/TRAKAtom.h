//
//  TRAKAtom.h
//  MP4Parser
//
//  Created by Alex Restrepo on 2/12/16.
//

#import "MP4Atom.h"
#import "HDLRAtom.h"
#import "COAtom.h"

@interface TRAKAtom : MP4Atom

@property (nonatomic, weak, readonly) HDLRAtom *hdlr;

- (void)addCoAtom:(COAtom *)atom;
- (NSArray <COAtom *> *)allCoAtoms;

@end
