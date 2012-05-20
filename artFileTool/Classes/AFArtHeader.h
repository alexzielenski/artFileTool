//
//  AFArtHeader.h
//  artFileTool
//
//  Created by Alex Zielenski on 5/20/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AFFileDescriptor, ArtFile;

@interface AFArtHeader : NSObject
@property (assign) uint16_t rowAmount;     // 1-3
@property (assign) uint16_t columnAmount;  // 1-3
@property (retain) NSData   *buffer1;      // 26 bytes of the unknown
@property (retain) NSArray  *rowHeights;   // Height of each row in their respective order
@property (retain) NSArray  *columnWidths; // read above
@property (retain) NSData   *buffer2;      // 2 bytes of the unknown

@property (retain) NSData   *imageData;
@property (assign) AFFileDescriptor *fileDescriptor;

+ (AFArtHeader *)artHeaderWithData:(NSData *)data offset:(NSUInteger)offset descriptor:(AFFileDescriptor *)descriptor;
- (id)initWithData:(NSData *)data offset:(NSUInteger)offset descriptor:(AFFileDescriptor *)descriptor;

+ (NSUInteger)expectedLengthForArtFile:(ArtFile *)file;

- (NSSize)totalImageSize;
- (NSRect)rectForRow:(NSUInteger)row column:(NSUInteger)column;

@end
