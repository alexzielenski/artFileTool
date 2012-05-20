//
//  AFFileDescriptor.h
//  artFileTool
//
//  Created by Alex Zielenski on 5/20/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFArtHeader.h"

@class ArtFile;
@interface AFFileDescriptor : NSObject

@property (assign) NSUInteger dataOffset;
@property (retain) NSArray   *tagIndices;
@property (assign) ArtFile   *artFile;

@property (retain) AFArtHeader *artHeader;

+ (AFFileDescriptor *)fileDescriptorWithData:(NSData *)data offset:(NSUInteger)offset artFile:(ArtFile *)artFile;
- (id)initWithData:(NSData *)data offset:(NSUInteger)offset artFile:(ArtFile *)artFile;

+ (NSUInteger)expectedLengthForArtFile:(ArtFile *)file;

@end
