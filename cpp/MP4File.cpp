//
//  MP4File.cpp
//  QTParse
//
//  Created by Alex Restrepo on 11/18/16.
//

#include "MP4File.h"

#include <arpa/inet.h>
#include <cassert>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <unordered_set>
#include <libgen.h>

MP4File::~MP4File() {
    if (_sourceFile) {
        fclose(_sourceFile);
    }
    _sourceFile = nullptr;
}

MP4File::MP4File(const char *path)
: _sourceFile(nullptr)
, _atoms()
{
    _sourceFile = fopen(path, "rb");
    _fileName = std::string(basename((char *)path));
    parse();
}

bool _isContainerAtom(uint32_t atomType) {
    static std::unordered_set<uint32_t> containerAtoms = {
        'moov',
        'clip',
        'udta',
        'trak',
        'clip',
        'matt',
        'edts',
        'mdia',
        'minf',
        'dinf',
        'stbl',
        'RYLO',
        'MAGE'
    };
    return containerAtoms.count(atomType) > 0;
}

off_t _fileSize(FILE *file) {
    off_t curr = ftello(file);
    
    // seek to end to get file size
    fseeko(file, 0, SEEK_END);
    off_t size = ftello(file);
    
    // seek back to original position
    fseeko(file, curr, SEEK_SET);
    
    return size;
}

#if !defined(MIN)
    #define MIN(A,B)	((A) < (B) ? (A) : (B))
#endif

size_t _copyFileData(FILE *source, FILE *destination, size_t dataSize) {
    char buffer[BUFSIZ];
    size_t copied = 0;
    size_t read = 0;
    
    while ((read = fread(buffer, 1, MIN(BUFSIZ, dataSize - copied), source))) {
        copied += fwrite(buffer, 1, read, destination);
    }
    
    return copied;
}

MP4Atom MP4File::loadAtomFromFile(FILE *file, off_t start, off_t end, MP4Atom *parent) {
    // atoms may not parse any of their data, so skip to the atom boundary.
    fseeko(file, start, SEEK_SET);
    
    // header
    // 1. size
    uint32_t size = 0;
    size_t read = fread(&size, sizeof(size), 1, file);
    size = ntohl(size);
    
    // 2. type
    uint32_t type = 0;
    read = fread(&type, sizeof(type), 1, file);
    type = ntohl(type);
    
    // extended size?
    bool hasExtendedSize = size == 1;
    uint64_t totalSize = size;
    if (hasExtendedSize) {
        read = fread(&totalSize, sizeof(totalSize), 1, file);
        totalSize = ntohll(totalSize);
    }
    
    // size must be at least 8 (4 size + 4 type)
    if(totalSize < 8
       || start + totalSize > end) {
        return MP4Atom();
    }
    
    MP4Atom atom = MP4Atom::atomWithComponents(start, hasExtendedSize, totalSize, type, parent);
    if (_isContainerAtom(type)) {
        loadContainerAtomFromFile(file, start + atom.headerSize(), atom.endOffsetInFile(), &atom, atom.children());
        
    } else {
        atom.loadPayload(file);
    }
    
    return atom;
}

void MP4File::loadContainerAtomFromFile(FILE *file, off_t start, off_t end, MP4Atom *parent, std::vector<MP4Atom> &storage) {
    off_t startOffset = start;
    
    while (startOffset < end) {
        MP4Atom atom = loadAtomFromFile(_sourceFile, startOffset, end, parent);
        if (atom.size() == 0) {
            break;
        }
        storage.push_back(atom);
        startOffset = atom.endOffsetInFile();
    }
}

void MP4File::parse() {
    if (!_sourceFile) {
        return;
    }
    loadContainerAtomFromFile(_sourceFile, 0, _fileSize(_sourceFile), nullptr, _atoms);
}

MP4Atom* MP4File::videoTrackAtom() {
    // the video track atom is located in moov > trak.
    
    for (int i = 0; i < _atoms.size(); i++) {
        if (_atoms[i].type() == 'moov') {
            std::vector<MP4Atom*> tracks = _atoms[i].childrenWithType('trak');
            for (int j = 0; j < tracks.size(); j++) {
                // there can be multiple tracks in the file, we need to find the video one.
                // for that we need to find the 'mdia' > 'hdlr' atom and extract its subtype.
                
                std::vector<MP4Atom*> mdia = tracks[j]->childrenWithType('mdia');
                if (!mdia.size()) {
                    continue;
                }
                
                std::vector<MP4Atom*> hdlr = mdia[0]->childrenWithType('hdlr');
                if (!hdlr.size()) {
                    continue;
                }
                
                // extract subtype...
                //https://developer.apple.com/library/mac/documentation/QuickTime/QTFF/QTFFChap2/qtff2.html#//apple_ref/doc/uid/TP40000939-CH204-33004
                fseek(_sourceFile, hdlr[0]->offsetInFile() + hdlr[0]->headerSize() + 8, SEEK_SET);
                uint32_t subtype = 0;
                fread(&subtype, sizeof(subtype), 1, _sourceFile);
                subtype = ntohl(subtype);
                
                if (subtype == 'vide') {
                    return tracks[j];
                }
            }
        }
    }
    
    return nullptr;
}

void MP4File::printStructure() {
    printf("\n[%s]: atoms: %lu, size %llu\n", _fileName.c_str(), _atoms.size(), calculatedSize());
    
    for (int i = 0; i < _atoms.size(); i++) {
        MP4Atom &atom = _atoms[i];
        
        if (i < _atoms.size() - 1) {
            atom.printStructureWithPadding("  ├─");
        } else {
            atom.printStructureWithPadding("  └─");
        }
    }
    
//    for (MP4Atom &atom : _atoms) {
//        atom.printStructure();
//    }
}

size_t _appendAtomHeaderToFile(MP4Atom &atom, FILE *dst) {
    size_t written = 0;
    
    uint32_t size = atom.hasExtendedSize() ? 1 : (uint32_t)atom.calculatedSize();
    size = htonl(size);
    written = fwrite(&size, 1, sizeof(uint32_t), dst);
    
    uint32_t type = atom.type();
    type = htonl(type);
    written += fwrite(&type, 1, sizeof(uint32_t), dst);
    
    if (atom.hasExtendedSize()) {
        uint64_t extendedSize = atom.calculatedSize();
        extendedSize = htonll(extendedSize);
        written += fwrite(&extendedSize, 1, sizeof(uint64_t), dst);
    }
    
    return written;
}

size_t _appendAtomToFile(MP4Atom &atom, FILE *src, FILE *dst) {
    size_t written = 0;
    
    if (atom.children().size()) {
        written += _appendAtomHeaderToFile(atom, dst);
        
        for (MP4Atom &child : atom.children()) {
            written += _appendAtomToFile(child, src, dst);
        }
        
    } else {
        if (atom.offsetInFile() < 0) {
            written += _appendAtomHeaderToFile(atom, dst);
            written += atom.appendPayloadToFile(dst);
            
        } else {
            // write the entire atom as a whole.
            fseek(src, atom.offsetInFile(), SEEK_SET);
            written += _copyFileData(src, dst, atom.calculatedSize());
        }
    }
    
    return written;
}

uint64_t MP4File::calculatedSize() {
    uint64_t size = 0;
    for (MP4Atom &atom : _atoms) {
        size += atom.calculatedSize();
    }
    
    return size;
}

bool MP4File::saveToPath(const char *path) {
    FILE *dst = fopen(path, "ab"); // append-bin
    if (!dst) {
        return false;
    }
    
    size_t written = 0;
    
    for (MP4Atom &atom : _atoms) {
        written += _appendAtomToFile(atom, _sourceFile, dst);
    }

    fclose(dst);
    return written == calculatedSize();
}
