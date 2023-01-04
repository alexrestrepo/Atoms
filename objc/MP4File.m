//
//  MP4File.m
//  MP4Parser
//
//  Created by Alex Restrepo on 2/11/16.
//

#import "MP4File.h"
#import "NSString+AtomType.h"

@interface MP4File ()

@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, strong) NSFileHandle *readHandle;

@end

@implementation MP4File

+ (MP4File *)mp4WithFileAtPath:(NSString *)filePath {
    return [[MP4File alloc] initWithFileAtPath:filePath];
}

- (void)dealloc {
    [_readHandle closeFile];
}

- (instancetype)initWithFileAtPath:(NSString *)filePath {
    self = [super init];
    if (self) {
        self.type = 'file'; // funs
        self.headerSize = 0;
        self.offsetInFile = 0;
        if(![self parseFileAtPath:filePath]) {
            return nil;
        }
        self.size = [[self.children  lastObject] endOffsetInFile] - self.offsetInFile;
    }
    return self;
}

- (NSString *)description {
    NSString *description = [NSString stringWithFormat: @"\n[MP4File: %lu top level atoms]\n%@",
                             (unsigned long)[self.children count], [super description]];
    return description;
}

#pragma mark - Parsing
- (BOOL)parseFileAtPath:(NSString *)path {
    
    _readHandle = [NSFileHandle fileHandleForReadingAtPath:path];
    if (!_readHandle) {
        NSLog(@"Error opening file %@", path);
        return NO;
    }
    
    self.filePath = path;
    NSUInteger fileLength = [_readHandle seekToEndOfFile];
    if (fileLength) {
        self.children = [self loadContainerAtomAtOffset:0
                                              endOffset:fileLength
                                                 parent:self];
    }
    
    return [self.children count] > 0;
}

- (NSMutableArray *)loadContainerAtomAtOffset:(off_t)start
                                    endOffset:(off_t)end
                                       parent:(MP4Atom *)parent {
    off_t startPos = start;
    NSMutableArray *atoms = [[NSMutableArray alloc] init];
    while (startPos < end) {
        MP4Atom *atom = [self loadAtomAtOffset:startPos endOffset:end parent:parent];
        if (!atom) {
            //error
            return nil;
        }
        [atoms addObject:atom];
        startPos = atom.offsetInFile + atom.size;
    }
    return atoms;
}

- (MP4Atom *)loadAtomAtOffset:(off_t)start
                    endOffset:(off_t)end
                       parent:(MP4Atom *)parent {

    // atom size.
    uint32_t size = 0;
    [_readHandle he_getBytes:&size range:NSMakeRange(start, sizeof(size))];
    size = CFSwapInt32BigToHost(size);
    
    // atom type.
    uint32_t type = 0;
    [_readHandle he_getBytes:&type range:NSMakeRange(start + 4, sizeof(type))];
    type = CFSwapInt32BigToHost(type);
    
    // extended size?
    uint8_t headerSize = 8;
    uint64_t extendedSize = 0;
    if (size == 1) {
        [_readHandle he_getBytes:&extendedSize range:NSMakeRange(start + 8, sizeof(extendedSize))];
        extendedSize = CFSwapInt64BigToHost(extendedSize);
        headerSize = 16; // 4 size + 4 type + 8 extended size
        
    } else if (size < 8) {
        // this can't happen...
        NSAssert(NO, @"Invalid size atom size?");
        return nil;
    }
    
    uint64_t totalSize = size == 1 ? extendedSize : size;
    if (start + totalSize > end) {
        NSAssert(NO, @"Invalid file / Atom exceeds bounds?");
        return nil;
    }
    
    MP4Atom *atom = [MP4Atom atomForType:type];
    atom.offsetInFile = start;
    atom.size = totalSize;
    atom.headerSize = headerSize;
    atom.parent = parent;
    atom.hasExtendedSize = size == 1;
    
    // containers we're interested in
    if (
        type == 'mdia'
        || type == 'moov'
        || type == 'trak'
        || type == 'dinf'
        || type == 'minf'
        || type == 'stbl'
        || type == 'udta'
        || type == 'RYLO'
        ) {
        
        atom.children = [self loadContainerAtomAtOffset:start + atom.headerSize
                                              endOffset:[atom endOffsetInFile]
                                                 parent:atom];
        if (!atom.children) {
            return nil;
        }
        
    } else {
        [atom processData:_readHandle];
    }
    return atom;
}

- (NSArray <TRAKAtom *> *)allTracks {
    // if any, it would be inside moov
    // the type will be in moov.trak.mdia.hdlr

    // find the moov atom...
    NSArray<MP4Atom *> *moov = [self atomsWithType:'moov'];
    if ([moov count]) {
        // now, the track atoms..
        NSArray<TRAKAtom *> *tracks = [[moov firstObject] atomsWithType:'trak'];
        return tracks;
    }

    return nil;
}

- (TRAKAtom *)videoTrackAtom {
    // if any, it would be inside moov
    // the type will be in moov.trak.mdia.hdlr
    
    TRAKAtom *atom = nil;
    NSArray<TRAKAtom *> *tracks = [self allTracks];
    // when parsing the hdlr atom, it should have set a shortcut to its track...
    for (TRAKAtom *track in tracks) {
        if (track.hdlr.componentSubtype == 'vide') {
            atom = track;
            break;
        }
    }

    return atom;
}

- (int32_t)mdataOffset {
    MP4Atom *data = [self atomsWithType:'mdat'].firstObject;
    return (int32_t)([data calculatedOffsetInFile] - data.offsetInFile);
}

#pragma mark - Saving

- (BOOL)save {
    int32_t offset = [self mdataOffset];
    if (offset != 0) {
        NSArray<TRAKAtom *> *tracks = [self allTracks];
        for (TRAKAtom *track in tracks) {
            for (COAtom *coatom in [track allCoAtoms]) {
                [coatom updateEntriesWithDelta:offset];
            }
        }
    }

    // write a new tmp file, then swap/replace the old
    NSString *filePath = [[[NSUUID UUID] UUIDString] stringByAppendingPathExtension:@"mp4"];
    filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:filePath];
    
    NSInteger bytesWritten = 0;
    BOOL success = NO;
    NSOutputStream *outputStream = [NSOutputStream outputStreamToFileAtPath:filePath append:NO];
    [outputStream open];
    if  ([outputStream hasSpaceAvailable]) {
        for (MP4Atom *atom in self.children) {
            bytesWritten += [self appendAtom:atom toStream:outputStream];
        }
    }
    [outputStream close];
    if (bytesWritten == [self calculatedSize]) {
        // success... replace old file
        [_readHandle closeFile];

        NSError *error = nil;
        success = [[NSFileManager defaultManager] replaceItemAtURL:[NSURL fileURLWithPath:_filePath]
                                                     withItemAtURL:[NSURL fileURLWithPath:filePath]
                                                    backupItemName:nil
                                                           options:NSFileManagerItemReplacementUsingNewMetadataOnly
                                                  resultingItemURL:nil
                                                             error:&error];
        if (success) {
            _readHandle = [NSFileHandle fileHandleForReadingAtPath:_filePath];
            [self reconcileOffsets];

        } else {
            NSLog(@"Error moving file %@", error);
        }
    }
    return success;
}

- (NSInteger)appendAtomHeader:(MP4Atom *)atom toStream:(NSOutputStream *)stream {
    NSInteger bytesWritten = 0;
    uint32_t size = atom.hasExtendedSize ? 1 : (uint32_t)[atom calculatedSize];
    size = CFSwapInt32HostToBig(size);
    bytesWritten += [stream write:(const uint8_t *)&size maxLength:sizeof(size)];
    
    uint32_t type = atom.type;
    type = CFSwapInt32HostToBig(type);
    bytesWritten += [stream write:(const uint8_t *)&type maxLength:sizeof(type)];
    
    if (atom.hasExtendedSize) {
        uint64_t extendedSize = [atom calculatedSize];
        extendedSize = CFSwapInt64BigToHost(extendedSize);
        bytesWritten += [stream write:(const uint8_t *)&extendedSize maxLength:sizeof(extendedSize)];
    }
    
    return bytesWritten;
}

- (NSInteger)appendAtom:(MP4Atom *)atom toStream:(NSOutputStream *)stream {

    NSInteger bytesWritten = 0;
    
    if ([atom.children count]) {
        bytesWritten += [self appendAtomHeader:atom toStream:stream];
        
        // then children
        for (MP4Atom *child in atom.children) {
            bytesWritten += [self appendAtom:child toStream:stream];
        }
        
    } else {
        
        // check if the atom has a valid offset, if not, it's a new atom...
        if (atom.offsetInFile < 0) {
            bytesWritten += [self appendAtomHeader:atom toStream:stream];
            bytesWritten += [atom appendContentsToStream:stream];
            
        } else {
            // there is an offset, simply copy that and append it to the stream...
            // todo, do this in pieces
//            NSData *chunk = [_data subdataWithRange:NSMakeRange(atom.offsetInFile, atom.size)];
//            bytesWritten += [stream write:chunk.bytes maxLength:[chunk length]];
            bytesWritten += [self appendDataInRange:NSMakeRange(atom.offsetInFile, atom.size)
                                           toStream:stream];
        }
    }
    
    return bytesWritten;
}

- (NSInteger)appendDataInRange:(NSRange)range toStream:(NSOutputStream *)stream {
    if (range.length == 0) {
        return 0;
    }

    const NSUInteger maxLength = 1024 * 1024 * 4; // 4 megs at a time max
    NSInteger bytesWritten = 0;
    while (bytesWritten < range.length) {
        @autoreleasepool {
            NSData *chunk = [_readHandle he_dataWithRange:NSMakeRange(range.location + bytesWritten, MIN(maxLength, range.length - bytesWritten))];
            NSInteger written = [stream write:chunk.bytes maxLength:[chunk length]];
            if (written > 0) {
                bytesWritten += written;

            } else {
                break;
            }
        }
    }

    return bytesWritten;
}

@end
