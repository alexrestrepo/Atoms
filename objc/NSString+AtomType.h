//
//  NSString+AtomType.h
//  MP4Parser
//
//  Created by Alex Restrepo on 2/11/16.
//

#import <Foundation/Foundation.h>

@interface NSString (AtomType)

+ (NSString *)stringWithAtomType:(uint32_t)type;

@end
