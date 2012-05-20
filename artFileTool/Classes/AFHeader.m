//
//  AFHeader.m
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

#import "AFHeader.h"
#import "NSData+Byte.h"

@interface AFHeader ()
- (void)_readHeaderFromData:(NSData *)data;
@end

@implementation AFHeader
@synthesize artFile               = _artFile;
@synthesize fileAmount            = _fileAmount;
@synthesize maximumDepth          = _maximumDepth;
@synthesize tagAmount             = _tagAmount;
@synthesize tagDescriptorsOffset  = _tagDescriptorsOffset;
@synthesize tagNamesOffset        = _tagNamesOffset;
@synthesize fileDescriptorsOffset = _fileDescriptorsOffset;
@synthesize fileDataOffset        = _fileDataOffset;

+ (AFHeader *)headerWithData:(NSData *)data artFile:(ArtFile *)file
{
    return [[[self alloc] initWithData:data artFile:file] autorelease];
}

- (id)initWithData:(NSData *)data artFile:(ArtFile *)file
{
    if ((self = [self init])) {
        _artFile = file;
        [self _readHeaderFromData:data];
    }
    
    return self;
}

- (void)_readHeaderFromData:(NSData *)data
{
    data.currentOffset         = 0;
    
    self.fileAmount            = data.nextShort;
    self.maximumDepth          = data.nextShort;
    self.tagAmount             = data.nextInt;
    self.tagDescriptorsOffset  = data.nextInt;
    self.tagNamesOffset        = data.nextInt;
    self.fileDescriptorsOffset = data.nextInt;
    self.fileDataOffset        = data.nextInt;
}

@end
