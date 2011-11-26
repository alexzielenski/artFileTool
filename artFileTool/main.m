//
//  main.m
//  artFileTool
//
//  Created by Alex Zielenski on 6/10/11.
//  Copyright 2011 Alex Zielenski. All rights reserved.
//

#include "decoder.h"
#include "encoder.h"

#define __DEBUG__
//#define __DECODE__

static const char *help = "Usage:\n\tDecode: -d [-l] [-c] filePath exportDirectory\n\tEncode: -e [-l] [-c] [-v] imageDirectory originalFilePath newFilePath\n\t-l: Use this argument if you are using a Snow Leopard file.\n\t-c: Use this argument to piece the images together/apart.\n";
int main (int argc, const char * argv[])
{
	
#ifdef __DEBUG__
#ifdef __DECODE__
	argc = 5;
	argv[1] = "-d";
	argv[2] = "-c";
	argv[3] = "/Users/Alex/Library/Developer/Xcode/DerivedData/artFileTool-hfscovimcodavkfrdkithbavgypc/Build/Products/Debug/ArtFile.bin";
	argv[4] = "/Users/Alex/Library/Developer/Xcode/DerivedData/artFileTool-hfscovimcodavkfrdkithbavgypc/Build/Products/Debug/artFiles";
#else
	argc = 6;
	argv[1] = "-e";
	argv[2] = "-c";
	argv[3] = "/Users/Alex/Library/Developer/Xcode/DerivedData/artFileTool-hfscovimcodavkfrdkithbavgypc/Build/Products/Debug/artFiles";
	argv[4] = "/Users/Alex/Library/Developer/Xcode/DerivedData/artFileTool-hfscovimcodavkfrdkithbavgypc/Build/Products/Debug/ArtFile.bin";
	argv[5] = "/Users/Alex/Library/Developer/Xcode/DerivedData/artFileTool-hfscovimcodavkfrdkithbavgypc/Build/Products/Debug/ArtFile.new.bin";
#endif
#endif
	
	if (argc < 3) {
        printf(help, NULL);
        return 1; // failure
    }
	
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	BOOL decode = NO;
	BOOL encode = NO;
	
	int startIdx = 0;
	for (int x = 1; x < argc; x++) {
		if ((!strcmp(argv[x], "-l"))) {
			legacy = YES;
			continue;
		} else if  ((!strcmp(argv[x], "-d"))) {
			decode = YES;
			encode = NO;
			continue;
		} else if  ((!strcmp(argv[x], "-e"))) {
			encode = YES;
			decode = NO;
			continue;
		} else if  ((!strcmp(argv[x], "-c"))) {
			connect = YES;
			continue;
		} else if ((!strcmp(argv[x], "-v"))) {
			verbose=YES;
			continue;
		} else {
			startIdx = x;
			break;
		}
	}
	

	if (legacy)
		printf("Using legacy mode…\n");
	if (connect)
		printf("Connecting Images\n");
	if (decode)
		printf("Decoding Files\n");
	if (encode)
		printf("Encoding Files\n");
	if (verbose)
		printf("Verbose mode\n");
	
    if (decode) {
		NSString *exportDir;
		NSString *file;
		
		file = [NSString stringWithUTF8String:argv[startIdx]];
		exportDir = [NSString stringWithUTF8String:argv[startIdx+1]];
        
		return !(artfile_decode(file, exportDir));
    } else if (encode) {
		NSString *dir;
		NSString *file;
		NSString *dest;
						
		dir = [NSString stringWithUTF8String:argv[startIdx]];
		file = [NSString stringWithUTF8String:argv[startIdx+1]];
		dest = [NSString stringWithUTF8String:argv[startIdx+2]];
		
		return !(artfile_encode(dir, file, dest));
    } else { // invalid first argument
        printf(help, NULL);
        [pool drain];
        return 1;
    }
	
    [pool drain];
    return 0;
}

