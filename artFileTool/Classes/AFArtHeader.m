//
//  AFArtHeader.m
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

#import "AFArtHeader.h"
#import "NSImageRep+Data.h"
#import "NSData+Byte.h"

@interface AFArtHeader ()
- (BOOL)_readFromData:(NSData *)data offset:(NSUInteger)offset;
@end

@implementation AFArtHeader
@synthesize rowAmount      = _rowAmount;
@synthesize columnAmount   = _columnAmount;
@synthesize buffer1        = _buffer1;
@synthesize rowHeights     = _rowHeights;
@synthesize columnWidths   = _columnWidths;
@synthesize buffer2        = _buffer2;
@synthesize imageData      = _imageData;
@synthesize fileDescriptor = _fileDescriptor;

+ (AFArtHeader *)artHeaderWithData:(NSData *)data offset:(NSUInteger)offset descriptor:(AFFileDescriptor *)descriptor
{
    return [[[self alloc] initWithData:data offset:offset descriptor:descriptor] autorelease];
}

- (id)initWithData:(NSData *)data offset:(NSUInteger)offset descriptor:(AFFileDescriptor *)descriptor
{
    if ((self = [self init])) {
        _fileDescriptor = descriptor;
        
        if (![self _readFromData:data offset:offset]) {
            [self release];
            return nil;
        }
            
    }
    
    return self;
}

- (NSSize)totalImageSize
{
    return NSMakeSize([[self valueForKeyPath:@"columnWidths.@sum.self"] unsignedIntegerValue], [[self valueForKeyPath:@"rowHeights.@sum.self"] unsignedIntegerValue]);
}

- (NSRect)rectForRow:(NSUInteger)row column:(NSUInteger)column
{
    return NSZeroRect;
}

- (BOOL)_readFromData:(NSData *)data offset:(NSUInteger)offset
{
    NSLog(@"%lu", offset);
    
    data.currentOffset = offset;
    
    self.rowAmount = data.nextShort;
    self.columnAmount = data.nextShort;
    
    // Jump over the metadata
    self.buffer1 = [data subdataWithRange:NSMakeRange(data.currentOffset, 26)];
    data.currentOffset += 26;
    
    self.rowHeights = [NSArray arrayWithObjects:
                       [NSNumber numberWithUnsignedShort:data.nextShort],
                       [NSNumber numberWithUnsignedShort:data.nextShort],
                       [NSNumber numberWithUnsignedShort:data.nextShort], nil];
    
    self.columnWidths = [NSArray arrayWithObjects:
                         [NSNumber numberWithUnsignedShort:data.nextShort],
                         [NSNumber numberWithUnsignedShort:data.nextShort],
                         [NSNumber numberWithUnsignedShort:data.nextShort], nil];
    
    // 2 more bytes of unknown
    self.buffer2 = [data subdataWithRange:NSMakeRange(data.currentOffset, 2)];
    data.currentOffset += 2;
    
    NSSize totalSize = self.totalImageSize;
    NSUInteger dataLength = totalSize.width * totalSize.height * 4;
        
    NSData *rawData = [data subdataWithRange:NSMakeRange(data.currentOffset, dataLength)];
    NSBitmapImageRep *processedImage = [NSBitmapImageRep imageRepWithArtFileData:rawData size:totalSize];
    
    self.imageData = [processedImage representationUsingType:NSPNGFileType properties:nil];
    return YES;
}

+ (NSUInteger)expectedLengthForArtFile:(ArtFile *)file
{
    return 44;
}

@end
