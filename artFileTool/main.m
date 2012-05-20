//
//  main.m
//  artFileTool
//
//  Created by Alex Zielenski on 6/10/11.
//  Copyright 2011 Alex Zielenski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ArtFile.h"
#include <mach/mach_time.h>

//static const char *help = "Usage:\n\tDecode: -d [-l] [-c] filePath exportDirectory\n\tEncode: -e [-l] [-c] [-v] imageDirectory originalFilePath newFilePath\n\t-l: Use this argument if you are using a Snow Leopard file.\n\t-c: Use this argument to piece the images together/apart.\n";
int main (int argc, const char * argv[])
{

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    uint64_t start = mach_absolute_time();
    ArtFile *file = [ArtFile artFileWithFileAtURL:[NSURL fileURLWithPath:@"/Users/Alex/Desktop/ArtFile_10x8.bin"]];
    [file decodeToFolder:[NSURL fileURLWithPath:@"/Users/Alex/Desktop/artFiles_10x8"] 
                   error:nil];
    uint64_t end = mach_absolute_time(); 
    uint64_t elapsed = end - start; mach_timebase_info_data_t info; 
    mach_timebase_info(&info); 
    uint64_t nanoSeconds = elapsed * info.numer / info.denom; 
    printf ("elapsed time was %lld nanoseconds\n", nanoSeconds);
    
    [pool drain];
    return 0;
}

