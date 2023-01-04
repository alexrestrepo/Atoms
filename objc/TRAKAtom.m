//
//  TRAKAtom.m
//  MP4Parser
//
//  Created by Alex Restrepo on 2/12/16.
//

#import "TRAKAtom.h"
#import "NSString+AtomType.h"

@interface TRAKAtom()
@property (nonatomic, strong) NSMutableOrderedSet <COAtom *> *coAtoms;
@end

@implementation TRAKAtom

+ (void)load {
    [MP4Atom registerAtom:self];
}

+ (uint32_t)atomClassType {
    return 'trak';
}

- (NSString *)description {
    NSString *description = [super description];
    return [description stringByAppendingFormat:@" [%@]", [NSString stringWithAtomType:self.hdlr.componentSubtype]];
}

- (void)addCoAtom:(COAtom *)atom {
    if (!_coAtoms) {
        _coAtoms = [[NSMutableOrderedSet alloc] init];
    }
    [_coAtoms addObject:atom];
}

- (NSArray<COAtom *> *)allCoAtoms {
    return [_coAtoms array];
}

- (HDLRAtom *)hdlr {
    // the track hdlr with the track subtype is in mdia > hdlr.
    MP4Atom *mdia = [[self atomsWithType:'mdia'] firstObject];
    return [[mdia atomsWithType:'hdlr'] firstObject];
}

@end
