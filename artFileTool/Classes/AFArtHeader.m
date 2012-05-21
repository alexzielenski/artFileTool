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
#import "AFFileDescriptor.h"

@interface AFArtHeader ()
- (BOOL)_readFromData:(NSData *)data offset:(NSUInteger)offset;
@end

@implementation AFArtHeader
@synthesize rowAmount      = _rowAmount;
@synthesize columnAmount   = _columnAmount;
@synthesize rectangles     = _rectangles;
@synthesize phase          = _phase;
@synthesize rowHeights     = _rowHeights;
@synthesize columnWidths   = _columnWidths;
@synthesize buffer1        = _buffer1;
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

+ (AFArtHeader *)artHeaderWithImageData:(NSData *)data
{
    return [[[self alloc] initWithImageData:data] autorelease];
}

- (id)initWithImageData:(NSData *)data
{
    if ((self = [self init])) {
        _imageData = [data retain];
    }
    
    return self;
}

- (NSDictionary *)metadata
{
    NSMutableArray *rectangles = [NSMutableArray arrayWithCapacity:3];
    
    for (NSValue *rect in self.rectangles) {
        [rectangles addObject:NSStringFromRect(rect.rectValue)];
    }
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
            rectangles, @"rectangles", 
            [NSNumber numberWithUnsignedShort:self.phase], @"phase", 
            self.buffer1, @"buffer1", 
            self.rowHeights, @"rowHeights",
            self.columnWidths, @"columnWidths", nil];
}

- (void)readMetadata:(NSDictionary *)metadata
{
    NSArray *rects = [metadata objectForKey:@"rectangles"];
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:3];
    
    for (NSString *rect in rects) {
        [values addObject:[NSValue valueWithRect:NSRectFromString(rect)]];
    }
    
    self.rectangles   = values;
    self.phase        = [[metadata objectForKey:@"phase"] unsignedShortValue];
    self.buffer1      = [metadata objectForKey:@"buffer1"];
    self.rowHeights   = [metadata objectForKey:@"rowHeights"];
    self.columnWidths = [metadata objectForKey:@"columnWidths"];
    self.rowAmount    = self.rowHeights.count;
    self.columnAmount = self.columnWidths.count;
}

- (NSSize)totalImageSize
{
    return NSMakeSize([[self valueForKeyPath:@"columnWidths.@sum.self"] unsignedIntegerValue], [[self valueForKeyPath:@"rowHeights.@sum.self"] unsignedIntegerValue]);
}

- (NSRect)rectForRow:(NSUInteger)row column:(NSUInteger)column
{
    NSUInteger width  = [[self.columnWidths objectAtIndex:column] unsignedIntegerValue];
    NSUInteger height = [[self.rowHeights objectAtIndex:row] unsignedIntegerValue];
    NSUInteger x      = 0;
    NSUInteger y      = 0;
    
    // This returns the rectangle of the image from the bottom left rather than the top left
    for (int z = (int)row + 1; z < self.rowHeights.count; z++) {
        y += [[self.rowHeights objectAtIndex:z] unsignedIntegerValue];
    }
    
    for (int z = (int)column - 1; z >= 0; z--) {
        x += [[self.columnWidths objectAtIndex:z] unsignedIntegerValue];
    }
    
    return NSMakeRect(x, y, width, height);
}

- (BOOL)_readFromData:(NSData *)data offset:(NSUInteger)offset
{    
    data.currentOffset = offset;
    
    _rowAmount    = data.nextShort;
    _columnAmount = data.nextShort;
    
    // Get the metadata
    NSRect rect0 = NSMakeRect(data.nextShort, data.nextShort, data.nextShort, data.nextShort);
    NSRect rect1 = NSMakeRect(data.nextShort, data.nextShort, data.nextShort, data.nextShort);
    NSRect rect2 = NSMakeRect(data.nextShort, data.nextShort, data.nextShort, data.nextShort);
    
    self.rectangles = [NSArray arrayWithObjects:[NSValue valueWithRect:rect0], [NSValue valueWithRect:rect1], [NSValue valueWithRect:rect2], nil];
    self.phase      = data.nextShort;
    
    NSMutableArray *rowHeights   = [NSMutableArray arrayWithCapacity:_rowAmount];
    NSMutableArray *columnWidths = [NSMutableArray arrayWithCapacity:_columnAmount];
    
    // Do them at the same time
    uint16_t rows[3];
    [data getBytes:&rows range:NSMakeRange(data.currentOffset, 6)];
    
    uint16_t cols[3];
    [data getBytes:&cols range:NSMakeRange(data.currentOffset + 6, 6)];
    
    data.currentOffset += 12;
    
    for (int x = 0; x < 3; x++) {
        uint16_t currentRow = rows[x];
        uint16_t currentCol = cols[x];
        
        if (currentRow != 0)
            [rowHeights addObject:[NSNumber numberWithUnsignedShort:currentRow]];
        if (currentCol != 0)
            [columnWidths addObject:[NSNumber numberWithUnsignedShort:currentCol]];
    }
    
    self.rowHeights   = rowHeights;
    self.columnWidths = columnWidths;
    
    // 2 more bytes of unknown
    self.buffer1 = [data subdataWithRange:NSMakeRange(data.currentOffset, 2)];
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

- (NSBitmapImageRep *)imageRepresentation
{
    return [NSBitmapImageRep imageRepWithData:self.imageData];
}

- (NSData *)headerData
{
    NSData *imageData = self.imageRepresentation.artFileData;
    NSMutableData *data = [NSMutableData dataWithCapacity:[self.class expectedLengthForArtFile:self.fileDescriptor.artFile] + imageData.length];
    
    // 4 bytes of rows and cols
    [data appendShort:self.rowAmount];
    [data appendShort:self.columnAmount];
    
    // 26 bytes of META
    for (NSValue *value in self.rectangles) {
        NSRect rect = value.rectValue;
        
        [data appendShort:rect.origin.x];
        [data appendShort:rect.origin.y];
        [data appendShort:rect.size.width];
        [data appendShort:rect.size.height];
        
    }
    
    [data appendShort:self.phase];
        
    // Heights
    for (int x = 0; x < 3; x++) {
        NSNumber *currentValue = nil;
        
        if (x < self.rowHeights.count)
            currentValue = [self.rowHeights objectAtIndex:x];
        
        uint16_t value = currentValue ? currentValue.unsignedShortValue : 0;
        [data appendShort:value];
    }
    
    // Widths
    for (int x = 0; x < 3; x++) {
        NSNumber *currentValue = nil;
        
        if (x < self.columnWidths.count)
            currentValue = [self.columnWidths objectAtIndex:x];
        
        uint16_t value = currentValue ? currentValue.unsignedShortValue : 0;
        [data appendShort:value];
    }
    
    // buffer1
    [data appendData:self.buffer1];
    
    // raw image data
    [data appendData:imageData];
    
    
    return data;
}

@end
