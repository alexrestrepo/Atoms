//
//  MP4File.hpp
//  QTParse
//
//  Created by Alex Restrepo on 11/18/16.
//

#ifndef MP4File_hpp
#define MP4File_hpp

#include <stdio.h>

#include "MP4Atom.h"



class MP4File {
public:
            MP4File(const char *path);
    virtual ~MP4File();
    
    MP4Atom *videoTrackAtom();
    bool    saveToPath(const char *path);
    
    std::vector<MP4Atom> &atoms() { return _atoms; };
    
    void    printStructure();
    
private:
    void    parse();
    
    MP4Atom loadAtomFromFile(FILE *file, off_t start, off_t end, MP4Atom *parent);
    void    loadContainerAtomFromFile(FILE *file, off_t start, off_t end, MP4Atom *parent, std::vector<MP4Atom> &storage);
    uint64_t calculatedSize();
    
private:
    FILE *_sourceFile;
    std::string _fileName;
    std::vector<MP4Atom> _atoms;
};

#endif /* MP4File_hpp */
