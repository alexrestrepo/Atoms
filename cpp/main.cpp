//
//  main.cpp
//  QTParse
//
//  Created by Alex Restrepo on 11/17/16.
//

#include <iostream>

#include "MP4File.h"

int main(int argc, const char * argv[]) {
    if (argc < 2) {
        std::cout << "Usage: atoms pathToFile\n";
        return 0;
    }
    
    MP4File file(argv[1]);
    if (file.atoms().size()) {
        std::cout << argv[1] << "\n";
        file.printStructure();
        
//        std::cout << "\n\nVideo Track:\n";
//
//        MP4Atom *videoTrack = file.videoTrackAtom();
//        if (videoTrack->size()) {
//            const char *spherical_payload = "\xff\xcc\x82\x63\xf8\x55\x4a\x93\x88\x14\x58\x7a\x02\x52\x1f\xdd"
//            "<?xml version=\"1.0\"?>"
//            "<rdf:SphericalVideo\n"
//            "xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"\n"
//            "xmlns:GSpherical=\"http://ns.google.com/videos/1.0/spherical/\">"
//            "<GSpherical:Spherical>true</GSpherical:Spherical>"
//            "<GSpherical:Stitched>true</GSpherical:Stitched>"
//            "<GSpherical:StitchingSoftware>"
//            "Spherical Metadata Tool"  // TODO: ???
//            "</GSpherical:StitchingSoftware>"
//            "<GSpherical:ProjectionType>equirectangular</GSpherical:ProjectionType>"
//            "</rdf:SphericalVideo>";
//
//            MP4Atom uuid = MP4Atom::atomWithPayload('uuid', (void *)spherical_payload, strlen(spherical_payload));
//            videoTrack->appendAtom(uuid);
//
//            videoTrack->printStructure();
//        }
//
//        const char *savePath = "/Users/alex/Desktop/test.mp4";
//        if (file.saveToPath(savePath)) {
//            MP4File saved(savePath);
//            saved.printStructure();
//        }
    } else {
        std::cout << "No atoms found or invalid file.\n";
    }
    
    return 0;
}
