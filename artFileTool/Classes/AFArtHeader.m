//
//  AFArtHeader.m
//  artFileTool
//
//  Created by Alex Zielenski on 5/20/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

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
