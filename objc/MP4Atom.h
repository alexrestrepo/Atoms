//
//  MP4Atom.h
//  MP4Parser
//
//  Created by Alex Restrepo on 2/11/16.
//

#import <Foundation/Foundation.h>

@interface NSFileHandle(data)
- (NSData *)he_dataWithRange:(NSRange)range;
- (void)he_getBytes:(void *)buffer range:(NSRange)range;
@end


@interface MP4Atom : NSObject

@property (nonatomic, assign) off_t offsetInFile;
@property (nonatomic, assign, readonly) off_t endOffsetInFile;

@property (nonatomic, assign) BOOL hasExtendedSize;
@property (nonatomic, assign) uint64_t size;                // includes extended size.
@property (nonatomic, assign, readonly) uint64_t dataSize;  // size - headers

@property (nonatomic, assign) uint32_t type;
@property (nonatomic, assign) uint8_t headerSize;

@property (nonatomic, weak) MP4Atom *parent;
@property (nonatomic, strong) NSMutableArray<MP4Atom *> *children;

// dynamic atom subclass registering
+ (uint32_t)atomClassType;
+ (void)registerAtom:(Class)atomClass;
+ (MP4Atom *)atomForType:(uint32_t)type;


- (instancetype)initWithType:(uint32_t)type;

/**
 *  Prints the structure of the atom
 *
 *  @param padding A string padding to prepend to the description tree
 *
 *  @return description tree as a string.
 */
- (NSString *)descriptionWithPadding:(NSString *)padding;


/**
 Gives each atom the opportunity to parse its contents. The default simply skips to the end of the atom.
 This is not called on container atoms.

 @param fileHandle  file from which to read the data.
 */
- (void)processData:(NSFileHandle *)fileHandle;

/**
 *  Finds all the children atoms (top level) that match the given type
 *
 *  @param type type to match
 *
 *  @return array of atoms that match the type
 */
- (NSArray *)atomsWithType:(uint32_t)type;

/**
 *  Appends an atom to this container. Will trigger a re-calculation of the size/offsets
 *
 *  @param atom the atom to append.
 */
- (void)appendAtom:(MP4Atom *)atom;

/**
 *  Recalculates all the offsets for all contained atoms, recursively.
 */
- (void)reconcileOffsets;

/**
 *  Calculates the atom size by adding the size of all children, if any.
 *  When writing, this should be the size used as it can be modified after the atom is read.
 *
 *  @return the calculated size.
 */
- (uint64_t)calculatedSize;

- (off_t)calculatedOffsetInFile;

/**
 *  Writes the atom data to the specified stream. The default implementation does nothing.
 *  NOTE: at this point the header (size, type [extended size]) has already been written to the stream.
 *
 *  @param stream the stream on which to save the awesomeness
 */
- (NSInteger)appendContentsToStream:(NSOutputStream *)stream;

@end
