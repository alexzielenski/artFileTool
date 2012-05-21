//
//  AFArtHeader.h
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

#import <Cocoa/Cocoa.h>

@class AFFileDescriptor, ArtFile;

@interface AFArtHeader : NSObject
@property (assign) uint16_t rowAmount;     // 1-3
@property (assign) uint16_t columnAmount;  // 1-3
@property (retain) NSArray  *rectangles;   // rect0, rect1, rect2. There will always be three rectangles
@property (assign) uint16_t phase;         // Looks like a type flag for the control
@property (retain) NSArray  *rowHeights;   // Height of each row in their respective order
@property (retain) NSArray  *columnWidths; // read above
@property (retain) NSData   *buffer1;      // 2 bytes of the unknown

@property (retain) NSData   *imageData;    // PNG data of the image in question
@property (assign) AFFileDescriptor *fileDescriptor;

+ (AFArtHeader *)artHeaderWithData:(NSData *)data offset:(NSUInteger)offset descriptor:(AFFileDescriptor *)descriptor;
- (id)initWithData:(NSData *)data offset:(NSUInteger)offset descriptor:(AFFileDescriptor *)descriptor;

+ (AFArtHeader *)artHeaderWithImageData:(NSData *)data;
- (id)initWithImageData:(NSData *)data;

+ (NSUInteger)expectedLengthForArtFile:(ArtFile *)file;

- (NSDictionary *)metadata;
- (void)readMetadata:(NSDictionary *)metadata;

- (NSSize)totalImageSize;
- (NSRect)rectForRow:(NSUInteger)row column:(NSUInteger)column;

- (NSBitmapImageRep *)imageRepresentation;

- (NSData *)headerData;

@end
