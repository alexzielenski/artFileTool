//
//  AFFileDescriptor.m
//  artFileTool
//
//  Created by Alex Zielenski on 5/20/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

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
                                         descriptor:self];;
    
    return YES;
}

+ (NSUInteger)expectedLengthForArtFile:(ArtFile *)file
{
    return 12;
}

@end
