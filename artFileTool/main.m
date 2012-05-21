//
//  main.m
//  artFileTool
//
//  Copyright (c) 2011-2012, Alex Zielenski
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided 
//  that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright notice, this list of conditions and the 
//    following disclaimer.
//  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the 
//    following disclaimer in the documentation and/or other materials provided with the distribution.
//  * Any redistribution, use, or modification is done solely for personal benefit and not for any commercial 
//    purpose or for monetary gain

//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS 
//  OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
//  AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS 
//  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
//  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY 
//  OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import <Foundation/Foundation.h>
#import "ArtFile.h"
#include <mach/mach_time.h>

//static const char *help = "Usage:\n\tDecode: -d [-l] [-c] filePath exportDirectory\n\tEncode: -e [-l] [-c] [-v] imageDirectory originalFilePath newFilePath\n\t-l: Use this argument if you are using a Snow Leopard file.\n\t-c: Use this argument to piece the images together/apart.\n";
int main (int argc, const char * argv[])
{

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    uint64_t start = mach_absolute_time();
    
    ArtFile *file = [ArtFile artFileWithFileAtURL:[NSURL fileURLWithPath:@"/Users/Alex/Desktop/ArtFile_10x8.bin"]];
    [file decodeToFolder:[NSURL fileURLWithPath:@"/Users/Alex/Desktop/artFiles_10x8"] error:nil];
	
    ArtFile *encode = [ArtFile artFileWithFolderAtURL:[NSURL fileURLWithPath:@"/Users/Alex/Desktop/artFiles_10x8"]];
	[encode.data writeToFile:@"/Users/Alex/Desktop/ArtFile.new_10x8.bin" atomically:NO];

	ArtFile *decode = [ArtFile artFileWithFileAtURL:[NSURL fileURLWithPath:@"/Users/Alex/Desktop/ArtFile.new_10x8.bin"]];
    [decode decodeToFolder:[NSURL fileURLWithPath:@"/Users/Alex/Desktop/artFiles2_10x8"] error:nil];
	
    uint64_t end = mach_absolute_time();
    uint64_t elapsed = end - start;
    mach_timebase_info_data_t info;
    mach_timebase_info(&info);
    uint64_t nanoSeconds = elapsed * info.numer / info.denom;
//    printf ("elapsed time was %lld nanoseconds\n", nanoSeconds);
    

//    [encode decodeToFolder:[NSURL fileURLWithPath:@"/Users/Alex/Desktop/artFiles3_10x8"] error:nil];
    
    end = mach_absolute_time(); 
    elapsed = end - start;
    mach_timebase_info(&info); 
    nanoSeconds = elapsed * info.numer / info.denom; 
    printf ("elapsed time was %lld nanoseconds\n", nanoSeconds);
    
    [pool drain];
    return 0;
}

