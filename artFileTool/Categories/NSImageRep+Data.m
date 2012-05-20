//
//  NSImageRep+Data.m
//  SArtFileTool
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

#import "NSImageRep+Data.h"
#import <Accelerate/Accelerate.h>

@implementation NSBitmapImageRep (DataAdditions)

+ (NSBitmapImageRep *)imageRepWithArtFileData:(NSData *)data size:(NSSize)size
{
    return [[[self alloc] initWithArtFileData:data size:size] autorelease];
}

- (id)initWithArtFileData:(NSData *)data size:(NSSize)size
{
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGImageAlphaFirst | kCGBitmapByteOrder32Little;
    
    CGImageRef cgImage = CGImageCreate(size.width, size.height, 8, 32, 4 * size.width, 
                                       colorSpace, bitmapInfo, provider, NULL, NO, 
                                       kCGRenderingIntentDefault);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return [self initWithCGImage:cgImage];
}

@end

@implementation NSImageRep (DataAdditions)

- (NSData *)artFileData
{
    // If we are an NSPDFImageRep instance
    if ([self respondsToSelector:@selector(PDFRepresentation)])
        return [self performSelector:@selector(PDFRepresentation)];
    
    if (![self isKindOfClass:[NSBitmapImageRep class]])
        return nil;
    
    NSBitmapImageRep *bitmapSelf = (NSBitmapImageRep *)self;
    NSInteger width  = [bitmapSelf pixelsWide];
    NSInteger height = [bitmapSelf pixelsHigh];
    
    BOOL alphaFirst = (bitmapSelf.bitmapFormat & NSAlphaFirstBitmapFormat);
    
    if (width == 0 || height == 0)
        return nil;
    
    unsigned char *bytes = [bitmapSelf bitmapData];
    
    vImage_Buffer src;
    src.data     = (void*)bytes;
    src.width    = width;
    src.height   = height;
    src.rowBytes = 4 * width;
        
    uint8_t permuteMap[4]; // RGBA

    if (alphaFirst) {
        // ARGB to BGRA
        permuteMap[0] = 3;
        permuteMap[1] = 2;
        permuteMap[2] = 1;
        permuteMap[3] = 0;
    } else {
        // RGBA to BGRA
        permuteMap[0] = 2;
        permuteMap[1] = 1;
        permuteMap[2] = 0;
        permuteMap[3] = 3;
    }
    
    vImagePermuteChannels_ARGB8888(&src, &src, permuteMap, 0);
        
    if (!(bitmapSelf.bitmapFormat & NSAlphaNonpremultipliedBitmapFormat)) {
        vImageUnpremultiplyData_BGRA8888(&src, &src, 0);
    }
    
    return [NSData dataWithBytesNoCopy:src.data length:width * height * 4 freeWhenDone:NO];
    
}

@end
