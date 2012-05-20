//
//  AFHeader.m
//  artFileTool
//
//  Created by Alex Zielenski on 5/20/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

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
