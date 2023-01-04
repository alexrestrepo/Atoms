//
//  MP4Atom.hpp
//  QTParse
//
//  Created by Alex Restrepo on 11/17/16.
//

#ifndef MP4Atom_hpp
#define MP4Atom_hpp

#include <stdio.h>
#include <stdint.h>
#include <stddef.h>
#include <stdio.h>

#include <vector>
#include <string>

// For a good intro to MP4/MOV Atoms refer to this:
// https://developer.apple.com/library/mac/documentation/QuickTime/QTFF/QTFFChap2/qtff2.html

class MP4Atom
{
public:
                MP4Atom();
                MP4Atom(uint32_t type);
    virtual     ~MP4Atom();
    
    uint8_t     headerSize();
    off_t       endOffsetInFile();
    
    off_t       offsetInFile() { return _offsetInFile; };
    bool        hasExtendedSize() { return _hasExtendedSize; };
    uint64_t    size() { return _size; };
    uint64_t    calculatedSize();
    
    uint32_t    type() { return _type; };
    
    void        appendAtom(MP4Atom atom);
    std::vector<MP4Atom *> childrenWithType(uint32_t type);
    std::vector<MP4Atom> &children() { return _children; };
    
    void        printStructureWithPadding(const char *padding);
    void        printDescription();
    
    static MP4Atom atomWithPayload(uint32_t type, void *payload, uint64_t payloadSize);
    static MP4Atom atomWithComponents(off_t offsetInFile, bool hasExtendedSize, uint64_t size, uint32_t type, MP4Atom *parent);
    
    // if this is not a container, this will be invoked in order to parse leaf data. Does nothing by default. Meant for subclasses.
    virtual void loadPayload(FILE *source);
    
    // If this is not a container, this will be invoked in order to write leaf data. Does nothing by default. Meant for subclasses.
    virtual size_t appendPayloadToFile(FILE *file);
    
private:
    off_t       _offsetInFile;
    
    bool        _hasExtendedSize;
    uint64_t    _size;
    
    uint32_t    _type;
    std::string _typeAsString;
    
    void        *_payload;
    uint64_t    _payloadSize;
    
    MP4Atom     *_parent;
    std::vector<MP4Atom> _children;
    
private:
    void        setType(uint32_t type);
};

#endif /* MP4Atom_hpp */
