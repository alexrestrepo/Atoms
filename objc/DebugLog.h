//
//  MageLog.h
//  MP4Parser
//
//  Created by Alex Restrepo on 12/1/17.
//

#ifndef _debuglog_h_
#define _debuglog_h_

#if DEBUG
static inline void __DebugLog_imp( const char *filePath, const int lineNumber, NSString *format, ... ) __printflike(3, 4) {
    va_list ap;
    va_start( ap, format );
    NSString *body = [[NSString alloc] initWithFormat:format arguments:ap];
    va_end( ap );

    NSString *fileName = [[NSString stringWithUTF8String:filePath] lastPathComponent];
    NSString *log = [NSString stringWithFormat:@"%@:%d > %@\n", fileName, lineNumber, body];

    printf("%s", [log UTF8String]);
}

#define DebugLog(args...) do {              \
__DebugLog_imp( __FILE__, __LINE__, args );    \
} while (0)

#else
#define DebugLog(args...)

#endif

#endif /* MageLog_h */
