//
//  HDLRAtom.m
//  MP4Parser
//
//  Created by Alex Restrepo on 2/11/16.
//

//https://developer.apple.com/library/mac/documentation/QuickTime/QTFF/QTFFChap2/qtff2.html#//apple_ref/doc/uid/TP40000939-CH204-33004
#import "HDLRAtom.h"

#import "TRAKAtom.h"
#import "NSString+AtomType.h"

@implementation HDLRAtom

+ (void)load {
    [MP4Atom registerAtom:self];
}

+ (uint32_t)atomClassType {
    return 'hdlr';
}

- (void)processData:(NSFileHandle *)fileHandle {
    /*
     Version
     A 1-byte specification of the version of this handler information.
     Flags
     A 3-byte space for handler information flags. Set this field to 0.
     Component type
     A four-character code that identifies the type of the handler. Only two values are valid for this field: 'mhlr' for media handlers and 'dhlr' for data handlers.
     Component subtype
     A four-character code that identifies the type of the media handler or data handler. For media handlers, this field defines the type of data—for example, 'vide' for video data, 'soun' for sound data or ‘subt’ for subtitles. See Media Data Atom Types for information about defined media data types.
     For data handlers, this field defines the data reference type; for example, a component subtype value of 'alis' identifies a file alias.
     */
    
    // currently, the only thing we're really interested in is the subtype.
    
    off_t subtypeOffset = self.offsetInFile + self.headerSize + 8;
    [fileHandle he_getBytes:&_componentSubtype range:NSMakeRange(subtypeOffset, sizeof(_componentSubtype))];
    if (_componentSubtype) {
        _componentSubtype = CFSwapInt32BigToHost(_componentSubtype);
    }
}

- (NSString *)description {
    NSString *description = [super description];
    return [description stringByAppendingFormat:@" [%@]", [NSString stringWithAtomType:_componentSubtype]];
}

@end
