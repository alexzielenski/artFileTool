//
//  AFFileDescriptor.m
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

#import "AFFileDescriptor.h"
#import "NSData+Byte.h"
#import "ArtFile.h"

@interface AFFileDescriptor ()
- (BOOL)_readFromData:(NSData *)data offset:(NSUInteger)offset;
@end

@implementation AFFileDescriptor
@synthesize dataOffset = _dataOffset;
@synthesize tagIndices = _tagIndices;
@synthesize artFile    = _artFile;
@synthesize artHeader  = _artHeader;

+ (AFFileDescriptor *)fileDescriptorWithData:(NSData *)data offset:(NSUInteger)offset artFile:(ArtFile *)artFile
{
    return [[[self alloc] initWithData:data offset:offset artFile:artFile] autorelease];
}

- (id)initWithData:(NSData *)data offset:(NSUInteger)offset artFile:(ArtFile *)artFile
{
    if ((self = [self init])) {
        self.artFile = artFile;
        
        if (![self _readFromData:data offset:offset]) {
            [self release];
            return nil;
        }
    }
    
    return self;
}

+ (AFFileDescriptor *)fileDescriptorWithURL:(NSURL *)url artFile:(ArtFile *)artFile
{
    return [[[self alloc] initWithURL:url artFile:artFile] autorelease];
}

- (id)initWithURL:(NSURL *)url artFile:(ArtFile *)artFile
{
    if ((self = [self init])) {
        self.artFile = artFile;
        
        NSString *fileName = [url.lastPathComponent stringByDeletingPathExtension];
        NSArray *tagNames  = [fileName componentsSeparatedByString:@"."];
        
        NSMutableArray *tagIndices = [NSMutableArray arrayWithCapacity:8];
                
        for (NSString *tagName in tagNames) {
            NSArray *allKeys = [artFile.tags allKeysForObject:tagName];
            if (allKeys.count > 0)
                [tagIndices addObject:[NSNumber numberWithUnsignedShort:(uint16_t)[[allKeys objectAtIndex:0] intValue]]];
            
        }
        
        self.tagIndices = tagIndices;
        
        self.artHeader = [AFArtHeader artHeaderWithImageData:[NSData dataWithContentsOfURL:url]];
        self.artHeader.fileDescriptor = self;
    }
    
    return self;
}

- (BOOL)_readFromData:(NSData *)data offset:(NSUInteger)offset
{
    data.currentOffset = offset;
    self.dataOffset = data.nextInt;
    
    uint8_t tags[8];
    [data getBytes:&tags range:NSMakeRange(data.currentOffset, sizeof(tags))];
    
    // Get the tag name
    NSMutableArray *indices = [NSMutableArray arrayWithCapacity:sizeof(tags) / sizeof(tags[0])];
    
    uint8_t currentTag = 0;
    uint8_t j = 0;
    
    while ((currentTag = tags[j]) != 0 && j < (sizeof(tags) / sizeof(tags[0]))) {
        [indices addObject:[NSNumber numberWithUnsignedChar:currentTag]];
        j++;
    }
    
    self.tagIndices = indices;
    
    // Get the file header
    self.artHeader = [AFArtHeader artHeaderWithData:data 
                                             offset:self.dataOffset + self.artFile.header.fileDataOffset
                                         descriptor:self];
    
    return YES;
}

+ (NSUInteger)expectedLengthForArtFile:(ArtFile *)file
{
    return 12;
}

- (NSData *)headerData
{
    NSMutableData *data = [NSMutableData dataWithCapacity:12];
    [data appendInt:(uint32_t)self.dataOffset];
    
    for (NSNumber *tag in self.tagIndices)
        [data appendByte:tag.unsignedCharValue];
    
    for (int x = (int)self.tagIndices.count; x < 8; x++)
        [data appendByte:0];
    
    return data;
}

- (NSString *)fullname
{
	return [self.artFile nameForDescriptor:self];
}

@end
