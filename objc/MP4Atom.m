//
//  MP4Atom.m
//  MP4Parser
//
//  Created by Alex Restrepo on 2/11/16.
//

#import "MP4Atom.h"
#import "NSString+AtomType.h"

static NSMutableArray *registeredAtoms = nil;

@implementation NSFileHandle(data)
- (NSData *)he_dataWithRange:(NSRange)range {
    [self seekToFileOffset:range.location];
    NSData *currentData = [self readDataOfLength:range.length];
    return currentData;
}

- (void)he_getBytes:(void *)buffer range:(NSRange)range {
    NSData *currentData = [self he_dataWithRange:range];
    [currentData getBytes:buffer range:NSMakeRange(0, range.length)];
}

@end

@implementation MP4Atom

// http://www.cocoawithlove.com/2009/07/simple-extensible-http-server-in-cocoa.html
+ (void)registerAtom:(Class)atomClass {
    if (registeredAtoms == nil) {
        registeredAtoms = [[NSMutableArray alloc] init];
    }
    [registeredAtoms addObject:atomClass];
}

+ (MP4Atom *)atomForType:(uint32_t)type {
    MP4Atom *atom = nil;
    
    for(Class atomClass in registeredAtoms) {
        if(type == [atomClass atomClassType]) {
            atom = [[atomClass alloc] initWithType:type];
            break;
        }
    }
    
    if (!atom) {
        atom = [[MP4Atom alloc] initWithType:type];
    }
    
    return atom;
}

+ (uint32_t)atomClassType {
    return 0;
}

- (instancetype)init {
    self = [self initWithType:[[self class] atomClassType]];
    if (self) {
        
    }
    return self;
}

- (instancetype)initWithType:(uint32_t)type
{
    self = [super init];
    if (self) {
        _offsetInFile = -1;
        _type = type;
        _headerSize = 8; //default
    }
    return self;
}

- (off_t)endOffsetInFile {
    return _offsetInFile + MAX(_size, _size);
}

- (uint64_t)dataSize {
    return _size - _headerSize;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"['%@'][%lld + %llu%@(%lld): %lld]",// [%p-%p]",
            [NSString stringWithAtomType:_type], _offsetInFile, _size, _hasExtendedSize ? @"[ext]" : @"", [self calculatedSize], [self endOffsetInFile] /*, self, _parent*/];
}

- (NSString *)descriptionWithPadding:(NSString *)padding {
    NSMutableString *description = [NSMutableString stringWithString:padding];
    [description appendFormat:@"%@\n",[self description]];

    [_children enumerateObjectsUsingBlock:^(MP4Atom * _Nonnull atom, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *nextPadding = padding;
        nextPadding = [nextPadding stringByReplacingOccurrencesOfString:@"├" withString:@"│"];
        nextPadding = [nextPadding stringByReplacingOccurrencesOfString:@"└" withString:@" "];
        nextPadding = [nextPadding stringByReplacingOccurrencesOfString:@"─" withString:@" "];
        
        if (idx < [_children count] - 1) {
            nextPadding = [nextPadding stringByAppendingString:@" ├─"];
            
        } else {
            nextPadding = [nextPadding stringByAppendingString:@" └─"];
        }
        
        [description appendString:[atom descriptionWithPadding:nextPadding]];
    }];
    
    return description;
}

- (void)processData:(NSFileHandle *)fileHandle {
    // ignore by default
}

- (NSArray *)atomsWithType:(uint32_t)type {
    NSMutableArray *result = [NSMutableArray new];
    for (MP4Atom *atom in _children) {
        if (atom.type == type) {
            [result addObject:atom];
        }
    }
    return [result copy];
}

- (void)appendAtom:(MP4Atom *)atom {
    if (!atom || atom.size < 8) {
        return;
    }
    
    // 1. append atom
    atom.parent = self;
    [self.children addObject:atom];


    /*
     We can mark atoms as "not saved" by giving them an
     offset of -1.
     Then when writing the new file, it will be written as a stream, so we just do a traversal of the structure and at that point
     we can calculate the new offsets...
    */
    atom.offsetInFile = -1;
}

- (void)reconcileOffsets {
    off_t startOffset = self.offsetInFile + self.headerSize;

    if (![self.children count]) {
        return;
    }
    
    for (MP4Atom *atom in self.children) {
        atom.offsetInFile = startOffset;
        [atom reconcileOffsets];
        
        startOffset += atom.size;
    }
    
    self.size = [[self.children  lastObject] endOffsetInFile] - self.offsetInFile;
}

- (uint64_t)calculatedSize {
    if (![self.children count]) {
        return self.size;
    }
    
    uint64_t size = 0;
    for (MP4Atom *atom in _children) {
        size += [atom calculatedSize];
    }
    
    return size + self.headerSize;
}

- (off_t)calculatedOffsetInFile {
    __block off_t offset = [_parent calculatedOffsetInFile];
    [_parent.children enumerateObjectsUsingBlock:^(MP4Atom * _Nonnull sibling, NSUInteger idx, BOOL * _Nonnull stop) {
        if (sibling == self) {
            *stop = YES;
        } else {
            offset += [sibling calculatedSize];
        }
    }];

    return offset;
}

- (NSInteger)appendContentsToStream:(NSOutputStream *)stream {
    // default does nothing, this will make the save method fail in an atom was modified and doesn't implement this method.
    return 0;
}

@end
