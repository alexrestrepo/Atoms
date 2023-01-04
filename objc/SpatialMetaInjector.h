//
//  SpatialMetaInjector.h
//  MP4Parser
//
//  Created by Alex Restrepo on 11/18/17.
//

#import <Foundation/Foundation.h>

@interface SpatialMetaInjector : NSObject

+ (BOOL)injectMetadataToFileAtPath:(NSString *)filePath;

@end
