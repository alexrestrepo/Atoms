//
//  MP4Atom.cpp
//  QTParse
//
//  Created by Alex Restrepo on 11/17/16.
//

#include "MP4Atom.h"

#include <cassert>
#include <algorithm>

MP4Atom::~MP4Atom() {

}

MP4Atom::MP4Atom()
: _offsetInFile(-1)
, _type(0)
, _hasExtendedSize(false)
, _size(0)
, _parent(nullptr)
, _children()
, _payload(nullptr)
, _payloadSize(0)
{
    
}

MP4Atom::MP4Atom(uint32_t type)
: MP4Atom() {
    setType(type);
}

MP4Atom MP4Atom::atomWithComponents(off_t offsetInFile, bool hasExtendedSize, uint64_t size, uint32_t type, MP4Atom *parent) {
    MP4Atom atom(type);
    atom._offsetInFile = offsetInFile;
    atom._hasExtendedSize = hasExtendedSize;
    atom._size = size;
    atom._parent = parent;
    
    return atom;
}

MP4Atom MP4Atom::atomWithPayload(uint32_t type, void *payload, uint64_t payloadSize) {
    MP4Atom atom(type);
    atom._payloadSize = payloadSize;
    atom._size = atom.headerSize() + payloadSize;
    atom._payload = payload;
    
    return atom;
}

uint8_t MP4Atom::headerSize() {
    return _hasExtendedSize ? 16 : 8;
}

off_t MP4Atom::endOffsetInFile() {
    return _offsetInFile + _size;
}

std::string StringFromType(uint32_t type) {
    unsigned char strType[5];
    strType[0] = (type >> 24) & 0xff;
    strType[1] = (type >> 16) & 0xff;
    strType[2] = (type >> 8) & 0xff;
    strType[3] = type & 0xff;
    strType[4] = 0;
    
    return std::string(reinterpret_cast<const char*>(strType));
}

void MP4Atom::setType(uint32_t type) {
    _type = type;
    _typeAsString = StringFromType(type);
}

uint64_t MP4Atom::calculatedSize() {
    if (!_children.size()) {
        return _size;
    }
    
    uint64_t size = 0;
    for (MP4Atom &atom : _children) {
        size += atom.calculatedSize();
    }
    
    return size + headerSize();
}

std::vector<MP4Atom *> MP4Atom::childrenWithType(uint32_t type) {
    std::vector<MP4Atom *> result;
    for (MP4Atom &atom : _children) {
        if (atom._type == type) {
            result.push_back(&atom);
        }
    }
    
    return result;
}

void MP4Atom::printDescription() {
    printf("['%s'][%lld + %llu%s(%lld) = %lld]", _typeAsString.c_str(), _offsetInFile, _size, _hasExtendedSize ? "[ext]" : "", calculatedSize(), endOffsetInFile());
}

//void MP4Atom::printStructure() {
//    printStructureWithPadding("");
//}

void _replaceAll(std::string& str, const std::string& from, const std::string& to) {
    if(from.empty())
        return;
    size_t start_pos = 0;
    while((start_pos = str.find(from, start_pos)) != std::string::npos) {
        str.replace(start_pos, from.length(), to);
        start_pos += to.length(); // In case 'to' contains 'from', like replacing 'x' with 'yx'
    }
}

void MP4Atom::printStructureWithPadding(const char *padding) {
    printf("%s", padding);
    printDescription();
    printf("\n");
    
    for (int i = 0; i < _children.size(); i++) {
        MP4Atom atom = _children[i];
        std::string nextPadding(padding);
        _replaceAll(nextPadding, "├", "│");
        _replaceAll(nextPadding, "└", " ");
        _replaceAll(nextPadding, "─", " ");
        
        if (i < _children.size() - 1) {
            nextPadding = nextPadding.append("  ├─");
        } else {
            nextPadding = nextPadding.append("  └─");
        }
        
        atom.printStructureWithPadding(nextPadding.c_str());
    }
}

void MP4Atom::appendAtom(MP4Atom atom) {
    if (atom.size() < 8) {
        return;
    }
    
    atom._parent = this;
    _children.push_back(atom);
}

void MP4Atom::loadPayload(FILE *source) {
    // does nothing by default.
}

size_t MP4Atom::appendPayloadToFile(FILE *file) {
    size_t written = 0;
    if (_payload) {
        written = fwrite(_payload, 1, _payloadSize, file);
    }
    return written;
}
