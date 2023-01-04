//
//  NSString+AtomType.m
//  MP4Parser
//
//  Created by Alex Restrepo on 2/11/16.
//

#import "NSString+AtomType.h"

@implementation NSString (AtomType)

+ (NSString *)stringWithAtomType:(uint32_t)type {
    unsigned char strType[5];
    
    strType[0] = (type >> 24) & 0xff;
    strType[1] = (type >> 16) & 0xff;
    strType[2] = (type >> 8) & 0xff;
    strType[3] = type & 0xff;
    strType[4] = 0;
    
    return [NSString stringWithCString:(const char *)&strType encoding:NSUTF8StringEncoding];
}

@end
